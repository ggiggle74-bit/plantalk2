-- Admin-controlled global policy. Change reset_interval_days in the Supabase
-- SQL editor; clients have no table privileges and no app release is required.
create table if not exists public.deep_health_usage_policy (
  policy_key text primary key default 'default'
    check (policy_key = 'default'),
  reset_interval_days integer not null default 30
    check (reset_interval_days between 1 and 365),
  updated_at timestamptz not null default now()
);

insert into public.deep_health_usage_policy (
  policy_key,
  reset_interval_days
)
values ('default', 30)
on conflict (policy_key) do nothing;

alter table public.deep_health_usage_policy enable row level security;

revoke all on table public.deep_health_usage_policy from anon, authenticated;

create or replace function public.reserve_deep_health_assessment_usage()
returns table (
  allowed boolean,
  requires_payment boolean,
  reservation_id uuid,
  free_remaining integer,
  current_usage integer,
  usage_limit integer,
  reset_at timestamptz
)
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_limit integer;
  v_occupied integer;
  v_reservation_id uuid;
  v_reset_interval_days integer;
  v_window_started_at timestamptz;
  v_reset_at timestamptz;
begin
  if v_user_id is null then
    raise exception 'authentication_required' using errcode = '28000';
  end if;

  select policy.reset_interval_days
    into v_reset_interval_days
    from public.deep_health_usage_policy as policy
    where policy.policy_key = 'default';

  if not found then
    raise exception 'deep_health_usage_policy_missing';
  end if;

  v_window_started_at := now() -
    make_interval(days => v_reset_interval_days);

  insert into public.deep_health_usage_accounts (user_id)
  values (v_user_id)
  on conflict (user_id) do nothing;

  select account.free_limit
    into v_limit
    from public.deep_health_usage_accounts as account
    where account.user_id = v_user_id
    for update;

  update public.deep_health_usage_reservations as reservation
    set status = 'expired',
        updated_at = now()
    where reservation.user_id = v_user_id
      and reservation.status in ('reserved', 'claimed')
      and reservation.expires_at <= now();

  select count(*)::integer
    into v_occupied
    from public.deep_health_usage_reservations as reservation
    where reservation.user_id = v_user_id
      and (
        (
          reservation.status = 'committed'
          and reservation.committed_at > v_window_started_at
        )
        or (
          reservation.status in ('reserved', 'claimed')
          and reservation.expires_at > now()
        )
      );

  if v_occupied >= v_limit then
    select min(
      case
        when reservation.status = 'committed' then
          reservation.committed_at +
            make_interval(days => v_reset_interval_days)
        else reservation.expires_at
      end
    )
      into v_reset_at
      from public.deep_health_usage_reservations as reservation
      where reservation.user_id = v_user_id
        and (
          (
            reservation.status = 'committed'
            and reservation.committed_at > v_window_started_at
          )
          or (
            reservation.status in ('reserved', 'claimed')
            and reservation.expires_at > now()
          )
        );

    return query
    select false, true, null::uuid, 0, v_occupied, v_limit, v_reset_at;
    return;
  end if;

  insert into public.deep_health_usage_reservations (user_id)
  values (v_user_id)
  returning id into v_reservation_id;

  update public.deep_health_usage_accounts
    set updated_at = now()
    where user_id = v_user_id;

  return query
  select
    true,
    false,
    v_reservation_id,
    greatest(v_limit - v_occupied, 0),
    v_occupied,
    v_limit,
    null::timestamptz;
end;
$$;

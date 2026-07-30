create table if not exists public.deep_health_usage_accounts (
  user_id uuid primary key references auth.users(id) on delete cascade,
  free_limit integer not null default 1 check (free_limit >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.deep_health_usage_reservations (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'reserved'
    check (status in ('reserved', 'committed', 'released', 'expired')),
  expires_at timestamptz not null default (now() + interval '15 minutes'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  committed_at timestamptz,
  released_at timestamptz
);

create index if not exists deep_health_usage_reservations_user_status_idx
  on public.deep_health_usage_reservations (user_id, status, expires_at);

alter table public.deep_health_usage_accounts enable row level security;
alter table public.deep_health_usage_reservations enable row level security;

revoke all on table public.deep_health_usage_accounts from anon, authenticated;
revoke all on table public.deep_health_usage_reservations from anon, authenticated;

create or replace function public.reserve_deep_health_assessment_usage()
returns table (
  allowed boolean,
  requires_payment boolean,
  reservation_id uuid,
  free_remaining integer,
  current_usage integer,
  usage_limit integer
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
begin
  if v_user_id is null then
    raise exception 'authentication_required' using errcode = '28000';
  end if;

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
      and reservation.status = 'reserved'
      and reservation.expires_at <= now();

  select count(*)::integer
    into v_occupied
    from public.deep_health_usage_reservations as reservation
    where reservation.user_id = v_user_id
      and (
        reservation.status = 'committed'
        or (
          reservation.status = 'reserved'
          and reservation.expires_at > now()
        )
      );

  if v_occupied >= v_limit then
    return query
    select false, true, null::uuid, 0, v_occupied, v_limit;
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
    v_limit;
end;
$$;

create or replace function public.commit_deep_health_assessment_usage(
  p_reservation_id uuid
)
returns table (
  reservation_id uuid,
  reservation_status text
)
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_status text;
  v_expires_at timestamptz;
begin
  if v_user_id is null then
    raise exception 'authentication_required' using errcode = '28000';
  end if;

  select reservation.status, reservation.expires_at
    into v_status, v_expires_at
    from public.deep_health_usage_reservations as reservation
    where reservation.id = p_reservation_id
      and reservation.user_id = v_user_id
    for update;

  if not found then
    raise exception 'reservation_not_found' using errcode = '22023';
  end if;

  if v_status = 'reserved' and v_expires_at <= now() then
    update public.deep_health_usage_reservations
      set status = 'expired',
          updated_at = now()
      where id = p_reservation_id;

    return query select p_reservation_id, 'expired'::text;
    return;
  end if;

  if v_status = 'reserved' then
    update public.deep_health_usage_reservations
      set status = 'committed',
          committed_at = now(),
          updated_at = now()
      where id = p_reservation_id;

    v_status := 'committed';
  end if;

  return query select p_reservation_id, v_status;
end;
$$;

create or replace function public.release_deep_health_assessment_usage(
  p_reservation_id uuid
)
returns table (
  reservation_id uuid,
  reservation_status text
)
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare
  v_user_id uuid := auth.uid();
  v_status text;
  v_expires_at timestamptz;
begin
  if v_user_id is null then
    raise exception 'authentication_required' using errcode = '28000';
  end if;

  select reservation.status, reservation.expires_at
    into v_status, v_expires_at
    from public.deep_health_usage_reservations as reservation
    where reservation.id = p_reservation_id
      and reservation.user_id = v_user_id
    for update;

  if not found then
    raise exception 'reservation_not_found' using errcode = '22023';
  end if;

  if v_status = 'reserved' and v_expires_at <= now() then
    update public.deep_health_usage_reservations
      set status = 'expired',
          updated_at = now()
      where id = p_reservation_id;

    v_status := 'expired';
  elsif v_status = 'reserved' then
    update public.deep_health_usage_reservations
      set status = 'released',
          released_at = now(),
          updated_at = now()
      where id = p_reservation_id;

    v_status := 'released';
  end if;

  return query select p_reservation_id, v_status;
end;
$$;

revoke all on function public.reserve_deep_health_assessment_usage() from public, anon;
revoke all on function public.commit_deep_health_assessment_usage(uuid) from public, anon;
revoke all on function public.release_deep_health_assessment_usage(uuid) from public, anon;

grant execute on function public.reserve_deep_health_assessment_usage()
  to authenticated;
grant execute on function public.commit_deep_health_assessment_usage(uuid)
  to authenticated;
grant execute on function public.release_deep_health_assessment_usage(uuid)
  to authenticated;

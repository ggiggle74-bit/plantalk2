alter table public.deep_health_usage_reservations
  add column if not exists claimed_at timestamptz;

alter table public.deep_health_usage_reservations
  drop constraint if exists deep_health_usage_reservations_status_check;

alter table public.deep_health_usage_reservations
  add constraint deep_health_usage_reservations_status_check
  check (
    status in ('reserved', 'claimed', 'committed', 'released', 'expired')
  );

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
      and reservation.status in ('reserved', 'claimed')
      and reservation.expires_at <= now();

  select count(*)::integer
    into v_occupied
    from public.deep_health_usage_reservations as reservation
    where reservation.user_id = v_user_id
      and (
        reservation.status = 'committed'
        or (
          reservation.status in ('reserved', 'claimed')
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

create or replace function public.claim_deep_health_assessment_usage(
  p_reservation_id uuid
)
returns table (
  claimed boolean,
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

  if v_status in ('reserved', 'claimed') and v_expires_at <= now() then
    update public.deep_health_usage_reservations
      set status = 'expired',
          updated_at = now()
      where id = p_reservation_id;

    return query select false, p_reservation_id, 'expired'::text;
    return;
  end if;

  if v_status = 'reserved' then
    update public.deep_health_usage_reservations
      set status = 'claimed',
          claimed_at = now(),
          updated_at = now()
      where id = p_reservation_id;

    return query select true, p_reservation_id, 'claimed'::text;
    return;
  end if;

  return query select false, p_reservation_id, v_status;
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

  if v_status in ('reserved', 'claimed') and v_expires_at <= now() then
    update public.deep_health_usage_reservations
      set status = 'expired',
          updated_at = now()
      where id = p_reservation_id;

    return query select p_reservation_id, 'expired'::text;
    return;
  end if;

  if v_status in ('reserved', 'claimed') then
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

  if v_status in ('reserved', 'claimed') and v_expires_at <= now() then
    update public.deep_health_usage_reservations
      set status = 'expired',
          updated_at = now()
      where id = p_reservation_id;

    v_status := 'expired';
  elsif v_status in ('reserved', 'claimed') then
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

revoke all on function public.claim_deep_health_assessment_usage(uuid)
  from public, anon;

grant execute on function public.claim_deep_health_assessment_usage(uuid)
  to authenticated;

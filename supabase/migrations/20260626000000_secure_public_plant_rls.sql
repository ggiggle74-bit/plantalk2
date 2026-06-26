-- RLS-1: secure Plantalk public plant data access.
-- This migration records the remote RLS hardening applied during MVP security cleanup.
-- It is intentionally idempotent because early Plantalk schema work existed before
-- complete Supabase CLI migrations were introduced.

do $$
begin
  if to_regclass('public.dialogues') is not null then
    alter table public.dialogues enable row level security;

    drop policy if exists "Allow client read non-draft dialogues" on public.dialogues;
    create policy "Allow client read non-draft dialogues"
    on public.dialogues
    for select
    to anon, authenticated
    using (
      situation is not null
      and situation <> 'draft'
    );
  end if;
end $$;

do $$
begin
  if to_regclass('public.plants') is not null then
    alter table public.plants
    add column if not exists user_id uuid references auth.users(id) on delete cascade;

    update public.plants
    set user_id = (
      select id
      from auth.users
      where is_anonymous = true
      order by created_at desc
      limit 1
    )
    where user_id is null
      and exists (
        select 1
        from auth.users
        where is_anonymous = true
      );

    create index if not exists idx_plants_user_id
    on public.plants(user_id);

    alter table public.plants enable row level security;

    drop policy if exists "Allow owner select plants" on public.plants;
    drop policy if exists "Allow owner insert plants" on public.plants;
    drop policy if exists "Allow owner update plants" on public.plants;
    drop policy if exists "Allow owner delete plants" on public.plants;

    create policy "Allow owner select plants"
    on public.plants
    for select
    to authenticated
    using (
      auth.uid() is not null
      and auth.uid() = user_id
    );

    create policy "Allow owner insert plants"
    on public.plants
    for insert
    to authenticated
    with check (
      auth.uid() is not null
      and auth.uid() = user_id
    );

    create policy "Allow owner update plants"
    on public.plants
    for update
    to authenticated
    using (
      auth.uid() is not null
      and auth.uid() = user_id
    )
    with check (
      auth.uid() is not null
      and auth.uid() = user_id
    );

    create policy "Allow owner delete plants"
    on public.plants
    for delete
    to authenticated
    using (
      auth.uid() is not null
      and auth.uid() = user_id
    );
  end if;
end $$;

do $$
begin
  if to_regclass('public.plant_memories') is not null then
    alter table public.plant_memories enable row level security;

    drop policy if exists "Allow anonymous select plant memories" on public.plant_memories;
    drop policy if exists "Allow anonymous insert plant memories" on public.plant_memories;
    drop policy if exists "Allow owner select plant memories" on public.plant_memories;
    drop policy if exists "Allow owner insert plant memories" on public.plant_memories;

    create policy "Allow owner select plant memories"
    on public.plant_memories
    for select
    to authenticated
    using (
      exists (
        select 1
        from public.plants p
        where p.id = plant_memories.plant_id
          and p.user_id = auth.uid()
      )
    );

    create policy "Allow owner insert plant memories"
    on public.plant_memories
    for insert
    to authenticated
    with check (
      exists (
        select 1
        from public.plants p
        where p.id = plant_memories.plant_id
          and p.user_id = auth.uid()
      )
    );
  end if;
end $$;

do $$
begin
  if to_regclass('public.plant_photos') is not null then
    alter table public.plant_photos enable row level security;

    drop policy if exists "Allow anon insert plant photo history during MVP" on public.plant_photos;
    drop policy if exists "Allow owner select plant photos" on public.plant_photos;
    drop policy if exists "Allow owner insert plant photos" on public.plant_photos;

    create policy "Allow owner select plant photos"
    on public.plant_photos
    for select
    to authenticated
    using (
      exists (
        select 1
        from public.plants p
        where p.id = plant_photos.plant_id
          and p.user_id = auth.uid()
      )
    );

    create policy "Allow owner insert plant photos"
    on public.plant_photos
    for insert
    to authenticated
    with check (
      exists (
        select 1
        from public.plants p
        where p.id = plant_photos.plant_id
          and p.user_id = auth.uid()
      )
    );
  end if;
end $$;

notify pgrst, 'reload schema';

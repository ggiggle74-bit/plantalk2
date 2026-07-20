alter table public.daily_keyword_contexts
  alter column created_at set default now(),
  alter column updated_at set default now();

update public.daily_keyword_contexts
set updated_at = created_at
where updated_at < created_at;

create or replace function public.set_daily_keyword_context_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

revoke all
  on function public.set_daily_keyword_context_updated_at()
  from public, anon, authenticated;

drop trigger if exists set_daily_keyword_context_updated_at
  on public.daily_keyword_contexts;

create trigger set_daily_keyword_context_updated_at
before update on public.daily_keyword_contexts
for each row
execute function public.set_daily_keyword_context_updated_at();

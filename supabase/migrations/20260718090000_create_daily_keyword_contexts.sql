create table if not exists public.daily_keyword_contexts (
  context_date date not null,
  locale text not null,
  region_code text not null,
  schema_version text not null,
  generated_at timestamptz not null,
  source_version text not null,
  keywords jsonb not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  primary key (context_date, locale, region_code),
  constraint daily_keyword_contexts_schema_version_check
    check (schema_version = 'daily-keyword-context/v1'),
  constraint daily_keyword_contexts_locale_check
    check (char_length(locale) between 2 and 32),
  constraint daily_keyword_contexts_region_code_check
    check (char_length(region_code) between 1 and 120),
  constraint daily_keyword_contexts_source_version_check
    check (char_length(source_version) between 1 and 120),
  constraint daily_keyword_contexts_keywords_check
    check (
      jsonb_typeof(keywords) = 'array'
      and jsonb_array_length(keywords) <= 8
    )
);

alter table public.daily_keyword_contexts enable row level security;

revoke all on table public.daily_keyword_contexts from anon, authenticated;
grant select on table public.daily_keyword_contexts to anon, authenticated;
grant all on table public.daily_keyword_contexts to service_role;

drop policy if exists "daily keyword contexts are publicly readable"
  on public.daily_keyword_contexts;

create policy "daily keyword contexts are publicly readable"
  on public.daily_keyword_contexts
  for select
  to anon, authenticated
  using (true);

-- Dialogue Phase 0A: DB authoring base for Plantalk dialogue replies.
-- This creates an operator-authored reply candidate pool while keeping app code
-- responsible for decision keys rather than hard-coded dialogue text.

create table if not exists public.dialogue_replies (
  id uuid primary key default gen_random_uuid(),

  locale text not null default 'ko',

  situation_key text not null,
  condition_key text null,
  personality_key text null,
  tone_key text null,
  relationship_key text null,

  reply_text text not null check (length(trim(reply_text)) > 0),

  weight integer not null default 100 check (weight > 0),
  priority integer not null default 0,

  enabled boolean not null default true,
  repeat_group text null,

  source_type text not null default 'manual' check (
    source_type in ('manual', 'collector', 'ai_suggested', 'system')
  ),
  review_status text not null default 'approved' check (
    review_status in ('draft', 'reviewed', 'approved', 'rejected')
  ),
  auto_category_confidence numeric(5, 2) null check (
    auto_category_confidence is null
    or (auto_category_confidence >= 0 and auto_category_confidence <= 100)
  ),
  created_by text not null default 'user',

  notes text null,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

comment on table public.dialogue_replies is
  'Operator-authored and collector-suggested Plantalk dialogue reply candidates.';
comment on column public.dialogue_replies.situation_key is
  'Dialogue situation key produced by the dialogue decision layer, e.g. greeting, thirsty.';
comment on column public.dialogue_replies.condition_key is
  'Optional condition memory key, e.g. water_needed, new_leaf.';
comment on column public.dialogue_replies.weight is
  'Weighted random selection weight within the best matching reply candidate set.';
comment on column public.dialogue_replies.review_status is
  'Only approved rows should be visible to the app reply selector.';

create index if not exists idx_dialogue_replies_lookup
on public.dialogue_replies (
  locale,
  enabled,
  review_status,
  situation_key
);

create index if not exists idx_dialogue_replies_slot_keys
on public.dialogue_replies (
  situation_key,
  condition_key,
  personality_key,
  tone_key
);

create index if not exists idx_dialogue_replies_review
on public.dialogue_replies (
  review_status,
  source_type
);

create table if not exists public.dialogue_key_registry (
  key_type text not null,
  key text not null,

  label text not null,
  description text null,

  enabled boolean not null default true,
  notes text null,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  primary key (key_type, key)
);

comment on table public.dialogue_key_registry is
  'Authoring registry for stable dialogue keys used by dialogue_replies.';

create index if not exists idx_dialogue_key_registry_type
on public.dialogue_key_registry (
  key_type,
  enabled
);

create or replace function public.set_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists set_dialogue_replies_updated_at on public.dialogue_replies;
create trigger set_dialogue_replies_updated_at
before update on public.dialogue_replies
for each row execute function public.set_updated_at();

drop trigger if exists set_dialogue_key_registry_updated_at on public.dialogue_key_registry;
create trigger set_dialogue_key_registry_updated_at
before update on public.dialogue_key_registry
for each row execute function public.set_updated_at();

alter table public.dialogue_replies enable row level security;
alter table public.dialogue_key_registry enable row level security;

drop policy if exists "Allow client read approved dialogue replies" on public.dialogue_replies;
create policy "Allow client read approved dialogue replies"
on public.dialogue_replies
for select
to anon, authenticated
using (enabled = true and review_status = 'approved');

drop policy if exists "Allow client read enabled dialogue keys" on public.dialogue_key_registry;
create policy "Allow client read enabled dialogue keys"
on public.dialogue_key_registry
for select
to anon, authenticated
using (enabled = true);

insert into public.dialogue_key_registry (key_type, key, label, description)
values
  ('situation', 'greeting', '인사', '사용자가 인사하거나 안부를 묻는 상황'),
  ('situation', 'smalltalk', '잡담', '일반 안부나 가벼운 대화'),
  ('situation', 'thanks', '감사', '사용자가 고마움을 표현하는 상황'),
  ('situation', 'thirsty', '물 필요', '물 필요 또는 수분 관련 대화'),
  ('situation', 'care_ack', '돌봄 확인', '사용자가 물주기 등 돌봄 행동을 언급한 상황'),
  ('situation', 'growth_happy', '성장 기쁨', '새 잎이나 개화 등 성장 관련 기쁨'),
  ('situation', 'condition_watch', '상태 관찰', '상태를 지켜봐야 하는 상황'),
  ('situation', 'encourage', '격려', '사용자에게 위로나 격려가 필요한 상황'),
  ('situation', 'complain', '투정', '식물이 가볍게 투정하는 상황'),
  ('situation', 'goodnight', '밤 인사', '잘 자거나 밤 인사를 하는 상황'),
  ('situation', 'fallback', '기본 응답', '적절한 상황을 찾지 못했을 때의 기본 응답'),
  ('condition', 'water_needed', '물 필요', '최근 상태 확인에서 물 필요가 감지된 기억'),
  ('condition', 'health_watch', '상태 관찰 필요', '최근 상태 확인에서 관찰이 필요한 기억'),
  ('condition', 'new_leaf', '새 잎', '새 잎이 발견된 성장 기억'),
  ('condition', 'flower_bloom', '개화', '꽃이나 개화가 발견된 성장 기억'),
  ('condition', 'condition_improved', '상태 호전', '이전보다 상태가 좋아진 기억'),
  ('condition', 'unknown_condition', '상태 미분류', '명확히 분류되지 않은 상태 확인 기억'),
  ('tone', 'warm', '따뜻함', '따뜻하고 다정한 말투'),
  ('tone', 'soft', '부드러움', '부드럽고 조심스러운 말투'),
  ('tone', 'dry', '건조한 유머', '담백하고 건조한 유머'),
  ('tone', 'playful', '장난기', '가벼운 장난기가 있는 말투'),
  ('tone', 'warm_teasing', '따뜻한 놀림', '장난스럽지만 애정 있는 말투'),
  ('tone', 'calm', '차분함', '차분하고 안정적인 말투'),
  ('tone', 'bright', '밝음', '밝고 활기 있는 말투'),
  ('tone', 'grumpy', '까칠함', '가볍게 까칠한 말투'),
  ('personality', 'playful', '장난기 있음', '장난기 있는 식물 성격'),
  ('personality', 'shy', '소심함', '조심스럽고 소심한 식물 성격'),
  ('personality', 'grumpy', '까칠함', '까칠하지만 정 있는 식물 성격'),
  ('personality', 'calm', '차분함', '차분하고 안정적인 식물 성격'),
  ('personality', 'clingy', '애착형', '사용자에게 애착이 있는 식물 성격'),
  ('personality', 'dry_humor', '건조한 유머', '무심한 듯 웃긴 식물 성격')
on conflict (key_type, key) do update set
  label = excluded.label,
  description = excluded.description,
  enabled = true,
  updated_at = now();

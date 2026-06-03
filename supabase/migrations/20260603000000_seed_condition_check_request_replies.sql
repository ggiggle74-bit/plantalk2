-- Dialogue Phase 4G: approved Korean replies for condition_check_request.
-- Adds a fresh migration because older seed migrations may already be applied.

insert into public.dialogue_key_registry (key_type, key, label, description)
values
  ('situation', 'condition_check_request', '상태 확인 요청', '최근 상태 확인 기록이 없을 때 사진으로 상태 확인을 요청하는 상황')
on conflict (key_type, key) do update set
  label = excluded.label,
  description = excluded.description,
  enabled = true,
  updated_at = now();

with seed (locale, situation_key, condition_key, personality_key, tone_key, relationship_key, reply_text, weight, priority, enabled, repeat_group, source_type, review_status, created_by, notes) as (
values
  ('ko', 'condition_check_request', null::text, null::text, null::text, null::text, '아직 최근 상태를 본 적은 없어. 사진으로 한 번 확인해볼까?', 100, 0, true, 'condition_check_request_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 4G condition check request seed'),
  ('ko', 'condition_check_request', null::text, null::text, null::text, null::text, '지금은 봐야 알겠다. 상태 확인 사진을 한 번 찍어보자.', 95, 0, true, 'condition_check_request_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 4G condition check request seed'),
  ('ko', 'condition_check_request', null::text, null::text, null::text, null::text, '최근 확인 기록이 없네. 사진으로 보면 더 정확히 말해줄 수 있다.', 90, 0, true, 'condition_check_request_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 4G condition check request seed'),
  ('ko', 'condition_check_request', null::text, null::text, null::text, null::text, '나도 지금 상태는 직접 봐야 알겠다. 사진으로 한 번 확인해줘.', 85, 0, true, 'condition_check_request_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 4G condition check request seed'),
  ('ko', 'condition_check_request', null::text, null::text, null::text, null::text, '아직은 짐작만 할 수 있어. 사진으로 상태를 보면 더 잘 말해줄게.', 80, 0, true, 'condition_check_request_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 4G condition check request seed')
)
insert into public.dialogue_replies (
  locale,
  situation_key,
  condition_key,
  personality_key,
  tone_key,
  relationship_key,
  reply_text,
  weight,
  priority,
  enabled,
  repeat_group,
  source_type,
  review_status,
  created_by,
  notes
)
select
  seed.locale,
  seed.situation_key,
  seed.condition_key,
  seed.personality_key,
  seed.tone_key,
  seed.relationship_key,
  seed.reply_text,
  seed.weight,
  seed.priority,
  seed.enabled,
  seed.repeat_group,
  seed.source_type,
  seed.review_status,
  seed.created_by,
  seed.notes
from seed
where not exists (
  select 1
  from public.dialogue_replies existing
  where existing.locale = seed.locale
    and existing.situation_key = seed.situation_key
    and coalesce(existing.condition_key, '') = coalesce(seed.condition_key, '')
    and coalesce(existing.personality_key, '') = coalesce(seed.personality_key, '')
    and coalesce(existing.tone_key, '') = coalesce(seed.tone_key, '')
    and coalesce(existing.relationship_key, '') = coalesce(seed.relationship_key, '')
    and existing.reply_text = seed.reply_text
);

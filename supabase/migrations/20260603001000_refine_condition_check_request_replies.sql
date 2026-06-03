-- Dialogue Phase 4H: refine approved Korean replies for condition_check_request.
-- Adds option styles only; routing and situation keys are unchanged.

with seed (locale, situation_key, condition_key, personality_key, tone_key, relationship_key, reply_text, weight, priority, enabled, repeat_group, source_type, review_status, created_by, notes) as (
values
  ('ko', 'condition_check_request', null::text, null::text, null::text, null::text, '지금은 아직 확인한 기록이 없어. 먼저 사진으로 봐야겠다.', 100, 0, true, 'condition_check_request_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 4H condition check request refinement'),
  ('ko', 'condition_check_request', null::text, null::text, null::text, null::text, '내 상태는 찍어봐야 더 정확히 말할 수 있다.', 95, 0, true, 'condition_check_request_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 4H condition check request refinement'),
  ('ko', 'condition_check_request', null::text, null::text, null::text, null::text, '아직은 느낌만으로 말하면 안 된다. 사진으로 한 번 보자.', 90, 0, true, 'condition_check_request_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 4H condition check request refinement'),
  ('ko', 'condition_check_request', null::text, null::text, null::text, null::text, '상태 확인 사진을 찍어주면 내가 그걸 기준으로 말해볼게.', 100, 0, true, 'condition_check_request_photo_prompt', 'manual', 'approved', 'seed', 'Dialogue Phase 4H condition check request refinement'),
  ('ko', 'condition_check_request', null::text, null::text, null::text, null::text, '잎이랑 흙이 보이게 한 장 찍어봐. 그다음에 얘기하자.', 95, 0, true, 'condition_check_request_photo_prompt', 'manual', 'approved', 'seed', 'Dialogue Phase 4H condition check request refinement'),
  ('ko', 'condition_check_request', null::text, null::text, null::text, null::text, '사진을 보고 더 잘 판단해 보자.', 90, 0, true, 'condition_check_request_photo_prompt', 'manual', 'approved', 'seed', 'Dialogue Phase 4H condition check request refinement'),
  ('ko', 'condition_check_request', null::text, null::text, null::text, null::text, '지금은 단정하지 않겠다. 확인하고 말하는 게 맞다.', 100, 0, true, 'condition_check_request_uncertain', 'manual', 'approved', 'seed', 'Dialogue Phase 4H condition check request refinement'),
  ('ko', 'condition_check_request', null::text, null::text, null::text, null::text, '나도 아직은 모르겠다. 그래도 같이 확인해보면 된다.', 95, 0, true, 'condition_check_request_uncertain', 'manual', 'approved', 'seed', 'Dialogue Phase 4H condition check request refinement'),
  ('ko', 'condition_check_request', null::text, null::text, null::text, null::text, '괜히 아는 척은 안 하겠다. 사진으로 먼저 보자.', 90, 0, true, 'condition_check_request_uncertain', 'manual', 'approved', 'seed', 'Dialogue Phase 4H condition check request refinement'),
  ('ko', 'condition_check_request', null::text, null::text, null::text, null::text, '나중엔 사진으로 상태를 더 자세히 볼 수 있게 해보자.', 100, 0, true, 'condition_check_request_api_ready', 'manual', 'approved', 'seed', 'Dialogue Phase 4H condition check request refinement'),
  ('ko', 'condition_check_request', null::text, null::text, null::text, null::text, '사진 확인이 들어오면 그때는 더 구체적으로 말해줄 수 있다.', 95, 0, true, 'condition_check_request_api_ready', 'manual', 'approved', 'seed', 'Dialogue Phase 4H condition check request refinement'),
  ('ko', 'condition_check_request', null::text, null::text, null::text, null::text, '지금은 확인 요청만 해둘게. 상태는 사진으로 보는 쪽이 맞다.', 90, 0, true, 'condition_check_request_api_ready', 'manual', 'approved', 'seed', 'Dialogue Phase 4H condition check request refinement')
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

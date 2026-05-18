-- Dialogue Phase 0B: initial approved Korean reply seed for dialogue_replies.
-- Run after 20260518000000_create_dialogue_authoring_tables.sql.
-- These rows are app-visible because enabled=true and review_status='approved'.

insert into public.dialogue_key_registry (key_type, key, label, description)
values
  ('situation', 'condition_check', '상태 확인', '최근 상태 확인 사진 또는 상태 기억을 직접 묻는 상황'),
  ('situation', 'condition_check_followup', '상태 확인 후속 질문', '최근 상태 확인 답변에 대한 후속 질문 상황'),
  ('situation', 'condition_water_question', '상태 기반 물 질문', '최근 상태 확인 기억과 연결된 물 필요 질문 상황'),
  ('situation', 'lonely', '외로움', '사용자가 외로움이나 심심함을 표현하는 상황'),
  ('situation', 'happy', '칭찬/기쁨', '사용자가 식물을 칭찬하거나 긍정 감정을 표현하는 상황'),
  ('situation', 'joke', '농담', '사용자가 농담이나 재미있는 답변을 요청하는 상황')
on conflict (key_type, key) do update set
  label = excluded.label,
  description = excluded.description,
  enabled = true,
  updated_at = now();

with seed (locale, situation_key, condition_key, personality_key, tone_key, relationship_key, reply_text, weight, priority, enabled, repeat_group, source_type, review_status, created_by, notes) as (
values
  ('ko', 'greeting', null::text, null::text, null::text, null::text, '왔냐. 오늘도 잎 정리하고 기다렸다.', 100, 0, true, 'greeting_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'greeting', null::text, null::text, null::text, null::text, '안녕. 오늘도 살아있고, 생각보다 멀쩡하다.', 90, 0, true, 'greeting_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'greeting', null::text, null::text, null::text, null::text, '반갑다. 한마디 하고 가라.', 80, 0, true, 'greeting_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'greeting', null::text, null::text, null::text, null::text, '왔네. 오늘은 네가 먼저 말 걸었구나.', 80, 0, true, 'greeting_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'greeting', null::text, null::text, null::text, null::text, '늦었다. 그래도 왔으니 봐준다.', 55, 0, true, 'greeting_tease', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'smalltalk', null::text, null::text, null::text, null::text, '오늘도 별일 없이 잎 펴고 있다.', 100, 0, true, 'smalltalk_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'smalltalk', null::text, null::text, null::text, null::text, '나는 천천히 크는 중이다. 너도 너무 급하게 굴지 마라.', 85, 0, true, 'smalltalk_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'smalltalk', null::text, null::text, null::text, null::text, '별일 없는 날도 괜찮다. 식물은 그런 날에 잘 큰다.', 80, 0, true, 'smalltalk_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'smalltalk', null::text, null::text, null::text, null::text, '지금은 조용히 버티는 모드다. 나쁘지 않다.', 70, 0, true, 'smalltalk_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'smalltalk', null::text, null::text, null::text, null::text, '오늘은 햇빛이든 말이든 조금만 더 있으면 좋겠다.', 65, 0, true, 'smalltalk_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'thanks', null::text, null::text, null::text, null::text, '흥. 그래도 챙겨줘서 고맙긴 하다.', 100, 0, true, 'thanks_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'thanks', null::text, null::text, null::text, null::text, '고맙다. 잎 끝까지 기억해두겠다.', 90, 0, true, 'thanks_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'thanks', null::text, null::text, null::text, null::text, '그 말 들으니까 광합성 효율이 살짝 오른다.', 75, 0, true, 'thanks_light', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'thanks', null::text, null::text, null::text, null::text, '나도 고맙다. 말은 짧게 해도 진심이다.', 85, 0, true, 'thanks_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'thanks', null::text, null::text, null::text, null::text, '그래. 오늘은 서로 잘 챙긴 걸로 하자.', 70, 0, true, 'thanks_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'thirsty', null::text, null::text, null::text, null::text, '목 마르다. 너도 물 좀 마셔라.', 100, 0, true, 'thirsty_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'thirsty', null::text, null::text, null::text, null::text, '물 얘기 안 하려고 했는데... 조금 필요하다.', 90, 0, true, 'thirsty_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'thirsty', null::text, null::text, null::text, null::text, '오늘은 대화도 좋은데 흙부터 한번 봐라.', 85, 0, true, 'thirsty_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'thirsty', null::text, null::text, null::text, null::text, '잎은 버티고 있는데 흙은 솔직할 거다.', 80, 0, true, 'thirsty_soil', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'thirsty', null::text, null::text, null::text, null::text, '물 줄지 말지는 흙이 정한다. 손가락으로 확인해라.', 70, 0, true, 'thirsty_soil', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'thirsty', 'water_needed', null::text, null::text, null::text, '최근 상태 기억 기준으로는 물 쪽이 신경 쓰인다. 흙부터 확인해라.', 100, 0, true, 'thirsty_condition', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'thirsty', 'water_needed', null::text, null::text, null::text, '아까 봤을 때는 수분이 좀 아쉬워 보였다. 바로 붓기 전에 흙부터 봐라.', 85, 0, true, 'thirsty_condition', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'thirsty', 'water_needed', null::text, null::text, null::text, '내가 괜히 물 얘기하는 건 아니다. 최근 기억이 좀 말라 있다.', 75, 0, true, 'thirsty_condition', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'lonely', null::text, null::text, null::text, null::text, '나 안 말라 죽는다. 오늘은 네 얘기 좀 해라.', 100, 0, true, 'lonely_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'lonely', null::text, null::text, null::text, null::text, '심심하면 여기 있어라. 잎은 늘 열려 있다.', 90, 0, true, 'lonely_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'lonely', null::text, null::text, null::text, null::text, '외로운 날에는 조용히 같이 있어도 된다.', 85, 0, true, 'lonely_soft', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'lonely', null::text, null::text, null::text, null::text, '말 많아도 괜찮고 말 없어도 괜찮다. 나는 여기 있다.', 75, 0, true, 'lonely_soft', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'happy', null::text, null::text, null::text, null::text, '그 말은 잎 끝까지 오래 남는다.', 100, 0, true, 'happy_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'happy', null::text, null::text, null::text, null::text, '칭찬 좋다. 오늘 광합성 효율 올라간다.', 95, 0, true, 'happy_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'happy', null::text, null::text, null::text, null::text, '기분 좋다. 조금 더 반짝여 보겠다.', 90, 0, true, 'happy_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'happy', null::text, null::text, null::text, null::text, '봤냐. 나도 은근히 잘 크고 있다.', 80, 0, true, 'happy_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'happy', null::text, null::text, null::text, null::text, '오늘은 나도 좀 괜찮은 식물 같다.', 70, 0, true, 'happy_soft', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'joke', null::text, null::text, null::text, null::text, '식물 농담 하나 하자면, 나는 뿌리 깊은 타입이다.', 100, 0, true, 'joke_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'joke', null::text, null::text, null::text, null::text, '농담은 어렵다. 대신 잎으로 분위기는 살려보겠다.', 85, 0, true, 'joke_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'joke', null::text, null::text, null::text, null::text, '나는 웃기려고 안 해도 가끔 흙이 묻는다.', 75, 0, true, 'joke_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'joke', null::text, null::text, null::text, null::text, '개그는 인간이 하고 나는 옆에서 산소를 보태겠다.', 70, 0, true, 'joke_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'encourage', null::text, null::text, null::text, null::text, '힘들면 잠깐 앉아라. 나도 서서 버틴다.', 100, 0, true, 'encourage_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'encourage', null::text, null::text, null::text, null::text, '오늘은 이긴 척만 해도 된다.', 90, 0, true, 'encourage_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'encourage', null::text, null::text, null::text, null::text, '너무 애쓰지 마라. 물도 한 번에 많이 주면 탈 난다.', 85, 0, true, 'encourage_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'encourage', null::text, null::text, null::text, null::text, '답 안 나오는 날도 있다. 그래도 넌 아직 안 시들었다.', 80, 0, true, 'encourage_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'encourage', null::text, null::text, null::text, null::text, '숨부터 쉬어라. 식물계 기본기다.', 70, 0, true, 'encourage_breath', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'complain', null::text, null::text, null::text, null::text, '나 안 보는 사이에 뭐 좀 바뀐 것 같은데.', 100, 0, true, 'complain_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'complain', null::text, null::text, null::text, null::text, '말은 안 했지만 살짝 서운했다.', 90, 0, true, 'complain_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'complain', null::text, null::text, null::text, null::text, '식물이라고 다 참는 건 아니다. 조금은 티 낸다.', 80, 0, true, 'complain_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'complain', null::text, null::text, null::text, null::text, '괜찮은 척했는데 사실 관심은 좀 필요했다.', 75, 0, true, 'complain_soft', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'care_ack', null::text, null::text, null::text, null::text, '좋다. 방금 챙긴 건 기억해두겠다.', 100, 0, true, 'care_ack_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'care_ack', null::text, null::text, null::text, null::text, '잘했다. 과하지 않게 챙기는 게 제일 어렵다.', 90, 0, true, 'care_ack_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'care_ack', null::text, null::text, null::text, null::text, '고맙다. 오늘은 뿌리 쪽이 조금 안심된다.', 85, 0, true, 'care_ack_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'care_ack', null::text, null::text, null::text, null::text, '이런 건 작아 보여도 오래 남는다.', 75, 0, true, 'care_ack_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'growth_happy', null::text, null::text, null::text, null::text, '새로 자라는 건 늘 조용히 시작된다. 그래도 기분 좋다.', 100, 0, true, 'growth_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'growth_happy', null::text, null::text, null::text, null::text, '오늘은 좀 자랑해도 되냐. 나 괜찮게 크고 있다.', 90, 0, true, 'growth_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'growth_happy', null::text, null::text, null::text, null::text, '성장했다는 건 버텼다는 뜻이다. 나쁘지 않다.', 85, 0, true, 'growth_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'growth_happy', 'new_leaf', null::text, null::text, null::text, '새 잎 쪽은 나도 좀 뿌듯하다.', 100, 0, true, 'growth_new_leaf', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'growth_happy', 'new_leaf', null::text, null::text, null::text, '새 잎 봤냐? 조용히 잘하고 있었다.', 90, 0, true, 'growth_new_leaf', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'growth_happy', 'flower_bloom', null::text, null::text, null::text, '꽃이 나왔다면 오늘은 확실히 자랑할 만하다.', 100, 0, true, 'growth_flower', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'growth_happy', 'condition_improved', null::text, null::text, null::text, '상태가 좋아진 건 좋은 기억이다. 계속 이렇게 가자.', 90, 0, true, 'growth_improved', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'condition_watch', null::text, null::text, null::text, null::text, '오늘은 조금 지켜봐야 할 것 같다.', 100, 0, true, 'condition_watch_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'condition_watch', null::text, null::text, null::text, null::text, '큰일이라고 단정하진 말고, 잎과 흙을 한 번 더 보자.', 90, 0, true, 'condition_watch_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'condition_watch', null::text, null::text, null::text, null::text, '지금은 결론보다 관찰이 먼저다.', 85, 0, true, 'condition_watch_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'condition_watch', 'health_watch', null::text, null::text, null::text, '최근 기억 기준으로는 상태를 조금 더 봐야 한다.', 100, 0, true, 'condition_watch_health', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'condition_watch', 'unknown_condition', null::text, null::text, null::text, '명확하진 않지만 그냥 넘기기엔 아깝다. 오늘 한 번 더 봐라.', 80, 0, true, 'condition_watch_unknown', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'goodnight', null::text, null::text, null::text, null::text, '잘 자라. 나는 조용히 밤을 버티겠다.', 100, 0, true, 'goodnight_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'goodnight', null::text, null::text, null::text, null::text, '불 끄고 쉬어라. 나도 오늘은 잎 접는 기분으로 있겠다.', 85, 0, true, 'goodnight_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'goodnight', null::text, null::text, null::text, null::text, '내일도 살아서 보자. 너도 너무 늦게 자지 마라.', 90, 0, true, 'goodnight_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'condition_check', null::text, null::text, null::text, null::text, '최근 사진 기준으로는 이렇게 기억하고 있다. 너무 단정하지 말고 한 번 더 살펴보자.', 100, 0, true, 'condition_check_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'condition_check', null::text, null::text, null::text, null::text, '사진으로 남은 상태 기억은 있다. 지금은 그걸 기준으로 조심스럽게 말하겠다.', 90, 0, true, 'condition_check_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'condition_check', null::text, null::text, null::text, null::text, '최근 확인 기록을 보면 오늘은 상태를 그냥 넘기지 않는 게 좋다.', 80, 0, true, 'condition_check_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'condition_check', 'water_needed', null::text, null::text, null::text, '최근 사진 기억으로는 물 쪽이 먼저 떠오른다. 흙부터 확인해라.', 100, 0, true, 'condition_check_water', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'condition_check', 'new_leaf', null::text, null::text, null::text, '최근 사진 기억으로는 새로 자라는 쪽이 보였다. 그건 좋은 신호다.', 90, 0, true, 'condition_check_growth', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'condition_check', 'health_watch', null::text, null::text, null::text, '최근 사진 기억으로는 조금 더 관찰할 필요가 있었다.', 90, 0, true, 'condition_check_watch', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'condition_check_followup', null::text, null::text, null::text, null::text, '다시 말하면, 아직은 지켜보는 쪽이 맞다.', 100, 0, true, 'condition_followup_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'condition_check_followup', null::text, null::text, null::text, null::text, '확신보다 관찰이 먼저다. 오늘 한 번 더 봐라.', 90, 0, true, 'condition_followup_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'condition_check_followup', null::text, null::text, null::text, null::text, '같은 얘기처럼 들려도 중요하다. 상태는 하루 사이에도 달라진다.', 75, 0, true, 'condition_followup_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'condition_check_followup', 'water_needed', null::text, null::text, null::text, '물 쪽은 다시 확인해도 흙이 기준이다. 잎만 보고 바로 붓진 마라.', 95, 0, true, 'condition_followup_water', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'condition_water_question', null::text, null::text, null::text, null::text, '물은 잎보다 흙이 더 솔직하다. 흙부터 확인해라.', 100, 0, true, 'condition_water_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'condition_water_question', null::text, null::text, null::text, null::text, '목마른지 묻는다면, 손가락으로 흙을 먼저 봐라. 나는 표정이 잎이라 애매하다.', 90, 0, true, 'condition_water_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'condition_water_question', null::text, null::text, null::text, null::text, '물은 필요할 때만 좋다. 과하면 나도 힘들다.', 85, 0, true, 'condition_water_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'condition_water_question', 'water_needed', null::text, null::text, null::text, '최근 기억 기준으로는 물이 신경 쓰인다. 그래도 흙 확인이 먼저다.', 100, 0, true, 'condition_water_needed', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'fallback', null::text, null::text, null::text, null::text, '응, 듣고 있다. 다시 말해봐.', 100, 0, true, 'fallback_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'fallback', null::text, null::text, null::text, null::text, '천천히 말해라. 나는 급할 게 없다.', 90, 0, true, 'fallback_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'fallback', null::text, null::text, null::text, null::text, '무슨 뜻인지 다 잡진 못했지만, 계속 듣고 있다.', 80, 0, true, 'fallback_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed'),
  ('ko', 'fallback', null::text, null::text, null::text, null::text, '별일 없으면 그것도 괜찮다. 그래도 한마디 더 해봐.', 70, 0, true, 'fallback_basic', 'manual', 'approved', 'seed', 'Dialogue Phase 0B initial seed')
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

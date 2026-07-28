import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/dialogue/models/conversation_usage_ledger.dart';

void main() {
  test('holds material and reply keys for their configured cooldowns', () {
    final ledger = ConversationUsageLedger(
      materialCooldownTurns: 3,
      replyCooldownTurns: 4,
    );

    ledger.record(materialKey: '비', replyKey: 'material:비:0');

    expect(ledger.canUseMaterial('비'), isFalse);
    expect(ledger.canUseReply('material:비:0'), isFalse);

    ledger.record(replyKey: 'plain:greeting:0');
    ledger.record(replyKey: 'plain:greeting:1');
    ledger.record(replyKey: 'plain:greeting:2');

    expect(ledger.canUseMaterial('비'), isTrue);
    expect(ledger.canUseReply('material:비:0'), isFalse);

    ledger.record(replyKey: 'plain:greeting:3');

    expect(ledger.canUseReply('material:비:0'), isTrue);
  });

  test('normalizes material and reply identities', () {
    final ledger = ConversationUsageLedger();

    ledger.record(materialKey: '  장맛비 ', replyKey: ' Plain: Greeting:0 ');

    expect(ledger.canUseMaterial('장맛비'), isFalse);
    expect(ledger.canUseReply('plain: greeting:0'), isFalse);
  });

  test('keeps tracked state bounded', () {
    final ledger = ConversationUsageLedger(
      maximumTrackedMaterials: 2,
      maximumTrackedReplies: 2,
    );

    ledger.record(materialKey: '비', replyKey: 'reply-1');
    ledger.record(materialKey: '여름', replyKey: 'reply-2');
    ledger.record(materialKey: '독서', replyKey: 'reply-3');

    expect(ledger.trackedMaterialKeys, hasLength(2));
    expect(ledger.trackedMaterialKeys, isNot(contains('비')));
    expect(ledger.trackedReplyKeys, hasLength(2));
    expect(ledger.trackedReplyKeys, isNot(contains('reply-1')));
  });
}

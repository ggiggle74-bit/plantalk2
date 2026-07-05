import 'package:flutter_test/flutter_test.dart';
import 'package:plantalk2/monetization/models/paid_feature.dart';

void main() {
  test('deepHealthAssessment has stable key', () {
    expect(PaidFeature.deepHealthAssessment.key, 'deep_health_assessment');
    expect(PaidFeature.deepHealthAssessment.title, '심층 건강 분석');
  });

  test('plantCharacterSlot has stable key', () {
    expect(PaidFeature.plantCharacterSlot.key, 'plant_character_slot');
    expect(PaidFeature.plantCharacterSlot.title, '식물 캐릭터 슬롯');
  });
}

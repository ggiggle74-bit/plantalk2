enum PaidFeature { deepHealthAssessment, plantCharacterSlot }

extension PaidFeatureCopy on PaidFeature {
  String get key {
    switch (this) {
      case PaidFeature.deepHealthAssessment:
        return 'deep_health_assessment';
      case PaidFeature.plantCharacterSlot:
        return 'plant_character_slot';
    }
  }

  String get title {
    switch (this) {
      case PaidFeature.deepHealthAssessment:
        return '심층 건강 분석';
      case PaidFeature.plantCharacterSlot:
        return '식물 캐릭터 슬롯';
    }
  }
}

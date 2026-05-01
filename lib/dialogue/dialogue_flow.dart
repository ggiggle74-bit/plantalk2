enum DialogueFlowType {
  firstMeet,
  needsWater,
  normal,
  friendshipUp,
  beforePhoto,
  afterPhoto,
}

DialogueFlowType getDialogueFlowType({
  required int waterDay,
  required int friendship,
  required bool hasPhoto,
}) {
  if (!hasPhoto) {
    return DialogueFlowType.beforePhoto;
  }

  if (waterDay >= 2) {
    return DialogueFlowType.needsWater;
  }

  if (friendship >= 5) {
    return DialogueFlowType.friendshipUp;
  }

  return DialogueFlowType.normal;
}

String getPlaceholderDialogue(DialogueFlowType type) {
  switch (type) {
    case DialogueFlowType.firstMeet:
      return '처음 만남 대화 자리';
    case DialogueFlowType.needsWater:
      return '물 부족 대화 자리';
    case DialogueFlowType.normal:
      return '일반 대화 자리';
    case DialogueFlowType.friendshipUp:
      return '친밀도 상승 대화 자리';
    case DialogueFlowType.beforePhoto:
      return '사진 등록 전 대화 자리';
    case DialogueFlowType.afterPhoto:
      return '사진 등록 후 대화 자리';
  }
}

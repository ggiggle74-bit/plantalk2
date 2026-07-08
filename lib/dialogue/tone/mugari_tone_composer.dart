class MugariToneComposer {
  const MugariToneComposer();

  String apply(String base, {String? plantName, String? mood}) {
    final trimmed = base.trim();
    if (trimmed.isEmpty) {
      return trimmed;
    }

    final moodText = mood?.trim();
    if (moodText == null || moodText.isEmpty || trimmed.length > 70) {
      return trimmed;
    }

    if (moodText.contains('shy') || moodText.contains('수줍')) {
      return '$trimmed 조금 조용히 말해봤어.';
    }

    if (moodText.contains('cheer') || moodText.contains('밝')) {
      return '$trimmed 오늘도 같이 가보자.';
    }

    return trimmed;
  }
}

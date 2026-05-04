import 'package:flutter/material.dart';

import '../widgets/photo_preview.dart';

Widget plantRegistrationPreviewContent({
  required String photoPath,
  required VoidCallback onCancel,
  required VoidCallback onContinue,
  String reactionText = '사진은 확인했다. 이제 이름을 붙여줘라.',
  String continueLabel = '이름 붙이기',
}) {
  return AlertDialog(
    title: const Text('사진 확인'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        photoPreview(photoPath),
        const SizedBox(height: 12),
        Text(reactionText),
      ],
    ),
    actions: [
      TextButton(onPressed: onCancel, child: const Text('취소')),
      ElevatedButton(onPressed: onContinue, child: Text(continueLabel)),
    ],
  );
}

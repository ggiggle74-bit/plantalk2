import 'package:flutter/material.dart';

Widget addPlantDialogContent({
  required TextEditingController controller,
  required VoidCallback onCancel,
  required Future<void> Function() onAdd,
}) {
  return AlertDialog(
    title: const Text('새 식물 추가'),
    content: TextField(
      controller: controller,
      decoration: const InputDecoration(hintText: '식물 이름 입력'),
    ),
    actions: [
      TextButton(
        onPressed: onCancel,
        child: const Text('취소'),
      ),
      ElevatedButton(
        onPressed: onAdd,
        child: const Text('추가'),
      ),
    ],
  );
}

import 'package:flutter/material.dart';

Widget addPlantDialogContent({
  required TextEditingController controller,
  required VoidCallback onCancel,
  required Future<void> Function() onAdd,
}) {
  return AlertDialog(
    title: const Text('식물 별명 정하기'),
    content: TextField(
      controller: controller,
      decoration: const InputDecoration(hintText: '예: 몬돌이'),
    ),
    actions: [
      TextButton(
        onPressed: onCancel,
        child: const Text('취소'),
      ),
      ElevatedButton(
        onPressed: onAdd,
        child: const Text('등록'),
      ),
    ],
  );
}

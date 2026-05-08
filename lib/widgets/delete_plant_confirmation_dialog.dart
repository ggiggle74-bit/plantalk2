import 'package:flutter/material.dart';

Future<bool?> showDeletePlantConfirmationDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('식물 삭제'),
        content: const Text('정말 이 식물을 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('삭제'),
          ),
        ],
      );
    },
  );
}

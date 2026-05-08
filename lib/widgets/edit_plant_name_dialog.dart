import 'package:flutter/material.dart';

Future<String?> showEditPlantNameDialogInput(
  BuildContext context, {
  required String currentName,
}) async {
  final controller = TextEditingController(text: currentName);

  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      String? errorText;

      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('식물 이름 수정'),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: '식물 이름',
                errorText: errorText,
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  final trimmedName = controller.text.trim();
                  if (trimmedName.isEmpty) {
                    setDialogState(() {
                      errorText = '식물 이름을 입력해주세요.';
                    });
                    return;
                  }
                  Navigator.pop(dialogContext, trimmedName);
                },
                child: const Text('저장'),
              ),
            ],
          );
        },
      );
    },
  );
}

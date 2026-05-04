import 'package:flutter/material.dart';

Widget photoPreview(String photoPath) {
  return Align(
    alignment: Alignment.centerLeft,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 140,
        height: 90,
        child:
            photoPath.startsWith('http://') ||
                photoPath.startsWith('https://') ||
                photoPath.startsWith('blob:')
            ? Image.network(photoPath, fit: BoxFit.contain)
            : const Center(child: Text('사진 미리보기 준비 중')),
      ),
    ),
  );
}

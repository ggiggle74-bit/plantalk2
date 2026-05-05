import 'package:flutter/material.dart';

import 'photo_preview.dart';

Widget plantCard(
  String name,
  String message,
  int days,
  int friendship,
  VoidCallback onWater, {
  VoidCallback? onTalk,
  VoidCallback? onDelete,
  VoidCallback? onPhoto,
  String? photoPath,
}) {
  return Card(
    margin: const EdgeInsets.all(12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (onDelete != null)
                IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
            ],
          ),

          const SizedBox(height: 10),
          if (photoPath != null) ...[
            photoPreview(photoPath),
            const SizedBox(height: 10),
          ],
          Text(message),

          const SizedBox(height: 10),
          Text('물 안 준지 $days일'),
          const SizedBox(height: 10),
          Text('친밀도 ❤️ $friendship'),
          const SizedBox(height: 10),

          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              ElevatedButton(onPressed: onWater, child: const Text('💧 물 줬어요')),
              ElevatedButton(onPressed: onTalk, child: const Text('💬 말 걸기')),
              if (onPhoto != null)
                ElevatedButton(
                  onPressed: onPhoto,
                  child: const Text('📷 사진 등록'),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}

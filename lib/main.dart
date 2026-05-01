import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dialogue/chat_panel.dart';
import 'services/plant_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qyhstykoshvdyhzknqmn.supabase.co',
    anonKey: 'sb_publishable_vweok1t5SRu9iqLs7uGwZg_sq6vBLlb',
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final PlantService plantService = PlantService();

  String monsteraMessage = '목이 조금 말라요 🌱';
  int monsteraWaterDay = 3;

  List<Map<String, dynamic>> extraPlants = [];

  @override
  void initState() {
    super.initState();
    loadPlantsFromSupabase();
  }

  Future<void> loadPlantsFromSupabase() async {
    final data = await plantService.loadPlants();

    if (!mounted) return;

    setState(() {
      extraPlants = data.map<Map<String, dynamic>>((plant) {
        return {
          'name': plant['name'],
          'message': plant['message'] ?? '안녕하세요 🌱',
          'waterDay': plant['water_day'] ?? 0,
          'friendship': plant['friendship'] ?? 0,
          'mood': plant['mood'] ?? '보통',
        };
      }).toList();
    });
  }

  Future<void> addPlantToSupabase(String plantName) async {
    await plantService.addPlant(plantName);
  }

  Future<void> updatePlantFriendship(
    String plantName,
    int friendship,
    String mood,
  ) async {
    await plantService.updatePlantFriendship(plantName, friendship, mood);
  }

  Future<void> deletePlantFromSupabase(String plantName) async {
    await plantService.deletePlant(plantName);
  }

  Future<void> updatePlantWaterDay(String plantName, int waterDay) async {
    await plantService.updatePlantWaterDay(plantName, waterDay);
  }

  Future<void> updatePlantMessage(String plantName, String message) async {
    await plantService.updatePlantMessage(plantName, message);
  }

  String stuckyMessage = '오늘 기분 좋아요 ☀️';
  int stuckyWaterDay = 1;

  int monsteraFriendship = 0;
  int stuckyFriendship = 0;

  int monsteraLevel = 1;
  int stuckyLevel = 1;

  int visitCount = 0;

  String monsteraMood = '보통';
  String stuckyMood = '보통';

  void waterMonstera() {
    setState(() {
      monsteraMessage = '고마워요 💚';
      monsteraWaterDay = 0;
    });
  }

  void waterStucky() {
    setState(() {
      stuckyMessage = '시원해졌어요 💧';
      stuckyWaterDay = 0;
    });
  }

  void talkToPlant(Map<String, dynamic> plant) {
    final messages = ['오늘 햇빛이 참 좋아요 ☀️', '조금 외로웠어요 🌱', '오늘도 와줘서 고마워요 💚'];

    final moods = ['행복 😊', '졸림 😴', '신남 🌞', '평온 🍃'];

    final random = Random();

    setState(() {
      plant['friendship']++;

      plant['mood'] = moods[random.nextInt(moods.length)];

      plant['message'] =
          '${messages[random.nextInt(messages.length)]} '
          '❤️${plant['friendship']} '
          '기분:${plant['mood']}';

      updatePlantFriendship(plant['name'], plant['friendship'], plant['mood']);

      updatePlantMessage(plant['name'], plant['message']);
    });
  }

  void addPlantDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('새 식물 추가'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: '식물 이름 입력'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isNotEmpty) {
                  setState(() {
                    extraPlants.add({
                      'name': controller.text.trim(),
                      'message': '새 친구가 왔어요 🌱',
                      'waterDay': 0,
                      'friendship': 0,
                      'mood': '보통',
                    });
                  });
                  await addPlantToSupabase(controller.text.trim());
                }

                if (!context.mounted) return;

                Navigator.pop(context);
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  Future<ChatPanelResult?> openChatPanel(
    BuildContext context, {
    required String plantName,
    required String initialPlantMessage,
    required int waterDay,
  }) async {
    return Navigator.push<ChatPanelResult>(
      context,
      MaterialPageRoute(
        builder: (_) {
          return ChatPanel(
            plantName: plantName,
            initialPlantMessage: initialPlantMessage,
            waterDay: waterDay,
          );
        },
      ),
    );
  }

  Widget plantCard(
    String name,
    String message,
    int days,
    int friendship,
    VoidCallback onWater, {
    VoidCallback? onTalk,
    VoidCallback? onDelete,
    VoidCallback? onPhoto,
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
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: onDelete,
                  ),
              ],
            ),

            const SizedBox(height: 10),
            Text(message),

            const SizedBox(height: 10),
            Text('물 준지 $days일'),
            const SizedBox(height: 10),
            Text('친밀도 ❤️ $friendship'),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                ElevatedButton(
                  onPressed: onWater,
                  child: const Text('💧 물 줬어요'),
                ),
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

  Widget extraPlantCard(String name) {
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Builder(
        builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('플랜톡'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    addPlantDialog(context);
                  },
                ),
              ],
            ),

            body: ListView(
              children: [
                plantCard(
                  '몬스테라',
                  monsteraMessage,
                  monsteraWaterDay,
                  monsteraFriendship,

                  waterMonstera,
                  onTalk: () async {
                    final chatResult = await openChatPanel(
                      context,
                      plantName: '몬스테라',
                      initialPlantMessage: monsteraMessage,
                      waterDay: monsteraWaterDay,
                    );
                    if (chatResult != null && mounted) {
                      setState(() {
                        final latestReply = chatResult.latestPlantReply;
                        if (latestReply != null) {
                          monsteraMessage = latestReply;
                        }
                        monsteraFriendship += chatResult.userMessageCount;
                      });
                    }
                  },
                ),

                plantCard(
                  '스투키',
                  stuckyMessage,
                  stuckyWaterDay,
                  stuckyFriendship,

                  waterStucky,
                  onTalk: () async {
                    final chatResult = await openChatPanel(
                      context,
                      plantName: '스투키',
                      initialPlantMessage: stuckyMessage,
                      waterDay: stuckyWaterDay,
                    );
                    if (chatResult != null && mounted) {
                      setState(() {
                        final latestReply = chatResult.latestPlantReply;
                        if (latestReply != null) {
                          stuckyMessage = latestReply;
                        }
                        stuckyFriendship += chatResult.userMessageCount;
                      });
                    }
                  },
                ),

                ...extraPlants.asMap().entries.map((entry) {
                  final index = entry.key;
                  final plant = entry.value;

                  return plantCard(
                    plant['name'],
                    plant['message'],
                    plant['waterDay'],
                    plant['friendship'] ?? 0,

                    () async {
                      setState(() {
                        plant['message'] = '고마워요 💧';
                        plant['waterDay'] = 0;
                      });

                      await updatePlantWaterDay(
                        plant['name'],
                        plant['waterDay'],
                      );

                      await updatePlantMessage(plant['name'], plant['message']);
                    },
                    onTalk: () async {
                      final chatResult = await openChatPanel(
                        context,
                        plantName: plant['name'],
                        initialPlantMessage: plant['message'],
                        waterDay: plant['waterDay'],
                      );
                      if (chatResult != null && mounted) {
                        final latestReply = chatResult.latestPlantReply;
                        setState(() {
                          if (latestReply != null) {
                            plant['message'] = latestReply;
                          }
                          plant['friendship'] =
                              (plant['friendship'] ?? 0) +
                              chatResult.userMessageCount;
                        });
                        if (latestReply != null) {
                          await updatePlantMessage(plant['name'], latestReply);
                        }
                      }
                    },
                    onDelete: () async {
                      await deletePlantFromSupabase(plant['name']);

                      setState(() {
                        extraPlants.removeAt(index);
                      });
                    },
                    onPhoto: () async {
                      final image = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                      );

                      if (image == null) return;

                      setState(() {
                        plant['message'] = '사진이 선택됐습니다 📷';
                      });
                    },
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

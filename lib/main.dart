import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'admin_dialogue_screen.dart';
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
          'id': plant['id'],
          'name': plant['name'],
          'message': plant['message'] ?? '안녕하세요 🌱',
          'waterDay': plant['water_day'] ?? 0,
          'friendship': plant['friendship'] ?? 0,
          'mood': plant['mood'] ?? '보통',
        };
      }).toList();
    });
  }

  Future<Map<String, dynamic>> addPlantToSupabase(String plantName) async {
    return await plantService.addPlant(plantName);
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

  String? _plantIdOf(Map<String, dynamic> plant) {
    final id = plant['id']?.toString();
    if (id == null || id.isEmpty) return null;
    return id;
  }

  int _waterDayOf(Map<String, dynamic> plant) {
    final value = plant['waterDay'] ?? plant['water_day'] ?? 0;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? 0;
  }

  void _setWaterDay(Map<String, dynamic> plant, int waterDay) {
    plant['waterDay'] = waterDay;
    plant['water_day'] = waterDay;
  }

  Future<void> updatePlantWaterDayByPlant(
    Map<String, dynamic> plant,
    int waterDay,
  ) async {
    final id = _plantIdOf(plant);
    if (id != null) {
      await plantService.updatePlantWaterDayById(id, waterDay);
      return;
    }

    await updatePlantWaterDay(plant['name'], waterDay);
  }

  Future<void> updatePlantMessageByPlant(
    Map<String, dynamic> plant,
    String message,
  ) async {
    final id = _plantIdOf(plant);
    if (id != null) {
      await plantService.updatePlantMessageById(id, message);
      return;
    }

    await updatePlantMessage(plant['name'], message);
  }

  Future<void> updatePlantFriendshipByPlant(
    Map<String, dynamic> plant,
    int friendship,
    String mood,
  ) async {
    final id = _plantIdOf(plant);
    if (id != null) {
      await plantService.updatePlantFriendshipById(id, friendship, mood);
      return;
    }

    await plantService.updatePlantFriendship(plant['name'], friendship, mood);
  }

  Future<void> deletePlantFromSupabaseByPlant(
    Map<String, dynamic> plant,
  ) async {
    final id = _plantIdOf(plant);
    if (id != null) {
      await plantService.deletePlantById(id);
      return;
    }

    await deletePlantFromSupabase(plant['name']);
  }

  String stuckyMessage = '오늘 기분 좋아요 ☀️';
  int stuckyWaterDay = 1;

  int monsteraFriendship = 0;
  int stuckyFriendship = 0;

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

  Future<void> startPlantRegistration(BuildContext context) async {
    final image = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (image == null) return;
    if (!context.mounted) return;

    await Future.delayed(const Duration(milliseconds: 200));

    if (!context.mounted) return;

    addPlantDialog(context, image.path);
  }

  void addPlantDialog(BuildContext context, String photoPath) {
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
                final plantName = controller.text.trim();
                if (plantName.isEmpty) return;

                final insertedPlant = await addPlantToSupabase(plantName);

                if (!mounted) return;

                setState(() {
                  extraPlants.add({
                    'id': insertedPlant['id'],
                    'name': insertedPlant['name'] ?? plantName,
                    'message': insertedPlant['message'] ?? '새 친구가 왔어요 🌱',
                    'waterDay': insertedPlant['water_day'] ?? 0,
                    'friendship': insertedPlant['friendship'] ?? 0,
                    'photoPath': photoPath,
                    'mood': insertedPlant['mood'] ?? '보통',
                  });
                });

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
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: onDelete,
                  ),
              ],
            ),

            const SizedBox(height: 10),
            if (photoPath != null) ...[
              Align(
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
              ),
              const SizedBox(height: 10),
            ],
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
                    startPlantRegistration(context);
                  },
                ),
              ],
            ),

            body: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AdminDialogueScreen(),
                        ),
                      );
                    },
                    child: const Text('관리자 대사 입력'),
                  ),
                ),
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
                    _waterDayOf(plant),
                    plant['friendship'] ?? 0,

                    () async {
                      final plantId = _plantIdOf(plant);
                      final plantIndex = plantId == null
                          ? extraPlants.indexOf(plant)
                          : extraPlants.indexWhere(
                              (extraPlant) => _plantIdOf(extraPlant) == plantId,
                            );
                      if (plantIndex < 0) return;

                      final selectedPlant = extraPlants[plantIndex];

                      setState(() {
                        selectedPlant['message'] = '고마워요 💧';
                        _setWaterDay(selectedPlant, 0);
                      });

                      await updatePlantWaterDayByPlant(
                        selectedPlant,
                        _waterDayOf(selectedPlant),
                      );

                      await updatePlantMessageByPlant(
                        selectedPlant,
                        selectedPlant['message'],
                      );
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
                        final currentFriendship = plant['friendship'] is int
                            ? plant['friendship'] as int
                            : 0;
                        final updatedFriendship =
                            currentFriendship + chatResult.userMessageCount;
                        final mood = plant['mood']?.toString() ?? '보통';
                        setState(() {
                          if (latestReply != null) {
                            plant['message'] = latestReply;
                          }
                          plant['friendship'] = updatedFriendship;
                        });
                        if (latestReply != null) {
                          await updatePlantMessageByPlant(plant, latestReply);
                        }
                        await updatePlantFriendshipByPlant(
                          plant,
                          updatedFriendship,
                          mood,
                        );
                      }
                    },
                    onDelete: () async {
                      await deletePlantFromSupabaseByPlant(plant);

                      setState(() {
                        extraPlants.removeAt(index);
                      });
                    },
                    photoPath: plant['photoPath'] as String?,
                    onPhoto: () async {
                      final image = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                      );

                      if (image == null) return;
                      if (!context.mounted) return;

                      const reactionMessage = '사진 봤다. 이제 말 좀 걸어봐라';

                      setState(() {
                        plant['photoPath'] = image.path;
                        plant['message'] = reactionMessage;
                      });

                      final chatResult = await openChatPanel(
                        context,
                        plantName: plant['name'],
                        initialPlantMessage: reactionMessage,
                        waterDay: plant['waterDay'],
                      );
                      if (chatResult != null && mounted) {
                        final latestReply = chatResult.latestPlantReply;
                        final currentFriendship = plant['friendship'] is int
                            ? plant['friendship'] as int
                            : 0;
                        final updatedFriendship =
                            currentFriendship + chatResult.userMessageCount;
                        final mood = plant['mood']?.toString() ?? '보통';
                        setState(() {
                          if (latestReply != null) {
                            plant['message'] = latestReply;
                          }
                          plant['friendship'] = updatedFriendship;
                        });
                        if (latestReply != null) {
                          await updatePlantMessageByPlant(plant, latestReply);
                        }
                        await updatePlantFriendshipByPlant(
                          plant,
                          updatedFriendship,
                          mood,
                        );
                      }
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

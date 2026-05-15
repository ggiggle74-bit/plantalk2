import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'admin_dialogue_screen.dart';
import 'dialogue/chat_panel.dart';
import 'photo/existing_plant_match_dialog.dart';
import 'photo/mock_plant_photo_analysis.dart';
import 'photo/plant_registration_preview.dart';
import 'photo/species_selection_dialog.dart';
import 'photo/supported_species.dart';
import 'services/plant_service.dart';
import 'services/photo_service.dart';
import 'widgets/add_plant_dialog.dart';
import 'widgets/delete_plant_confirmation_dialog.dart';
import 'widgets/edit_plant_name_dialog.dart';
import 'widgets/plant_card.dart';

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
  final PhotoService photoService = PhotoService();

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
          'photoPath': plant['photo_url'],
          'speciesKey': plant['species_key'] ?? 'unknown',
          'speciesDisplayName': plant['species_display_name'] ?? '알 수 없음',
          'speciesGuess': plant['species_guess'],
          'mood': plant['mood'] ?? '보통',
        };
      }).toList();
    });
  }

  Future<Map<String, dynamic>> addPlantToSupabase(
    String plantName, {
    String speciesKey = 'unknown',
    String speciesDisplayName = '알 수 없음',
    String? speciesGuess,
  }) async {
    return await plantService.addPlant(
      plantName,
      speciesKey: speciesKey,
      speciesDisplayName: speciesDisplayName,
      speciesGuess: speciesGuess,
    );
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

  Future<String> resolvePhotoPath({
    required XFile image,
    String? plantId,
  }) async {
    if (plantId == null || plantId.isEmpty) {
      return image.path;
    }

    final photoUrl = await photoService.uploadPlantPhoto(
      image: image,
      plantId: plantId,
    );
    await plantService.updatePlantPhotoUrlById(plantId, photoUrl);
    return photoUrl;
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

  Future<void> showEditPlantNameDialog(
    BuildContext context,
    Map<String, dynamic> plant,
  ) async {
    final id = _plantIdOf(plant);

    final newName = await showEditPlantNameDialogInput(
      context,
      currentName: plant['name']?.toString() ?? '',
    );

    if (newName == null) return;

    if (id == null) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('식물 id가 없어 이름을 저장할 수 없습니다.')),
      );
      return;
    }

    await plantService.updatePlantNameById(id, newName);

    if (!mounted) return;

    setState(() {
      plant['name'] = newName;
    });
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

    await showDialog(
      context: context,
      builder: (_) {
        return plantRegistrationPreviewContent(
          photoPath: image.path,
          onCancel: () {
            Navigator.pop(context);
          },
          onContinue: () async {
            Navigator.pop(context);
            await continuePlantRegistrationAfterPreview(context, image);
          },
        );
      },
    );
  }

  Future<void> continuePlantRegistrationAfterPreview(
    BuildContext context,
    XFile image,
  ) async {
    final analysis = mockAnalyzePlantPhoto(image.path);

    if (extraPlants.isNotEmpty) {
      final matchResult = await showExistingPlantMatchDialog(
        context,
        plants: List<Map<String, dynamic>>.from(extraPlants),
        analysis: analysis,
      );

      if (!context.mounted) return;
      if (matchResult == null) return;

      final existingPlant = matchResult.plant;
      if (!matchResult.createNewPlant && existingPlant != null) {
        await attachPhotoToExistingPlant(context, image, existingPlant);
        return;
      }
    }

    if (!context.mounted) return;

    await startNewPlantCreation(context, image, analysis);
  }

  Future<void> attachPhotoToExistingPlant(
    BuildContext context,
    XFile image,
    Map<String, dynamic> plant,
  ) async {
    const reactionMessage = '사진 봤다. 이제 말 좀 걸어봐라.';
    final plantId = _plantIdOf(plant);
    final photoPath = await resolvePhotoPath(image: image, plantId: plantId);

    if (!mounted || !context.mounted) return;

    setState(() {
      plant['photoPath'] = photoPath;
      plant['message'] = reactionMessage;
    });

    final chatResult = await openChatPanel(
      context,
      plantId: plantId,
      plantName: plant['name']?.toString() ?? '이름 없는 식물',
      initialPlantMessage: reactionMessage,
      waterDay: _waterDayOf(plant),
    );

    if (chatResult != null) {
      await updatePlantAfterChat(plant, chatResult);
    }
  }

  Future<void> startNewPlantCreation(
    BuildContext context,
    XFile image,
    MockPlantPhotoAnalysis analysis,
  ) async {
    final selectedSpecies = await showSpeciesSelectionDialog(
      context,
      suggestedSpecies: analysis.speciesSuggestions,
    );

    if (selectedSpecies == null || !context.mounted) return;

    addPlantDialog(
      context,
      image,
      selectedSpecies: selectedSpecies,
      speciesGuess: analysis.speciesSuggestions
          .map((species) => species.displayName)
          .join(', '),
    );
  }

  void addPlantDialog(
    BuildContext context,
    XFile image, {
    required SupportedSpecies selectedSpecies,
    required String speciesGuess,
  }) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return addPlantDialogContent(
          controller: controller,
          onCancel: () {
            Navigator.pop(context);
          },
          onAdd: () async {
            final plantName = controller.text.trim();
            if (plantName.isEmpty) return;

            final insertedPlant = await addPlantToSupabase(
              plantName,
              speciesKey: selectedSpecies.key,
              speciesDisplayName: selectedSpecies.displayName,
              speciesGuess: speciesGuess,
            );

            if (!mounted) return;

            const firstMessage = '너를 기다리고 있었다.';

            final plantId = insertedPlant['id']?.toString();
            final photoPath = await resolvePhotoPath(
              image: image,
              plantId: plantId,
            );

            final newPlant = <String, dynamic>{
              'id': insertedPlant['id'],
              'name': insertedPlant['name'] ?? plantName,
              'message': firstMessage,
              'waterDay': insertedPlant['water_day'] ?? 0,
              'friendship': insertedPlant['friendship'] ?? 0,
              'photoPath': photoPath,
              'speciesKey': insertedPlant['species_key'] ?? selectedSpecies.key,
              'speciesDisplayName':
                  insertedPlant['species_display_name'] ??
                  selectedSpecies.displayName,
              'speciesGuess': insertedPlant['species_guess'] ?? speciesGuess,
              'mood': insertedPlant['mood'] ?? '보통',
            };

            setState(() {
              extraPlants.add(newPlant);
            });

            if (!context.mounted) return;

            Navigator.pop(context);

            final chatResult = await openChatPanel(
              context,
              plantId: _plantIdOf(newPlant),
              plantName: newPlant['name'],
              initialPlantMessage: firstMessage,
              waterDay: _waterDayOf(newPlant),
            );

            if (chatResult != null) {
              await updatePlantAfterChat(newPlant, chatResult);
            }
          },
        );
      },
    );
  }

  Future<void> updatePlantAfterChat(
    Map<String, dynamic> plant,
    ChatPanelResult chatResult,
  ) async {
    if (!mounted) return;

    final latestReply = chatResult.latestPlantReply;
    final currentFriendship = plant['friendship'] is int
        ? plant['friendship'] as int
        : 0;
    final updatedFriendship = currentFriendship + chatResult.userMessageCount;
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

    await updatePlantFriendshipByPlant(plant, updatedFriendship, mood);
  }

  Future<ChatPanelResult?> openChatPanel(
    BuildContext context, {
    String? plantId,
    required String plantName,
    required String initialPlantMessage,
    required int waterDay,
  }) async {
    return Navigator.push<ChatPanelResult>(
      context,
      MaterialPageRoute(
        builder: (_) {
          return ChatPanel(
            plantId: plantId,
            plantName: plantName,
            initialPlantMessage: initialPlantMessage,
            waterDay: waterDay,
          );
        },
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
                        plantId: _plantIdOf(plant),
                        plantName: plant['name'],
                        initialPlantMessage: plant['message'],
                        waterDay: plant['waterDay'],
                      );
                      if (chatResult != null) {
                        await updatePlantAfterChat(plant, chatResult);
                      }
                    },
                    onEditName: () => showEditPlantNameDialog(context, plant),
                    onDelete: () async {
                      final shouldDelete =
                          await showDeletePlantConfirmationDialog(context);

                      if (shouldDelete != true) return;

                      await deletePlantFromSupabaseByPlant(plant);

                      if (!mounted) return;

                      setState(() {
                        extraPlants.removeAt(index);
                      });
                    },
                    photoPath: plant['photoPath'] as String?,
                    speciesDisplayName: plant['speciesDisplayName']?.toString(),
                    onPhoto: () async {
                      final image = await ImagePicker().pickImage(
                        source: ImageSource.gallery,
                      );

                      if (image == null) return;
                      if (!context.mounted) return;

                      const reactionMessage = '사진 봤다. 저장도 해뒀다. 이제 말 좀 걸어봐라.';

                      await showDialog(
                        context: context,
                        builder: (_) {
                          return plantRegistrationPreviewContent(
                            photoPath: image.path,
                            reactionText: reactionMessage,
                            continueLabel: '말걸기',
                            onCancel: () {
                              Navigator.pop(context);
                            },
                            onContinue: () async {
                              Navigator.pop(context);
                              if (!context.mounted) return;

                              final plantId = _plantIdOf(plant);
                              final photoPath = await resolvePhotoPath(
                                image: image,
                                plantId: plantId,
                              );

                              if (!context.mounted) return;

                              setState(() {
                                plant['photoPath'] = photoPath;
                                plant['message'] = reactionMessage;
                              });

                              final chatResult = await openChatPanel(
                                context,
                                plantId: plantId,
                                plantName: plant['name'],
                                initialPlantMessage: reactionMessage,
                                waterDay: plant['waterDay'],
                              );
                              if (chatResult != null) {
                                await updatePlantAfterChat(plant, chatResult);
                              }
                            },
                          );
                        },
                      );
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

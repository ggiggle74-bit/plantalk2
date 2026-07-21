import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'admin_dialogue_screen.dart';
import 'app/condition_check_action_coordinator.dart';
import 'app/daily_opening_context_coordinator.dart';
import 'app/plant_chat_result_handler.dart';
import 'app/plant_registration_action_coordinator.dart';
import 'app/plant_card_state_mapper.dart';
import 'dialogue/chat_panel.dart';
import 'models/latest_condition_memory.dart';
import 'plant_analysis/factories/existing_plant_state_check_service_factory.dart';
import 'photo/mock_plant_photo_analysis.dart';
import 'photo/photo_input_service.dart';
import 'photo/photo_source_picker.dart';
import 'photo/plant_registration_preview.dart';
import 'services/plant_condition_check_flow_service.dart';
import 'services/plant_service.dart';
import 'services/plant_photo_flow_service.dart';
import 'services/photo_service.dart';
import 'widgets/delete_plant_confirmation_dialog.dart';
import 'widgets/edit_plant_name_dialog.dart';
import 'widgets/plant_card.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://qyhstykoshvdyhzknqmn.supabase.co',
    anonKey: 'sb_publishable_vweok1t5SRu9iqLs7uGwZg_sq6vBLlb',
  );

  await _ensureAnonymousAuthSession();

  runApp(const MyApp());
}

Future<void> _ensureAnonymousAuthSession() async {
  final auth = Supabase.instance.client.auth;

  if (auth.currentSession != null) {
    return;
  }

  await auth.signInAnonymously();
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final PlantService plantService = PlantService();
  final PhotoService photoService = PhotoService();
  final PhotoInputService photoInputService = PhotoInputService();
  final ExistingPlantStateCheckAnalysisServices stateCheckAnalysisServices =
      ExistingPlantStateCheckServiceFactory.supabase().build();
  final ConditionCheckActionCoordinator conditionCheckActionCoordinator =
      const ConditionCheckActionCoordinator();
  final DailyOpeningContextCoordinator dailyOpeningContextCoordinator =
      DailyOpeningContextCoordinator.supabase();
  final PlantChatResultHandler plantChatResultHandler =
      const PlantChatResultHandler();
  final PlantRegistrationActionCoordinator plantRegistrationActionCoordinator =
      const PlantRegistrationActionCoordinator();
  late final PlantPhotoFlowService plantPhotoFlowService;
  late final PlantConditionCheckFlowService plantConditionCheckFlowService;

  String monsteraMessage = '목이 조금 말라요 🌱';
  int monsteraWaterDay = 3;

  List<Map<String, dynamic>> extraPlants = [];

  @override
  void initState() {
    super.initState();
    plantPhotoFlowService = PlantPhotoFlowService(
      photoService: photoService,
      plantService: plantService,
    );
    plantConditionCheckFlowService = PlantConditionCheckFlowService(
      plantPhotoFlowService: plantPhotoFlowService,
      conditionAnalysisService:
          stateCheckAnalysisServices.generalObservationService,
      plantService: plantService,
    );
    loadPlantsFromSupabase();
  }

  Future<void> loadPlantsFromSupabase() async {
    final data = await plantService.loadPlants();

    if (!mounted) return;

    setState(() {
      extraPlants = data.map<Map<String, dynamic>>((plant) {
        return plantCardStateFromSupabaseRow(plant);
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

  Future<String> saveRepresentativePlantPhoto({
    required XFile image,
    String? plantId,
  }) async {
    if (plantId == null || plantId.isEmpty) {
      return image.path;
    }

    return plantPhotoFlowService.saveRepresentativePhoto(
      image: image,
      plantId: plantId,
    );
  }

  Future<void> handleConditionCheck(
    BuildContext context,
    Map<String, dynamic> plant,
  ) async {
    final result = await conditionCheckActionCoordinator.handleConditionCheck(
      context: context,
      plant: plant,
      photoInputService: photoInputService,
      plantConditionCheckFlowService: plantConditionCheckFlowService,
    );
    if (result == null || !mounted || !context.mounted) return;

    final chatResult = await openChatPanel(
      context,
      plantId: plantIdOf(plant),
      plantName: plant['name']?.toString() ?? '이름 없는 식물',
      initialPlantMessage: result.analysisResult.conditionMessage,
      initialConditionMemory: LatestConditionMemory(
        message: result.memoryPayload.message,
        eventType: result.memoryPayload.eventType,
      ),
      waterDay: waterDayOf(plant),
    );
    if (chatResult != null) {
      await updatePlantAfterChat(plant, chatResult);
    }
  }

  Future<void> updatePlantWaterDayByPlant(
    Map<String, dynamic> plant,
    int waterDay,
  ) async {
    final id = plantIdOf(plant);
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
    final id = plantIdOf(plant);
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
    final id = plantIdOf(plant);

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
    final id = plantIdOf(plant);
    if (id != null) {
      await plantService.updatePlantFriendshipById(id, friendship, mood);
      return;
    }

    await plantService.updatePlantFriendship(plant['name'], friendship, mood);
  }

  Future<void> deletePlantFromSupabaseByPlant(
    Map<String, dynamic> plant,
  ) async {
    final id = plantIdOf(plant);
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
    await plantRegistrationActionCoordinator.startPlantRegistration(
      context: context,
      extraPlants: extraPlants,
      photoInputService: photoInputService,
      onAttachPhotoToExistingPlant: attachPhotoToExistingPlant,
      onStartNewPlantCreation: startNewPlantCreation,
    );
  }

  Future<void> attachPhotoToExistingPlant(
    BuildContext context,
    XFile image,
    Map<String, dynamic> plant,
  ) async {
    const reactionMessage = '사진 봤다. 이제 말 좀 걸어봐라.';
    final plantId = plantIdOf(plant);
    final photoPath = await saveRepresentativePlantPhoto(
      image: image,
      plantId: plantId,
    );

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
      waterDay: waterDayOf(plant),
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
    await plantRegistrationActionCoordinator.startNewPlantCreation(
      context: context,
      image: image,
      analysis: analysis,
      isMounted: () => mounted,
      onAddPlantToSupabase: addPlantToSupabase,
      onSaveRepresentativePlantPhoto: saveRepresentativePlantPhoto,
      onAppendNewPlant: (newPlant) {
        setState(() {
          extraPlants.add(newPlant);
        });
      },
      onOpenFirstChatForNewPlant: openFirstChatForNewPlant,
    );
  }

  Future<void> openFirstChatForNewPlant(
    BuildContext context,
    Map<String, dynamic> newPlant,
    String initialPlantMessage,
  ) async {
    final chatResult = await openChatPanel(
      context,
      plantId: plantIdOf(newPlant),
      plantName: newPlant['name'],
      initialPlantMessage: initialPlantMessage,
      waterDay: waterDayOf(newPlant),
    );

    if (chatResult != null) {
      await updatePlantAfterChat(newPlant, chatResult);
    }
  }

  Future<void> updatePlantAfterChat(
    Map<String, dynamic> plant,
    ChatPanelResult chatResult,
  ) async {
    await plantChatResultHandler.updatePlantAfterChat(
      isMounted: mounted,
      plant: plant,
      chatResult: chatResult,
      updateState: setState,
      updatePlantMessage: updatePlantMessageByPlant,
      updatePlantFriendship: updatePlantFriendshipByPlant,
    );
  }

  Future<ChatPanelResult?> openChatPanel(
    BuildContext context, {
    String? plantId,
    required String plantName,
    required String initialPlantMessage,
    required int waterDay,
    LatestConditionMemory? initialConditionMemory,
  }) async {
    final normalizedPlantId = plantId?.trim();
    final dailyOpeningContext = await dailyOpeningContextCoordinator.loadForChat(
      date: DateTime.now(),
      locale: 'ko-KR',
      plantKey: normalizedPlantId == null || normalizedPlantId.isEmpty
          ? plantName
          : normalizedPlantId,
    );
    if (!context.mounted) {
      return null;
    }

    return Navigator.push<ChatPanelResult>(
      context,
      MaterialPageRoute(
        builder: (_) {
          return ChatPanel(
            plantId: plantId,
            plantName: plantName,
            speciesDisplayName: speciesDisplayNameForChat(plantId, extraPlants),
            initialPlantMessage: initialPlantMessage,
            waterDay: waterDay,
            initialConditionMemory: initialConditionMemory,
            dailyOpeningContext: dailyOpeningContext,
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
                    waterDayOf(plant),
                    plant['friendship'] ?? 0,

                    () async {
                      final plantId = plantIdOf(plant);
                      final plantIndex = plantId == null
                          ? extraPlants.indexOf(plant)
                          : extraPlants.indexWhere(
                              (extraPlant) => plantIdOf(extraPlant) == plantId,
                            );
                      if (plantIndex < 0) return;

                      final selectedPlant = extraPlants[plantIndex];

                      setState(() {
                        selectedPlant['message'] = '고마워요 💧';
                        setWaterDay(selectedPlant, 0);
                      });

                      await updatePlantWaterDayByPlant(
                        selectedPlant,
                        waterDayOf(selectedPlant),
                      );

                      await updatePlantMessageByPlant(
                        selectedPlant,
                        selectedPlant['message'],
                      );
                    },
                    onTalk: () async {
                      final chatResult = await openChatPanel(
                        context,
                        plantId: plantIdOf(plant),
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
                    onConditionCheck: () =>
                        handleConditionCheck(context, plant),
                    onPhoto: () async {
                      final source = await showPhotoSourcePicker(context);
                      if (source == null) return;

                      final image = await photoInputService.pickImage(source);

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

                              final plantId = plantIdOf(plant);
                              final photoPath =
                                  await saveRepresentativePlantPhoto(
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

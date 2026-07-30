import 'package:flutter/material.dart';

import '../models/latest_condition_memory.dart';
import '../services/plant_service.dart';
import 'chat_panel_conversation_controller.dart';
import 'daily_keywords/models/daily_conversation_material_context.dart';
import 'daily_keywords/models/daily_opening_context.dart';
import 'dialogue_engine.dart';
import 'models/conversation_usage_ledger.dart';

typedef FetchLatestConditionMemoryCallback =
    Future<LatestConditionMemory?> Function(String plantId);
typedef FetchDialogueReplyCallback = ChatPanelDialogueReplyFetcher;

class ChatPanelResult {
  const ChatPanelResult({
    required this.latestPlantReply,
    required this.userMessageCount,
  });

  final String? latestPlantReply;
  final int userMessageCount;
}

class ChatPanel extends StatefulWidget {
  const ChatPanel({
    super.key,
    this.plantId,
    this.speciesDisplayName,
    this.speciesKey,
    this.mood,
    this.friendship,
    required this.plantName,
    required this.initialPlantMessage,
    required this.waterDay,
    this.initialConditionMemory,
    this.fetchLatestConditionMemory,
    this.fetchDialogueReply,
    this.conversationController,
    this.dailyOpeningContext,
    this.dailyConversationMaterialContext,
  });

  final String? plantId;
  final String? speciesDisplayName;
  final String? speciesKey;
  final String? mood;
  final int? friendship;
  final String plantName;
  final String initialPlantMessage;
  final int waterDay;
  final LatestConditionMemory? initialConditionMemory;
  final FetchLatestConditionMemoryCallback? fetchLatestConditionMemory;
  final FetchDialogueReplyCallback? fetchDialogueReply;
  final ChatPanelConversationController? conversationController;
  final DailyOpeningContext? dailyOpeningContext;
  final DailyConversationMaterialContext? dailyConversationMaterialContext;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final TextEditingController _controller = TextEditingController();
  PlantService? _plantService;
  late final ChatPanelConversationController _conversationController;
  final List<Map<String, String>> _messages = [];
  final ConversationUsageLedger _conversationUsageLedger =
      ConversationUsageLedger();
  String? _latestPlantReply;
  LatestConditionMemory? _latestConditionMemory;
  Future<void>? _conditionMemoryLoad;
  int _userMessageCount = 0;
  int _conditionMemoryReplyCount = 0;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    _conversationController =
        widget.conversationController ?? ChatPanelConversationController();
    _latestConditionMemory = _freshConditionMemory(
      widget.initialConditionMemory,
    );

    final String firstMessage;
    final initialMessage = widget.initialPlantMessage.trim();

    if (initialMessage.isNotEmpty) {
      firstMessage = initialMessage;
    } else if (widget.waterDay >= 4) {
      firstMessage = '나 지금 말라가는 중이다. 인간아.';
    } else if (widget.waterDay >= 3) {
      firstMessage = '이틀은 참았다. 이제 물 얘기 좀 하자.';
    } else if (widget.waterDay >= 2) {
      firstMessage = '목 마르다. 물 좀 챙겨줘.';
    } else {
      firstMessage = '';
    }

    if (firstMessage.trim().isNotEmpty) {
      _latestPlantReply = firstMessage;
      _messages.add({'sender': 'plant', 'text': firstMessage});
    }

    if (_latestConditionMemory == null) {
      _conditionMemoryLoad = _loadLatestConditionMemory();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (_isSending) {
      return;
    }

    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    final isOpeningTurn = _userMessageCount == 0;

    setState(() {
      _isSending = true;
    });

    try {
      final conditionMemoryLoad = _conditionMemoryLoad;
      if (conditionMemoryLoad != null &&
          DialogueEngine.isConditionMemoryQuestion(text)) {
        await conditionMemoryLoad;
      }

      String? prevUser;

      for (int i = _messages.length - 1; i >= 0; i--) {
        if (_messages[i]['sender'] == 'user') {
          prevUser = _messages[i]['text'];
          break;
        }
      }

      final previousPlantReply =
          prevUser == null || DialogueEngine.isConditionMemoryQuestion(prevUser)
          ? null
          : _latestPlantReply;

      setState(() {
        _userMessageCount++;
        _messages.add({'sender': 'user', 'text': text});
      });

      _controller.clear();

      final response = await _conversationController.generateReply(
        ChatPanelConversationRequest(
          plantId: widget.plantId,
          speciesDisplayName: widget.speciesDisplayName,
          speciesKey: widget.speciesKey,
          mood: widget.mood,
          friendship: widget.friendship,
          plantName: widget.plantName,
          userMessage: text,
          waterDay: widget.waterDay,
          previousUserMessage: prevUser,
          previousPlantReply: previousPlantReply,
          latestConditionMemory: _latestConditionMemory,
          conditionMemoryReplyCount: _conditionMemoryReplyCount,
          fetchDialogueReply: widget.fetchDialogueReply,
          dailyOpeningContext: widget.dailyOpeningContext,
          dailyConversationMaterialContext:
              widget.dailyConversationMaterialContext,
          usageLedger: _conversationUsageLedger,
          isOpeningTurn: isOpeningTurn,
          now: DateTime.now(),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _conditionMemoryReplyCount = response.conditionMemoryReplyCount;
        _latestPlantReply = response.replyText;
        _messages.add({'sender': 'plant', 'text': response.replyText});
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      } else {
        _isSending = false;
      }
    }
  }

  void _closePanel() {
    Navigator.of(context).pop(
      ChatPanelResult(
        latestPlantReply: _latestPlantReply,
        userMessageCount: _userMessageCount,
      ),
    );
  }

  Future<void> _loadLatestConditionMemory() async {
    final plantId = widget.plantId;
    if (plantId == null || plantId.isEmpty) return;

    LatestConditionMemory? memory;
    try {
      memory = await _fetchLatestConditionMemory(plantId);
    } catch (_) {
      return;
    }
    final freshMemory = _freshConditionMemory(memory);
    if (freshMemory == null || !mounted) {
      return;
    }

    setState(() {
      _latestConditionMemory = freshMemory;
    });
  }

  LatestConditionMemory? _freshConditionMemory(
    LatestConditionMemory? memory,
  ) {
    if (memory == null) {
      return null;
    }

    return memory.isFreshAt(DateTime.now()) ? memory : null;
  }

  Future<LatestConditionMemory?> _fetchLatestConditionMemory(String plantId) {
    final callback = widget.fetchLatestConditionMemory;
    if (callback != null) {
      return callback(plantId);
    }

    final plantService = _plantService ??= PlantService();
    return plantService.fetchLatestConditionMemoryBestEffort(plantId: plantId);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final speciesDisplayName = widget.speciesDisplayName;
    final speciesLabel =
        speciesDisplayName == null ||
            speciesDisplayName.trim().isEmpty ||
            speciesDisplayName == '알 수 없음'
        ? '종류 미확인'
        : '추정 종류: $speciesDisplayName';
    final latestConditionMemoryMessage = _freshConditionMemory(
      _latestConditionMemory,
    )?.message;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _closePanel();
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              children: [
                ListTile(
                  title: Text(widget.plantName),
                  subtitle: Text(
                    latestConditionMemoryMessage == null
                        ? speciesLabel
                        : '$speciesLabel\n최근 상태 확인: $latestConditionMemoryMessage',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _closePanel,
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: _messages.isEmpty
                      ? Center(
                          child: Text(
                            widget.waterDay >= 2
                                ? '목 마르다. 물 좀 챙겨줘 '
                                : '${widget.plantName}에게 말을 걸어보세요.',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            final isUser = message['sender'] == 'user';

                            return Align(
                              alignment: isUser
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: isUser
                                      ? Colors.green.shade100
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(message['text'] ?? ''),
                              ),
                            );
                          },
                        ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          enabled: !_isSending,
                          onSubmitted: _isSending
                              ? null
                              : (_) => _sendMessage(),
                          decoration: InputDecoration(
                            hintText: '${widget.plantName}에게 말 걸기',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: _isSending ? null : () => _sendMessage(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

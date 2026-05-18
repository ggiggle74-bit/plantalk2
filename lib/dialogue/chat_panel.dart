import 'package:flutter/material.dart';

import '../models/latest_condition_memory.dart';
import '../services/dialogue_service.dart';
import '../services/plant_service.dart';
import 'dialogue_engine.dart';

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
    required this.plantName,
    required this.initialPlantMessage,
    required this.waterDay,
  });

  final String? plantId;
  final String? speciesDisplayName;
  final String plantName;
  final String initialPlantMessage;
  final int waterDay;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final TextEditingController _controller = TextEditingController();
  final DialogueService _dialogueService = DialogueService();
  final PlantService _plantService = PlantService();
  final List<Map<String, String>> _messages = [];
  String? _latestPlantReply;
  LatestConditionMemory? _latestConditionMemory;
  int _userMessageCount = 0;
  int _conditionMemoryReplyCount = 0;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();

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

    _loadLatestConditionMemory();
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

    setState(() {
      _isSending = true;
    });

    try {
      String? prevUser;

      for (int i = _messages.length - 1; i >= 0; i--) {
        if (_messages[i]['sender'] == 'user') {
          prevUser = _messages[i]['text'];
          break;
        }
      }

      setState(() {
        _userMessageCount++;
        _messages.add({'sender': 'user', 'text': text});
      });

      _controller.clear();

      final conditionContext = _conditionMemoryReplyCount >= 2
          ? null
          : DialogueEngine.photoConditionDialogueContext(
              userMessage: text,
              memoryMessage: _latestConditionMemory?.message,
              memoryEventType: _latestConditionMemory?.eventType,
              replyCount: _conditionMemoryReplyCount,
            );

      final memoryReply = conditionContext == null
          ? null
          : DialogueEngine.conditionMemoryReply(
              plantName: widget.plantName,
              waterDay: widget.waterDay,
              context: conditionContext,
            );

      final fallbackReply = DialogueEngine.placeholderReply(
        plantName: widget.plantName,
        userMessage: text,
        waterDay: widget.waterDay,
        previousUserMessage: prevUser,
      );

      final detectedSituation = DialogueEngine.detectSituation(
        userMessage: text,
        waterDay: widget.waterDay,
        previousUserMessage: prevUser,
      );

      var reply = fallbackReply;
      var usedDbReply = false;

      debugPrint(
        'chat input="$text" waterDay=${widget.waterDay} situation=${conditionContext?.situation ?? detectedSituation}',
      );

      if (conditionContext != null) {
        try {
          final dbReply = await _dialogueService.fetchRandomReply(
            situation: conditionContext.situation,
          );

          if (dbReply != null) {
            reply = dbReply;
            usedDbReply = true;
          } else if (memoryReply != null) {
            reply = memoryReply;
          }
        } catch (_) {
          reply = memoryReply ?? fallbackReply;
        }

        _conditionMemoryReplyCount++;
      } else if (memoryReply == null &&
          detectedSituation != null &&
          detectedSituation.trim().isNotEmpty) {
        try {
          final dbReply = await _dialogueService.fetchRandomReply(
            situation: detectedSituation,
          );

          if (dbReply != null) {
            reply = dbReply;
            usedDbReply = true;
          }
        } catch (_) {
          reply = fallbackReply;
        }
      }

      debugPrint('chat dbReplyUsed=$usedDbReply');

      reply = DialogueEngine.applyPlantPersonality(
        reply: reply,
        plantId: widget.plantId,
        plantName: widget.plantName,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _latestPlantReply = reply;
        _messages.add({'sender': 'plant', 'text': reply});
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

    final memory = await _plantService.fetchLatestConditionMemoryBestEffort(
      plantId: plantId,
    );
    if (memory == null || !mounted) return;

    setState(() {
      _latestConditionMemory = memory;
    });
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

    final latestConditionMemoryMessage = _latestConditionMemory?.message;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _closePanel();
      },
      child: Scaffold(
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

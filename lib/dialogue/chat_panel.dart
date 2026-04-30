import 'package:flutter/material.dart';

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
    required this.plantName,
    required this.initialPlantMessage,
    required this.waterDay,
  });

  final String plantName;
  final String initialPlantMessage;
  final int waterDay;

  @override
  State<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends State<ChatPanel> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  String? _latestPlantReply;
  int _userMessageCount = 0;

  @override
  void initState() {
    super.initState();

    if (widget.initialPlantMessage.trim().isNotEmpty) {
      _latestPlantReply = widget.initialPlantMessage;
      _messages.add({
        'sender': 'plant',
        'text': widget.initialPlantMessage,
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() {
      _userMessageCount++;
      _messages.add({
        'sender': 'user',
        'text': text,
      });
    });

    _controller.clear();

    final reply = DialogueEngine.placeholderReply(
      plantName: widget.plantName,
      userMessage: text,
    );

    setState(() {
      _latestPlantReply = reply;
      _messages.add({
        'sender': 'plant',
        'text': reply,
      });
    });
  }

  void _closePanel() {
    Navigator.of(context).pop(
      ChatPanelResult(
        latestPlantReply: _latestPlantReply,
        userMessageCount: _userMessageCount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            children: [
              ListTile(
                title: Text(widget.plantName),
                subtitle: Text('${widget.plantName}와 대화 중'),
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
                              : '무가리한테 말을 걸어보세요',
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
                        onSubmitted: (_) => _sendMessage(),
                        decoration: const InputDecoration(
                          hintText: '무가리에게 말 걸기',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

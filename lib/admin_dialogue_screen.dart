import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDialogueScreen extends StatefulWidget {
  const AdminDialogueScreen({super.key});

  @override
  State<AdminDialogueScreen> createState() => _AdminDialogueScreenState();
}

class _AdminDialogueScreenState extends State<AdminDialogueScreen> {
  final TextEditingController _situationController = TextEditingController();
  final TextEditingController _textController = TextEditingController();

  bool _isSaving = false;
  String _statusMessage = '';

  @override
  void dispose() {
    _situationController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveDialogue() async {
    final situation = _situationController.text.trim();
    final text = _textController.text.trim();

    if (situation.isEmpty || text.isEmpty) {
      setState(() {
        _statusMessage = '상황과 대사를 모두 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _statusMessage = '저장 중...';
    });

    try {
      await Supabase.instance.client.from('dialogues').insert({
        'situation': situation,
        'text': text,
      });

      if (!mounted) return;

      _situationController.clear();
      _textController.clear();

      setState(() {
        _statusMessage = '저장되었습니다.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _statusMessage = '저장 실패: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관리자 대사 입력')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _situationController,
              decoration: const InputDecoration(
                labelText: '상황',
                hintText: '예: 물 부족, 기분 좋음',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: '대사',
                hintText: '무가리가 할 말을 입력하세요.',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveDialogue,
              child: Text(_isSaving ? '저장 중...' : '저장'),
            ),
            const SizedBox(height: 12),
            Text(_statusMessage),
          ],
        ),
      ),
    );
  }
}

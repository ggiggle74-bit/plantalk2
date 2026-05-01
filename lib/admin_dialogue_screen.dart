import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDialogueScreen extends StatefulWidget {
  const AdminDialogueScreen({super.key});

  @override
  State<AdminDialogueScreen> createState() => _AdminDialogueScreenState();
}

class _AdminDialogueScreenState extends State<AdminDialogueScreen> {
  static const List<String> _situations = [
    'greeting',
    'thirsty',
    'lonely',
    'happy',
    'joke',
    'encourage',
    'complain',
    'thanks',
  ];

  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  final List<Map<String, String>> _recentSaved = [];

  String _selectedSituation = _situations.first;
  bool _isSaving = false;
  String _statusMessage = '';

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  Future<void> _saveDialogue() async {
    final text = _textController.text.trim();

    if (text.isEmpty) {
      setState(() {
        _statusMessage = 'Enter dialogue text.';
      });
      _textFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isSaving = true;
      _statusMessage = 'Saving...';
    });

    try {
      await Supabase.instance.client.from('dialogues').insert({
        'situation': _selectedSituation,
        'text': text,
      });

      if (!mounted) return;

      _textController.clear();

      setState(() {
        _statusMessage = 'Saved.';
        _recentSaved.insert(0, {'situation': _selectedSituation, 'text': text});
        if (_recentSaved.length > 5) {
          _recentSaved.removeLast();
        }
      });

      _textFocusNode.requestFocus();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _statusMessage = 'Save failed: $error';
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
      appBar: AppBar(title: const Text('Admin Dialogue')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Situation',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _situations.map((situation) {
                  return ChoiceChip(
                    label: Text(situation),
                    selected: _selectedSituation == situation,
                    onSelected: _isSaving
                        ? null
                        : (selected) {
                            if (!selected) return;
                            setState(() {
                              _selectedSituation = situation;
                              _statusMessage = '';
                            });
                            _textFocusNode.requestFocus();
                          },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                focusNode: _textFocusNode,
                decoration: const InputDecoration(
                  labelText: 'Dialogue text',
                  hintText: 'Enter Mugari dialogue.',
                  border: OutlineInputBorder(),
                ),
                minLines: 4,
                maxLines: 6,
                textInputAction: TextInputAction.newline,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveDialogue,
                child: Text(_isSaving ? 'Saving...' : 'Save'),
              ),
              const SizedBox(height: 8),
              Text(_statusMessage),
              if (_recentSaved.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Recent saved',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ..._recentSaved.map((dialogue) {
                  return Card(
                    child: ListTile(
                      dense: true,
                      title: Text(dialogue['text'] ?? ''),
                      subtitle: Text(dialogue['situation'] ?? ''),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

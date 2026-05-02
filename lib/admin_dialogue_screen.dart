import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDialogueScreen extends StatefulWidget {
  const AdminDialogueScreen({super.key});

  @override
  State<AdminDialogueScreen> createState() => _AdminDialogueScreenState();
}

class _AdminDialogueScreenState extends State<AdminDialogueScreen> {
  static const List<String> _activeSituations = [
    'greeting',
    'thirsty',
    'lonely',
    'thanks',
    'happy',
    'joke',
    'encourage',
    'complain',
  ];

  static const List<String> _situations = [..._activeSituations, 'draft'];

  static const Map<String, String> _situationLabels = {
    'greeting': '인사',
    'thirsty': '물 필요',
    'lonely': '외로움',
    'thanks': '감사',
    'happy': '기쁨',
    'joke': '농담',
    'encourage': '응원',
    'complain': '불평',
    'draft': '초안',
  };

  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  final List<Map<String, String>> _recentSaved = [];
  final List<Map<String, dynamic>> _draftDialogues = [];
  final Map<Object, String> _draftSelections = {};
  final Set<Object> _updatingDraftIds = {};

  String _selectedSituation = _situations.first;
  bool _isSaving = false;
  bool _isLoadingDrafts = false;
  String _statusMessage = '';
  String _draftStatusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDraftDialogues();
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  String _labelFor(String situation) {
    return _situationLabels[situation] ?? situation;
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

      if (_selectedSituation == 'draft') {
        await _loadDraftDialogues();
      }

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

  Future<void> _loadDraftDialogues() async {
    setState(() {
      _isLoadingDrafts = true;
      _draftStatusMessage = '';
    });

    try {
      final data = await Supabase.instance.client
          .from('dialogues')
          .select('id, situation, text, created_at')
          .eq('situation', 'draft')
          .order('created_at', ascending: false);

      if (!mounted) return;

      final rows = List<Map<String, dynamic>>.from(data);

      setState(() {
        _draftDialogues
          ..clear()
          ..addAll(rows);
        _draftSelections.clear();

        for (final row in rows) {
          final id = row['id'];
          if (id != null) {
            _draftSelections[id] = _activeSituations.first;
          }
        }

        if (rows.isEmpty) {
          _draftStatusMessage = '검토할 초안이 없습니다.';
        }
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _draftStatusMessage = '초안을 불러오지 못했습니다: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDrafts = false;
        });
      }
    }
  }

  Future<void> _reclassifyDraft(Map<String, dynamic> dialogue) async {
    final id = dialogue['id'];
    if (id == null) {
      setState(() {
        _draftStatusMessage = '초안 id가 없어 수정할 수 없습니다.';
      });
      return;
    }

    final selectedSituation = _draftSelections[id] ?? _activeSituations.first;

    setState(() {
      _updatingDraftIds.add(id);
      _draftStatusMessage = '';
    });

    try {
      await Supabase.instance.client
          .from('dialogues')
          .update({'situation': selectedSituation})
          .eq('id', id);

      if (!mounted) return;

      setState(() {
        _draftDialogues.removeWhere((row) => row['id'] == id);
        _draftSelections.remove(id);
        _draftStatusMessage = '초안을 ${_labelFor(selectedSituation)}(으)로 이동했습니다.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _draftStatusMessage = '초안 수정에 실패했습니다: $error';
      });
    } finally {
      if (mounted) {
        setState(() {
          _updatingDraftIds.remove(id);
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
                    label: Text(_labelFor(situation)),
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
                      subtitle: Text(_labelFor(dialogue['situation'] ?? '')),
                    ),
                  );
                }),
              ],
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      '초안 검토',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoadingDrafts ? null : _loadDraftDialogues,
                    child: const Text('새로고침'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (_isLoadingDrafts)
                const Center(child: CircularProgressIndicator())
              else if (_draftDialogues.isNotEmpty)
                ..._draftDialogues.map((dialogue) {
                  final id = dialogue['id'];
                  final isUpdating =
                      id != null && _updatingDraftIds.contains(id);
                  final selectedSituation = id == null
                      ? _activeSituations.first
                      : _draftSelections[id] ?? _activeSituations.first;

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(dialogue['text']?.toString() ?? ''),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: selectedSituation,
                            decoration: const InputDecoration(
                              labelText: '이동할 카테고리',
                              border: OutlineInputBorder(),
                            ),
                            items: _activeSituations.map((situation) {
                              return DropdownMenuItem(
                                value: situation,
                                child: Text(_labelFor(situation)),
                              );
                            }).toList(),
                            onChanged: isUpdating || id == null
                                ? null
                                : (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _draftSelections[id] = value;
                                    });
                                  },
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: isUpdating || id == null
                                ? null
                                : () => _reclassifyDraft(dialogue),
                            child: Text(isUpdating ? '이동 중...' : '카테고리로 이동'),
                          ),
                        ],
                      ),
                    ),
                  );
                })
              else
                const Text('검토할 초안이 없습니다.'),
              if (_draftStatusMessage.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_draftStatusMessage),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

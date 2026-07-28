class ConversationUsageLedger {
  ConversationUsageLedger({
    this.materialCooldownTurns = 3,
    this.replyCooldownTurns = 4,
    this.maximumTrackedMaterials = 8,
    this.maximumTrackedReplies = 16,
  }) : assert(materialCooldownTurns > 0),
       assert(replyCooldownTurns > 0),
       assert(maximumTrackedMaterials > 0),
       assert(maximumTrackedReplies > 0);

  final int materialCooldownTurns;
  final int replyCooldownTurns;
  final int maximumTrackedMaterials;
  final int maximumTrackedReplies;

  final Map<String, int> _materialLastUsedTurn = {};
  final Map<String, int> _replyLastUsedTurn = {};
  int _turn = 0;

  int get turn => _turn;

  Set<String> get trackedMaterialKeys =>
      Set.unmodifiable(_materialLastUsedTurn.keys);

  Set<String> get trackedReplyKeys => Set.unmodifiable(_replyLastUsedTurn.keys);

  bool canUseMaterial(String key) {
    return _isAvailable(
      _materialLastUsedTurn,
      _normalize(key),
      materialCooldownTurns,
    );
  }

  bool canUseReply(String key) {
    return _isAvailable(
      _replyLastUsedTurn,
      _normalize(key),
      replyCooldownTurns,
    );
  }

  void record({String? materialKey, required String replyKey}) {
    _turn++;

    final normalizedMaterialKey = _normalize(materialKey ?? '');
    if (normalizedMaterialKey.isNotEmpty) {
      _materialLastUsedTurn[normalizedMaterialKey] = _turn;
      _trimOldest(_materialLastUsedTurn, maximumTrackedMaterials);
    }

    final normalizedReplyKey = _normalize(replyKey);
    if (normalizedReplyKey.isNotEmpty) {
      _replyLastUsedTurn[normalizedReplyKey] = _turn;
      _trimOldest(_replyLastUsedTurn, maximumTrackedReplies);
    }
  }

  bool _isAvailable(
    Map<String, int> usage,
    String key,
    int cooldownTurns,
  ) {
    if (key.isEmpty) {
      return false;
    }

    final lastUsedTurn = usage[key];
    return lastUsedTurn == null || _turn - lastUsedTurn >= cooldownTurns;
  }

  void _trimOldest(Map<String, int> usage, int maximumEntries) {
    while (usage.length > maximumEntries) {
      String? oldestKey;
      int? oldestTurn;

      usage.forEach((key, turn) {
        if (oldestTurn == null || turn < oldestTurn!) {
          oldestKey = key;
          oldestTurn = turn;
        }
      });

      if (oldestKey == null) {
        return;
      }
      usage.remove(oldestKey);
    }
  }

  String _normalize(String value) {
    return value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}

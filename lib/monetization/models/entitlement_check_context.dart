class EntitlementCheckContext {
  const EntitlementCheckContext({
    this.currentUsage,
    this.currentPlantCount,
    this.now,
  });

  final int? currentUsage;
  final int? currentPlantCount;
  final DateTime? now;
}

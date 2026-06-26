class PlantAnalysisException implements Exception {
  const PlantAnalysisException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() {
    final cause = this.cause;
    if (cause == null) {
      return 'PlantAnalysisException: $message';
    }

    return 'PlantAnalysisException: $message ($cause)';
  }
}

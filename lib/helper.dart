  /// Returns a date string in the format "YYYY-MM-DD".
  String formatDate(DateTime date) {
    return date.toIso8601String().substring(0, 10);
  }

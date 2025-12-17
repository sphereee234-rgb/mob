class HistoryTracker {
  final int? id;
  final String currency;
  final double rate;
  final DateTime date;
  final String baseCurrency;

  HistoryTracker({
    this.id,
    required this.currency,
    required this.rate,
    required this.date,
    required this.baseCurrency,
  });

  /// Convert to Map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'currency': currency,
      'rate': rate,
      // Store dates as ISO8601 strings so ordering by text works and
      // parsing back is deterministic.
      'date': date.toIso8601String(), // ISO string for SQLite TEXT
      'baseCurrency': baseCurrency,
    };
  }

  /// Convert from Map (handle both old int and new ISO string)
  factory HistoryTracker.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    final dateValue = map['date'];

    if (dateValue is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(dateValue);
    } else if (dateValue is String) {
      parsedDate = DateTime.parse(dateValue);
    } else {
      throw Exception('Invalid date format: $dateValue');
    }

    return HistoryTracker(
      id: map['id'] as int?,
      currency: map['currency'] as String,
      rate: (map['rate'] as num).toDouble(),
      date: parsedDate,
      baseCurrency: map['baseCurrency'] as String,
    );
  }
}

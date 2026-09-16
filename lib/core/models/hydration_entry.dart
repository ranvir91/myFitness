class HydrationEntry {
  const HydrationEntry({
    required this.id,
    required this.amountMl,
    required this.timestamp,
  });

  final String id;
  final int amountMl;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'id': id,
        'amountMl': amountMl,
        'timestamp': timestamp.toIso8601String(),
      };

  factory HydrationEntry.fromJson(Map<String, dynamic> json) {
    return HydrationEntry(
      id: json['id'] as String,
      amountMl: json['amountMl'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

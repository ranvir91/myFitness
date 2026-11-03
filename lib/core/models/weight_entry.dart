class WeightEntry {
  const WeightEntry({
    required this.id,
    required this.weightKg,
    required this.timestamp,
  });

  final String id;
  final double weightKg;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'id': id,
        'weightKg': weightKg,
        'timestamp': timestamp.toIso8601String(),
      };

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      id: json['id'] as String,
      weightKg: (json['weightKg'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

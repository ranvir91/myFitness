class WorkoutSet {
  const WorkoutSet({
    required this.id,
    required this.exercise,
    required this.reps,
    required this.timestamp,
  });

  final String id;
  final String exercise;
  final int reps;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'id': id,
        'exercise': exercise,
        'reps': reps,
        'timestamp': timestamp.toIso8601String(),
      };

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      id: json['id'] as String,
      exercise: json['exercise'] as String,
      reps: json['reps'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

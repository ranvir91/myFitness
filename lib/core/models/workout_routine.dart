class WorkoutRoutine {
  const WorkoutRoutine({
    required this.id,
    required this.name,
    required this.exercises,
  });

  final String id;
  final String name;
  final List<String> exercises;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'exercises': exercises,
      };

  factory WorkoutRoutine.fromJson(Map<String, dynamic> json) {
    return WorkoutRoutine(
      id: json['id'] as String,
      name: json['name'] as String,
      exercises: (json['exercises'] as List).cast<String>(),
    );
  }
}

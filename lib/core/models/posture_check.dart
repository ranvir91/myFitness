enum PostureStatus { good, adjusted }

class PostureCheck {
  const PostureCheck({
    required this.id,
    required this.status,
    required this.timestamp,
  });

  final String id;
  final PostureStatus status;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status.name,
        'timestamp': timestamp.toIso8601String(),
      };

  factory PostureCheck.fromJson(Map<String, dynamic> json) {
    return PostureCheck(
      id: json['id'] as String,
      status: PostureStatus.values.byName(json['status'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class ScoreEntry {
  final String id;
  final String? userId;
  final String username;
  final int moves;
  final int seconds;
  final String difficulty;
  final DateTime timestamp;

  ScoreEntry({
    required this.id,
    this.userId,
    required this.username,
    required this.moves,
    required this.seconds,
    required this.difficulty,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'username': username,
    'moves': moves,
    'seconds': seconds,
    'difficulty': difficulty,
    'created_at': timestamp.toIso8601String(),
  };

  factory ScoreEntry.fromJson(Map<String, dynamic> json) => ScoreEntry(
    id: json['id']?.toString() ?? '',
    userId: json['user_id'],
    username: json['username'] ?? 'Anonymous',
    moves: json['moves'] ?? 0,
    seconds: json['seconds'] ?? 0,
    difficulty: json['difficulty'] ?? 'easy',
    timestamp: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
  );
}

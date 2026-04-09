class ScoreEntry {
  final String id;
  final String username;
  final int moves;
  final int seconds;
  final String difficulty;
  final DateTime timestamp;

  ScoreEntry({
    required this.id,
    required this.username,
    required this.moves,
    required this.seconds,
    required this.difficulty,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'moves': moves,
    'seconds': seconds,
    'difficulty': difficulty,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ScoreEntry.fromJson(Map<String, dynamic> json) => ScoreEntry(
    id: json['id'],
    username: json['username'],
    moves: json['moves'],
    seconds: json['seconds'],
    difficulty: json['difficulty'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}

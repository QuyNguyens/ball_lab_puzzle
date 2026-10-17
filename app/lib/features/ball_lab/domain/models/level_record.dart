import 'package:meta/meta.dart';

/// Performance and completion record for a single Ball Lab level.
@immutable
class LevelRecord {
  const LevelRecord({
    required this.levelId,
    this.isCompleted = false,
    this.stars = 0,
    this.bestMoves,
  });

  /// Deserializes a [LevelRecord] from JSON, with defensive defaults.
  factory LevelRecord.fromJson(Map<String, dynamic> json) {
    final int? id = json['levelId'] as int?;
    final int safeId = id != null && id > 0 ? id : 1;
    final bool completed = (json['isCompleted'] as bool?) ?? false;
    final int starCount = ((json['stars'] as int?) ?? 0).clamp(0, 3);
    final int? moves = json['bestMoves'] as int?;

    return LevelRecord(
      levelId: safeId,
      isCompleted: completed,
      stars: completed ? starCount : 0,
      bestMoves: completed ? moves : null,
    );
  }

  /// The level number this record belongs to.
  final int levelId;

  /// Whether the player has successfully solved this level at least once.
  final bool isCompleted;

  /// The highest star rating achieved (0 to 3).
  final int stars;

  /// The lowest move count used to successfully solve this level.
  final int? bestMoves;

  /// Returns a copy of this record with the specified fields replaced.
  LevelRecord copyWith({
    int? levelId,
    bool? isCompleted,
    int? stars,
    int? bestMoves,
  }) {
    return LevelRecord(
      levelId: levelId ?? this.levelId,
      isCompleted: isCompleted ?? this.isCompleted,
      stars: stars ?? this.stars,
      bestMoves: bestMoves ?? this.bestMoves,
    );
  }

  /// Converts this record to a JSON map for persistent storage.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'levelId': levelId,
      'isCompleted': isCompleted,
      'stars': stars,
      if (bestMoves != null) 'bestMoves': bestMoves,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LevelRecord &&
        other.levelId == levelId &&
        other.isCompleted == isCompleted &&
        other.stars == stars &&
        other.bestMoves == bestMoves;
  }

  @override
  int get hashCode => Object.hash(levelId, isCompleted, stars, bestMoves);

  @override
  String toString() =>
      'LevelRecord(levelId: $levelId, isCompleted: $isCompleted, stars: $stars, bestMoves: $bestMoves)';
}

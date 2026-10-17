import 'package:meta/meta.dart';

import 'level_record.dart';

/// Overall player campaign progression across Ball Lab Puzzle levels.
@immutable
class GameProgression {
  const GameProgression({
    this.unlockedLevelMax = 1,
    this.records = const <int, LevelRecord>{},
  });

  /// Deserializes [GameProgression] from JSON with fault-tolerant fallbacks.
  factory GameProgression.fromJson(Map<String, dynamic> json) {
    final int rawUnlocked = (json['unlockedLevelMax'] as int?) ?? 1;
    final int safeUnlocked = rawUnlocked < 1 ? 1 : rawUnlocked;

    final Map<String, dynamic>? rawRecords =
        json['records'] as Map<String, dynamic>?;
    final Map<int, LevelRecord> map = <int, LevelRecord>{};

    if (rawRecords != null) {
      rawRecords.forEach((String key, dynamic value) {
        final int? id = int.tryParse(key);
        if (id != null && value is Map<String, dynamic>) {
          try {
            map[id] = LevelRecord.fromJson(value);
          } catch (_) {
            // Ignore malformed individual records safely
          }
        }
      });
    }

    return GameProgression(
      unlockedLevelMax: safeUnlocked,
      records: Map<int, LevelRecord>.unmodifiable(map),
    );
  }

  /// The highest level ID unlocked so far. Always at least 1.
  final int unlockedLevelMax;

  /// Map of levelId to performance record.
  final Map<int, LevelRecord> records;

  /// Total stars collected across all completed levels.
  /// Each level contributes only its best star rating (0 to 3).
  int get totalStars {
    int total = 0;
    for (final LevelRecord record in records.values) {
      if (record.isCompleted) {
        total += record.stars.clamp(0, 3);
      }
    }
    return total;
  }

  /// Whether [levelId] is currently unlocked and playable.
  /// Level 1 is always unlocked.
  bool isLevelUnlocked(int levelId) {
    if (levelId <= 1) return true;
    return levelId <= unlockedLevelMax;
  }

  /// Retrieves the performance record for [levelId], or an uncompleted default.
  LevelRecord getRecord(int levelId) {
    return records[levelId] ?? LevelRecord(levelId: levelId);
  }

  /// Registers a level completion result adhering to non-decreasing progression rules:
  ///
  /// 1. Unlocks the next level: `max(unlockedLevelMax, levelId + 1)`.
  /// 2. Only upgrades stars if [stars] > previous best stars.
  /// 3. Best moves is retained as the minimum moves used among winning runs.
  /// 4. Never reduces stars, best moves, or locks any previously unlocked level.
  GameProgression recordLevelCompletion({
    required int levelId,
    required int stars,
    required int movesUsed,
  }) {
    final LevelRecord previous = getRecord(levelId);
    final int safeStars = stars.clamp(0, 3);
    final int newStars = safeStars > previous.stars ? safeStars : previous.stars;

    int newBestMoves = movesUsed;
    if (previous.isCompleted && previous.bestMoves != null) {
      newBestMoves = movesUsed < previous.bestMoves! ? movesUsed : previous.bestMoves!;
    }

    final LevelRecord updatedRecord = LevelRecord(
      levelId: levelId,
      isCompleted: true,
      stars: newStars,
      bestMoves: newBestMoves,
    );

    final Map<int, LevelRecord> updatedRecords =
        Map<int, LevelRecord>.from(records);
    updatedRecords[levelId] = updatedRecord;

    final int nextLevel = levelId + 1;
    final int newUnlockedMax =
        nextLevel > unlockedLevelMax ? nextLevel : unlockedLevelMax;

    return GameProgression(
      unlockedLevelMax: newUnlockedMax,
      records: Map<int, LevelRecord>.unmodifiable(updatedRecords),
    );
  }

  /// Converts this progression state to JSON for persistence.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'unlockedLevelMax': unlockedLevelMax,
      'records': records.map(
        (int key, LevelRecord val) =>
            MapEntry<String, dynamic>('$key', val.toJson()),
      ),
    };
  }


  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! GameProgression) return false;
    if (other.unlockedLevelMax != unlockedLevelMax) return false;
    if (other.records.length != records.length) return false;
    for (final MapEntry<int, LevelRecord> entry in records.entries) {
      if (other.records[entry.key] != entry.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(unlockedLevelMax, Object.hashAll(records.entries));

  @override
  String toString() =>
      'GameProgression(unlockedLevelMax: $unlockedLevelMax, totalStars: $totalStars, records: ${records.length})';
}

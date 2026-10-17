import 'package:meta/meta.dart';

/// Tracks player consumable resources: daily lives, undos, and hints.
///
/// Designed with defensive defaults and separation between daily free quotas
/// and purchased/rewarded bonus items.
@immutable
class GameEconomy {
  const GameEconomy({
    this.dailyLives = defaultMaxDailyLives,
    this.bonusLives = 0,
    this.undoCount = defaultDailyUndos,
    this.hintCount = defaultDailyHints,
    this.lastDailyRefreshDate = '',
    this.lastKnownTimestampMs = 0,
  });

  /// Deserializes a [GameEconomy] snapshot from JSON with defensive clamps and fallbacks.
  factory GameEconomy.fromJson(Map<String, dynamic> json) {
    final int safeDailyLives = ((json['dailyLives'] as int?) ?? defaultMaxDailyLives)
        .clamp(0, defaultMaxDailyLives);
    final int safeBonusLives = ((json['bonusLives'] as int?) ?? 0)
        .clamp(0, 9999);
    final int safeUndos = ((json['undoCount'] as int?) ?? defaultDailyUndos)
        .clamp(0, 9999);
    final int safeHints = ((json['hintCount'] as int?) ?? defaultDailyHints)
        .clamp(0, 9999);
    final String safeDate = (json['lastDailyRefreshDate'] as String?) ?? '';
    final int safeTimestamp = (json['lastKnownTimestampMs'] as int?) ?? 0;

    return GameEconomy(
      dailyLives: safeDailyLives,
      bonusLives: safeBonusLives,
      undoCount: safeUndos,
      hintCount: safeHints,
      lastDailyRefreshDate: safeDate,
      lastKnownTimestampMs: safeTimestamp,
    );
  }

  /// Initial daily free lives given to the player.
  static const int defaultMaxDailyLives = 5;

  /// Initial daily free Undos available.
  static const int defaultDailyUndos = 3;

  /// Initial daily free Hints available.
  static const int defaultDailyHints = 2;

  /// Remaining free lives from the daily quota (0 to 5).
  final int dailyLives;

  /// Additional rewarded or purchased lives that never expire on daily rollover.
  final int bonusLives;

  /// Remaining Undos for today.
  final int undoCount;

  /// Remaining Hints for today.
  final int hintCount;

  /// Date string of the last daily reset (`YYYY-MM-DD` in Asia/Ho_Chi_Minh).
  final String lastDailyRefreshDate;

  /// Monotonic timestamp (epoch milliseconds) when the economy was last touched.
  /// Used for basic clock rollback tampering detection.
  final int lastKnownTimestampMs;

  /// Total playable attempts available (daily free quota + bonus lives).
  int get totalLives => dailyLives + bonusLives;

  /// Whether the player has at least 1 attempt to start a game level.
  bool get canPlay => totalLives > 0;

  /// Whether an Undo action can currently be performed.
  bool get canUndo => undoCount > 0;

  /// Whether a Hint action can currently be requested.
  bool get canHint => hintCount > 0;

  /// Creates a copy of this state with specified fields replaced.
  GameEconomy copyWith({
    int? dailyLives,
    int? bonusLives,
    int? undoCount,
    int? hintCount,
    String? lastDailyRefreshDate,
    int? lastKnownTimestampMs,
  }) {
    return GameEconomy(
      dailyLives: dailyLives ?? this.dailyLives,
      bonusLives: bonusLives ?? this.bonusLives,
      undoCount: undoCount ?? this.undoCount,
      hintCount: hintCount ?? this.hintCount,
      lastDailyRefreshDate: lastDailyRefreshDate ?? this.lastDailyRefreshDate,
      lastKnownTimestampMs: lastKnownTimestampMs ?? this.lastKnownTimestampMs,
    );
  }

  /// Consumes 1 life upon an actual game defeat.
  ///
  /// Depletes from [dailyLives] first, then from [bonusLives].
  /// Returns the unchanged instance if [totalLives] is already 0.
  GameEconomy consumeLife({int? nowMs}) {
    if (!canPlay) return this;

    final int updatedTimestamp = nowMs ?? lastKnownTimestampMs;
    if (dailyLives > 0) {
      return copyWith(
        dailyLives: dailyLives - 1,
        lastKnownTimestampMs: updatedTimestamp,
      );
    } else {
      return copyWith(
        bonusLives: (bonusLives - 1).clamp(0, 9999),
        lastKnownTimestampMs: updatedTimestamp,
      );
    }
  }

  /// Consumes 1 Undo following a successfully performed undo operation.
  GameEconomy consumeUndo({int? nowMs}) {
    if (!canUndo) return this;
    return copyWith(
      undoCount: undoCount - 1,
      lastKnownTimestampMs: nowMs ?? lastKnownTimestampMs,
    );
  }

  /// Consumes 1 Hint after a valid hint move has been delivered to the player.
  GameEconomy consumeHint({int? nowMs}) {
    if (!canHint) return this;
    return copyWith(
      hintCount: hintCount - 1,
      lastKnownTimestampMs: nowMs ?? lastKnownTimestampMs,
    );
  }

  /// Adds bonus lives (from rewarded ads or in-app purchases in future).
  GameEconomy addBonusLives(int count, {int? nowMs}) {
    if (count <= 0) return this;
    return copyWith(
      bonusLives: bonusLives + count,
      lastKnownTimestampMs: nowMs ?? lastKnownTimestampMs,
    );
  }

  /// Refreshes daily free quotas for a new day.
  ///
  /// Restores [dailyLives] to 5, [undoCount] to 3, [hintCount] to 2.
  /// Preserves all previously earned/purchased [bonusLives].
  GameEconomy refreshForNewDay(String newDateStr, int nowMs) {
    return copyWith(
      dailyLives: defaultMaxDailyLives,
      undoCount: defaultDailyUndos,
      hintCount: defaultDailyHints,
      lastDailyRefreshDate: newDateStr,
      lastKnownTimestampMs: nowMs,
    );
  }

  /// Converts this record to a JSON map for persistent storage.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'dailyLives': dailyLives,
      'bonusLives': bonusLives,
      'undoCount': undoCount,
      'hintCount': hintCount,
      'lastDailyRefreshDate': lastDailyRefreshDate,
      'lastKnownTimestampMs': lastKnownTimestampMs,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GameEconomy &&
        other.dailyLives == dailyLives &&
        other.bonusLives == bonusLives &&
        other.undoCount == undoCount &&
        other.hintCount == hintCount &&
        other.lastDailyRefreshDate == lastDailyRefreshDate &&
        other.lastKnownTimestampMs == lastKnownTimestampMs;
  }

  @override
  int get hashCode => Object.hash(
        dailyLives,
        bonusLives,
        undoCount,
        hintCount,
        lastDailyRefreshDate,
        lastKnownTimestampMs,
      );

  @override
  String toString() =>
      'GameEconomy(lives: $totalLives ($dailyLives+$bonusLives), undos: $undoCount, hints: $hintCount, date: $lastDailyRefreshDate)';
}

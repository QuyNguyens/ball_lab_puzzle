import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../models/game_progression.dart';

/// Contract for persisting and retrieving player campaign progression.
abstract interface class ProgressionRepository {
  /// Loads progression synchronously from memory/cache or defaults to initial state.
  GameProgression getProgression();

  /// Persists [progression] safely to non-volatile storage.
  Future<void> saveProgression(GameProgression progression);

  /// Resets progression back to the initial state (e.g. Level 1 unlocked, 0 stars).
  Future<void> clearProgression();
}

/// Hive-backed implementation storing serialized progression in a `Box<String>`.
class HiveProgressionRepository implements ProgressionRepository {
  HiveProgressionRepository(this._box,
      {this.storageKey = 'ball_lab_progression'});

  final Box<String> _box;
  final String storageKey;

  @override
  GameProgression getProgression() {
    try {
      final String? jsonStr = _box.get(storageKey);
      if (jsonStr == null || jsonStr.trim().isEmpty) {
        return const GameProgression();
      }
      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return GameProgression.fromJson(decoded);
      }
    } catch (e, stack) {
      debugPrint('Failed to load progression from Hive: $e\n$stack');
    }
    return const GameProgression();
  }

  @override
  Future<void> saveProgression(GameProgression progression) async {
    try {
      final String jsonStr = jsonEncode(progression.toJson());
      await _box.put(storageKey, jsonStr);
    } catch (e, stack) {
      debugPrint('Failed to save progression to Hive: $e\n$stack');
    }
  }

  @override
  Future<void> clearProgression() async {
    try {
      await _box.delete(storageKey);
    } catch (e, stack) {
      debugPrint('Failed to clear progression from Hive: $e\n$stack');
    }
  }
}

/// In-memory progression repository for unit tests and stateless runs.
class InMemoryProgressionRepository implements ProgressionRepository {
  InMemoryProgressionRepository(
      [GameProgression initial = const GameProgression()])
      : _progression = initial;

  GameProgression _progression;

  @override
  GameProgression getProgression() => _progression;

  @override
  Future<void> saveProgression(GameProgression progression) async {
    _progression = progression;
  }

  @override
  Future<void> clearProgression() async {
    _progression = const GameProgression();
  }
}

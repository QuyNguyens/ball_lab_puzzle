import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../models/active_game_session.dart';
import '../models/game_economy.dart';

/// Contract for persisting and retrieving player daily lives, undos, and hints.
abstract interface class EconomyRepository {
  /// Loads economy snapshot synchronously from storage or defaults to initial state.
  GameEconomy getEconomy();

  /// Persists [economy] safely to non-volatile storage.
  Future<void> saveEconomy(GameEconomy economy);

  /// Resets economy back to the initial defaults.
  Future<void> clearEconomy();

  /// Retrieves any active mid-game session saved prior to unexpected closure.
  ActiveGameSession? getActiveSession();

  /// Persists [session] so player can resume without losing an attempt.
  Future<void> saveActiveSession(ActiveGameSession session);

  /// Clears the active game session upon level completion or defeat.
  Future<void> clearActiveSession();
}

/// Hive-backed production implementation storing JSON in a `Box<String>`.
class HiveEconomyRepository implements EconomyRepository {
  HiveEconomyRepository(
    this._box, {
    this.economyKey = 'ball_lab_economy',
    this.sessionKey = 'ball_lab_active_session',
  });

  final Box<String> _box;
  final String economyKey;
  final String sessionKey;

  @override
  GameEconomy getEconomy() {
    try {
      final String? jsonStr = _box.get(economyKey);
      if (jsonStr == null || jsonStr.trim().isEmpty) {
        return const GameEconomy();
      }
      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return GameEconomy.fromJson(decoded);
      }
    } catch (e, stack) {
      debugPrint('Failed to load economy from Hive: $e\n$stack');
    }
    return const GameEconomy();
  }

  @override
  Future<void> saveEconomy(GameEconomy economy) async {
    try {
      final String jsonStr = jsonEncode(economy.toJson());
      await _box.put(economyKey, jsonStr);
    } catch (e, stack) {
      debugPrint('Failed to save economy to Hive: $e\n$stack');
    }
  }

  @override
  Future<void> clearEconomy() async {
    try {
      await _box.delete(economyKey);
    } catch (e, stack) {
      debugPrint('Failed to clear economy from Hive: $e\n$stack');
    }
  }

  @override
  ActiveGameSession? getActiveSession() {
    try {
      final String? jsonStr = _box.get(sessionKey);
      if (jsonStr == null || jsonStr.trim().isEmpty) return null;
      final dynamic decoded = jsonDecode(jsonStr);
      if (decoded is Map<String, dynamic>) {
        return ActiveGameSession.fromJson(decoded);
      }
    } catch (e, stack) {
      debugPrint('Failed to load active session from Hive: $e\n$stack');
    }
    return null;
  }

  @override
  Future<void> saveActiveSession(ActiveGameSession session) async {
    try {
      final String jsonStr = jsonEncode(session.toJson());
      await _box.put(sessionKey, jsonStr);
    } catch (e, stack) {
      debugPrint('Failed to save active session to Hive: $e\n$stack');
    }
  }

  @override
  Future<void> clearActiveSession() async {
    try {
      await _box.delete(sessionKey);
    } catch (e, stack) {
      debugPrint('Failed to clear active session from Hive: $e\n$stack');
    }
  }
}

/// In-memory economy repository for widget and unit tests.
class InMemoryEconomyRepository implements EconomyRepository {
  InMemoryEconomyRepository([GameEconomy initial = const GameEconomy()])
      : _economy = initial;

  GameEconomy _economy;
  ActiveGameSession? _activeSession;

  @override
  GameEconomy getEconomy() => _economy;

  @override
  Future<void> saveEconomy(GameEconomy economy) async {
    _economy = economy;
  }

  @override
  Future<void> clearEconomy() async {
    _economy = const GameEconomy();
  }

  @override
  ActiveGameSession? getActiveSession() => _activeSession;

  @override
  Future<void> saveActiveSession(ActiveGameSession session) async {
    _activeSession = session;
  }

  @override
  Future<void> clearActiveSession() async {
    _activeSession = null;
  }
}

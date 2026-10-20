import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../domain/models/active_game_session.dart';
import '../../domain/models/game_economy.dart';
import '../../domain/services/economy_repository.dart';
import '../../domain/services/time_service.dart';
import 'audio_controller.dart';

/// Provider for the [TimeService]. Defaults to [VietnamTimeService] (`Asia/Ho_Chi_Minh`, UTC+7).
final Provider<TimeService> timeServiceProvider =
    Provider<TimeService>((Ref ref) {
  return const VietnamTimeService();
}, name: 'timeServiceProvider');

/// Provider for the [EconomyRepository]. Wraps Core's `prefsBoxProvider` or defaults to in-memory.
final Provider<EconomyRepository> economyRepositoryProvider =
    Provider<EconomyRepository>((Ref ref) {
  try {
    final Box<String> box = ref.watch(prefsBoxProvider);
    return HiveEconomyRepository(box);
  } catch (_) {
    return InMemoryEconomyRepository();
  }
}, name: 'economyRepositoryProvider');

/// Riverpod Notifier managing daily lives, undos, and hints across the application.
final NotifierProvider<EconomyController, GameEconomy>
    economyControllerProvider =
    NotifierProvider<EconomyController, GameEconomy>(
  EconomyController.new,
  name: 'economyControllerProvider',
);

class EconomyController extends Notifier<GameEconomy> {
  @override
  GameEconomy build() {
    final EconomyRepository repo = ref.watch(economyRepositoryProvider);
    final TimeService timeService = ref.watch(timeServiceProvider);

    GameEconomy stored = repo.getEconomy();
    if (stored.dailyLives > GameEconomy.defaultMaxDailyLives) {
      stored = stored.copyWith(dailyLives: GameEconomy.defaultMaxDailyLives);
      repo.saveEconomy(stored);
    }
    if (stored.hintCount == 0 && stored.lastDailyRefreshDate.isEmpty) {
      stored = stored.copyWith(hintCount: GameEconomy.defaultDailyHints);
      repo.saveEconomy(stored);
    }
    return _applyDailyRefresh(stored, timeService, repo);
  }

  /// Internal helper verifying and applying daily quota reset on initialization or app resume.
  GameEconomy _applyDailyRefresh(
    GameEconomy current,
    TimeService timeService,
    EconomyRepository repo,
  ) {
    if (current.dailyLives > GameEconomy.defaultMaxDailyLives) {
      current = current.copyWith(dailyLives: GameEconomy.defaultMaxDailyLives);
      repo.saveEconomy(current);
    }
    final String todayVn = timeService.getVietnamDateString();
    final int nowMs = timeService.nowUtc().millisecondsSinceEpoch;

    // Check if new player or a calendar day has elapsed in Asia/Ho_Chi_Minh
    if (current.lastDailyRefreshDate.isEmpty ||
        current.lastDailyRefreshDate != todayVn) {
      // Basic clock rollback check: if user moved device clock back before last recorded event
      final bool isClockRollback = current.lastKnownTimestampMs > 0 &&
          nowMs < (current.lastKnownTimestampMs - 60000);

      if (!isClockRollback) {
        final GameEconomy refreshed = current.refreshForNewDay(todayVn, nowMs);
        repo.saveEconomy(refreshed);
        return refreshed;
      }
    }

    // Reset rewarded lives quota if calendar date changed according to Vietnam timezone
    if (current.lastRewardedLivesDate.isNotEmpty &&
        current.lastRewardedLivesDate != todayVn &&
        current.rewardedLivesToday > 0) {
      final GameEconomy resetRewarded = current.copyWith(
        rewardedLivesToday: 0,
        lastRewardedLivesDate: todayVn,
      );
      repo.saveEconomy(resetRewarded);
      return resetRewarded;
    }

    // Update last known timestamp monotonically
    if (nowMs > current.lastKnownTimestampMs) {
      final GameEconomy updatedTimestamp =
          current.copyWith(lastKnownTimestampMs: nowMs);
      repo.saveEconomy(updatedTimestamp);
      return updatedTimestamp;
    }

    return current;
  }

  /// Forces an on-demand check for daily rollover (e.g. when app resumes from background).
  void refreshDailyQuotasIfNeeded() {
    final TimeService timeService = ref.read(timeServiceProvider);
    final EconomyRepository repo = ref.read(economyRepositoryProvider);
    state = _applyDailyRefresh(state, timeService, repo);
  }

  /// Deducts exactly 1 life upon a verified game defeat.
  ///
  /// Safe to call multiple times defensively; consumers must guard idempotency per loss.
  /// Returns `true` if a life was consumed, `false` if total lives were already 0.
  Future<bool> consumeLifeOnDefeat() async {
    if (!state.canPlay) return false;

    final bool hadLivesBefore = state.canPlay;
    final TimeService timeService = ref.read(timeServiceProvider);
    final int nowMs = timeService.nowUtc().millisecondsSinceEpoch;

    final GameEconomy updated = state.consumeLife(nowMs: nowMs);
    state = updated;

    final EconomyRepository repo = ref.read(economyRepositoryProvider);
    await repo.saveEconomy(updated);

    if (hadLivesBefore && !updated.canPlay) {
      ref.read(gameAudioServiceProvider).playOutOfLives();
    }
    return true;
  }

  /// Consumes 1 Undo upon an executed undo move.
  ///
  /// Returns `true` if an Undo quota was consumed, `false` if no undos were remaining.
  Future<bool> consumeUndo() async {
    if (!state.canUndo) return false;

    final TimeService timeService = ref.read(timeServiceProvider);
    final int nowMs = timeService.nowUtc().millisecondsSinceEpoch;

    final GameEconomy updated = state.consumeUndo(nowMs: nowMs);
    state = updated;

    final EconomyRepository repo = ref.read(economyRepositoryProvider);
    await repo.saveEconomy(updated);
    return true;
  }

  /// Consumes 1 Hint upon a delivered hint move.
  ///
  /// Returns `true` if a Hint quota was consumed, `false` if no hints were remaining.
  Future<bool> consumeHint() async {
    if (!state.canHint) return false;

    final TimeService timeService = ref.read(timeServiceProvider);
    final int nowMs = timeService.nowUtc().millisecondsSinceEpoch;

    final GameEconomy updated = state.consumeHint(nowMs: nowMs);
    state = updated;

    final EconomyRepository repo = ref.read(economyRepositoryProvider);
    await repo.saveEconomy(updated);
    return true;
  }

  /// Grants bonus lives (e.g. from future Rewarded Ads or In-App Purchases).
  ///
  /// Bonus lives never expire upon daily midnight rollover.
  Future<void> addBonusLives(int count) async {
    if (count <= 0) return;

    final TimeService timeService = ref.read(timeServiceProvider);
    final int nowMs = timeService.nowUtc().millisecondsSinceEpoch;

    final GameEconomy updated = state.addBonusLives(count, nowMs: nowMs);
    state = updated;

    final EconomyRepository repo = ref.read(economyRepositoryProvider);
    await repo.saveEconomy(updated);
  }

  /// Adds 1 rewarded hint upon watching a rewarded ad.
  Future<void> addRewardedHint([int count = 1]) async {
    if (count <= 0) return;
    final TimeService timeService = ref.read(timeServiceProvider);
    final int nowMs = timeService.nowUtc().millisecondsSinceEpoch;

    final GameEconomy updated = state.addRewardedHints(count, nowMs: nowMs);
    state = updated;

    final EconomyRepository repo = ref.read(economyRepositoryProvider);
    await repo.saveEconomy(updated);
  }

  /// Adds exactly 1 rewarded life upon watching a rewarded ad (max 3/day in Asia/Ho_Chi_Minh).
  ///
  /// Returns `true` if granted, or `false` if daily rewarded limit (3) was already reached.
  Future<bool> addRewardedLife() async {
    refreshDailyQuotasIfNeeded();
    if (!state.canWatchAdForLife) return false;

    final TimeService timeService = ref.read(timeServiceProvider);
    final String todayVn = timeService.getVietnamDateString();
    final int nowMs = timeService.nowUtc().millisecondsSinceEpoch;

    final GameEconomy updated = state.addRewardedLife(
      todayVn: todayVn,
      nowMs: nowMs,
    );
    state = updated;

    final EconomyRepository repo = ref.read(economyRepositoryProvider);
    await repo.saveEconomy(updated);
    return true;
  }

  /// Saves the current mid-game session snapshot.
  Future<void> saveActiveSession(ActiveGameSession session) async {
    final EconomyRepository repo = ref.read(economyRepositoryProvider);
    await repo.saveActiveSession(session);
  }

  /// Alias for [saveActiveSession].
  Future<void> saveSession(ActiveGameSession session) =>
      saveActiveSession(session);

  /// Clears active game session upon level completion or loss.
  Future<void> clearActiveSession() async {
    final EconomyRepository repo = ref.read(economyRepositoryProvider);
    await repo.clearActiveSession();
  }

  /// Alias for [clearActiveSession].
  Future<void> clearSession() => clearActiveSession();

  /// Retrieves any previously saved mid-game session.
  ActiveGameSession? getActiveSession() {
    final EconomyRepository repo = ref.read(economyRepositoryProvider);
    return repo.getActiveSession();
  }

  /// Alias for [getActiveSession].
  ActiveGameSession? get activeSession => getActiveSession();

  /// Calculates duration remaining until 00:00:00 midnight in Asia/Ho_Chi_Minh.
  Duration timeUntilNextDailyRefresh() {
    final TimeService timeService = ref.read(timeServiceProvider);
    return timeService.timeUntilNextMidnight();
  }

  /// Resets economy to new-player initial state (e.g. for testing / account reset).
  Future<void> resetEconomy() async {
    final TimeService timeService = ref.read(timeServiceProvider);
    final String todayVn = timeService.getVietnamDateString();
    final int nowMs = timeService.nowUtc().millisecondsSinceEpoch;

    final GameEconomy initial = GameEconomy(
      lastDailyRefreshDate: todayVn,
      lastKnownTimestampMs: nowMs,
    );
    state = initial;

    final EconomyRepository repo = ref.read(economyRepositoryProvider);
    await repo.saveEconomy(initial);
    await repo.clearActiveSession();
  }
}

import 'package:core/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../../domain/models/game_progression.dart';
import '../../domain/models/level_record.dart';
import '../../domain/services/progression_repository.dart';

/// Provider for the [ProgressionRepository]. In production, wraps Core's `prefsBoxProvider`.
final Provider<ProgressionRepository> progressionRepositoryProvider =
    Provider<ProgressionRepository>((Ref ref) {
  try {
    final Box<String> box = ref.watch(prefsBoxProvider);
    return HiveProgressionRepository(box);
  } catch (_) {
    return InMemoryProgressionRepository();
  }
}, name: 'progressionRepositoryProvider');

/// Riverpod Notifier managing player campaign progression across the application.
final NotifierProvider<ProgressionController, GameProgression>
    progressionControllerProvider =
    NotifierProvider<ProgressionController, GameProgression>(
  ProgressionController.new,
  name: 'progressionControllerProvider',
);

class ProgressionController extends Notifier<GameProgression> {
  @override
  GameProgression build() {
    final ProgressionRepository repo = ref.watch(progressionRepositoryProvider);
    return repo.getProgression();
  }

  /// Records a verified level victory, upgrading stars, recording best moves,
  /// and unlocking the next level.
  Future<void> recordVictory({
    required int levelId,
    required int stars,
    required int movesUsed,
  }) async {
    final GameProgression updated = state.recordLevelCompletion(
      levelId: levelId,
      stars: stars,
      movesUsed: movesUsed,
    );
    state = updated;

    final ProgressionRepository repo = ref.read(progressionRepositoryProvider);
    await repo.saveProgression(updated);
  }

  /// Checks if [levelId] is currently unlocked.
  bool isLevelUnlocked(int levelId) => state.isLevelUnlocked(levelId);

  /// Gets the player record for [levelId].
  LevelRecord getRecord(int levelId) => state.getRecord(levelId);

  /// Resets progression to default new player state.
  Future<void> resetProgression() async {
    state = const GameProgression();
    final ProgressionRepository repo = ref.read(progressionRepositoryProvider);
    await repo.clearProgression();
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/game_progression.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/level_data.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/level_record.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/services/level_provider_service.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/services/progression_repository.dart';
import 'package:flutter_riverpod_template/features/ball_lab/presentation/controllers/progression_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Progression & Star Rating Domain Tests', () {
    test('1. New player starts with only Level 1 unlocked and 0 total stars', () {
      const GameProgression progression = GameProgression();
      expect(progression.unlockedLevelMax, equals(1));
      expect(progression.totalStars, equals(0));
      expect(progression.isLevelUnlocked(1), isTrue);
      expect(progression.isLevelUnlocked(2), isFalse);
      expect(progression.isLevelUnlocked(5), isFalse);

      final LevelRecord l1 = progression.getRecord(1);
      expect(l1.isCompleted, isFalse);
      expect(l1.stars, equals(0));
      expect(l1.bestMoves, isNull);
    });

    test('2. Completing level 1 unlocks exactly level 2 and awards stars', () {
      const GameProgression initial = GameProgression();
      final GameProgression updated = initial.recordLevelCompletion(
        levelId: 1,
        stars: 3,
        movesUsed: 12,
      );

      expect(updated.unlockedLevelMax, equals(2));
      expect(updated.isLevelUnlocked(1), isTrue);
      expect(updated.isLevelUnlocked(2), isTrue);
      expect(updated.isLevelUnlocked(3), isFalse);
      expect(updated.totalStars, equals(3));

      final LevelRecord record1 = updated.getRecord(1);
      expect(record1.isCompleted, isTrue);
      expect(record1.stars, equals(3));
      expect(record1.bestMoves, equals(12));
    });

    test('3. Replaying a level does not downgrade best stars or best moves', () {
      GameProgression progression = const GameProgression();

      // Run 1: 3 stars in 12 moves
      progression = progression.recordLevelCompletion(
        levelId: 1,
        stars: 3,
        movesUsed: 12,
      );
      expect(progression.getRecord(1).stars, equals(3));
      expect(progression.getRecord(1).bestMoves, equals(12));

      // Run 2: Replay with worse performance (1 star in 18 moves)
      progression = progression.recordLevelCompletion(
        levelId: 1,
        stars: 1,
        movesUsed: 18,
      );
      // Best record must be retained!
      expect(progression.getRecord(1).stars, equals(3));
      expect(progression.getRecord(1).bestMoves, equals(12));
      expect(progression.totalStars, equals(3));

      // Run 3: Replay with same stars but fewer moves (3 stars in 10 moves)
      progression = progression.recordLevelCompletion(
        levelId: 1,
        stars: 3,
        movesUsed: 10,
      );
      expect(progression.getRecord(1).stars, equals(3));
      expect(progression.getRecord(1).bestMoves, equals(10));
    });

    test('4. Total stars is the sum of best stars across all completed levels, not replay sum', () {
      GameProgression progression = const GameProgression();

      // Complete Level 1 with 2 stars
      progression = progression.recordLevelCompletion(
        levelId: 1,
        stars: 2,
        movesUsed: 14,
      );
      expect(progression.totalStars, equals(2));

      // Complete Level 2 with 3 stars
      progression = progression.recordLevelCompletion(
        levelId: 2,
        stars: 3,
        movesUsed: 8,
      );
      expect(progression.totalStars, equals(5));

      // Replay Level 1 and upgrade to 3 stars -> total stars increases by 1 to 6
      progression = progression.recordLevelCompletion(
        levelId: 1,
        stars: 3,
        movesUsed: 12,
      );
      expect(progression.totalStars, equals(6));

      // Replay Level 2 and get 3 stars again -> total stars remains 6
      progression = progression.recordLevelCompletion(
        levelId: 2,
        stars: 3,
        movesUsed: 9,
      );
      expect(progression.totalStars, equals(6));
    });

    test('5. Star rating thresholds calculate properly based on verified level moves', () {
      const LevelProviderService service = LevelProviderService();
      final LevelData level1 = service.getLevel(1)!;

      expect(level1.calculateStars(10), equals(3)); // <= 12
      expect(level1.calculateStars(12), equals(3)); // == 12
      expect(level1.calculateStars(13), equals(2)); // <= 15
      expect(level1.calculateStars(15), equals(2)); // == 15
      expect(level1.calculateStars(16), equals(1)); // <= 18
      expect(level1.calculateStars(18), equals(1)); // == 18
      expect(level1.calculateStars(19), equals(0)); // > maxMoves
      expect(level1.calculateStars(0), equals(0));
    });

    test('6. Milestone levels (Level 5 and 10) have isMilestone set to true', () {
      const LevelProviderService service = LevelProviderService();
      expect(service.getLevel(1)!.isMilestone, isFalse);
      expect(service.getLevel(4)!.isMilestone, isFalse);
      expect(service.getLevel(5)!.isMilestone, isTrue);
      expect(service.getLevel(6)!.isMilestone, isFalse);
      expect(service.getLevel(10)!.isMilestone, isTrue);
    });

    test('7. Progression survives JSON serialization and deserialization intact', () {
      GameProgression progression = const GameProgression();
      progression = progression.recordLevelCompletion(levelId: 1, stars: 3, movesUsed: 12);
      progression = progression.recordLevelCompletion(levelId: 2, stars: 2, movesUsed: 14);

      final Map<String, dynamic> json = progression.toJson();
      final GameProgression restored = GameProgression.fromJson(json);

      expect(restored.unlockedLevelMax, equals(3));
      expect(restored.totalStars, equals(5));
      expect(restored.getRecord(1).stars, equals(3));
      expect(restored.getRecord(1).bestMoves, equals(12));
      expect(restored.getRecord(2).stars, equals(2));
      expect(restored.getRecord(2).bestMoves, equals(14));
      expect(restored.isLevelUnlocked(1), isTrue);
      expect(restored.isLevelUnlocked(2), isTrue);
      expect(restored.isLevelUnlocked(3), isTrue);
      expect(restored.isLevelUnlocked(4), isFalse);
    });

    test('8. ProgressionController updates and saves through ProgressionRepository', () async {
      final InMemoryProgressionRepository memoryRepo =
          InMemoryProgressionRepository();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          progressionRepositoryProvider.overrideWithValue(memoryRepo),
        ],
      );

      final ProgressionController controller =
          container.read(progressionControllerProvider.notifier);
      expect(container.read(progressionControllerProvider).unlockedLevelMax, equals(1));

      // Record victory on Level 1
      await controller.recordVictory(levelId: 1, stars: 3, movesUsed: 12);

      expect(container.read(progressionControllerProvider).unlockedLevelMax, equals(2));
      expect(container.read(progressionControllerProvider).totalStars, equals(3));
      // Persisted to repository
      expect(memoryRepo.getProgression().unlockedLevelMax, equals(2));
      expect(memoryRepo.getProgression().totalStars, equals(3));

      // Reset
      await controller.resetProgression();
      expect(container.read(progressionControllerProvider).unlockedLevelMax, equals(1));
      expect(container.read(progressionControllerProvider).totalStars, equals(0));
      expect(memoryRepo.getProgression().totalStars, equals(0));
    });
  });
}

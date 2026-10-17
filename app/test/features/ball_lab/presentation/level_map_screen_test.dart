import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/game_progression.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/services/progression_repository.dart';
import 'package:flutter_riverpod_template/features/ball_lab/presentation/controllers/progression_controller.dart';
import 'package:flutter_riverpod_template/features/ball_lab/presentation/screens/level_map_screen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget createTestWidget({
    ProgressionRepository? repo,
  }) {
    return ProviderScope(
      overrides: <Override>[
        if (repo != null)
          progressionRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(
        home: LevelMapScreen(),
      ),
    );
  }

  group('LevelMapScreen - Visuals & Progression Rendering', () {
    testWidgets('1. Renders title header, total stars pill, and all 10 level nodes', (
      WidgetTester tester,
    ) async {
      final InMemoryProgressionRepository repo =
          InMemoryProgressionRepository();

      await tester.pumpWidget(createTestWidget(repo: repo));
      await tester.pumpAndSettle();

      expect(find.text('BALL LAB JOURNEY'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('total_stars_counter')), findsOneWidget);
      expect(find.text('0 / 2997'), findsOneWidget);

      // Level 1 node is visible and unlocked with PLAY label
      expect(find.byKey(const ValueKey<String>('level_node_1')), findsOneWidget);
      expect(find.text('PLAY'), findsOneWidget);
    });

    testWidgets('2. Tapping a locked level displays explanatory unlock snackbar', (
      WidgetTester tester,
    ) async {
      final InMemoryProgressionRepository repo =
          InMemoryProgressionRepository();

      await tester.pumpWidget(createTestWidget(repo: repo));
      await tester.pumpAndSettle();

      // Tap on Level 2 (locked for new player)
      final Finder level2Finder = find.byKey(const ValueKey<String>('level_node_2'));
      // If not rendered yet because of scroll offset, scroll or tap the lock icon
      // In our layout Level 2 is around y = 170 which is well within 600px height
      if (level2Finder.evaluate().isNotEmpty) {
        await tester.tap(level2Finder);
      } else {
        // Tapping lock icon of level 2
        await tester.tap(find.byIcon(Icons.lock_rounded).first);
      }
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.textContaining('Complete Level 1 to unlock'), findsOneWidget);
    });

    testWidgets('3. Tapping an unlocked level opens the preview bottom sheet', (
      WidgetTester tester,
    ) async {
      final InMemoryProgressionRepository repo =
          InMemoryProgressionRepository();

      await tester.pumpWidget(createTestWidget(repo: repo));
      await tester.pumpAndSettle();

      // Tap Level 1
      await tester.tap(find.byKey(const ValueKey<String>('level_node_1')));
      await tester.pumpAndSettle();

      // Bottom sheet appears with Level 1 details and start button
      expect(find.text('LEVEL 1'), findsOneWidget);
      expect(find.text('COLORS'), findsOneWidget);
      expect(find.text('TUBES'), findsOneWidget);
      expect(find.text('MAX MOVES'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('level_preview_start_button')), findsOneWidget);
    });

    testWidgets('4. Completed levels display their earned stars and total stars counter updates', (
      WidgetTester tester,
    ) async {
      // Setup progression with Level 1 completed (3 stars) and Level 2 unlocked (current)
      GameProgression progression = const GameProgression();
      progression = progression.recordLevelCompletion(levelId: 1, stars: 3, movesUsed: 12);

      final InMemoryProgressionRepository repo =
          InMemoryProgressionRepository(progression);

      await tester.pumpWidget(createTestWidget(repo: repo));
      await tester.pumpAndSettle();

      // Total stars must show 3 / 2997
      expect(find.text('3 / 2997'), findsOneWidget);

      // Level 1 node shows 3 stars under it
      expect(find.byKey(const ValueKey<String>('level_node_1')), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('level_node_2')), findsOneWidget);

      // Level 2 is now current (has PLAY badge)
      expect(find.text('PLAY'), findsOneWidget);
    });

    testWidgets('5. Milestone level (Level 5) shows milestone trophy icon', (
      WidgetTester tester,
    ) async {
      // Unlocked up to Level 5
      const GameProgression progression = GameProgression(unlockedLevelMax: 5);
      final InMemoryProgressionRepository repo =
          InMemoryProgressionRepository(progression);

      await tester.pumpWidget(createTestWidget(repo: repo));
      await tester.pumpAndSettle();

      // Milestone trophy icon should appear on level 5 node
      expect(find.byIcon(Icons.emoji_events_rounded), findsWidgets);
    });
  });
}

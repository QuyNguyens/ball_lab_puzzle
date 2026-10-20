import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/ball_color.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/level_data.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/tube.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/services/level_provider_service.dart';
import 'package:flutter_riverpod_template/features/ball_lab/presentation/controllers/game_controller.dart';
import 'package:flutter_riverpod_template/features/ball_lab/presentation/screens/ball_lab_screen.dart';
import 'package:flutter_riverpod_template/features/ball_lab/presentation/widgets/level_completed_dialog.dart';
import 'package:flutter_riverpod_template/features/ball_lab/presentation/widgets/level_failed_dialog.dart';
import 'package:flutter_riverpod_template/features/ball_lab/presentation/widgets/test_tube_widget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod_template/app/l10n.dart';
import 'package:flutter_riverpod_template/l10n/app_localizations.dart';

void main() {
  Widget createTestApp({
    List<Override> overrides = const <Override>[],
    int? initialLevelId,
  }) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: BallLabScreen(initialLevelId: initialLevelId),
      ),
    );
  }

  group('BallLabScreen - Gameplay UI & Rendering', () {
    testWidgets('1. Screen renders the initial level and tubes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('LEVEL 1'), findsOneWidget);
      expect(find.text('MOVES LEFT: 18'), findsOneWidget);
      expect(find.textContaining('Sort all balls by color'), findsOneWidget);
      expect(find.byType(TestTubeWidget), findsNWidgets(5));
      expect(find.byKey(const ValueKey<String>('action_restart_button')),
          findsOneWidget);
      expect(find.byKey(const ValueKey<String>('action_undo_button')),
          findsOneWidget);
      expect(find.byKey(const ValueKey<String>('action_hint_button')),
          findsOneWidget);
    });

    testWidgets('2. Move counter updates after a valid move', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('MOVES LEFT: 18'), findsOneWidget);

      // Level 1: Tube 0 top is Blue, Tube 3 is empty
      await tester.tap(find.byKey(const ValueKey<String>('tube_0')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey<String>('tube_3')));
      await tester.pumpAndSettle();

      expect(find.text('MOVES LEFT: 17'), findsOneWidget);
    });

    testWidgets(
        '3. Tapping tubes follows controller selection and move behavior', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap 1: Select Tube 0
      await tester.tap(find.byKey(const ValueKey<String>('tube_0')));
      await tester.pumpAndSettle();

      TestTubeWidget tube0 = tester.widget<TestTubeWidget>(
        find.byKey(const ValueKey<String>('tube_0')),
      );
      expect(tube0.isSelected, isTrue);

      // Tap same tube: Deselect Tube 0
      await tester.tap(find.byKey(const ValueKey<String>('tube_0')));
      await tester.pumpAndSettle();

      tube0 = tester.widget<TestTubeWidget>(
        find.byKey(const ValueKey<String>('tube_0')),
      );
      expect(tube0.isSelected, isFalse);
    });

    testWidgets('4. Undo and Restart work from UI', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Execute a move: Tube 0 -> Tube 3
      await tester.tap(find.byKey(const ValueKey<String>('tube_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('tube_3')));
      await tester.pumpAndSettle();

      expect(find.text('MOVES LEFT: 17'), findsOneWidget);

      // Tap Undo
      await tester
          .tap(find.byKey(const ValueKey<String>('action_undo_button')));
      await tester.pumpAndSettle();

      expect(find.text('MOVES LEFT: 18'), findsOneWidget);

      // Execute move again
      await tester.tap(find.byKey(const ValueKey<String>('tube_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('tube_3')));
      await tester.pumpAndSettle();

      expect(find.text('MOVES LEFT: 17'), findsOneWidget);

      // Tap Restart
      await tester
          .tap(find.byKey(const ValueKey<String>('action_restart_button')));
      await tester.pumpAndSettle();

      expect(find.text('MOVES LEFT: 18'), findsOneWidget);
    });
  });

  group('BallLabScreen - Level Completion & Navigation', () {
    testWidgets('5. A completed game displays the victory UI', (
      WidgetTester tester,
    ) async {
      final _MockTwoLevelService mockService = _MockTwoLevelService();

      await tester.pumpWidget(
        createTestApp(
          overrides: <Override>[
            levelProviderServiceProvider.overrideWithValue(mockService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Move red from Tube 2 to Tube 0 (completes level)
      await tester.tap(find.byKey(const ValueKey<String>('tube_2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('tube_0')));
      await tester.pumpAndSettle();

      // Victory dialog should appear
      expect(find.byType(LevelCompletedDialog), findsOneWidget);
      expect(find.text('EXPERIMENT COMPLETE!'), findsOneWidget);
      expect(find.text('Level 1 Mastered'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('victory_play_again_button')),
          findsOneWidget);
      expect(find.byKey(const ValueKey<String>('victory_next_level_button')),
          findsOneWidget);
    });

    testWidgets('6. Next Level action works when next level exists', (
      WidgetTester tester,
    ) async {
      final _MockTwoLevelService mockService = _MockTwoLevelService();

      await tester.pumpWidget(
        createTestApp(
          overrides: <Override>[
            levelProviderServiceProvider.overrideWithValue(mockService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Solve level 1
      await tester.tap(find.byKey(const ValueKey<String>('tube_2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('tube_0')));
      await tester.pumpAndSettle();

      expect(find.byType(LevelCompletedDialog), findsOneWidget);

      // Tap Next Level
      await tester
          .tap(find.byKey(const ValueKey<String>('victory_next_level_button')));
      await tester.pumpAndSettle();

      // Dialog is dismissed and Level 2 is loaded
      expect(find.byType(LevelCompletedDialog), findsNothing);
      expect(find.text('LEVEL 2'), findsOneWidget);
      expect(find.text('MOVES LEFT: 18'), findsOneWidget);
    });

    testWidgets('7. Narrow screen does not produce layout overflow', (
      WidgetTester tester,
    ) async {
      // Simulate a small viewport (320x568)
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(BallLabScreen), findsOneWidget);
      expect(find.byType(TestTubeWidget), findsNWidgets(5));
    });

    testWidgets(
        '8. Drag and drop ball from tube 0 to tube 3 executes valid move', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('MOVES LEFT: 18'), findsOneWidget);

      final Offset tube0Center = tester.getCenter(
        find.byKey(const ValueKey<String>('tube_0')),
      );
      final Offset tube3Center = tester.getCenter(
        find.byKey(const ValueKey<String>('tube_3')),
      );

      final TestGesture gesture = await tester.startGesture(tube0Center);
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(milliseconds: 50));

      await gesture.moveTo(tube3Center);
      await tester.pump(const Duration(milliseconds: 50));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('MOVES LEFT: 17'), findsOneWidget);
    });

    testWidgets('9. Drag and drop onto invalid tube snaps back safely', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tube 0 top is Blue, Tube 1 top is Red (color mismatch)
      final Offset tube0Center = tester.getCenter(
        find.byKey(const ValueKey<String>('tube_0')),
      );
      final Offset tube1Center = tester.getCenter(
        find.byKey(const ValueKey<String>('tube_1')),
      );

      final TestGesture gesture = await tester.startGesture(tube0Center);
      await gesture.moveBy(const Offset(0, -20));
      await tester.pump(const Duration(milliseconds: 50));

      await gesture.moveTo(tube1Center);
      await tester.pump(const Duration(milliseconds: 50));

      await gesture.up();
      await tester.pumpAndSettle();

      // Move count remains 0 (movesLeft remains 18) because the drop was invalid
      expect(find.text('MOVES LEFT: 18'), findsOneWidget);
    });

    testWidgets(
        '10. Drag and drop back to source tube snaps back without moving', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final Offset tube0Center = tester.getCenter(
        find.byKey(const ValueKey<String>('tube_0')),
      );

      final TestGesture gesture = await tester.startGesture(tube0Center);
      await gesture.moveBy(const Offset(0, -40));
      await tester.pump(const Duration(milliseconds: 50));

      await gesture.moveTo(tube0Center);
      await tester.pump(const Duration(milliseconds: 50));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('MOVES LEFT: 18'), findsOneWidget);
    });

    testWidgets('11. Drag and release outside board snaps back safely', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final Offset tube0Center = tester.getCenter(
        find.byKey(const ValueKey<String>('tube_0')),
      );

      final TestGesture gesture = await tester.startGesture(tube0Center);
      await gesture.moveBy(const Offset(0, -250));
      await tester.pump(const Duration(milliseconds: 50));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('MOVES LEFT: 18'), findsOneWidget);
    });

    testWidgets(
        '12. Tapping Hint button displays visual bounce and ghost preview ball',
        (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      await tester
          .tap(find.byKey(const ValueKey<String>('action_hint_button')));
      await tester.pump(const Duration(milliseconds: 100));

      // Visual hint should activate on source and target tubes directly on board
      final Finder sourceTubeFinder = find.byWidgetPredicate(
        (Widget w) => w is TestTubeWidget && w.isHintSource,
      );
      final Finder targetTubeFinder = find.byWidgetPredicate(
        (Widget w) => w is TestTubeWidget && w.isHintTarget,
      );

      expect(sourceTubeFinder, findsOneWidget);
      expect(targetTubeFinder, findsOneWidget);

      final TestTubeWidget targetTube =
          tester.widget<TestTubeWidget>(targetTubeFinder);
      expect(targetTube.previewBallColor, isNotNull);

      // Fast forward past 3 seconds auto-dismiss timer
      await tester.pump(const Duration(milliseconds: 3100));

      // After timeout, hint effects clear automatically
      expect(
        find.byWidgetPredicate(
            (Widget w) => w is TestTubeWidget && w.isHintSource),
        findsNothing,
      );
      expect(
        find.byWidgetPredicate(
            (Widget w) => w is TestTubeWidget && w.isHintTarget),
        findsNothing,
      );
    });

    testWidgets('13. Running out of moves triggers failure dialog', (
      WidgetTester tester,
    ) async {
      final _MockTwoLevelService mockService = _MockTwoLevelService();

      await tester.pumpWidget(
        createTestApp(
          overrides: <Override>[
            levelProviderServiceProvider.overrideWithValue(mockService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Move Red from Tube 2 to empty Tube 3 (consumes 1 move, does NOT complete puzzle)
      await tester.tap(find.byKey(const ValueKey<String>('tube_2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('tube_3')));
      await tester.pumpAndSettle();

      // Since maxMoves is 1, running out of moves displays LevelFailedDialog
      expect(find.byType(LevelFailedDialog), findsOneWidget);
      expect(find.text('OUT OF MOVES!'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('defeat_play_again_button')),
          findsOneWidget);
    });

    testWidgets(
        '14. Play Again from failure dialog restarts level and resets moves', (
      WidgetTester tester,
    ) async {
      final _MockTwoLevelService mockService = _MockTwoLevelService();

      await tester.pumpWidget(
        createTestApp(
          overrides: <Override>[
            levelProviderServiceProvider.overrideWithValue(mockService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Exhaust moves: Move Red from Tube 2 to Tube 3
      await tester.tap(find.byKey(const ValueKey<String>('tube_2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('tube_3')));
      await tester.pumpAndSettle();

      expect(find.byType(LevelFailedDialog), findsOneWidget);

      // Tap Play Again
      await tester
          .tap(find.byKey(const ValueKey<String>('defeat_play_again_button')));
      await tester.pumpAndSettle();

      // Dialog is dismissed and moves are restored
      expect(find.byType(LevelFailedDialog), findsNothing);
      expect(find.text('MOVES LEFT: 1'), findsOneWidget);
    });

    testWidgets(
        '15. Winning on the exact last move displays victory dialog, not defeat',
        (
      WidgetTester tester,
    ) async {
      final _MockTwoLevelService mockService = _MockTwoLevelService();

      await tester.pumpWidget(
        createTestApp(
          overrides: <Override>[
            levelProviderServiceProvider.overrideWithValue(mockService),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Move red from Tube 2 to Tube 0 (solves puzzle on move 1 of 1)
      await tester.tap(find.byKey(const ValueKey<String>('tube_2')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey<String>('tube_0')));
      await tester.pumpAndSettle();

      // Must show victory, NOT defeat
      expect(find.byType(LevelCompletedDialog), findsOneWidget);
      expect(find.byType(LevelFailedDialog), findsNothing);
      expect(find.text('EXPERIMENT COMPLETE!'), findsOneWidget);
    });
  });
}

class _MockTwoLevelService extends LevelProviderService {
  _MockTwoLevelService();

  static final LevelData _level1 = LevelData(
    levelId: 1,
    parMoves: 1,
    maxMoves: 1,
    initialTubes: <Tube>[
      Tube(balls: const <BallColor>[
        BallColor.crimsonRed,
        BallColor.crimsonRed,
        BallColor.crimsonRed,
      ]),
      Tube(balls: const <BallColor>[
        BallColor.cobaltBlue,
        BallColor.cobaltBlue,
        BallColor.cobaltBlue,
        BallColor.cobaltBlue,
      ]),
      Tube(balls: const <BallColor>[BallColor.crimsonRed]),
      Tube(balls: const <BallColor>[]),
    ],
  );

  static final LevelData _level2 = LevelData(
    levelId: 2,
    parMoves: 12,
    initialTubes: <Tube>[
      Tube(balls: const <BallColor>[
        BallColor.crimsonRed,
        BallColor.crimsonRed,
        BallColor.cobaltBlue,
        BallColor.cobaltBlue,
      ]),
      Tube(balls: const <BallColor>[
        BallColor.cobaltBlue,
        BallColor.cobaltBlue,
        BallColor.emeraldGreen,
        BallColor.emeraldGreen,
      ]),
      Tube(balls: const <BallColor>[
        BallColor.emeraldGreen,
        BallColor.emeraldGreen,
        BallColor.crimsonRed,
        BallColor.crimsonRed,
      ]),
      Tube(balls: const <BallColor>[]),
      Tube(balls: const <BallColor>[]),
    ],
  );

  @override
  List<LevelData> getLevels() => <LevelData>[_level1, _level2];

  @override
  LevelData? getLevel(int id) {
    if (id == 1) return _level1;
    if (id == 2) return _level2;
    return null;
  }

  @override
  bool hasLevel(int id) => id == 1 || id == 2;
}

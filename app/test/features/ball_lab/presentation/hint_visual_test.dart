import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/ball_color.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/puzzle_move.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/tube.dart';
import 'package:flutter_riverpod_template/features/ball_lab/presentation/screens/ball_lab_screen.dart';
import 'package:flutter_riverpod_template/features/ball_lab/presentation/widgets/ball_widget.dart';
import 'package:flutter_riverpod_template/features/ball_lab/presentation/widgets/test_tube_widget.dart';
import 'package:flutter_riverpod_template/features/ball_lab/presentation/widgets/tube_board.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:flutter_riverpod_template/app/l10n.dart';
import 'package:flutter_riverpod_template/l10n/app_localizations.dart';

void main() {
  group('TestTubeWidget - Visual Hint Elements', () {
    testWidgets(
        'Source tube elevates and bobs the top ball with Transform.translate', (
      WidgetTester tester,
    ) async {
      final Tube tube = Tube(
        balls: const <BallColor>[BallColor.crimsonRed, BallColor.cobaltBlue],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TestTubeWidget(
                tube: tube,
                index: 0,
                isSelected: false,
                isHintSource: true,
                hintBobOffset: 10,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Verify Transform.translate is applied with negative Y offset to bob top ball
      final Finder transformFinder = find.byWidgetPredicate(
        (Widget w) => w is Transform && w.transform.getTranslation().y == -10.0,
      );
      expect(transformFinder, findsOneWidget);

      // Verify the tube domain model remains untouched
      expect(tube.balls.length, 2);
    });

    testWidgets(
        'Target tube renders preview ghost ball for empty tube in bottom slot',
        (
      WidgetTester tester,
    ) async {
      final Tube emptyTube = Tube(
        balls: const <BallColor>[],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TestTubeWidget(
                tube: emptyTube,
                index: 1,
                isSelected: false,
                isHintTarget: true,
                previewBallColor: BallColor.amberYellow,
                previewBallOpacity: 0.60,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // BallWidget should exist with yellow color despite tube.balls being empty
      final Finder previewBallFinder = find.byWidgetPredicate(
        (Widget w) => w is BallWidget && w.color == BallColor.amberYellow,
      );
      expect(previewBallFinder, findsOneWidget);

      // Verify Opacity widget wraps the preview ball with given opacity
      final Finder opacityFinder = find.byWidgetPredicate(
        (Widget w) => w is Opacity && (w.opacity - 0.60).abs() < 0.001,
      );
      expect(opacityFinder, findsOneWidget);

      // Domain tube balls must remain empty (no state mutation)
      expect(emptyTube.balls.isEmpty, isTrue);
    });

    testWidgets(
        'Target tube renders preview ghost ball on top of existing balls', (
      WidgetTester tester,
    ) async {
      final Tube tubeWithBalls = Tube(
        balls: const <BallColor>[BallColor.cyanGlow, BallColor.cyanGlow],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TestTubeWidget(
                tube: tubeWithBalls,
                index: 2,
                isSelected: false,
                isHintTarget: true,
                previewBallColor: BallColor.cyanGlow,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // 2 real balls + 1 preview ball = 3 BallWidgets in the UI tree
      final Finder ballFinders = find.byType(BallWidget);
      expect(ballFinders, findsNWidgets(3));

      // Domain tube model still only has 2 balls
      expect(tubeWithBalls.balls.length, 2);
    });
  });

  group('TubeBoard - Hint Lifecycle & Gestures', () {
    testWidgets(
        'Board displays activeHint across tubes and dismisses on pointer down',
        (
      WidgetTester tester,
    ) async {
      final List<Tube> tubes = <Tube>[
        Tube(
          balls: const <BallColor>[
            BallColor.crimsonRed,
            BallColor.emeraldGreen
          ],
        ),
        Tube(
          balls: const <BallColor>[BallColor.emeraldGreen],
        ),
      ];

      bool hintDismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 500,
              child: TubeBoard(
                tubes: tubes,
                selectedTubeIndex: null,
                activeHint: const PuzzleMove(
                  fromIndex: 0,
                  toIndex: 1,
                  movedColor: BallColor.emeraldGreen,
                ),
                onHintDismissed: () {
                  hintDismissed = true;
                },
                onTubeTapped: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 50));

      // Tube 0 should be hint source, Tube 1 should be hint target
      expect(
        find.byWidgetPredicate(
            (Widget w) => w is TestTubeWidget && w.isHintSource),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
            (Widget w) => w is TestTubeWidget && w.isHintTarget),
        findsOneWidget,
      );

      // Touching the board should immediately trigger onHintDismissed
      final Offset boardCenter = tester.getCenter(find.byType(TubeBoard));
      await tester.tapAt(boardCenter);
      await tester.pump();

      expect(hintDismissed, isTrue);
    });
  });

  group('BallLabScreen - Visual Hint Full Flow', () {
    testWidgets(
        'Hint activates visual bounce and preview ball without verbose text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BallLabScreen(initialLevelId: 1),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap hint action button
      await tester
          .tap(find.byKey(const ValueKey<String>('action_hint_button')));
      await tester.pump(const Duration(milliseconds: 100));

      // Verify no verbose SnackBar message is shown
      expect(find.textContaining('Hint: Move'), findsNothing);

      // Visual source and target are active on board
      expect(
        find.byWidgetPredicate(
            (Widget w) => w is TestTubeWidget && w.isHintSource),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
            (Widget w) => w is TestTubeWidget && w.isHintTarget),
        findsOneWidget,
      );

      // Target tube shows the ghost preview ball
      final Finder targetFinder = find.byWidgetPredicate(
        (Widget w) => w is TestTubeWidget && w.isHintTarget,
      );
      final TestTubeWidget targetWidget =
          tester.widget<TestTubeWidget>(targetFinder);
      expect(targetWidget.previewBallColor, isNotNull);

      // After 3 seconds, hint automatically vanishes
      await tester.pump(const Duration(milliseconds: 3100));

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
  });
}

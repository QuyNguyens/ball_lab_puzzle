import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_riverpod_template/app/l10n.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/game_economy.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/services/economy_repository.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/services/rewarded_ad_service.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/services/time_service.dart';
import 'package:flutter_riverpod_template/features/ball_lab/presentation/controllers/economy_controller.dart';
import 'package:flutter_riverpod_template/features/ball_lab/presentation/screens/ball_lab_screen.dart';
import 'package:flutter_riverpod_template/features/ball_lab/presentation/widgets/test_tube_widget.dart';
import 'package:flutter_riverpod_template/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

class FakeRewardedAdService extends RewardedAdService {
  FakeRewardedAdService({
    this.initialStatus = RewardedAdStatus.ready,
    this.shouldEarnReward = true,
  }) : super(autoLoad: false);

  final RewardedAdStatus initialStatus;
  final bool shouldEarnReward;
  int showCallCount = 0;

  @override
  RewardedAdState build() {
    return RewardedAdState(status: initialStatus);
  }

  @override
  void showAd({
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdClosed,
    void Function(String reason)? onAdFailedToShow,
  }) {
    showCallCount++;
    if (!state.isReady) {
      onAdFailedToShow?.call('Ad is not ready');
      return;
    }
    if (shouldEarnReward) {
      onUserEarnedReward();
    }
    onAdClosed?.call();
  }
}

class MockTimeService implements TimeService {
  const MockTimeService();

  @override
  DateTime nowUtc() => DateTime.utc(2026, 10, 19, 5);

  @override
  DateTime nowVietnam() => DateTime.utc(2026, 10, 19, 12);

  @override
  String getVietnamDateString() => '2026-10-19';

  @override
  DateTime getNextMidnightVietnam() => DateTime.utc(2026, 10, 20);

  @override
  Duration timeUntilNextMidnight() => const Duration(hours: 12);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget createTestWidget({
    required FakeRewardedAdService adService,
    int initialHintCount = 2,
  }) {
    final InMemoryEconomyRepository inMemoryRepo = InMemoryEconomyRepository(
      GameEconomy(
        hintCount: initialHintCount,
        lastDailyRefreshDate: '2026-10-19',
        lastKnownTimestampMs:
            DateTime.utc(2026, 10, 19, 5).millisecondsSinceEpoch,
      ),
    );

    return ProviderScope(
      overrides: <Override>[
        rewardedAdServiceProvider.overrideWith(() => adService),
        economyRepositoryProvider.overrideWithValue(inMemoryRepo),
        timeServiceProvider.overrideWithValue(const MockTimeService()),
      ],
      child: const MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('en'),
        home: BallLabScreen(initialLevelId: 1),
      ),
    );
  }

  group('Rewarded Ad Hint Integration', () {
    testWidgets('1. Daily hint available uses free quota without ad prompt',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final FakeRewardedAdService fakeAdService = FakeRewardedAdService();

      await tester.pumpWidget(createTestWidget(
        adService: fakeAdService,
      ));
      await tester.pumpAndSettle();

      // Hint button displays normal quota: "Hint (2)"
      expect(find.text('Hint (2)'), findsOneWidget);

      // Tap Hint button
      await tester
          .tap(find.byKey(const ValueKey<String>('action_hint_button')));
      await tester.pump();

      // Ad dialog must NOT be displayed
      expect(find.text('Need a Hint?'), findsNothing);
      expect(fakeAdService.showCallCount, 0);

      // Visual hint activates on tubes
      expect(
        find.byWidgetPredicate((Widget w) =>
            w is TestTubeWidget && (w.isHintSource || w.isHintTarget)),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets(
        '2. Zero hints shows (+1 Ad) button and opens confirmation dialog',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final FakeRewardedAdService fakeAdService = FakeRewardedAdService();

      await tester.pumpWidget(createTestWidget(
        adService: fakeAdService,
        initialHintCount: 0,
      ));
      await tester.pumpAndSettle();

      // Hint button displays ad label: "Hint (+1 Ad)" and video icon
      expect(find.text('Hint (+1 Ad)'), findsOneWidget);
      expect(find.byIcon(Icons.ondemand_video_rounded), findsOneWidget);

      // Tap Hint button to request ad
      await tester
          .tap(find.byKey(const ValueKey<String>('action_hint_button')));
      await tester.pumpAndSettle();

      // Confirmation dialog appears with title and choices
      expect(find.text('Need a Hint?'), findsOneWidget);
      expect(find.text('Not Now'), findsOneWidget);
      expect(find.text('Watch Ad'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Not Now'));
      await tester.pumpAndSettle();

      // Dialog closed, no ad shown
      expect(find.text('Need a Hint?'), findsNothing);
      expect(fakeAdService.showCallCount, 0);
    });

    testWidgets(
        '3. Confirming Watch Ad triggers reward callback and grants hint',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final FakeRewardedAdService fakeAdService = FakeRewardedAdService();

      await tester.pumpWidget(createTestWidget(
        adService: fakeAdService,
        initialHintCount: 0,
      ));
      await tester.pumpAndSettle();

      // Tap Hint (+1 Ad)
      await tester
          .tap(find.byKey(const ValueKey<String>('action_hint_button')));
      await tester.pumpAndSettle();

      // Confirm Watch Ad
      await tester.tap(find.text('Watch Ad'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // ShowAd was called once
      expect(fakeAdService.showCallCount, 1);

      // Reward granted toast appears
      expect(find.text('Hint unlocked from ad!'), findsOneWidget);

      // Hint button now shows 1 available hint without requiring ad
      expect(find.text('Hint (1)'), findsOneWidget);

      // Tap Hint button to directly consume the earned hint
      await tester
          .tap(find.byKey(const ValueKey<String>('action_hint_button')));
      await tester.pump();

      // Visual hint activates on tubes
      expect(
        find.byWidgetPredicate((Widget w) =>
            w is TestTubeWidget && (w.isHintSource || w.isHintTarget)),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('4. Dismissing ad without reward does not grant hint',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final FakeRewardedAdService fakeAdService = FakeRewardedAdService(
        shouldEarnReward: false, // User closed early
      );

      await tester.pumpWidget(createTestWidget(
        adService: fakeAdService,
        initialHintCount: 0,
      ));
      await tester.pumpAndSettle();

      // Tap Hint (+1 Ad)
      await tester
          .tap(find.byKey(const ValueKey<String>('action_hint_button')));
      await tester.pumpAndSettle();

      // Tap Watch Ad
      await tester.tap(find.text('Watch Ad'));
      await tester.pumpAndSettle();

      // Ad was shown
      expect(fakeAdService.showCallCount, 1);

      // Reward toast was NOT shown
      expect(find.text('Hint unlocked from ad!'), findsNothing);

      // Hint visual bob is NOT active on tubes
      expect(
        find.byWidgetPredicate((Widget w) =>
            w is TestTubeWidget && (w.isHintSource || w.isHintTarget)),
        findsNothing,
      );
    });

    testWidgets('5. Tapping Hint when ad is loading does not open dialog',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final FakeRewardedAdService fakeAdService = FakeRewardedAdService(
        initialStatus: RewardedAdStatus.loading,
      );

      await tester.pumpWidget(createTestWidget(
        adService: fakeAdService,
        initialHintCount: 0,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Loading spinner is visible on Hint button
      expect(
        find.byKey(const ValueKey<String>('hint_ad_loading_indicator')),
        findsOneWidget,
      );

      // Tap Hint while loading
      await tester
          .tap(find.byKey(const ValueKey<String>('action_hint_button')));
      await tester.pump();

      // Confirmation dialog should NOT appear and ad not shown
      expect(find.text('Need a Hint?'), findsNothing);
      expect(fakeAdService.showCallCount, 0);
    });

    testWidgets(
        '6. Tapping Hint when ad is failed shows friendly toast and requests reload',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final FakeRewardedAdService fakeAdService = FakeRewardedAdService(
        initialStatus: RewardedAdStatus.failed,
      );

      await tester.pumpWidget(createTestWidget(
        adService: fakeAdService,
        initialHintCount: 0,
      ));
      await tester.pumpAndSettle();

      // Tap Hint (+1 Ad)
      await tester
          .tap(find.byKey(const ValueKey<String>('action_hint_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Confirmation dialog should NOT appear and ad not shown
      expect(find.text('Need a Hint?'), findsNothing);
      expect(fakeAdService.showCallCount, 0);

      // Friendly loading message is displayed
      expect(
        find.text('Ad is loading. Please try again in a moment.'),
        findsOneWidget,
      );
    });
  });
}

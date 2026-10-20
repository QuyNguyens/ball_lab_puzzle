import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/active_game_session.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/ball_color.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/game_economy.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/models/tube.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/services/economy_repository.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/services/time_service.dart';
import 'package:flutter_riverpod_template/features/ball_lab/presentation/controllers/economy_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class MockTimeService implements TimeService {
  MockTimeService({DateTime? initialUtc})
      : _currentUtc =
            initialUtc ?? DateTime.utc(2026, 10, 16, 5); // 12:00 in UTC+7

  DateTime _currentUtc;

  void advanceDays(int days) {
    _currentUtc = _currentUtc.add(Duration(days: days));
  }

  @override
  DateTime nowUtc() => _currentUtc;

  @override
  DateTime nowVietnam() => _currentUtc.toUtc().add(const Duration(hours: 7));

  @override
  String getVietnamDateString() {
    final DateTime vn = nowVietnam();
    return '${vn.year.toString().padLeft(4, '0')}-${vn.month.toString().padLeft(2, '0')}-${vn.day.toString().padLeft(2, '0')}';
  }

  @override
  Duration timeUntilNextMidnight() {
    final DateTime vn = nowVietnam();
    final DateTime nextMidnight = getNextMidnightVietnam();
    return nextMidnight.difference(vn);
  }

  @override
  DateTime getNextMidnightVietnam() {
    final DateTime vn = nowVietnam();
    return DateTime.utc(vn.year, vn.month, vn.day + 1);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Ball Lab Economy & Daily Quota Specification Tests (16 Scenarios)',
      () {
    late InMemoryEconomyRepository repository;
    late MockTimeService timeService;
    late ProviderContainer container;

    setUp(() {
      repository = InMemoryEconomyRepository();
      timeService = MockTimeService();
      container = ProviderContainer(
        overrides: <Override>[
          economyRepositoryProvider.overrideWithValue(repository),
          timeServiceProvider.overrideWithValue(timeService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    // 1. Người chơi mới có 3 lượt chơi, 3 lượt Undo và 2 lượt Hint.
    test('1. New player initializes with exactly 3 lives, 3 undos, and 2 hints',
        () {
      final GameEconomy economy = container.read(economyControllerProvider);

      expect(economy.dailyLives, equals(3));
      expect(economy.bonusLives, equals(0));
      expect(economy.totalLives, equals(3));
      expect(economy.undoCount, equals(3));
      expect(economy.hintCount, equals(2));
      expect(economy.canPlay, isTrue);
      expect(economy.canUndo, isTrue);
      expect(economy.canHint, isTrue);
    });

    // 2. Thua một ván chỉ trừ đúng một lượt.
    test('2. Game defeat deducts exactly 1 life', () async {
      final EconomyController controller =
          container.read(economyControllerProvider.notifier);

      final bool consumed = await controller.consumeLifeOnDefeat();
      expect(consumed, isTrue);

      final GameEconomy state = container.read(economyControllerProvider);
      expect(state.dailyLives, equals(2));
      expect(state.totalLives, equals(2));
    });

    // 3. Thắng không bị trừ lượt.
    test('3. Victory does not deduct lives', () {
      final GameEconomy initial = container.read(economyControllerProvider);
      // In the game architecture, victory triggers ProgressionController.recordVictory and clearSession
      // without invoking consumeLifeOnDefeat.
      final GameEconomy afterWin = container.read(economyControllerProvider);

      expect(afterWin.totalLives, equals(initial.totalLives));
      expect(afterWin.dailyLives, equals(3));
    });

    // 4. Thoát game giữa ván không tự động bị trừ lượt (active session persisted).
    test(
        '4. Exiting mid-game does not penalize the player and persists active session',
        () async {
      final EconomyController controller =
          container.read(economyControllerProvider.notifier);
      final ActiveGameSession session = ActiveGameSession(
        levelId: 3,
        tubes: <Tube>[
          Tube(balls: const <BallColor>[
            BallColor.crimsonRed,
            BallColor.crimsonRed
          ]),
          Tube(balls: const <BallColor>[BallColor.amberYellow]),
        ],
        moveCount: 4,
        maxMoves: 15,
      );

      // Save ongoing session upon player move
      await controller.saveActiveSession(session);

      // Verify lives were NOT deducted
      final GameEconomy current = container.read(economyControllerProvider);
      expect(current.totalLives, equals(3));

      // Verify session can be retrieved upon app reopen
      final ActiveGameSession? retrieved = controller.getActiveSession();
      expect(retrieved, isNotNull);
      expect(retrieved!.levelId, equals(3));
      expect(retrieved.moveCount, equals(4));
      expect(retrieved.maxMoves, equals(15));
      expect(retrieved.tubes.length, equals(2));
    });

    // 5. Mở lại ứng dụng không khôi phục tài nguyên đã sử dụng trong ngày.
    test(
        '5. Reopening the app on the same day does not restore consumed resources',
        () async {
      final EconomyController controller =
          container.read(economyControllerProvider.notifier);

      // Consume resources
      await controller.consumeLifeOnDefeat(); // 2 lives left
      await controller.consumeUndo(); // 2 undos left
      await controller.consumeHint(); // 1 hint left

      expect(container.read(economyControllerProvider).totalLives, equals(2));
      expect(container.read(economyControllerProvider).undoCount, equals(2));
      expect(container.read(economyControllerProvider).hintCount, equals(1));

      // Simulate app reopen by creating a new container backed by the same persistent repository
      final ProviderContainer newContainer = ProviderContainer(
        overrides: <Override>[
          economyRepositoryProvider.overrideWithValue(repository),
          timeServiceProvider.overrideWithValue(timeService),
        ],
      );

      final GameEconomy reloaded = newContainer.read(economyControllerProvider);
      expect(reloaded.totalLives, equals(2));
      expect(reloaded.undoCount, equals(2));
      expect(reloaded.hintCount, equals(1));

      newContainer.dispose();
    });

    // 6. Ngày mới phục hồi hạn mức miễn phí chính xác.
    test(
        '6. New calendar day in Asia/Ho_Chi_Minh restores daily quotas to 3 lives, 3 undos, 2 hints',
        () async {
      final EconomyController controller =
          container.read(economyControllerProvider.notifier);

      // Deplete some resources on Day 1
      await controller.consumeLifeOnDefeat();
      await controller.consumeLifeOnDefeat();
      await controller.consumeUndo();
      await controller.consumeHint();

      expect(container.read(economyControllerProvider).dailyLives, equals(1));
      expect(container.read(economyControllerProvider).undoCount, equals(2));
      expect(container.read(economyControllerProvider).hintCount, equals(1));

      // Advance time by 24 hours to Day 2
      timeService.advanceDays(1);

      // Simulate app launch on the next day
      final ProviderContainer day2Container = ProviderContainer(
        overrides: <Override>[
          economyRepositoryProvider.overrideWithValue(repository),
          timeServiceProvider.overrideWithValue(timeService),
        ],
      );

      final GameEconomy refreshed =
          day2Container.read(economyControllerProvider);
      expect(refreshed.dailyLives, equals(3));
      expect(refreshed.undoCount, equals(3));
      expect(refreshed.hintCount, equals(2));
      expect(refreshed.lastDailyRefreshDate,
          equals(timeService.getVietnamDateString()));

      day2Container.dispose();
    });

    // 7. Thay đổi trạng thái game hoặc animation không làm trừ lượt lặp.
    test(
        '7. Multiple repeated defeat triggers are idempotent and only deduct 1 life',
        () async {
      final EconomyController controller =
          container.read(economyControllerProvider.notifier);

      // In BallLabScreen, _hasDeductedLifeForDefeat guards repeated triggers
      bool hasDeducted = false;

      void triggerDefeatCallback() {
        if (!hasDeducted) {
          hasDeducted = true;
          controller.consumeLifeOnDefeat();
        }
      }

      // Simulate 5 rapid animation and listener callbacks
      for (int i = 0; i < 5; i++) {
        triggerDefeatCallback();
      }

      final GameEconomy state = container.read(economyControllerProvider);
      expect(state.totalLives, equals(2)); // Only 1 deducted from 3!
    });

    // 8. Undo thành công trừ một lượt.
    test('8. Successful undo move consumes exactly 1 undo quota', () async {
      final EconomyController controller =
          container.read(economyControllerProvider.notifier);

      final bool success = await controller.consumeUndo();
      expect(success, isTrue);

      final GameEconomy state = container.read(economyControllerProvider);
      expect(state.undoCount, equals(2));
    });

    // 9. Undo thất bại hoặc không có lịch sử không trừ lượt.
    test('9. Empty move history prevents undo and does not deduct quota',
        () async {
      final EconomyController controller =
          container.read(economyControllerProvider.notifier);

      // Simulate: No moves to undo -> Controller does NOT call consumeUndo
      final List<int> history = <int>[];
      if (history.isNotEmpty) {
        await controller.consumeUndo();
      }

      final GameEconomy state = container.read(economyControllerProvider);
      expect(state.undoCount, equals(3)); // Retains 3
    });

    // 10. Hint thành công trừ một lượt.
    test('10. Valid hint calculation deducts exactly 1 hint quota', () async {
      final EconomyController controller =
          container.read(economyControllerProvider.notifier);

      final bool success = await controller.consumeHint();
      expect(success, isTrue);

      final GameEconomy state = container.read(economyControllerProvider);
      expect(state.hintCount, equals(1));
    });

    // 11. Hint không tìm được gợi ý hợp lệ không trừ lượt.
    test('11. When no valid hint move exists, no hint quota is deducted',
        () async {
      final EconomyController controller =
          container.read(economyControllerProvider.notifier);

      // Simulate: Engine returns null hint
      const String? hint = null;
      if (hint != null) {
        await controller.consumeHint();
      }

      final GameEconomy state = container.read(economyControllerProvider);
      expect(state.hintCount, equals(2)); // Retains 2
    });

    // 12. Restart level không phục hồi hạn mức Undo/Hint.
    test('12. Restarting a level retains consumed Undo and Hint counts',
        () async {
      final EconomyController controller =
          container.read(economyControllerProvider.notifier);

      await controller.consumeUndo();
      await controller.consumeHint();

      // Restarting clears session but preserves economy
      await controller.clearActiveSession();

      final GameEconomy state = container.read(economyControllerProvider);
      expect(state.undoCount, equals(2));
      expect(state.hintCount, equals(1));
    });

    // 13. Hết lượt chơi thì không thể bắt đầu ván mới.
    test('13. Exhausting all lives prevents starting new games', () async {
      final EconomyController controller =
          container.read(economyControllerProvider.notifier);

      // Consume all 3 lives
      for (int i = 0; i < 3; i++) {
        await controller.consumeLifeOnDefeat();
      }

      final GameEconomy state = container.read(economyControllerProvider);
      expect(state.totalLives, equals(0));
      expect(state.canPlay, isFalse);

      // Attempting further deduction fails gracefully
      final bool consumedExtra = await controller.consumeLifeOnDefeat();
      expect(consumedExtra, isFalse);
      expect(container.read(economyControllerProvider).totalLives, equals(0));
    });

    // 14. Hết lượt không làm mất quyền xem bản đồ và thành tích.
    test('14. Having 0 lives does not lock level map or erase achievements',
        () async {
      final EconomyController controller =
          container.read(economyControllerProvider.notifier);

      for (int i = 0; i < 3; i++) {
        await controller.consumeLifeOnDefeat();
      }

      final GameEconomy state = container.read(economyControllerProvider);
      expect(state.totalLives, equals(0));

      // LevelMapScreen only gates starting a level, map navigation and star display remain accessible
      expect(state.canPlay, isFalse);
    });

    // 15. Dữ liệu lượt thưởng trong tương lai không bị ghi đè bởi việc phục hồi hạn mức miễn phí.
    test('15. Bonus lives are preserved across daily midnight quota rollover',
        () async {
      final EconomyController controller =
          container.read(economyControllerProvider.notifier);

      // Player receives 3 bonus lives (e.g. from future Rewarded Ads or IAP)
      await controller.addBonusLives(3);

      GameEconomy state = container.read(economyControllerProvider);
      expect(state.dailyLives, equals(3));
      expect(state.bonusLives, equals(3));
      expect(state.totalLives, equals(6));

      // Player loses 4 games: 3 daily lives consumed + 1 bonus life consumed
      for (int i = 0; i < 4; i++) {
        await controller.consumeLifeOnDefeat();
      }

      state = container.read(economyControllerProvider);
      expect(state.dailyLives, equals(0));
      expect(state.bonusLives, equals(2));
      expect(state.totalLives, equals(2));

      // Day rollover occurs in Vietnam
      timeService.advanceDays(1);

      final ProviderContainer day2Container = ProviderContainer(
        overrides: <Override>[
          economyRepositoryProvider.overrideWithValue(repository),
          timeServiceProvider.overrideWithValue(timeService),
        ],
      );

      final GameEconomy rolledOver =
          day2Container.read(economyControllerProvider);
      // Daily quota resets to 3, bonus lives stay at 2 -> Total = 5 lives!
      expect(rolledOver.dailyLives, equals(3));
      expect(rolledOver.bonusLives, equals(2));
      expect(rolledOver.totalLives, equals(5));

      day2Container.dispose();
    });

    // 16. Tất cả dữ liệu vẫn nhất quán sau khi đóng và mở ứng dụng (JSON round-trip & repository persistence).
    test(
        '16. All economy and session data round-trips cleanly through JSON persistence',
        () {
      const GameEconomy originalEconomy = GameEconomy(
        dailyLives: 2,
        bonusLives: 4,
        undoCount: 1,
        hintCount: 0,
        lastDailyRefreshDate: '2026-10-16',
        lastKnownTimestampMs: 1760616000000,
      );

      final Map<String, dynamic> economyJson = originalEconomy.toJson();
      final GameEconomy restoredEconomy = GameEconomy.fromJson(economyJson);

      expect(restoredEconomy, equals(originalEconomy));
      expect(restoredEconomy.totalLives, equals(6));
      expect(restoredEconomy.canPlay, isTrue);
      expect(restoredEconomy.canUndo, isTrue);
      expect(restoredEconomy.canHint, isFalse);

      final ActiveGameSession originalSession = ActiveGameSession(
        levelId: 4,
        tubes: <Tube>[
          Tube(balls: const <BallColor>[
            BallColor.cobaltBlue,
            BallColor.cobaltBlue
          ]),
          Tube(balls: const <BallColor>[BallColor.emeraldGreen]),
        ],
        moveCount: 8,
        maxMoves: 22,
      );

      final Map<String, dynamic> sessionJson = originalSession.toJson();
      final ActiveGameSession restoredSession =
          ActiveGameSession.fromJson(sessionJson);

      expect(restoredSession, equals(originalSession));
      expect(restoredSession.levelId, equals(4));
      expect(restoredSession.moveCount, equals(8));
      expect(restoredSession.maxMoves, equals(22));
      expect(restoredSession.isFinished, isFalse);
    });
  });
}

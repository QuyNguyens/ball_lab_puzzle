import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_riverpod_template/features/ball_lab/domain/services/rewarded_ad_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> dummyAdLoader({
    required String adUnitId,
    required AdRequest request,
    required RewardedAdLoadCallback rewardedAdLoadCallback,
  }) async {}

  group('RewardedAdState', () {
    test('default state is initial and not ready/loading/showing', () {
      const RewardedAdState state = RewardedAdState();
      expect(state.status, RewardedAdStatus.initial);
      expect(state.isReady, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.isShowing, isFalse);
      expect(state.isFailed, isFalse);
      expect(state.retryCount, 0);
      expect(state.errorMessage, isNull);
    });

    test('copyWith updates fields correctly', () {
      const RewardedAdState state = RewardedAdState();
      final RewardedAdState readyState = state.copyWith(
        status: RewardedAdStatus.ready,
        retryCount: 1,
      );
      expect(readyState.status, RewardedAdStatus.ready);
      expect(readyState.isReady, isTrue);
      expect(readyState.retryCount, 1);

      final RewardedAdState failedState = readyState.copyWith(
        status: RewardedAdStatus.failed,
        errorMessage: 'Network timeout',
      );
      expect(failedState.status, RewardedAdStatus.failed);
      expect(failedState.isFailed, isTrue);
      expect(failedState.errorMessage, 'Network timeout');
    });
  });

  group('RewardedAdService Lifecycle & Safeguards', () {
    test('safely handles ad not ready without crashing or invoking reward', () {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          rewardedAdServiceProvider.overrideWith(
            () => RewardedAdService(
              autoLoad: false,
              adLoader: dummyAdLoader,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final RewardedAdService service =
          container.read(rewardedAdServiceProvider.notifier);

      bool rewardEarned = false;
      bool adClosed = false;
      String? failureReason;

      service.showAd(
        onUserEarnedReward: () {
          rewardEarned = true;
        },
        onAdClosed: () {
          adClosed = true;
        },
        onAdFailedToShow: (String reason) {
          failureReason = reason;
        },
      );

      expect(rewardEarned, isFalse);
      expect(failureReason, isNotNull);
      expect(adClosed, isFalse);
    });

    test('does not perform concurrent displays when showing', () {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          rewardedAdServiceProvider.overrideWith(
            () => RewardedAdService(
              autoLoad: false,
              adLoader: dummyAdLoader,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final RewardedAdService service =
          container.read(rewardedAdServiceProvider.notifier);

      int failCount = 0;
      service
        ..testState = container.read(rewardedAdServiceProvider).copyWith(
              status: RewardedAdStatus.showing,
            )
        ..showAd(
          onUserEarnedReward: () {},
          onAdFailedToShow: (_) {
            failCount++;
          },
        );

      // Concurrent show is ignored directly
      expect(failCount, 0);
      expect(
        container.read(rewardedAdServiceProvider).isShowing,
        isTrue,
      );
    });

    test('dispose cleans up resources and prevents further updates', () {
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          rewardedAdServiceProvider.overrideWith(
            () => RewardedAdService(
              autoLoad: false,
              adLoader: dummyAdLoader,
            ),
          ),
        ],
      );

      final RewardedAdService service =
          container.read(rewardedAdServiceProvider.notifier);
      container.dispose();

      // Calling load or show after container dispose should be safe and no-op without exception
      service
        ..loadAd()
        ..showAd(onUserEarnedReward: () {});
    });
  });
}

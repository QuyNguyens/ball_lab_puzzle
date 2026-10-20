import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'admob_config.dart';

/// Status of the rewarded ad lifecycle.
enum RewardedAdStatus {
  initial,
  loading,
  ready,
  showing,
  failed,
}

/// State representing the current status of rewarded ads.
class RewardedAdState {
  const RewardedAdState({
    this.status = RewardedAdStatus.initial,
    this.errorMessage,
    this.retryCount = 0,
  });

  final RewardedAdStatus status;
  final String? errorMessage;
  final int retryCount;

  bool get isReady => status == RewardedAdStatus.ready;
  bool get isLoading => status == RewardedAdStatus.loading;
  bool get isShowing => status == RewardedAdStatus.showing;
  bool get isFailed => status == RewardedAdStatus.failed;

  RewardedAdState copyWith({
    RewardedAdStatus? status,
    String? errorMessage,
    bool clearError = false,
    int? retryCount,
  }) {
    return RewardedAdState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

/// Function signature for loading a RewardedAd.
typedef RewardedAdLoader = Future<void> Function({
  required String adUnitId,
  required AdRequest request,
  required RewardedAdLoadCallback rewardedAdLoadCallback,
});

/// Service managing the lifecycle, preloading, bounded retries, and display
/// of Google AdMob Rewarded Ads.
class RewardedAdService extends Notifier<RewardedAdState> {
  RewardedAdService({
    this.maxRetries = 3,
    this.autoLoad = true,
    RewardedAdLoader? adLoader,
  }) : _adLoader = adLoader ?? _defaultAdLoader;

  final int maxRetries;
  final bool autoLoad;
  final RewardedAdLoader _adLoader;
  RewardedAd? _rewardedAd;
  Timer? _retryTimer;
  bool _isDisposed = false;

  static Future<void> _defaultAdLoader({
    required String adUnitId,
    required AdRequest request,
    required RewardedAdLoadCallback rewardedAdLoadCallback,
  }) async {
    await RewardedAd.load(
      adUnitId: adUnitId,
      request: request,
      rewardedAdLoadCallback: rewardedAdLoadCallback,
    );
  }

  @override
  RewardedAdState build() {
    ref.onDispose(() {
      _isDisposed = true;
      _retryTimer?.cancel();
      _disposeCurrentAd();
    });

    if (autoLoad && isSupportedPlatform) {
      Future<void>.microtask(loadAd);
    }

    return const RewardedAdState();
  }

  /// Whether the current platform natively supports Google Mobile Ads SDK.
  static bool get isSupportedPlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  /// For testing: manually set or read state.
  @visibleForTesting
  RewardedAdState get testState => state;

  @visibleForTesting
  set testState(RewardedAdState newState) {
    state = newState;
  }

  /// Initiates asynchronous loading of a rewarded ad.
  void loadAd() {
    if (_isDisposed) return;
    if (!isSupportedPlatform) {
      state = state.copyWith(
        status: RewardedAdStatus.initial,
        errorMessage: 'Platform not supported for mobile ads',
      );
      return;
    }

    if (state.isLoading || state.isReady || state.isShowing) {
      return;
    }

    state = state.copyWith(
      status: RewardedAdStatus.loading,
      clearError: true,
    );

    try {
      _adLoader(
        adUnitId: AdMobConfig.rewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (RewardedAd ad) {
            if (_isDisposed) {
              ad.dispose();
              return;
            }
            _disposeCurrentAd();
            _rewardedAd = ad;
            state = state.copyWith(
              status: RewardedAdStatus.ready,
              retryCount: 0,
              clearError: true,
            );
          },
          onAdFailedToLoad: (LoadAdError error) {
            if (_isDisposed) return;
            _disposeCurrentAd();
            debugPrint(
                'RewardedAd failed to load: ${error.code} - ${error.message}');

            final int nextRetry = state.retryCount + 1;
            state = state.copyWith(
              status: RewardedAdStatus.failed,
              errorMessage: error.message,
              retryCount: nextRetry,
            );

            // Bounded retry with exponential backoff (2s, 4s, 8s) up to maxRetries
            if (nextRetry <= maxRetries) {
              final int delaySeconds = 1 << nextRetry;
              _retryTimer?.cancel();
              _retryTimer = Timer(Duration(seconds: delaySeconds), () {
                if (!_isDisposed && state.status == RewardedAdStatus.failed) {
                  loadAd();
                }
              });
            }
          },
        ),
      );
    } catch (e) {
      debugPrint('RewardedAd.load exception caught: $e');
      if (_isDisposed) return;
      state = state.copyWith(
        status: RewardedAdStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }

  /// Displays the loaded rewarded ad.
  ///
  /// [onUserEarnedReward]: Called strictly when the user finishes viewing and earns the reward.
  /// [onAdClosed]: Called when the ad is dismissed or failed to show.
  /// [onAdFailedToShow]: Called if the ad fails to display or is not ready.
  void showAd({
    required VoidCallback onUserEarnedReward,
    VoidCallback? onAdClosed,
    void Function(String reason)? onAdFailedToShow,
  }) {
    if (_isDisposed) return;

    if (!isSupportedPlatform) {
      onAdFailedToShow?.call('Mobile ads are not supported on this platform');
      return;
    }

    if (state.isShowing) {
      // Prevent multiple concurrent show calls
      return;
    }

    final RewardedAd? ad = _rewardedAd;
    if (ad == null || !state.isReady) {
      onAdFailedToShow?.call('Ad is not ready yet');
      loadAd(); // Ensure we try loading one
      return;
    }

    state = state.copyWith(status: RewardedAdStatus.showing);

    ad
      ..fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
        onAdShowedFullScreenContent: (RewardedAd ad) {
          debugPrint('Rewarded ad showed full screen content.');
        },
        onAdDismissedFullScreenContent: (RewardedAd ad) {
          debugPrint('Rewarded ad dismissed full screen content.');
          _disposeCurrentAd();
          if (!_isDisposed) {
            state = state.copyWith(status: RewardedAdStatus.initial);
            onAdClosed?.call();
            // Preload next ad automatically
            loadAd();
          }
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          debugPrint('Rewarded ad failed to show: ${error.message}');
          _disposeCurrentAd();
          if (!_isDisposed) {
            state = state.copyWith(
              status: RewardedAdStatus.failed,
              errorMessage: error.message,
            );
            onAdFailedToShow?.call(error.message);
            onAdClosed?.call();
            // Preload next ad automatically
            loadAd();
          }
        },
      )
      ..show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          if (!_isDisposed) {
            onUserEarnedReward();
          }
        },
      );
  }

  void _disposeCurrentAd() {
    try {
      _rewardedAd?.dispose();
    } catch (e) {
      debugPrint('Error disposing RewardedAd: $e');
    }
    _rewardedAd = null;
  }

  /// Explicitly cleanup resources on destruction.
  void dispose() {
    _isDisposed = true;
    _retryTimer?.cancel();
    _disposeCurrentAd();
  }
}

/// Riverpod Notifier provider for the RewardedAdService.
final NotifierProvider<RewardedAdService, RewardedAdState>
    rewardedAdServiceProvider =
    NotifierProvider<RewardedAdService, RewardedAdState>(
  RewardedAdService.new,
  name: 'rewardedAdServiceProvider',
);

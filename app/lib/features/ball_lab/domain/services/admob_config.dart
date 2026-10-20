// ignore_for_file: do_not_use_environment

/// Centralized configuration for Google AdMob in Ball Lab Puzzle.
///
/// Keeps AdMob App IDs and Ad Unit IDs in one place, defaulting to official
/// Google sample test IDs in development to ensure compliance and avoid
/// policy violations or accidental clicks on live ads.
class AdMobConfig {
  AdMobConfig._();

  /// Official Google-provided sample Android App ID for testing.
  static const String testAndroidAppId =
      'ca-app-pub-3940256099942544~3347511713';

  /// Official Google-provided sample Android Rewarded Ad Unit ID for testing.
  static const String testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  /// Production placeholders (to be set when ready for release).
  static const String prodAndroidAppId = 'YOUR_ADMOB_ANDROID_APP_ID';
  static const String prodRewardedAdUnitId = 'YOUR_REWARDED_AD_UNIT_ID';

  /// Flag set at compile-time via `--dart-define=ADMOB_ENV=production` or `--dart-define=IS_PROD_ADS=true`.
  static const bool isProductionEnvironment = bool.fromEnvironment(
    'ADMOB_ENV_PRODUCTION',
  );

  /// Safe check: only use production ads when explicitly enabled AND
  /// when valid non-placeholder production IDs are provided.
  static bool get useProductionAds {
    if (!isProductionEnvironment) return false;
    if (prodRewardedAdUnitId == 'YOUR_REWARDED_AD_UNIT_ID' ||
        prodRewardedAdUnitId.trim().isEmpty) {
      return false;
    }
    return true;
  }

  /// Active Android App ID.
  static String get androidAppId {
    const String envAppId = String.fromEnvironment('ADMOB_ANDROID_APP_ID');
    if (envAppId.isNotEmpty && envAppId != 'YOUR_ADMOB_ANDROID_APP_ID') {
      return envAppId;
    }
    if (useProductionAds) {
      return prodAndroidAppId;
    }
    return testAndroidAppId;
  }

  /// Active Rewarded Ad Unit ID for Android.
  static String get rewardedAdUnitId {
    const String envUnitId =
        String.fromEnvironment('ADMOB_REWARDED_AD_UNIT_ID');
    if (envUnitId.isNotEmpty && envUnitId != 'YOUR_REWARDED_AD_UNIT_ID') {
      return envUnitId;
    }
    if (useProductionAds) {
      return prodRewardedAdUnitId;
    }
    return testRewardedAdUnitId;
  }
}

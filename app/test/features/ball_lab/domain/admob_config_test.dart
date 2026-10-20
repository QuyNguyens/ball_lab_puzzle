import 'package:flutter_riverpod_template/features/ball_lab/domain/services/admob_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdMobConfig', () {
    test('defaults to official Google test Android App ID in development', () {
      expect(
        AdMobConfig.testAndroidAppId,
        'ca-app-pub-3940256099942544~3347511713',
      );
      expect(AdMobConfig.androidAppId, AdMobConfig.testAndroidAppId);
    });

    test('defaults to official Google test Rewarded Ad Unit ID in development',
        () {
      expect(
        AdMobConfig.testRewardedAdUnitId,
        'ca-app-pub-3940256099942544/5224354917',
      );
      expect(AdMobConfig.rewardedAdUnitId, AdMobConfig.testRewardedAdUnitId);
    });

    test('production placeholders are defined as expected without hardcoding',
        () {
      expect(AdMobConfig.prodAndroidAppId, 'YOUR_ADMOB_ANDROID_APP_ID');
      expect(AdMobConfig.prodRewardedAdUnitId, 'YOUR_REWARDED_AD_UNIT_ID');
    });

    test('safely disables production ads if placeholders are unchanged', () {
      // Even if someone toggled production flag, unmodified placeholder IDs must never be used
      expect(AdMobConfig.useProductionAds, isFalse);
    });
  });
}

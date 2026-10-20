import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:material_ui/material_ui.dart';

import '../hive/hive.dart';

bool _licensesRegistered = false;
bool _mobileAdsInitialized = false;

/// Registers open source licenses for bundled assets (Roboto OFL license).
void _registerLicenses() {
  if (_licensesRegistered) return;
  _licensesRegistered = true;
  LicenseRegistry.addLicense(() async* {
    final String ofl = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(<String>['Roboto'], ofl);
  });
}

/// Initializes Google Mobile Ads SDK once if running on a supported platform.
Future<void> initMobileAds() async {
  if (_mobileAdsInitialized) return;
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    try {
      await MobileAds.instance.initialize();
      _mobileAdsInitialized = true;
    } catch (e) {
      debugPrint('MobileAds initialization error: $e');
    }
  }
}

/// App-owned startup work that runs before the app launches.
Future<void> setUpApp() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerLicenses();
  await initHive();
  await initMobileAds();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await FlutterDisplayMode.setHighRefreshRate();
  }
}

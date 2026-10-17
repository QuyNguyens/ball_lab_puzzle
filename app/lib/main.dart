import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/l10n.dart';
import 'app/setup.dart';
import 'features/ball_lab/presentation/screens/level_map_screen.dart';
import 'l10n/app_localizations.dart';

/// Single default entry point for Ball Lab Puzzle.
/// Easily runnable with a standard `flutter run`.
Future<void> main() async {
  await setUpApp();
  runApp(
    const ProviderScope(
      child: BallLabApp(),
    ),
  );
}

/// Root widget hosting Ball Lab Puzzle casual game.
class BallLabApp extends StatelessWidget {
  const BallLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ball Lab Puzzle',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          brightness: Brightness.dark,
          surface: const Color(0xFF0F172A),
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback:
          (Locale? locale, Iterable<Locale> supportedLocales) {
        if (locale != null && locale.languageCode == 'vi') {
          return const Locale('vi');
        }
        return const Locale('en');
      },
      home: const LevelMapScreen(),
    );
  }
}

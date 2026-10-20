import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod_template/app/l10n.dart';
import 'package:flutter_riverpod_template/features/ball_lab/presentation/widgets/out_of_lives_dialog.dart';
import 'package:flutter_riverpod_template/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('OutOfLivesDialog Widget Tests', () {
    testWidgets(
        'Displays out of lives copy, countdown timer, options and triggers back callback',
        (WidgetTester tester) async {
      bool backTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: Scaffold(
              body: OutOfLivesDialog(
                timeUntilRefill:
                    const Duration(hours: 3, minutes: 25, seconds: 40),
                onBackToMap: () {
                  backTapped = true;
                },
              ),
            ),
          ),
        ),
      );

      // Verify header and titles
      expect(find.byKey(const ValueKey<String>('out_of_lives_title')),
          findsOneWidget);
      expect(find.text('OUT OF LIVES'), findsOneWidget);

      // Verify formatted countdown time
      expect(find.byKey(const ValueKey<String>('lives_refill_countdown')),
          findsOneWidget);
      expect(find.text('03:25:40'), findsOneWidget);

      // Verify active Rewarded Ad (+1 Life) with daily quota badge (0/3)
      expect(find.text('0/3'), findsOneWidget);
      expect(find.text('Watch Lab Video (+1 Life)'), findsOneWidget);

      // Verify IAP coming soon badge
      expect(find.text('COMING SOON'), findsOneWidget);
      expect(find.text('Instant Lab Energy Refill'), findsOneWidget);

      // Verify primary action button
      expect(find.text('BACK TO MAP'), findsOneWidget);
      await tester
          .tap(find.byKey(const ValueKey<String>('out_of_lives_back_button')));
      await tester.pump();

      expect(backTapped, isTrue);
    });
  });
}

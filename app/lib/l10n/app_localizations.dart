import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Ball Lab Puzzle'**
  String get appTitle;

  /// No description provided for @backTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backTooltip;

  /// No description provided for @levelTitle.
  ///
  /// In en, this message translates to:
  /// **'Level {levelId}'**
  String levelTitle(int levelId);

  /// No description provided for @levelBadge.
  ///
  /// In en, this message translates to:
  /// **'LEVEL {levelId}'**
  String levelBadge(int levelId);

  /// No description provided for @movesLeftCount.
  ///
  /// In en, this message translates to:
  /// **'MOVES LEFT: {count}'**
  String movesLeftCount(int count);

  /// No description provided for @actionRestart.
  ///
  /// In en, this message translates to:
  /// **'Restart'**
  String get actionRestart;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo ({count})'**
  String actionUndo(int count);

  /// No description provided for @actionUndoSimple.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndoSimple;

  /// No description provided for @actionHint.
  ///
  /// In en, this message translates to:
  /// **'Hint ({count})'**
  String actionHint(int count);

  /// No description provided for @outOfUndosToast.
  ///
  /// In en, this message translates to:
  /// **'You have used all free Undo moves for today!'**
  String get outOfUndosToast;

  /// No description provided for @outOfHintsToast.
  ///
  /// In en, this message translates to:
  /// **'You have used all free Hints for today!'**
  String get outOfHintsToast;

  /// No description provided for @gameInstruction.
  ///
  /// In en, this message translates to:
  /// **'Moves: {current} / {max} • Sort all balls by color'**
  String gameInstruction(int current, int max);

  /// No description provided for @tubesSolvedProgress.
  ///
  /// In en, this message translates to:
  /// **'{completed} / {total} Solved'**
  String tubesSolvedProgress(int completed, int total);

  /// No description provided for @hintAlreadyCompleted.
  ///
  /// In en, this message translates to:
  /// **'Level already completed!'**
  String get hintAlreadyCompleted;

  /// No description provided for @hintNoMoveFound.
  ///
  /// In en, this message translates to:
  /// **'No helpful moves found. Try Undo or Restart!'**
  String get hintNoMoveFound;

  /// No description provided for @victoryTitle.
  ///
  /// In en, this message translates to:
  /// **'EXPERIMENT COMPLETE!'**
  String get victoryTitle;

  /// No description provided for @milestoneReached.
  ///
  /// In en, this message translates to:
  /// **'MILESTONE REACHED!'**
  String get milestoneReached;

  /// No description provided for @levelMastered.
  ///
  /// In en, this message translates to:
  /// **'Level {levelId} Mastered'**
  String levelMastered(int levelId);

  /// No description provided for @victoryPerfect.
  ///
  /// In en, this message translates to:
  /// **'PERFECT SORTING!'**
  String get victoryPerfect;

  /// No description provided for @victoryExcellent.
  ///
  /// In en, this message translates to:
  /// **'EXCELLENT LAB WORK!'**
  String get victoryExcellent;

  /// No description provided for @victoryGood.
  ///
  /// In en, this message translates to:
  /// **'EXPERIMENT SOLVED!'**
  String get victoryGood;

  /// No description provided for @movesTakenLabel.
  ///
  /// In en, this message translates to:
  /// **'MOVES TAKEN'**
  String get movesTakenLabel;

  /// No description provided for @parMovesLabel.
  ///
  /// In en, this message translates to:
  /// **'PAR MOVES'**
  String get parMovesLabel;

  /// No description provided for @starThresholds.
  ///
  /// In en, this message translates to:
  /// **'3★: ≤{threeStar} moves  •  2★: ≤{twoStar} moves'**
  String starThresholds(int threeStar, int twoStar);

  /// No description provided for @newBestRecord.
  ///
  /// In en, this message translates to:
  /// **'✨ NEW BEST RECORD!'**
  String get newBestRecord;

  /// No description provided for @buttonPlayAgain.
  ///
  /// In en, this message translates to:
  /// **'Play Again'**
  String get buttonPlayAgain;

  /// No description provided for @buttonNextLevel.
  ///
  /// In en, this message translates to:
  /// **'Next Level'**
  String get buttonNextLevel;

  /// No description provided for @buttonReturnToMap.
  ///
  /// In en, this message translates to:
  /// **'Return to Map'**
  String get buttonReturnToMap;

  /// No description provided for @defeatTitle.
  ///
  /// In en, this message translates to:
  /// **'OUT OF MOVES!'**
  String get defeatTitle;

  /// No description provided for @levelIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Level {levelId} Incomplete'**
  String levelIncomplete(int levelId);

  /// No description provided for @defeatMessage.
  ///
  /// In en, this message translates to:
  /// **'You have used all {maxMoves} allowed moves for this experiment. Re-calibrate your strategy and try again!'**
  String defeatMessage(int maxMoves);

  /// No description provided for @movesUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'MOVES USED'**
  String get movesUsedLabel;

  /// No description provided for @maxLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'MAX LIMIT'**
  String get maxLimitLabel;

  /// No description provided for @outOfLivesTitle.
  ///
  /// In en, this message translates to:
  /// **'OUT OF LIVES'**
  String get outOfLivesTitle;

  /// No description provided for @outOfLivesMessage.
  ///
  /// In en, this message translates to:
  /// **'You have used all 5 free daily experiment attempts.\nYour lives replenish every midnight (00:00 VN).'**
  String get outOfLivesMessage;

  /// No description provided for @nextFreeRefillIn.
  ///
  /// In en, this message translates to:
  /// **'NEXT FREE REFILL IN'**
  String get nextFreeRefillIn;

  /// No description provided for @watchVideoOption.
  ///
  /// In en, this message translates to:
  /// **'Watch Lab Video (+1 Life)'**
  String get watchVideoOption;

  /// No description provided for @comingSoonTag.
  ///
  /// In en, this message translates to:
  /// **'COMING SOON'**
  String get comingSoonTag;

  /// No description provided for @instantRefillOption.
  ///
  /// In en, this message translates to:
  /// **'Instant Lab Energy Refill'**
  String get instantRefillOption;

  /// No description provided for @buttonBackToMap.
  ///
  /// In en, this message translates to:
  /// **'BACK TO MAP'**
  String get buttonBackToMap;

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'BALL LAB JOURNEY'**
  String get mapTitle;

  /// No description provided for @mapSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Select a puzzle experiment'**
  String get mapSubtitle;

  /// No description provided for @previousChapterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Previous chapter'**
  String get previousChapterTooltip;

  /// No description provided for @nextChapterTooltip.
  ///
  /// In en, this message translates to:
  /// **'Next chapter'**
  String get nextChapterTooltip;

  /// No description provided for @chapterIndicator.
  ///
  /// In en, this message translates to:
  /// **'CHAPTER {current} / {total}'**
  String chapterIndicator(int current, int total);

  /// No description provided for @chapterProgress.
  ///
  /// In en, this message translates to:
  /// **'Level {start} – {end}  •  ⭐ {stars}/{maxStars}'**
  String chapterProgress(int start, int end, int stars, int maxStars);

  /// No description provided for @activeLevelShort.
  ///
  /// In en, this message translates to:
  /// **'Lv {levelId}'**
  String activeLevelShort(int levelId);

  /// No description provided for @selectChapterTitle.
  ///
  /// In en, this message translates to:
  /// **'SELECT CHAPTER'**
  String get selectChapterTitle;

  /// No description provided for @chapterPickerSummary.
  ///
  /// In en, this message translates to:
  /// **'{chapters} Chapters  •  {levels} Levels'**
  String chapterPickerSummary(int chapters, int levels);

  /// No description provided for @chapterItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Chapter {number}'**
  String chapterItemTitle(int number);

  /// No description provided for @nodePlay.
  ///
  /// In en, this message translates to:
  /// **'PLAY'**
  String get nodePlay;

  /// No description provided for @bossBadge.
  ///
  /// In en, this message translates to:
  /// **'BOSS'**
  String get bossBadge;

  /// No description provided for @milestoneLevelDesc.
  ///
  /// In en, this message translates to:
  /// **'High-difficulty Laboratory Milestone challenge'**
  String get milestoneLevelDesc;

  /// No description provided for @normalLevelDesc.
  ///
  /// In en, this message translates to:
  /// **'Color segregation experiment'**
  String get normalLevelDesc;

  /// No description provided for @statColors.
  ///
  /// In en, this message translates to:
  /// **'COLORS'**
  String get statColors;

  /// No description provided for @statTubes.
  ///
  /// In en, this message translates to:
  /// **'TUBES'**
  String get statTubes;

  /// No description provided for @statMaxMoves.
  ///
  /// In en, this message translates to:
  /// **'MAX MOVES'**
  String get statMaxMoves;

  /// No description provided for @statBestRun.
  ///
  /// In en, this message translates to:
  /// **'BEST RUN'**
  String get statBestRun;

  /// No description provided for @statNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get statNone;

  /// No description provided for @movesUnit.
  ///
  /// In en, this message translates to:
  /// **'{moves} moves'**
  String movesUnit(int moves);

  /// No description provided for @starCondition.
  ///
  /// In en, this message translates to:
  /// **'≤ {moves} moves'**
  String starCondition(int moves);

  /// No description provided for @buttonStartExperiment.
  ///
  /// In en, this message translates to:
  /// **'START EXPERIMENT'**
  String get buttonStartExperiment;

  /// No description provided for @levelLockedToast.
  ///
  /// In en, this message translates to:
  /// **'Complete Level {levelId} to unlock this experiment!'**
  String levelLockedToast(int levelId);

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an account'**
  String get authCreateAccount;

  /// No description provided for @authCredentialsRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email and password.'**
  String get authCredentialsRequired;

  /// No description provided for @authEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEmailHint;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get authEmailInvalid;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter an email address'**
  String get authEmailRequired;

  /// No description provided for @authLoginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLoginButton;

  /// No description provided for @authLoginFailed.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get authLoginFailed;

  /// No description provided for @authLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You can login with your email and password'**
  String get authLoginSubtitle;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get authLoginTitle;

  /// No description provided for @authPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get authPasswordHint;

  /// No description provided for @authPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordLabel;

  /// No description provided for @authRegisterButton.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get authRegisterButton;

  /// No description provided for @authRegisterCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get authRegisterCancel;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'New Profile'**
  String get authRegisterTitle;

  /// No description provided for @authUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your username'**
  String get authUsernameHint;

  /// No description provided for @authUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authUsernameLabel;

  /// No description provided for @authWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the app'**
  String get authWelcome;

  /// Body of the permission demo screens.
  ///
  /// In en, this message translates to:
  /// **'You can see this page because your permissions include the \"{area}\" area.'**
  String demoAreaBody(String area);

  /// No description provided for @demoComponentRulesTitle.
  ///
  /// In en, this message translates to:
  /// **'Component rules'**
  String get demoComponentRulesTitle;

  /// No description provided for @demoDeleteAccountHidden.
  ///
  /// In en, this message translates to:
  /// **'Delete account (hidden)'**
  String get demoDeleteAccountHidden;

  /// No description provided for @demoEditProfileDisabled.
  ///
  /// In en, this message translates to:
  /// **'Edit profile (disabled)'**
  String get demoEditProfileDisabled;

  /// No description provided for @demoEmailReadonly.
  ///
  /// In en, this message translates to:
  /// **'Email (read-only)'**
  String get demoEmailReadonly;

  /// No description provided for @demoOrdersTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get demoOrdersTitle;

  /// No description provided for @demoPermissionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission demo'**
  String get demoPermissionsTitle;

  /// No description provided for @demoProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get demoProfileTitle;

  /// No description provided for @demoReportsTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get demoReportsTitle;

  /// No description provided for @demoSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get demoSettingsTitle;

  /// No description provided for @homeBottomNavFirst.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeBottomNavFirst;

  /// No description provided for @homeBottomNavSecond.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get homeBottomNavSecond;

  /// No description provided for @homeInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get homeInfo;

  /// No description provided for @homeIntro.
  ///
  /// In en, this message translates to:
  /// **'Hi, I am Eren 👋🏽'**
  String get homeIntro;

  /// No description provided for @homeMenuTitle.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get homeMenuTitle;

  /// No description provided for @homeMore.
  ///
  /// In en, this message translates to:
  /// **'Learn More'**
  String get homeMore;

  /// No description provided for @homeThemeMode.
  ///
  /// In en, this message translates to:
  /// **'Theme Mode'**
  String get homeThemeMode;

  /// No description provided for @homeThemeModeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get homeThemeModeDark;

  /// No description provided for @homeThemeModeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get homeThemeModeLight;

  /// No description provided for @homeThemeModeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get homeThemeModeSystem;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTitle;

  /// No description provided for @homeToggleLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get homeToggleLanguage;

  /// No description provided for @homeToggleTheme.
  ///
  /// No description provided for @homeToggleTheme.
  ///
  /// In en, this message translates to:
  /// **'Change Theme'**
  String get homeToggleTheme;

  /// In en, this message translates to:
  /// **'Sound Effects'**
  String get soundEffectsLabel;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}

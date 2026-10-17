// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ball Lab Puzzle';

  @override
  String get backTooltip => 'Back';

  @override
  String levelTitle(int levelId) {
    return 'Level $levelId';
  }

  @override
  String levelBadge(int levelId) {
    return 'LEVEL $levelId';
  }

  @override
  String movesLeftCount(int count) {
    return 'MOVES LEFT: $count';
  }

  @override
  String get actionRestart => 'Restart';

  @override
  String actionUndo(int count) {
    return 'Undo ($count)';
  }

  @override
  String get actionUndoSimple => 'Undo';

  @override
  String actionHint(int count) {
    return 'Hint ($count)';
  }

  @override
  String get outOfUndosToast => 'You have used all free Undo moves for today!';

  @override
  String get outOfHintsToast => 'You have used all free Hints for today!';

  @override
  String gameInstruction(int current, int max) {
    return 'Moves: $current / $max • Sort all balls by color';
  }

  @override
  String tubesSolvedProgress(int completed, int total) {
    return '$completed / $total Solved';
  }

  @override
  String get hintAlreadyCompleted => 'Level already completed!';

  @override
  String get hintNoMoveFound => 'No helpful moves found. Try Undo or Restart!';

  @override
  String get victoryTitle => 'EXPERIMENT COMPLETE!';

  @override
  String get milestoneReached => 'MILESTONE REACHED!';

  @override
  String levelMastered(int levelId) {
    return 'Level $levelId Mastered';
  }

  @override
  String get victoryPerfect => 'PERFECT SORTING!';

  @override
  String get victoryExcellent => 'EXCELLENT LAB WORK!';

  @override
  String get victoryGood => 'EXPERIMENT SOLVED!';

  @override
  String get movesTakenLabel => 'MOVES TAKEN';

  @override
  String get parMovesLabel => 'PAR MOVES';

  @override
  String starThresholds(int threeStar, int twoStar) {
    return '3★: ≤$threeStar moves  •  2★: ≤$twoStar moves';
  }

  @override
  String get newBestRecord => '✨ NEW BEST RECORD!';

  @override
  String get buttonPlayAgain => 'Play Again';

  @override
  String get buttonNextLevel => 'Next Level';

  @override
  String get buttonReturnToMap => 'Return to Map';

  @override
  String get defeatTitle => 'OUT OF MOVES!';

  @override
  String levelIncomplete(int levelId) {
    return 'Level $levelId Incomplete';
  }

  @override
  String defeatMessage(int maxMoves) {
    return 'You have used all $maxMoves allowed moves for this experiment. Re-calibrate your strategy and try again!';
  }

  @override
  String get movesUsedLabel => 'MOVES USED';

  @override
  String get maxLimitLabel => 'MAX LIMIT';

  @override
  String get outOfLivesTitle => 'OUT OF LIVES';

  @override
  String get outOfLivesMessage =>
      'You have used all 5 free daily experiment attempts.\nYour lives replenish every midnight (00:00 VN).';

  @override
  String get nextFreeRefillIn => 'NEXT FREE REFILL IN';

  @override
  String get watchVideoOption => 'Watch Lab Video (+1 Life)';

  @override
  String get comingSoonTag => 'COMING SOON';

  @override
  String get instantRefillOption => 'Instant Lab Energy Refill';

  @override
  String get buttonBackToMap => 'BACK TO MAP';

  @override
  String get mapTitle => 'BALL LAB JOURNEY';

  @override
  String get mapSubtitle => 'Select a puzzle experiment';

  @override
  String get previousChapterTooltip => 'Previous chapter';

  @override
  String get nextChapterTooltip => 'Next chapter';

  @override
  String chapterIndicator(int current, int total) {
    return 'CHAPTER $current / $total';
  }

  @override
  String chapterProgress(int start, int end, int stars, int maxStars) {
    return 'Level $start – $end  •  ⭐ $stars/$maxStars';
  }

  @override
  String activeLevelShort(int levelId) {
    return 'Lv $levelId';
  }

  @override
  String get selectChapterTitle => 'SELECT CHAPTER';

  @override
  String chapterPickerSummary(int chapters, int levels) {
    return '$chapters Chapters  •  $levels Levels';
  }

  @override
  String chapterItemTitle(int number) {
    return 'Chapter $number';
  }

  @override
  String get nodePlay => 'PLAY';

  @override
  String get bossBadge => 'BOSS';

  @override
  String get milestoneLevelDesc =>
      'High-difficulty Laboratory Milestone challenge';

  @override
  String get normalLevelDesc => 'Color segregation experiment';

  @override
  String get statColors => 'COLORS';

  @override
  String get statTubes => 'TUBES';

  @override
  String get statMaxMoves => 'MAX MOVES';

  @override
  String get statBestRun => 'BEST RUN';

  @override
  String get statNone => 'None';

  @override
  String movesUnit(int moves) {
    return '$moves moves';
  }

  @override
  String starCondition(int moves) {
    return '≤ $moves moves';
  }

  @override
  String get buttonStartExperiment => 'START EXPERIMENT';

  @override
  String levelLockedToast(int levelId) {
    return 'Complete Level $levelId to unlock this experiment!';
  }

  @override
  String get authCreateAccount => 'Create an account';

  @override
  String get authCredentialsRequired => 'Please enter your email and password.';

  @override
  String get authEmailHint => 'Enter your email';

  @override
  String get authEmailInvalid => 'Please enter a valid email address';

  @override
  String get authEmailRequired => 'Please enter an email address';

  @override
  String get authLoginButton => 'Login';

  @override
  String get authLoginFailed => 'Wrong email or password.';

  @override
  String get authLoginSubtitle => 'You can login with your email and password';

  @override
  String get authLoginTitle => 'Login';

  @override
  String get authPasswordHint => 'Enter your password';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authRegisterButton => 'Register';

  @override
  String get authRegisterCancel => 'Cancel';

  @override
  String get authRegisterTitle => 'New Profile';

  @override
  String get authUsernameHint => 'Enter your username';

  @override
  String get authUsernameLabel => 'Username';

  @override
  String get authWelcome => 'Welcome to the app';

  @override
  String demoAreaBody(String area) {
    return 'You can see this page because your permissions include the \"$area\" area.';
  }

  @override
  String get demoComponentRulesTitle => 'Component rules';

  @override
  String get demoDeleteAccountHidden => 'Delete account (hidden)';

  @override
  String get demoEditProfileDisabled => 'Edit profile (disabled)';

  @override
  String get demoEmailReadonly => 'Email (read-only)';

  @override
  String get demoOrdersTitle => 'Orders';

  @override
  String get demoPermissionsTitle => 'Permission demo';

  @override
  String get demoProfileTitle => 'Profile';

  @override
  String get demoReportsTitle => 'Reports';

  @override
  String get demoSettingsTitle => 'Settings';

  @override
  String get homeBottomNavFirst => 'Home';

  @override
  String get homeBottomNavSecond => 'Info';

  @override
  String get homeInfo => 'Info';

  @override
  String get homeIntro => 'Hi, I am Eren 👋🏽';

  @override
  String get homeMenuTitle => 'Menu';

  @override
  String get homeMore => 'Learn More';

  @override
  String get homeThemeMode => 'Theme Mode';

  @override
  String get homeThemeModeDark => 'Dark';

  @override
  String get homeThemeModeLight => 'Light';

  @override
  String get homeThemeModeSystem => 'System';

  @override
  String get homeTitle => 'Home';

  @override
  String get homeToggleLanguage => 'Change Language';

  @override
  String get homeToggleTheme => 'Change Theme';

  @override
  String get soundEffectsLabel => 'Sound Effects';
}

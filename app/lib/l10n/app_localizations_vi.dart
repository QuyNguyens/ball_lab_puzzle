// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Ball Lab Puzzle';

  @override
  String get backTooltip => 'Quay lại';

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
    return 'LƯỢT CÒN LẠI: $count';
  }

  @override
  String get actionRestart => 'Chơi lại';

  @override
  String actionUndo(int count) {
    return 'Hoàn tác ($count)';
  }

  @override
  String get actionUndoSimple => 'Hoàn tác';

  @override
  String actionHint(int count) {
    return 'Gợi ý ($count)';
  }

  @override
  String get outOfUndosToast => 'Bạn đã hết lượt Hoàn tác miễn phí hôm nay!';

  @override
  String get outOfHintsToast => 'Bạn đã hết lượt Gợi ý miễn phí hôm nay!';

  @override
  String gameInstruction(int current, int max) {
    return 'Lượt: $current / $max • Phân loại bóng theo màu';
  }

  @override
  String tubesSolvedProgress(int completed, int total) {
    return 'Đã hoàn thành $completed / $total';
  }

  @override
  String get hintAlreadyCompleted => 'Màn chơi đã hoàn thành!';

  @override
  String get hintNoMoveFound =>
      'Không tìm thấy nước đi phù hợp. Hãy thử Hoàn tác hoặc Chơi lại!';

  @override
  String get victoryTitle => 'THÍ NGHIỆM THÀNH CÔNG!';

  @override
  String get milestoneReached => 'ĐẠT CỘT MỐC ĐẶC BIỆT!';

  @override
  String levelMastered(int levelId) {
    return 'Đã chinh phục Level $levelId';
  }

  @override
  String get victoryPerfect => 'PHÂN LOẠI HOÀN HẢO!';

  @override
  String get victoryExcellent => 'KẾT QUẢ XUẤT SẮC!';

  @override
  String get victoryGood => 'HOÀN THÀNH THÍ NGHIỆM!';

  @override
  String get movesTakenLabel => 'SỐ LƯỢT ĐI';

  @override
  String get parMovesLabel => 'LƯỢT TỐI ƯU';

  @override
  String starThresholds(int threeStar, int twoStar) {
    return '3★: ≤$threeStar lượt  •  2★: ≤$twoStar lượt';
  }

  @override
  String get newBestRecord => '✨ KỶ LỤC MỚI!';

  @override
  String get buttonPlayAgain => 'Chơi lại';

  @override
  String get buttonNextLevel => 'Màn tiếp theo';

  @override
  String get buttonReturnToMap => 'Về bản đồ';

  @override
  String get defeatTitle => 'HẾT LƯỢT ĐI!';

  @override
  String levelIncomplete(int levelId) {
    return 'Chưa hoàn thành Level $levelId';
  }

  @override
  String defeatMessage(int maxMoves) {
    return 'Bạn đã sử dụng hết $maxMoves lượt cho thí nghiệm này. Hãy điều chỉnh chiến thuật và thử lại!';
  }

  @override
  String get movesUsedLabel => 'LƯỢT ĐÃ DÙNG';

  @override
  String get maxLimitLabel => 'GIỚI HẠN TỐI ĐA';

  @override
  String get outOfLivesTitle => 'HẾT MẠNG CHƠI';

  @override
  String get outOfLivesMessage =>
      'Bạn đã sử dụng hết 5 lượt chơi miễn phí hôm nay.\nSố mạng sẽ hồi phục vào nửa đêm (00:00 VN).';

  @override
  String get nextFreeRefillIn => 'HỒI PHỤC MIỄN PHÍ SAU';

  @override
  String get watchVideoOption => 'Xem video (+1 Mạng)';

  @override
  String get comingSoonTag => 'SẮP RA MẮT';

  @override
  String get instantRefillOption => 'Hồi phục năng lượng ngay';

  @override
  String get buttonBackToMap => 'VỀ BẢN ĐỒ';

  @override
  String get mapTitle => 'HÀNH TRÌNH BALL LAB';

  @override
  String get mapSubtitle => 'Chọn thí nghiệm giải đố';

  @override
  String get previousChapterTooltip => 'Chặng trước';

  @override
  String get nextChapterTooltip => 'Chặng tiếp theo';

  @override
  String chapterIndicator(int current, int total) {
    return 'CHẶNG $current / $total';
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
  String get selectChapterTitle => 'CHỌN CHẶNG THÍ NGHIỆM';

  @override
  String chapterPickerSummary(int chapters, int levels) {
    return '$chapters Chặng  •  $levels Level';
  }

  @override
  String chapterItemTitle(int number) {
    return 'Chặng $number';
  }

  @override
  String get nodePlay => 'CHƠI';

  @override
  String get bossBadge => 'BOSS';

  @override
  String get milestoneLevelDesc => 'Thử thách cột mốc đặc biệt độ khó cao';

  @override
  String get normalLevelDesc => 'Thí nghiệm phân loại màu sắc';

  @override
  String get statColors => 'SỐ MÀU';

  @override
  String get statTubes => 'SỐ ỐNG';

  @override
  String get statMaxMoves => 'GIỚI HẠN LƯỢT';

  @override
  String get statBestRun => 'KỶ LỤC';

  @override
  String get statNone => 'Chưa có';

  @override
  String movesUnit(int moves) {
    return '$moves lượt';
  }

  @override
  String starCondition(int moves) {
    return '≤ $moves lượt';
  }

  @override
  String get buttonStartExperiment => 'BẮT ĐẦU THÍ NGHIỆM';

  @override
  String levelLockedToast(int levelId) {
    return 'Hoàn thành Level $levelId để mở khóa thí nghiệm này!';
  }

  @override
  String get authCreateAccount => 'Tạo tài khoản';

  @override
  String get authCredentialsRequired => 'Vui lòng nhập email và mật khẩu.';

  @override
  String get authEmailHint => 'Nhập email của bạn';

  @override
  String get authEmailInvalid => 'Vui lòng nhập địa chỉ email hợp lệ';

  @override
  String get authEmailRequired => 'Vui lòng nhập địa chỉ email';

  @override
  String get authLoginButton => 'Đăng nhập';

  @override
  String get authLoginFailed => 'Sai email hoặc mật khẩu.';

  @override
  String get authLoginSubtitle => 'Bạn có thể đăng nhập bằng email và mật khẩu';

  @override
  String get authLoginTitle => 'Đăng nhập';

  @override
  String get authPasswordHint => 'Nhập mật khẩu của bạn';

  @override
  String get authPasswordLabel => 'Mật khẩu';

  @override
  String get authRegisterButton => 'Đăng ký';

  @override
  String get authRegisterCancel => 'Hủy';

  @override
  String get authRegisterTitle => 'Hồ sơ mới';

  @override
  String get authUsernameHint => 'Nhập tên người dùng';

  @override
  String get authUsernameLabel => 'Tên người dùng';

  @override
  String get authWelcome => 'Chào mừng đến với ứng dụng';

  @override
  String demoAreaBody(String area) {
    return 'Bạn có thể xem trang này vì quyền của bạn bao gồm khu vực \"$area\".';
  }

  @override
  String get demoComponentRulesTitle => 'Quy tắc thành phần';

  @override
  String get demoDeleteAccountHidden => 'Xóa tài khoản (ẩn)';

  @override
  String get demoEditProfileDisabled => 'Sửa hồ sơ (vô hiệu)';

  @override
  String get demoEmailReadonly => 'Email (chỉ đọc)';

  @override
  String get demoOrdersTitle => 'Đơn hàng';

  @override
  String get demoPermissionsTitle => 'Bản demo phân quyền';

  @override
  String get demoProfileTitle => 'Hồ sơ';

  @override
  String get demoReportsTitle => 'Báo cáo';

  @override
  String get demoSettingsTitle => 'Cài đặt';

  @override
  String get homeBottomNavFirst => 'Trang chủ';

  @override
  String get homeBottomNavSecond => 'Thông tin';

  @override
  String get homeInfo => 'Thông tin';

  @override
  String get homeIntro => 'Xin chào, tôi là Eren 👋🏽';

  @override
  String get homeMenuTitle => 'Menu';

  @override
  String get homeMore => 'Tìm hiểu thêm';

  @override
  String get homeThemeMode => 'Chế độ giao diện';

  @override
  String get homeThemeModeDark => 'Tối';

  @override
  String get homeThemeModeLight => 'Sáng';

  @override
  String get homeThemeModeSystem => 'Hệ thống';

  @override
  String get homeTitle => 'Trang chủ';

  @override
  String get homeToggleLanguage => 'Đổi ngôn ngữ';

  @override
  String get homeToggleTheme => 'Đổi giao diện';

  @override
  String get soundEffectsLabel => 'Hiệu ứng âm thanh';
}

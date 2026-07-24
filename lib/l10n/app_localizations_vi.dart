// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Walkamon';

  @override
  String get system => 'Hệ thống';

  @override
  String get notificationsRemind => 'Thông báo nhắc nhở';

  @override
  String get notificationsSubtitle => 'Nhận lịch nhắc cho thú cưng ăn, đi bộ';

  @override
  String get featuresSupport => 'Tính năng & Hỗ trợ';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get languageVi => 'Tiếng Việt';

  @override
  String get languageEn => 'English';

  @override
  String get sendFeedback => 'Gửi góp ý & Báo lỗi cho Dev';

  @override
  String get accountSecurity => 'Tài khoản & Bảo mật';

  @override
  String get changePassword => 'Đổi mật khẩu tài khoản';

  @override
  String get logout => 'Đăng xuất tài khoản';

  @override
  String get feedbackTitle => 'Gửi phản hồi';

  @override
  String get feedbackSuggestion => 'Góp ý';

  @override
  String get feedbackBug => 'Báo lỗi';

  @override
  String get feedbackDetail => 'Mô tả chi tiết';

  @override
  String get feedbackHintSuggestion => 'Bạn có ý tưởng gì mới cho game không?';

  @override
  String get feedbackHintBug => 'Bạn đã gặp vấn đề gì trong lúc chơi?';

  @override
  String get feedbackSending => 'Đang gửi...';

  @override
  String get feedbackSubmit => 'Gửi ngay';

  @override
  String get feedbackSuccess => 'Bạn đã đánh giá thành công';

  @override
  String feedbackMinLength(int count) {
    return 'Mô tả phải có ít nhất 20 kí tự. ($count/20)';
  }

  @override
  String get gameSettings => 'Thiết Lập Game';

  @override
  String get bgm => 'Nhạc nền (BGM)';

  @override
  String get sfx => 'Hiệu ứng (SFX)';

  @override
  String get fps60 => 'Chế độ 60 FPS';

  @override
  String get fps60Hint => 'Mượt mà hơn, tốn pin hơn';

  @override
  String get darkMode => 'Chế độ tối';

  @override
  String get navHome => 'Trang chủ';

  @override
  String get navShop => 'Cửa hàng';

  @override
  String get navBag => 'Túi đồ';

  @override
  String get navQuest => 'Nhiệm vụ';

  @override
  String get navProfile => 'Hồ sơ';

  @override
  String get welcomeTagline => 'Đi bộ và cùng phát triển';

  @override
  String get welcomeExplore => 'Khám phá ngay';

  @override
  String get welcomeLogin => 'Đăng nhập';

  @override
  String get welcomeRegister => 'Đăng ký';

  @override
  String get welcomeOr => 'HOẶC';

  @override
  String get welcomeGoogleLogin => 'Đăng nhập bằng Google';

  @override
  String get googleLoginFailed => 'Đăng nhập Google thất bại';

  @override
  String get healthWarning =>
      'Chơi game quá 180 phút một ngày sẽ ảnh hưởng xấu đến sức khỏe';

  @override
  String get today => 'Hôm Nay';

  @override
  String get todayStepsDesc => 'Số bước chân bạn đã đi trong ngày hôm nay';

  @override
  String get step => 'Bước';

  @override
  String get luminaStatus => 'TRẠNG THÁI LUMINA';

  @override
  String get energy => 'Năng Lượng';

  @override
  String get lifeForce => 'Sinh Mệnh Lực';

  @override
  String get bonding => 'Độ Gắn Kết';

  @override
  String levelShort(int level) {
    return 'Lv. $level';
  }

  @override
  String expProgress(int current, int max) {
    return 'EXP $current/$max';
  }

  @override
  String get homeNavCommunity => 'Cộng Đồng';

  @override
  String get homeNavPvp => 'PvP';

  @override
  String get homeNavInventory => 'Túi Đồ';

  @override
  String get homeNavStore => 'Cửa Hàng';

  @override
  String get loginBack => 'Quay lại';

  @override
  String get loginTagline => 'Mỗi bước chân, một phép màu';

  @override
  String get loginWelcomeBack => 'Chào mừng trở lại!';

  @override
  String get loginSubtitle =>
      'Tiếp tục hành trình cùng tinh linh Lumina của bạn.';

  @override
  String get loginEmailRequired => 'Email không được để trống.';

  @override
  String get loginEmailInvalid => 'Email không đúng định dạng.';

  @override
  String get loginPasswordRequired => 'Mật khẩu không được để trống.';

  @override
  String get loginFailed => 'Đăng nhập thất bại.';

  @override
  String get loginEmail => 'Email';

  @override
  String get loginPassword => 'Mật khẩu';

  @override
  String get showPassword => 'Hiện mật khẩu';

  @override
  String get hidePassword => 'Ẩn mật khẩu';

  @override
  String get forgotPassword => 'Quên mật khẩu?';

  @override
  String get forgotPasswordTitle => 'Lạc Mất Mật Mã?';

  @override
  String get forgotPasswordSubtitle =>
      'Nhập email đã đăng ký, chúng tôi sẽ gửi mã OTP để bạn đặt lại mật khẩu.';

  @override
  String get forgotPasswordResetSent =>
      'Nếu email tồn tại, một mã OTP đặt lại mật khẩu đã được gửi.';

  @override
  String get forgotPasswordRequestFailed =>
      'Không thể gửi yêu cầu đặt lại mật khẩu.';

  @override
  String get forgotPasswordSendSignal => 'Gửi Tín Hiệu';

  @override
  String get loginButton => 'Đăng nhập';

  @override
  String get noAccount => 'Chưa có tài khoản?';

  @override
  String get registerNow => 'Đăng ký ngay';

  @override
  String get registerTitle => 'Gieo Hạt Mầm Đầu Tiên';

  @override
  String get registerSubtitle =>
      'Ký kết khế ước và bắt đầu hành trình ma thuật của riêng bạn';

  @override
  String get registerNameHint => 'Tên của bạn';

  @override
  String get registerPasswordMinLength => 'Mật khẩu phải chứa ít nhất 6 ký tự.';

  @override
  String get registerConfirmPassword => 'Xác nhận mật khẩu';

  @override
  String get registerNameRequired => 'Tên không được để trống.';

  @override
  String get registerNameMinLength => 'Tên phải chứa ít nhất 2 ký tự.';

  @override
  String get registerConfirmPasswordRequired => 'Vui lòng xác nhận mật khẩu.';

  @override
  String get registerPasswordMismatch => 'Mật khẩu xác nhận không trùng khớp.';

  @override
  String get registerFailed => 'Đăng ký thất bại. Vui lòng thử lại.';

  @override
  String get registerAgreeTerms => 'Tôi đã đọc và đồng ý với ';

  @override
  String get privacyPolicy => 'Chính sách và quy định sử dụng';

  @override
  String get registerButton => 'Bắt Đầu Khế Ước';

  @override
  String get registerAlreadyAccount => 'Đã ký kết khế ước?';

  @override
  String get registerLoginHere => 'Đăng nhập tại đây';

  @override
  String get changePasswordTitle => 'Đổi mật khẩu';

  @override
  String get changePasswordSubtitle =>
      'Cập nhật mật khẩu để bảo vệ tài khoản của bạn';

  @override
  String get changePasswordCurrentPassword => 'Mật khẩu hiện tại';

  @override
  String get changePasswordCurrentPasswordHint =>
      'Nhập mật khẩu hiện tại của bạn';

  @override
  String get changePasswordCurrentPasswordRequired =>
      'Mật khẩu hiện tại không được để trống.';

  @override
  String get changePasswordNewPassword => 'Mật khẩu mới';

  @override
  String get changePasswordNewPasswordHint => 'Nhập mật khẩu mới của bạn';

  @override
  String get changePasswordNewPasswordRequired =>
      'Mật khẩu mới không được để trống.';

  @override
  String get changePasswordNewPasswordMinLength =>
      'Mật khẩu mới phải có ít nhất 6 ký tự.';

  @override
  String get changePasswordConfirmPassword => 'Xác nhận mật khẩu mới';

  @override
  String get changePasswordConfirmPasswordHint =>
      'Xác nhận mật khẩu mới của bạn';

  @override
  String get changePasswordConfirmPasswordRequired =>
      'Vui lòng xác nhận mật khẩu mới.';

  @override
  String get changePasswordConfirmPasswordMismatch =>
      'Mật khẩu xác nhận không khớp.';

  @override
  String get changePasswordSave => 'Lưu thay đổi';

  @override
  String get changePasswordSuccessTitle => 'Đổi mật khẩu thành công!';

  @override
  String get changePasswordSuccessSubtitle =>
      'Mật khẩu của bạn đã được cập nhật an toàn. Vui lòng sử dụng mật khẩu mới ở lần đăng nhập sau.';

  @override
  String get changePasswordBackToSettings => 'Quay lại cài đặt';

  @override
  String get changePasswordFailed => 'Đổi mật khẩu thất bại. Vui lòng thử lại.';

  @override
  String get otpTitle => 'OTP';

  @override
  String get otpSubtitle => 'Nhập 6 chữ số OTP đã được gửi đến hòm thư của bạn';

  @override
  String get otpVerifyButton => 'Xác Nhận OTP';

  @override
  String get otpResendButton => 'Gửi lại OTP';

  @override
  String get otpIncomplete => 'OTP phải nhập đủ 6 ô.';

  @override
  String get otpDigitsOnly => 'OTP chỉ được nhập số.';

  @override
  String get otpRequestCodeNotFound => 'Không tìm thấy mã yêu cầu OTP.';

  @override
  String get otpEmailNotFound => 'Không tìm thấy email để gửi lại OTP.';

  @override
  String get otpInvalid => 'Mã OTP không hợp lệ.';

  @override
  String get otpVerifySuccess => 'Xác thực OTP thành công!';

  @override
  String get otpResendSuccess => 'Đã gửi lại mã OTP thành công!';

  @override
  String get otpResendFailed => 'Gửi lại mã OTP thất bại.';

  @override
  String get seedContinue => 'Tiếp tục';

  @override
  String get seedTitle => 'Mầm Ánh Sáng';

  @override
  String get seedDescription =>
      'Đây là khởi đầu của hành trình. Mầm Ánh Sáng sẽ hấp thụ Sinh Mệnh Lực từ những bước chân của bạn để phát triển.';

  @override
  String get seedEvolutionTitle => 'Tiến Hoá';

  @override
  String get seedEvolutionDescription =>
      'Mầm sẽ tiến hóa thành các dạng Tinh Linh khác nhau dựa trên thói quen vận động của bạn.';

  @override
  String get seedPath1Name => 'Tinh Linh Bình Minh';

  @override
  String get seedPath1Description => 'Hệ Bay • Đi bộ buổi sáng';

  @override
  String get seedPath2Name => 'Tinh Linh Ánh Trăng';

  @override
  String get seedPath2Description => 'Hệ Dạ Quang • Đi bộ buổi tối';

  @override
  String get seedPath3Name => 'Tinh Linh Nắng Ấm';

  @override
  String get seedPath3Description => 'Hệ Thực Vật • Đi bộ dàn trải';

  @override
  String get privacyTitle => 'Điều khoản dịch vụ';

  @override
  String get privacySubtitle => 'Khế ước đồng hành cùng Walkamon';

  @override
  String get privacyIntroTitle => 'GIỚI THIỆU';

  @override
  String get privacyIntroContent => 'Cảm ơn bạn đã sử dụng Walkamon.';

  @override
  String get privacyPart1 => 'PHẦN 1';

  @override
  String get privacySection1Title => '1. Đăng ký';

  @override
  String get privacySection1Content => '...';

  @override
  String get privacySection2Title => '2. Đặt tên';

  @override
  String get privacySection2Content => '...';

  @override
  String get privacySection3Title => '3. Lưu trữ dữ liệu';

  @override
  String get privacySection3Content => '...';

  @override
  String get privacySection4Title => '4. Hành vi bị cấm';

  @override
  String get privacySection4Content => '...';

  @override
  String get privacySection5Title => '5. Chấm dứt tài khoản';

  @override
  String get privacySection5Content => '...';

  @override
  String get privacyPart2 => 'PHẦN 2';

  @override
  String get privacySection6Title => '1. Quản lý nội dung';

  @override
  String get privacySection6Content => '...';

  @override
  String get privacySection7Title => '2. Phân loại độ tuổi';

  @override
  String get privacySection7Content => '...';

  @override
  String get privacySection8Title => '3. Vật phẩm ảo';

  @override
  String get privacySection8Content => '...';

  @override
  String get privacySection9Title => '4. Bản quyền';

  @override
  String get privacySection9Content => '...';

  @override
  String get privacySection10Title => '5. Website bên thứ ba';

  @override
  String get privacySection10Content => '...';

  @override
  String get privacyContactTitle => 'LIÊN HỆ';

  @override
  String get privacyContactContent => '...';

  @override
  String get privacyLastUpdated => 'Ngày cập nhật: 25/06/2026';

  @override
  String get privacyAgreeButton => 'Tôi Đã Hiểu & Đồng Ý';

  @override
  String get profileTitle => 'Hồ Sơ';

  @override
  String get loading => 'Đang tải...';

  @override
  String get traveler => 'Lữ Hành Giả';

  @override
  String get managementStats => 'Quản Lý & Thống Kê';

  @override
  String get accountInfo => 'Thông tin tài khoản';

  @override
  String get setStepGoal => 'Đặt mục tiêu bước đi';

  @override
  String get streak => 'Chuỗi ngày (Streak)';

  @override
  String get activityStats => 'Thống kê hoạt động';

  @override
  String get achievements => 'Thành Tựu';

  @override
  String get achievementVault => 'Kho Thành Tựu';

  @override
  String get achievementsLoadFailed => 'Không tải được thành tựu';

  @override
  String achievementsCollected(int count) {
    return 'Đã thu thập $count danh hiệu';
  }

  @override
  String get achievementsUnlockedTab => 'Đã Nhận';

  @override
  String get achievementsLockedTab => 'Chưa Nhận';

  @override
  String get achievementsCurrentProgress => 'Tiến độ hiện tại';

  @override
  String achievementsLockedDetail(String description, int reward) {
    return '$description.\nPhần thưởng: $reward Giọt Sương';
  }

  @override
  String achievementsUnlockedAt(String date) {
    return 'Đạt được vào: $date';
  }

  @override
  String achievementsUnlockedDetail(String description) {
    return '$description. Tiếp tục duy trì phong độ này để mở khóa thêm nhiều thành tựu mới nhé!';
  }

  @override
  String get achievementsKeepTrying => 'Tiếp tục cố gắng';

  @override
  String get achievementsCollection => 'Bộ Sưu Tập';

  @override
  String get achievementsGoals => 'Mục Tiêu';

  @override
  String achievementsLockedCount(int count) {
    return 'Còn $count danh hiệu đang chờ bạn khám phá';
  }

  @override
  String get retry => 'Thử lại';

  @override
  String get characterNotFound => 'Không tìm thấy thông tin nhân vật.';

  @override
  String get notUpdated => 'Chưa cập nhật';

  @override
  String get dateOfBirth => 'Ngày sinh';

  @override
  String get gender => 'Giới tính';

  @override
  String get joinDate => 'Ngày tham gia';

  @override
  String get genderMale => 'Nam';

  @override
  String get genderFemale => 'Nữ';

  @override
  String get genderOther => 'Khác';

  @override
  String get dailyLoginNoData => 'Không có dữ liệu điểm danh.';

  @override
  String get dailyLoginTitle => 'Điểm Danh';

  @override
  String get dailyLoginRewardTitle => 'Quà Hàng Ngày';

  @override
  String get dailyLoginRewardSubtitle =>
      'Đăng nhập mỗi ngày để nhận quà hấp dẫn.\nĐừng bỏ lỡ ngày thứ 7 nhé!';

  @override
  String get dailyLoginAlreadyClaimed => 'Hôm nay bạn đã nhận quà rồi!';

  @override
  String get dailyLoginSuccessTitle => 'Thành Công!';

  @override
  String dailyLoginSuccessMessage(int day) {
    return 'Chúc mừng bạn đã nhận quà thành công ngày $day!';
  }

  @override
  String dailyLoginSuccessReward(int amount) {
    return 'Phần thưởng: +$amount Giọt nước';
  }

  @override
  String dailyLoginSuccessBalance(int balance) {
    return 'Số dư hiện tại: $balance Giọt nước';
  }

  @override
  String get dailyLoginSuccessAction => 'Tuyệt vời';

  @override
  String get dailyLoginClaimedToday => 'Đã Nhận Hôm Nay';

  @override
  String get dailyLoginClaimNow => 'Nhận Quà Ngay';

  @override
  String get dailyLoginNoRewardData => 'Chưa có dữ liệu phần thưởng';

  @override
  String dayLabel(int day) {
    return 'NGÀY $day';
  }

  @override
  String rewardCount(int count) {
    return 'x$count';
  }

  @override
  String get errorPrefix => 'Lỗi';

  @override
  String get friendsLoadError => 'Lỗi tải danh sách bạn bè';

  @override
  String get friendsRemoveTitle => 'Xóa bạn bè';

  @override
  String friendsRemoveConfirm(String name) {
    return 'Bạn có chắc chắn muốn xóa $name khỏi danh sách bạn bè?';
  }

  @override
  String get friendsCancel => 'Hủy';

  @override
  String get friendsRemove => 'Xóa';

  @override
  String get friendsRequest => 'Yêu cầu';

  @override
  String get friendsAdd => 'Thêm Bạn';

  @override
  String get friendsSearchHint => 'Tìm kiếm bạn bè...';

  @override
  String get friendsEmptyTitle => 'Chưa có đồng đội nào!';

  @override
  String get friendsEmptySubtitle =>
      'Bấm \'Thêm Bạn\' để bắt đầu hành trình nhé.';

  @override
  String get friendsNoResult => 'Không tìm thấy người bạn này.';

  @override
  String friendsRemoveSuccess(String name) {
    return 'Đã hủy kết bạn với $name!';
  }

  @override
  String get friendsRemoveFailure => 'Lỗi xóa bạn bè, vui lòng thử lại!';

  @override
  String get pvpTitle => 'Đấu trường PvP';

  @override
  String get pvpComingSoonTitle => 'Chế độ thi đấu PvP đang được phát triển!';

  @override
  String get pvpComingSoonDescription =>
      'So tài sức mạnh Lumina cùng các đối thủ tầm cỡ.';

  @override
  String get inventoryLoadError => 'Không tải được túi đồ.';

  @override
  String get inventoryNoItems => 'Không có vật phẩm nào.';

  @override
  String get inventoryNoEffect => 'Không có hiệu ứng';

  @override
  String inventoryUsed(String name) {
    return 'Đã sử dụng: $name';
  }

  @override
  String inventoryUseFailed(String message) {
    return 'Sử dụng thất bại: $message';
  }

  @override
  String inventoryUseError(String message) {
    return 'Lỗi khi sử dụng: $message';
  }

  @override
  String get inventoryCommunity => 'Cộng Đồng';

  @override
  String get inventoryPvp => 'PvP';

  @override
  String get inventoryBag => 'Túi Đồ';

  @override
  String get inventoryStore => 'Cửa Hàng';

  @override
  String get inventoryHome => 'Trang Chủ';

  @override
  String get leaderboardTitle => 'Bảng xếp hạng';

  @override
  String leaderboardYourRank(int rank) {
    return 'Hạng của bạn: #$rank';
  }

  @override
  String get leaderboardToday => 'Hôm nay';

  @override
  String get leaderboardThisWeek => 'Tuần này';

  @override
  String get leaderboardThisMonth => 'Tháng này';

  @override
  String get leaderboardSteps => 'Bước chân';

  @override
  String get leaderboardLevel => 'Cấp độ';

  @override
  String get leaderboardYou => 'Bạn';

  @override
  String get leaderboardUserDefault => 'Người dùng';

  @override
  String get leaderboardCouldNotLoad => 'Không tải được bảng xếp hạng';

  @override
  String get leaderboardCouldNotConnect => 'Không thể kết nối tới máy chủ';

  @override
  String get missionsDefaultDescription =>
      'Hoàn thành nhiệm vụ để nhận thưởng.';

  @override
  String get missionsChallengeDescription =>
      'Hoàn thành thử thách để nhận thưởng.';

  @override
  String get missionsLoadError => 'Không tải được nhiệm vụ.';

  @override
  String missionsClaimSuccess(int amount) {
    return 'Nhận thưởng thành công: +$amount';
  }

  @override
  String missionsClaimFailed(String message) {
    return 'Không thể nhận thưởng: $message';
  }

  @override
  String get missionsChallengeExists =>
      'Bạn đang có một thử thách. Hãy hoàn thành hoặc hủy nó trước!';

  @override
  String get missionsChallengeCanceled => 'Đã hủy thử thách.';

  @override
  String get missionsChallengeCreated => 'Đã nhận thử thách mới!';

  @override
  String missionsCancelFailed(String message) {
    return 'Không thể hủy thử thách: $message';
  }

  @override
  String get missionsDailyTitle => 'Nhiệm vụ ngày';

  @override
  String get missionsOverallTitle => 'Nhiệm vụ tổng';

  @override
  String get missionsDailyEmpty => 'Không có nhiệm vụ ngày.';

  @override
  String get missionsOverallEmpty => 'Không có nhiệm vụ tổng.';

  @override
  String get missionsRandomChallenge => 'Thử thách ngẫu nhiên';

  @override
  String missionsCancelRemaining(int remaining, int limit) {
    return 'Lượt hủy: $remaining/$limit';
  }

  @override
  String get missionsNoActiveChallenge =>
      'Hiện tại không có thử thách nào đang thực hiện.';

  @override
  String get missionsNewChallenge => 'Nhận Thử Thách Mới';

  @override
  String get missionsTitle => 'Nhiệm Vụ';

  @override
  String get missionsTabMission => 'Nhiệm vụ';

  @override
  String get missionsTabChallenge => 'Thử thách';

  @override
  String get notificationsTitle => 'Thông Báo';

  @override
  String get notificationsEmpty => 'Không có thông báo nào.';

  @override
  String get notificationsDeleted => 'Đã xóa thông báo';

  @override
  String notificationsDeleteFailed(String message) {
    return 'Xóa thất bại: $message';
  }

  @override
  String get notificationsDetailError => 'Đã có lỗi xảy ra khi tải nội dung.';

  @override
  String notificationsTimeAgoDays(int count) {
    return '$count ngày trước';
  }

  @override
  String notificationsTimeAgoHours(int count) {
    return '$count giờ trước';
  }

  @override
  String notificationsTimeAgoMinutes(int count) {
    return '$count phút trước';
  }

  @override
  String get notificationsTimeAgoJustNow => 'Vừa xong';

  @override
  String get notificationsTypeDailyReward => 'Quà đăng nhập hàng ngày';

  @override
  String get notificationsTypeStreakReward => 'Quà chuỗi điểm danh';

  @override
  String get notificationsTypeMissionComplete => 'Hoàn thành nhiệm vụ';

  @override
  String get notificationsTypeAchievementComplete => 'Hoàn thành thành tựu';

  @override
  String get notificationsTypeChallengeInvite => 'Lời mời thử thách';

  @override
  String get notificationsTypePvpInvite => 'Lời mời đấu PvP';

  @override
  String get notificationsTypeFriendRequest => 'Yêu cầu kết bạn';

  @override
  String get notificationsTypeFriendAccepted => 'Chấp nhận kết bạn';

  @override
  String get notificationsTypeFriendRemoved => 'Hủy kết bạn';

  @override
  String get notificationsTypeSpiritHungry => 'Lumina đang đói';

  @override
  String get notificationsTypeSpiritReadyEvolution => 'Đủ điều kiện tiến hóa';

  @override
  String get notificationsTypeSpiritEnergyFull => 'Năng lượng đã đầy';

  @override
  String get notificationsTypeSpiritBondLow => 'Sinh mệnh thấp';

  @override
  String get notificationsTypeSpiritLevelUp => 'Lên cấp';

  @override
  String get notificationsTypeItemPurchased => 'Mua vật phẩm thành công';

  @override
  String get notificationsTypePvpResult => 'Kết quả đấu PvP';

  @override
  String get notificationsTypeMaintenance => 'Thông báo bảo trì';

  @override
  String get notificationsTypePatchNotes => 'Ghi chú cập nhật';

  @override
  String get notificationsTypeNews => 'Tin tức mới';

  @override
  String get notificationsTypeEvent => 'Sự kiện';

  @override
  String get notificationsTypeCompensation => 'Quà đền bù';

  @override
  String get notificationsTypeServerAnnouncement => 'Thông báo từ máy chủ';

  @override
  String get profileEditTitle => 'Chỉnh Sửa Hồ Sơ';

  @override
  String get profileEditDisplayName => 'Tên hiển thị';

  @override
  String get profileEditDisplayNameHint => 'Nhập tên của bạn';

  @override
  String get profileEditEmailLabel => 'Email (Không thể thay đổi)';

  @override
  String get profileEditEmailHint => 'Nhập email';

  @override
  String get profileEditGenderLabel => 'Giới tính';

  @override
  String get profileEditBirthLabel => 'Ngày sinh';

  @override
  String get profileEditBioLabel => 'Tiểu sử';

  @override
  String get profileEditBioHint => 'Vài nét về bạn...';

  @override
  String get profileEditSaveLoading => 'Đang Lưu...';

  @override
  String get profileEditSave => 'Lưu Thay Đổi';

  @override
  String get profileEditSuccessMessage =>
      'Thông tin hồ sơ của bạn đã được cập nhật thành công!';

  @override
  String get profileEditFailureMessage =>
      'Cập nhật thất bại. Vui lòng kiểm tra lại.';

  @override
  String get profileEditRequiredName => 'Không được bỏ trống';

  @override
  String get profileEditConfirm => 'Xác Nhận';

  @override
  String get profileEditDefaultName => 'Lữ Hành Giả';

  @override
  String get profileEditDefaultBio => 'Đang tận hưởng hành trình Walkamon!';

  @override
  String get activityStatsTitle => 'Hoạt Động';

  @override
  String get activityStatsStats => 'Thống Kê';

  @override
  String get activityStatsHistory => 'Lịch Sử';

  @override
  String get activityStatsDaily => 'Ngày';

  @override
  String get activityStatsWeekly => 'Tuần';

  @override
  String get activityStatsMonthly => 'Tháng';

  @override
  String get activityStatsTotalSteps => 'Tổng bước';

  @override
  String get activityStatsDistance => 'Khoảng cách';

  @override
  String get activityStatsNoChartData => 'Chưa có dữ liệu biểu đồ';

  @override
  String get activityStatsNoHistory => 'Chưa có lịch sử hoạt động';

  @override
  String get activityStatsGoalReached => 'ĐẠT MỤC TIÊU';

  @override
  String get activityStatsStepsUnit => 'bước';

  @override
  String get activityStatsStepsPerDay => 'bước/ngày';

  @override
  String get activityStatsSuffixKm => 'km';

  @override
  String get activityStatsTodayTitle => 'Hoạt động hôm nay';

  @override
  String get activityStatsWeekTitle => 'Hoạt động tuần này';

  @override
  String get activityStatsMonthTitle => 'Hoạt động tháng này';

  @override
  String get activityStatsTotal => 'Tổng';

  @override
  String get activityStatsAverage => 'Trung bình';

  @override
  String activityStatsWeekBucket(int week) {
    return 'Tuần $week';
  }

  @override
  String get streakTitle => 'Chuỗi Đăng Nhập';

  @override
  String get streakDays => 'ngày';

  @override
  String get streakEncouragement =>
      'Bạn đang làm rất tốt! Hãy tiếp tục duy trì để nhận phần thưởng hấp dẫn.';

  @override
  String get streakThirtyDays => 'Chuỗi 30 Ngày';

  @override
  String get streakRecord => 'Kỷ lục chuỗi';

  @override
  String get streakCurrent => 'Chuỗi hiện tại';

  @override
  String get shopTitle => 'Cửa Hàng';

  @override
  String get shopCurrency => 'Giọt Sương';

  @override
  String get shopNoItems => 'Không có shop item nào.';

  @override
  String get shopBuy => 'Mua';

  @override
  String shopBuySuccess(String name) {
    return 'Mua thành công: $name';
  }

  @override
  String shopBuyFailed(String message) {
    return 'Mua thất bại: $message';
  }

  @override
  String shopBuyError(String message) {
    return 'Lỗi khi mua: $message';
  }

  @override
  String get shopType => 'Loại';

  @override
  String get shopPrice => 'Giá bán';

  @override
  String get shopDescription => 'Mô tả';

  @override
  String get socialTitle => 'Cộng Đồng';

  @override
  String get socialFriends => 'Bạn Bè';

  @override
  String get socialLeaderboard => 'Xếp Hạng';

  @override
  String get dailyRewardTitle => 'Điểm Danh Hàng Ngày';

  @override
  String get dailyRewardSubtitle => 'Tính năng Điểm Danh đang được phát triển!';

  @override
  String get dailyRewardDescription =>
      'Đăng nhập mỗi ngày để nhận những giọt sương ma thuật.';

  @override
  String get namePetTitle => 'Đặt tên cho Lumina';

  @override
  String get namePetDescription =>
      'Hãy chọn một cái tên thật ý nghĩa cho người bạn đồng hành của mình.';

  @override
  String get namePetHint => 'Nhập tên tinh linh...';

  @override
  String get namePetComplete => 'Hoàn tất';

  @override
  String get namePetCreateFailed =>
      'Không thể tạo thú cưng khởi đầu. Vui lòng thử lại.';

  @override
  String get seedTitleScreen => 'Mầm Ánh Sáng';

  @override
  String get seedDescriptionScreen =>
      'Đây là khởi đầu của hành trình. Mầm Ánh Sáng sẽ hấp thụ Sinh Mệnh Lực từ những bước chân của bạn để phát triển.';

  @override
  String get storySkip => 'Bỏ qua';

  @override
  String get storyBack => 'Quay lại';

  @override
  String get storyContinue => 'Tiếp tục';

  @override
  String get storyExplore => 'Khám phá';

  @override
  String get close => 'Đóng';

  @override
  String get processing => 'Đang xử lý...';

  @override
  String get profileEditFailureTitle => 'Thất Bại';

  @override
  String get missionsClaim => 'NHẬN';

  @override
  String get missionsClaimed => 'ĐÃ NHẬN';

  @override
  String get inventoryNoDescription => 'Chưa có mô tả.';

  @override
  String get inventoryUse => 'Sử Dụng';

  @override
  String friendsListCount(int count) {
    return 'DANH SÁCH ($count)';
  }

  @override
  String get friendsSearchError => 'Lỗi tìm kiếm';

  @override
  String get friendsAddNew => 'Thêm Bạn Mới';

  @override
  String get friendsPlayerNameHint => 'Nhập tên người chơi...';

  @override
  String friendsSuggestionsCount(int count) {
    return 'GỢI Ý KẾT BẠN ($count)';
  }

  @override
  String friendsSearchResultsCount(int count) {
    return 'KẾT QUẢ TÌM KIẾM ($count)';
  }

  @override
  String get friendsNoAvailablePlayers => 'Không có người chơi nào khả dụng';

  @override
  String get friendsAddShort => 'Thêm';

  @override
  String get friendsInbox => 'Hộp Thư Kết Bạn';

  @override
  String get friendsReceivedInvites => 'Lời mời đã nhận';

  @override
  String get friendsSentInvites => 'Đã gửi đi';

  @override
  String get friendsNoSentInvites => 'Bạn chưa gửi lời mời nào gần đây.';

  @override
  String get friendsNoReceivedInvites => 'Không có lời mời kết bạn nào.';

  @override
  String get stepGoalTitle => 'Mục tiêu bước chân';

  @override
  String get stepGoalCustomTitle => 'Mục tiêu tự chọn';

  @override
  String get stepGoalInputHint => 'Nhập số bước...';

  @override
  String get stepGoalSuggestions => 'GỢI Ý MỤC TIÊU';

  @override
  String get stepGoalTodayProgress => 'TIẾN ĐỘ HÔM NAY';

  @override
  String get stepGoalMinError => 'Mục tiêu phải lớn hơn 500 bước.';

  @override
  String get stepGoalMaxError => 'Mục tiêu không được vượt quá 100.000 bước.';

  @override
  String get stepGoalGreaterThanCurrent =>
      'Mục tiêu mới phải lớn hơn mục tiêu hiện tại.';

  @override
  String get stepGoalInvalidNumber => 'Nhập số bước hợp lệ.';

  @override
  String stepGoalSaved(String steps) {
    return 'Đã lưu mục tiêu $steps bước.';
  }

  @override
  String stepGoalClaimSuccess(String amount) {
    return 'Nhận thưởng thành công: +$amount Giọt Sương.';
  }

  @override
  String stepGoalOutOfSteps(String steps) {
    return ' / $steps bước';
  }

  @override
  String stepGoalRemaining(String steps) {
    return 'Còn $steps bước';
  }

  @override
  String get stepGoalNotSet => 'Chưa đặt mục tiêu';

  @override
  String get stepGoalChoosePrompt =>
      'Chọn một mục tiêu bên dưới để bắt đầu theo dõi tiến độ hôm nay.';

  @override
  String get stepGoalCompletedMessage =>
      'Tuyệt vời! Bạn đã hoàn thành mục tiêu ngày hôm nay.';

  @override
  String get stepGoalActiveMessage =>
      'Hãy đặt mục tiêu vừa sức và tăng dần để giữ chuỗi ngày năng động.';

  @override
  String get stepGoalStreakTitle => 'Chuỗi mục tiêu';

  @override
  String get stepGoalStreakSubtitle => 'Hoàn thành mục tiêu để tăng thưởng ví.';

  @override
  String get stepGoalLongest => 'Dài nhất';

  @override
  String get stepGoalClaiming => 'Đang nhận';

  @override
  String get stepGoalCustomShort => 'Tùy chỉnh';

  @override
  String spiritDetailTitle(String name) {
    return 'Chi Tiết $name';
  }

  @override
  String spiritLevel(int level) {
    return 'Cấp $level';
  }

  @override
  String get spiritRecoveryPotion => 'Bình Hồi Phục';

  @override
  String spiritBondBonus(int amount) {
    return '+$amount Độ gắn kết';
  }

  @override
  String spiritEnergyBonus(int amount) {
    return '+$amount Năng lượng';
  }

  @override
  String get spiritPlantType => 'Hệ Thực Vật';

  @override
  String get spiritStatsTab => 'Chỉ Số';

  @override
  String get spiritEvolutionTab => 'Tiến Hóa';

  @override
  String get spiritLifeForceExp => 'Sinh Mệnh Lực (EXP)';

  @override
  String get spiritSupportItems => 'Vật Phẩm Hỗ Trợ';

  @override
  String get spiritTapLumina => 'Chạm Lumina';

  @override
  String get spiritTapSuccess => 'Đã chạm Lumina thành công';

  @override
  String get spiritFeed => 'Cho ăn';

  @override
  String get spiritFeedSuccess => 'Đã cho Lumina ăn thành công';

  @override
  String get spiritEvolutionStages => 'Giai Đoạn Tiến Hóa';

  @override
  String get spiritStageSeed => 'Mầm';

  @override
  String get spiritStageSprout => 'Chồi';

  @override
  String get spiritStageLeaf => 'Lá';

  @override
  String spiritCurrentRequirement(int level, int bonding) {
    return 'Điều kiện hiện tại: Lv $level - Bond $bonding';
  }

  @override
  String get spiritReady => 'Sẵn sàng';

  @override
  String get spiritEvolutionHistory => 'Lịch Sử Tiến Hóa';

  @override
  String get spiritHistoryHatched => 'Ấp nở thành công';

  @override
  String get spiritHistorySprout => 'Tiến hóa thành Dạng Chồi';

  @override
  String get spiritHistoryLeaf => 'Tiến hóa thành Dạng Lá';

  @override
  String get spiritEvolutionConditions => 'Điều Kiện Tiến Hóa';

  @override
  String get spiritReachLevel15 => 'Đạt Cấp 15';

  @override
  String get spiritBondRequirement => 'Độ Gắn Kết Đạt Yêu Cầu';

  @override
  String get spiritMet => 'Đạt';

  @override
  String get spiritEvolveNow => 'Tiến Hóa Ngay';

  @override
  String get spiritMaxEvolution =>
      'Lumina đã đạt dạng tiến hóa tối đa hiện tại!';

  @override
  String get spiritEvolving => 'Đang Tiến Hóa...';

  @override
  String get storySlide1 =>
      'Bạn nhặt được một chiếc máy thám hiểm không gian cũ. Bên trong là một \'Mầm Ánh Sáng\'...';

  @override
  String get storySlide2 =>
      '...đó là một sinh vật Lumina đến từ một hành tinh đã mất đi trọng lực.';

  @override
  String get storySlide3 =>
      'Để sinh tồn và lớn lên, Lumina cần hấp thụ Sinh Mệnh Lực từ những bước đi của con người.';

  @override
  String get storySlide4 =>
      'Lumina không cần bạn chiến đấu, nó chỉ muốn đồng hành cùng bạn trong những chuyến đi dạo đời thực để ngắm nhìn thế giới này.';

  @override
  String get profileEditGenderMale => 'Nam';

  @override
  String get profileEditGenderFemale => 'Nữ';

  @override
  String get profileEditGenderOther => 'Khác';

  @override
  String friendsRequestSentTo(String name) {
    return 'Đã gửi lời mời tới $name!';
  }

  @override
  String get friendsRequestSendFailed =>
      'Không thể gửi lời mời. Vui lòng thử lại sau.';

  @override
  String get friendsRequestAlreadySent =>
      'Bạn đã gửi lời mời cho người này rồi!';

  @override
  String get friendsAlreadyFriend => 'Hai bạn đã là bạn bè rồi!';

  @override
  String get friendsPlayerNotFound => 'Không tìm thấy người chơi này.';

  @override
  String get friendProfileTitle => 'Hồ sơ Lữ hành giả';

  @override
  String get friendProfileTraveler => 'Lữ hành giả';

  @override
  String get friendProfileUnknownPlayer => 'Người chơi ẩn danh';

  @override
  String get friendProfileCompanion => 'Linh hồn đồng hành';

  @override
  String get friendProfileStats => 'Thống kê';

  @override
  String get friendProfileAchievements => 'Thành tựu nổi bật';

  @override
  String friendProfileSpiritName(String name) {
    return 'Spirit: $name';
  }

  @override
  String get friendProfileViewStats => 'Xem thống kê';

  @override
  String friendProfileSpiritMeta(String type, int level) {
    return '$type - Cấp $level';
  }

  @override
  String get friendProfileNoSpirit => 'Chưa có tinh linh';

  @override
  String get friendProfileSpiritTypeUnknown => 'Chưa rõ hệ';

  @override
  String get friendProfileTotalSteps => 'Tổng bước đi';

  @override
  String get friendProfileStreak => 'Chuỗi ngày';

  @override
  String get friendProfileEnergy => 'Năng lượng';

  @override
  String get friendProfileBond => 'Gắn kết';

  @override
  String get friendProfileLifeForce => 'Sinh mệnh lực';

  @override
  String get friendProfileExp => 'EXP';

  @override
  String get friendProfileUnavailable => '--';

  @override
  String get friendProfileAchievementsUnavailable =>
      'Dữ liệu thành tựu chưa sẵn sàng.';

  @override
  String get friendProfileLoadFailed => 'Không thể tải hồ sơ người chơi này.';

  @override
  String get friendProfileRequestSentTitle => 'Đã gửi lời mời!';

  @override
  String friendProfileRequestSentMessage(String name) {
    return 'Lời mời kết bạn đã được gửi đến $name. Cùng nhau tích bước nhé!';
  }

  @override
  String get friendProfileGreat => 'Tuyệt vời';

  @override
  String get friendSpiritTitle => 'Thống kê tinh linh';

  @override
  String get feedbackWaitBeforeRetry => 'Vui lòng đợi trước khi gửi lại.';

  @override
  String get feedbackSendFailed =>
      'Gửi phản hồi thất bại. Vui lòng thử lại sau.';

  @override
  String get friendSpiritNoData => 'Không có dữ liệu Spirit bạn bè.';

  @override
  String friendSpiritOfName(String userName) {
    return 'Spirit của $userName';
  }

  @override
  String friendSpiritLevel(int level) {
    return 'Cấp $level';
  }

  @override
  String get friendSpiritStatsTitle => 'Chỉ Số';

  @override
  String get friendSpiritEvolutionTitle => 'Tiến Hóa';

  @override
  String get friendSpiritExp => 'Kinh Nghiệm (EXP)';

  @override
  String get friendSpiritLifeForce => 'Sinh Mệnh Lực (Life Force)';

  @override
  String get friendSpiritBonding => 'Độ Gắn Kết (Bond)';

  @override
  String get friendSpiritEnergy => 'Năng Lượng (Energy)';

  @override
  String get friendSpiritCurrentStage => 'GIAI ĐOẠN HIỆN TẠI';

  @override
  String get friendSpiritCurrentProperty =>
      'Thuộc tính hiện năng được ghi nhận';

  @override
  String get friendSpiritEvolutionStages => 'GIAI ĐOẠN TIẾN HÓA';

  @override
  String get friendSpiritMilestones => 'LỊCH SỬ DẤU MỐC';

  @override
  String friendSpiritReachLevel(int level) {
    return 'Đạt cấp độ $level';
  }

  @override
  String get friendSpiritRecently => 'Gần đây';

  @override
  String get friendSpiritBeginJourney => 'Bắt đầu hành trình Walkamon';

  @override
  String get friendSpiritInit => 'Khởi tạo';

  @override
  String get friendSpiritStageSeedling => 'Mầm Non';

  @override
  String get friendSpiritStageSprout => 'Chồi Non';

  @override
  String get friendSpiritStageLeaf => 'Lá Xanh';
}

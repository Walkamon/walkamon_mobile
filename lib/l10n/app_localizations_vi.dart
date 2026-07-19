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
}

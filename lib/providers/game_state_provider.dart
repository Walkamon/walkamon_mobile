import 'package:flutter/foundation.dart';

import '../core/auth/token_storage.dart';
import '../core/utils/login_screen_error_translator.dart';
import '../data/repositories/login_screen_repository.dart';
import '../data/repositories/setting_screen_repository.dart';
import '../data/repositories/profile_view_screen_repository.dart';

class GameUser {
  const GameUser({
    required this.name,
    required this.level,
    required this.coins,
    this.email = '',
    this.id = '',
    this.joinDate = 'Tháng 6, 2026',
    // ── THÊM MỚI: Các trường thực tế từ DB Walkamon ──
    this.bio = '',
    this.gender = 'Chưa rõ',
    this.dob = 'Chưa cập nhật',
    this.avatarUrl = '',
  });

  final String name;
  final int level;
  final int coins;
  final String email;
  final String id;
  final String joinDate;
  // ── THÊM MỚI ──
  final String bio;
  final String gender;
  final String dob;
  final String avatarUrl;

  GameUser copyWith({
    String? name,
    int? level,
    int? coins,
    String? email,
    String? id,
    String? joinDate,
    String? bio,
    String? gender,
    String? dob,
    String? avatarUrl,
  }) {
    return GameUser(
      name: name ?? this.name,
      level: level ?? this.level,
      coins: coins ?? this.coins,
      email: email ?? this.email,
      id: id ?? this.id,
      joinDate: joinDate ?? this.joinDate,
      bio: bio ?? this.bio,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}

class GameSettings {
  const GameSettings({
    this.darkMode = true,
    this.soundEnabled = true,
    this.notifications = true,
    this.languageCode = 'vi-VN',
  });

  final bool darkMode;
  final bool soundEnabled;
  final bool notifications;
  final String languageCode;

  GameSettings copyWith({
    bool? darkMode,
    bool? soundEnabled,
    bool? notifications,
    String? languageCode,
  }) {
    return GameSettings(
      darkMode: darkMode ?? this.darkMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      notifications: notifications ?? this.notifications,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}

class GameStateProvider extends ChangeNotifier {
  final LoginScreenRepository _loginRepository = LoginScreenRepository();
  final SettingScreenRepository _settingRepository = SettingScreenRepository();
  final ProfileViewScreenRepository _profileRepository;

  GameStateProvider(this._profileRepository);

  GameUser? _user;
  GameSettings _settings = const GameSettings();
  int _bondingLevel = 0;
  bool _hasSeenStory = false;

  bool _isLoading = false;
  String? _errorMessage;

  bool _isProfileLoading = false;
  String? _profileErrorMessage;

  GameUser? get user => _user;
  GameSettings get settings => _settings;
  bool get isAuthenticated => _user != null;
  int get bondingLevel => _bondingLevel;
  bool get hasSeenStory => _hasSeenStory;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isProfileLoading => _isProfileLoading;
  String? get profileErrorMessage => _profileErrorMessage;

  void setUser(GameUser? user) {
    _user = user;
    notifyListeners();
  }

  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _loginRepository.login(
      email: email,
      password: password,
    );

    _isLoading = false;

    if (response.success && response.data != null) {
      // Đăng nhập thành công -> Map data từ LoginResponse vào GameUser cũ
      TokenStorage.setToken(response.data!.token);

      _user = GameUser(
        id: response.data!.userId ?? '0',
        name: response.data!.username ?? 'Lữ Hành Giả',
        email: email,
        level: 1,
        coins: 0,
        joinDate: 'Chưa có dữ liệu',
      );

      notifyListeners();
      return true;
    } else {
      _errorMessage = translateError(response.message);
      notifyListeners();
      return false;
    }
  }

  Future<bool> googleLogin({required String idToken}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _loginRepository.googleLogin(idToken: idToken);

    _isLoading = false;

    if (response.success && response.data != null) {
      TokenStorage.setToken(response.data!.token);

      _user = GameUser(
        id: response.data!.userId ?? '0',
        name: response.data!.username ?? 'Lữ Hành Giả',
        email: '',
        level: 1,
        coins: 0,
        joinDate: 'Chưa có dữ liệu',
      );

      notifyListeners();
      return true;
    } else {
      _errorMessage = translateError(response.message);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _settingRepository.logout();
    } catch (e) {
      // Bỏ qua lỗi gọi API
    }

    TokenStorage.clear();
    _user = null;
    _profileErrorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  // ── Nhận dữ liệu trực tiếp từ Repository ──
  Future<bool> fetchProfileDetail() async {
    _isProfileLoading = true;
    _profileErrorMessage = null;
    notifyListeners();

    try {
      // Gọi Repo trả thẳng về Model ProfileViewResponse sạch sẽ
      final profileData = await _profileRepository.getUserProfile();
      _isProfileLoading = false;

      // Đồng bộ nạp dữ liệu từ DB thực tế vào đối tượng GameUser hiện tại
      _user = GameUser(
        name: profileData.username,
        level: _user?.level ?? 1, // Cày cuốc từ hệ thống game
        coins: _user?.coins ?? 0, // Đồng bộ từ ví tiền wallets
        email: profileData.email,
        id: _user?.id ?? '',
        joinDate: profileData.createdAt.isNotEmpty
            ? profileData.createdAt
            : 'Chưa có dữ liệu',
        bio: profileData.bio,
        gender: profileData.gender,
        dob: profileData.formattedDob,
        avatarUrl: profileData.avatarUrl,
      );

      // Cập nhật cấu hình ứng dụng từ profile_settings người dùng lưu trong DB
      _settings = _settings.copyWith(
        // Tạm thời comment dòng này lại để khi fetch API Profile không bị ghi đè theme hiện tại của app
        // darkMode: profileData.themeCode == 'dark',
        notifications: profileData.notificationsEnabled,
        languageCode: profileData.languageCode,
      );

      _hasSeenStory = profileData.hasSeenStory;

      notifyListeners();
      return true;
    } catch (e) {
      _isProfileLoading = false;
      // Dịch lỗi nếu e là chuỗi hoặc dùng lỗi hệ thống mặc định
      _profileErrorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  void setLanguageCode(String languageCode) {
    _settings = _settings.copyWith(languageCode: languageCode);
    notifyListeners();
  }



  // ── THÊM MỚI: Xử lý lưu thông tin chỉnh sửa hồ sơ lên API & RAM ──
  Future<bool> updateProfile({
    required String name,
    required String gender,
    required DateTime dob,
    required String bio,
    String? localAvatarPath,
    Uint8List? imageBytes,
  }) async {
    _isProfileLoading = true;
    _profileErrorMessage = null;
    notifyListeners();

    try {
      final cleanBio = bio.trim().isEmpty ? "Chưa cập nhật" : bio.trim();
      // Định dạng ngày sinh sang chuỗi yyyy-MM-dd để Backend C# nhận diện đúng kiểu dữ liệu
      final dobStringForApi =
          "${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}";

      // Định dạng dd/MM/yyyy giúp gán trực tiếp vào GameUser hiển thị ngay lên UI không bị lệch format
      final dobStringForUi =
          "${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}";

      // Gọi repository đẩy dữ liệu cập nhật xuống datasource
      await _profileRepository.updateUserProfile(
        username: name,
        gender: gender,
        dob: dobStringForApi,
        bio: cleanBio,
        // localAvatarPath: localAvatarPath, // (Bật lên nếu repo nhận path)
        imageBytes: imageBytes, // (Bật lên nếu repo nhận bytes)
      );

      _isProfileLoading = false;

      // Cập nhật nóng vào RAM cục bộ để toàn bộ màn hình Game thay đổi tức thì mà không cần reload app
      if (_user != null) {
        _user = _user!.copyWith(
          name: name,
          bio: bio,
          gender: gender,
          dob: dobStringForUi,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      _isProfileLoading = false;
      _profileErrorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<bool> sendFeedback({
    required String content,
    required String feedbackTypeCode,
  }) async {
    // Deprecated: simple bool. Newer implementation handled below in sendFeedbackWithCooldown.
    try {
      final response = await _settingRepository.sendFeedback(
        content: content,
        feedbackTypeCode: feedbackTypeCode,
      );
      return response.success;
    } catch (_) {
      return false;
    }
  }

  // Result object for feedback send attempts

  // Sends feedback with backend-enforced 24-hour cooldown.
  Future<FeedbackResult> sendFeedbackWithCooldown({
    required String content,
    required String feedbackTypeCode,
  }) async {
    try {
      final response = await _settingRepository.sendFeedback(
        content: content,
        feedbackTypeCode: feedbackTypeCode,
      );

      if (response.success) {
        return FeedbackResult(success: true);
      }

      final message = response.message.isNotEmpty
          ? response.message
          : 'Gửi phản hồi thất bại.';

      final isCooldownError =
          response.status == 400 &&
          (message.toLowerCase().contains('24') ||
              message.toLowerCase().contains('24 giờ') ||
              message.toLowerCase().contains('24 hours'));

      return FeedbackResult(
        success: false,
        message: message,
        retryAfter: isCooldownError ? const Duration(hours: 24) : null,
      );
    } catch (e) {
      return FeedbackResult(success: false, message: e.toString());
    }
  }

  void updateSettings({
    bool? darkMode,
    bool? soundEnabled,
    bool? notifications,
  }) {
    _settings = _settings.copyWith(
      darkMode: darkMode,
      soundEnabled: soundEnabled,
      notifications: notifications,
    );
    notifyListeners();
  }

  void increaseBonding() {
    if (_bondingLevel < 100) {
      _bondingLevel++;
      notifyListeners();
    }
  }

  void setHasSeenStory(bool seen) {
    _hasSeenStory = seen;
    notifyListeners();
  }

  bool canAfford(int price) => _user != null && _user!.coins >= price;

  int get coins => _user?.coins ?? 1240;

  Future<bool> buyShopItem({required int price}) async {
    if (_user == null || _user!.coins < price) return false;

    _user = _user!.copyWith(coins: _user!.coins - price);
    notifyListeners();
    return true;
  }


}

class FeedbackResult {
  final bool success;
  final String? message;
  final Duration? retryAfter;

  FeedbackResult({required this.success, this.message, this.retryAfter});
}

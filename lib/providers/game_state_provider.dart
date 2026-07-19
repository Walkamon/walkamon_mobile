import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/auth/token_storage.dart';
import '../core/l10n/locale_helper.dart';
import '../core/utils/login_screen_error_translator.dart';
import '../data/repositories/login_screen_repository.dart';
import '../data/repositories/setting_screen_repository.dart';
import '../data/repositories/profile_view_screen_repository.dart';
import '../data/repositories/pet_screen_repository.dart';
import '../data/repositories/notification_repository.dart';
import '../data/services/fcm_service.dart';

class GameUser {
  const GameUser({
    required this.name,
    required this.level,
    required this.coins,
    this.email = '',
    this.id = '',
    this.joinDate = 'Tháng 6, 2026',
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
    this.notifications = true, // Đã có sẵn thuộc tính notifications[cite: 5]
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
  static const _languageCodeKey = 'language_code';

  final LoginScreenRepository _loginRepository = LoginScreenRepository();
  final SettingScreenRepository _settingRepository = SettingScreenRepository();
  final ProfileViewScreenRepository _profileRepository;
  final PetScreenRepository _petRepository;

  final FCMService _fcmService;

  // ── THÊM MỚI: Khai báo Notification Repository ──
  final NotificationRepository _notificationRepository;

  // ── THÊM MỚI: Yêu cầu NotificationRepository khi khởi tạo Provider ──
  GameStateProvider(
    this._profileRepository,
    this._notificationRepository,
    this._fcmService,
    this._petRepository,
  ) {
    _loadSavedLanguage();
  }

  GameUser? _user;
  GameSettings _settings = const GameSettings();
  int _bondingLevel = 50;
  int _spiritLevel = 1;
  int _spiritExp = 25;
  int _spiritEnergy = 62;
  int _spiritHealth = 70;
  String _spiritName = 'Lumina';
  String _spiritInfo = 'Lumina Spirit đang sẵn sàng khám phá.';
  bool _hasSeenStory = false;

  bool _isLoading = false;
  String? _errorMessage;

  bool _isProfileLoading = false;
  String? _profileErrorMessage;

  GameUser? get user => _user;
  GameSettings get settings => _settings;
  Locale get locale => LocaleHelper.localeFromCode(_settings.languageCode);
  bool get isAuthenticated => _user != null;
  int get bondingLevel => _bondingLevel;
  int get spiritLevel => _spiritLevel;
  int get spiritExp => _spiritExp;
  int get spiritEnergy => _spiritEnergy;
  int get spiritHealth => _spiritHealth;
  String get spiritName => _spiritName;
  String get spiritInfo => _spiritInfo;
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
      _fcmService.setupToken();
      return true;
    } else {
      _errorMessage = translateError(response.message);
      notifyListeners();
      return false;
    }
  }

  Future<bool> tryAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();

      // Kiểm tra xem có key hay không
      if (!prefs.containsKey('access_token')) {
        print(
          "[AutoLogin] Không tìm thấy key 'access_token' trong SharedPreferences!",
        );
        return false;
      }

      final token = prefs.getString('access_token');
      if (token == null || token.isEmpty) {
        print("[AutoLogin] Token tìm thấy bị rỗng hoặc null!");
        return false;
      }

      print(
        "AutoLogin] Tìm thấy Token: ${token.substring(0, token.length > 10 ? 10 : token.length)}...",
      );
      TokenStorage.setToken(token);

      final restoredUserId =
          prefs.getString('user_id') ?? _userIdFromJwt(token);
      if (restoredUserId != null && restoredUserId.isNotEmpty) {
        await prefs.setString('user_id', restoredUserId);
        _user = GameUser(id: restoredUserId, name: '', level: 1, coins: 0);
      }

      print("[AutoLogin] Đang gọi fetchProfileDetail()...");
      final successFetch = await fetchProfileDetail();

      if (successFetch) {
        print("[AutoLogin] Tự động đăng nhập THÀNH CÔNG!");
        _fcmService.setupToken();
        return true;
      } else {
        print(
          "[AutoLogin] Gọi fetchProfileDetail() THẤT BẠI (Token có thể hết hạn)!",
        );
        await logout();
        return false;
      }
    } catch (e) {
      print("[AutoLogin] Lỗi hệ thống khi tự động đăng nhập: $e");
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
      _fcmService.setupToken();
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
      await _fcmService.deactivateToken();
    } catch (e) {
      debugPrint('Huỷ FCM Token thất bại: $e');
    }

    try {
      // 1. Gọi API logout lên server trước khi xóa token
      await _settingRepository.logout();
    } catch (e) {
      // Bỏ qua lỗi gọi API
    }

    // 2. Xóa token dưới thiết bị
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_id');

    // 3. Xóa token trên RAM và reset trạng thái app
    TokenStorage.clear();
    _user = null;
    _profileErrorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> fetchProfileDetail() async {
    _isProfileLoading = true;
    _profileErrorMessage = null;
    notifyListeners();

    try {
      final profileData = await _profileRepository.getUserProfile();
      _isProfileLoading = false;

      _user = GameUser(
        name: profileData.username,
        level: _user?.level ?? 1,
        coins: _user?.coins ?? 0,
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

      _settings = _settings.copyWith(
        notifications: profileData.notificationsEnabled,
        languageCode: profileData.languageCode,
      );

      _hasSeenStory = profileData.hasSeenStory;

      notifyListeners();
      return true;
    } catch (e) {
      _isProfileLoading = false;
      _profileErrorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageCodeKey);
      if (savedLanguage == null || savedLanguage.isEmpty) return;
      if (savedLanguage == _settings.languageCode) return;

      _settings = _settings.copyWith(languageCode: savedLanguage);
      notifyListeners();
    } catch (e) {
      debugPrint('Không thể tải ngôn ngữ đã lưu: $e');
    }
  }

  Future<void> setLanguageCode(String languageCode) async {
    _settings = _settings.copyWith(languageCode: languageCode);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageCodeKey, languageCode);
    } catch (e) {
      debugPrint('Không thể lưu ngôn ngữ: $e');
    }
  }

  // ── THÊM MỚI: Hàm xử lý Bật/Tắt Notification gọi xuống Backend ──
  Future<void> setNotificationsEnabled(bool value) async {
    // 1. Lấy giá trị cũ từ biến private _settings
    final oldValue = _settings.notifications;

    // 2. Cập nhật State ngay lập tức vào _settings để giao diện phản hồi mượt mà
    _settings = _settings.copyWith(notifications: value);
    notifyListeners();

    try {
      // 3. Gửi request lên server
      await _notificationRepository.updateNotification(value);
    } catch (e) {
      // 4. Hoàn tác lại giá trị cũ vào _settings nếu API báo lỗi
      _settings = _settings.copyWith(notifications: oldValue);
      notifyListeners();

      debugPrint('Cập nhật thông báo thất bại: $e');
    }
  }

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
      final dobStringForApi =
          "${dob.year}-${dob.month.toString().padLeft(2, '0')}-${dob.day.toString().padLeft(2, '0')}";

      final dobStringForUi =
          "${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}";

      await _profileRepository.updateUserProfile(
        username: name,
        gender: gender,
        dob: dobStringForApi,
        bio: cleanBio,
        imageBytes: imageBytes,
      );

      _isProfileLoading = false;

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

  // ── Fetch Pet Status from API ──
  Future<bool> fetchPetStatus() async {
    try {
      final petStatus = await _petRepository.getPetStatus();

      // Map API response to local state
      _spiritEnergy = petStatus.currentEnergy;
      _spiritHealth = petStatus.currentLifeForce;
      _bondingLevel = petStatus.currentBond;

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Lỗi khi tải trạng thái thú cưng: $e');
      return false;
    }
  }

  // ── Feed Spirit with API call ──
  Future<bool> feedSpirit() async {
    try {
      final result = await _petRepository.feedSpirit();

      // Update local state from API response
      _spiritEnergy = result.currentEnergy;
      _spiritHealth = result.currentLifeForce;
      _bondingLevel = result.currentBond;
      _spiritExp = (_spiritExp + 10).clamp(0, 100);
      _adjustSpiritLevel();

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Lỗi khi cho thú cưng ăn: $e');
      return false;
    }
  }

  // ── Tap Spirit with API call ──
  Future<bool> tapSpirit() async {
    try {
      final result = await _petRepository.tapSpirit();

      // Update local state from API response
      _spiritEnergy = result.currentEnergy;
      _spiritHealth = result.currentLifeForce;
      _bondingLevel = result.currentBond;
      _spiritExp = (_spiritExp + 3).clamp(0, 100);
      _adjustSpiritLevel();

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Lỗi khi nhấp vào thú cưng: $e');
      return false;
    }
  }

  void _adjustSpiritLevel() {
    if (_spiritExp >= 100) {
      _spiritExp -= 100;
      _spiritLevel++;
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

  String? _userIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map) return null;
      const claimNames = [
        'sub',
        'nameid',
        'userId',
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier',
      ];
      for (final claim in claimNames) {
        final value = payload[claim]?.toString();
        if (value != null && value.isNotEmpty) return value;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

class FeedbackResult {
  final bool success;
  final String? message;
  final Duration? retryAfter;

  FeedbackResult({required this.success, this.message, this.retryAfter});
}

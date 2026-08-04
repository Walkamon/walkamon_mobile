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
    this.darkMode = false,
    this.soundEnabled = true,
    this.backgroundMusicEnabled = true,
    this.notifications = false,
    this.languageCode = 'vi-VN',
  });

  final bool darkMode;
  final bool soundEnabled;
  final bool backgroundMusicEnabled;
  final bool notifications;
  final String languageCode;

  GameSettings copyWith({
    bool? darkMode,
    bool? soundEnabled,
    bool? backgroundMusicEnabled,
    bool? notifications,
    String? languageCode,
  }) {
    return GameSettings(
      darkMode: darkMode ?? this.darkMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      backgroundMusicEnabled:
          backgroundMusicEnabled ?? this.backgroundMusicEnabled,
      notifications: notifications ?? this.notifications,
      languageCode: languageCode ?? this.languageCode,
    );
  }
}

enum PetFeedFailureReason {
  none,
  busy,
  fullLifeForce,
  limitReached,
  insufficientDew,
  failed,
}

class GameStateProvider extends ChangeNotifier {
  static const _languageCodeKey = 'language_code';
  static const _notificationPreferenceKeyPrefix =
      'notifications_enabled_for_user_';

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
  bool _hasStarterPet = false;
  bool _hasSeenStory = false;
  bool _hasCompletedStoryThisSession = false;
  bool _hasLocalLanguagePreference = false;

  String _affinityCode = 'sprout';
  int _petStageNo = 0;
  String _animationType = 'idle';
  String _petStageName = '';

  bool _isLoading = false;
  String? _errorMessage;

  bool _isProfileLoading = false;
  bool _isUpdatingNotifications = false;
  bool _isFeedingSpirit = false;
  PetFeedFailureReason _lastFeedFailure = PetFeedFailureReason.none;
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
  bool get hasStarterPet => _hasStarterPet;
  bool get hasSeenStory => _hasSeenStory;
  bool get hasCompletedStoryThisSession => _hasCompletedStoryThisSession;
  String get affinityCode => _affinityCode;
  int get petStageNo => _petStageNo;
  String get animationType => _animationType;
  String get petStageName => _petStageName;
  PetScreenRepository get petRepository => _petRepository;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get isProfileLoading => _isProfileLoading;
  bool get isUpdatingNotifications => _isUpdatingNotifications;
  bool get isFeedingSpirit => _isFeedingSpirit;
  PetFeedFailureReason get lastFeedFailure => _lastFeedFailure;
  String? get profileErrorMessage => _profileErrorMessage;

  void setUser(GameUser? user) {
    _user = user;
    notifyListeners();
  }

  void _resetAccountScopedState() {
    debugPrint(
      '[AccountState] Resetting pet/profile state before account swap',
    );
    _user = null;
    _settings = _settings.copyWith(notifications: false);
    _bondingLevel = 50;
    _spiritLevel = 1;
    _spiritExp = 25;
    _spiritEnergy = 62;
    _spiritHealth = 70;
    _spiritName = 'Lumina';
    _spiritInfo = 'Lumina Spirit đang sẵn sàng khám phá.';
    _hasStarterPet = false;
    _hasSeenStory = false;
    _hasCompletedStoryThisSession = false;
    _affinityCode = 'sprout';
    _petStageNo = 0;
    _animationType = 'idle';
    _petStageName = '';
    _isFeedingSpirit = false;
    _lastFeedFailure = PetFeedFailureReason.none;
    _isProfileLoading = false;
    _profileErrorMessage = null;
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
      _resetAccountScopedState();

      final resolvedUserId =
          response.data!.userId ?? _userIdFromJwt(response.data!.token) ?? '';
      await _persistResolvedUserId(resolvedUserId);

      _user = GameUser(
        id: resolvedUserId,
        name: response.data!.username ?? 'Lữ Hành Giả',
        email: email,
        level: 1,
        coins: 0,
        joinDate: 'Chưa có dữ liệu',
      );

      notifyListeners();
      await fetchProfileDetail();
      await _synchronizeNotificationsAfterLogin();
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
        await _synchronizeNotificationsAfterLogin();
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
      _resetAccountScopedState();

      final resolvedUserId =
          response.data!.userId ?? _userIdFromJwt(response.data!.token) ?? '';
      await _persistResolvedUserId(resolvedUserId);

      _user = GameUser(
        id: resolvedUserId,
        name: response.data!.username ?? 'Lữ Hành Giả',
        email: '',
        level: 1,
        coins: 0,
        joinDate: 'Chưa có dữ liệu',
      );

      notifyListeners();
      await fetchProfileDetail();
      await _synchronizeNotificationsAfterLogin();
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

    // 2. Xóa token dưới thiết bị và trên RAM ngay lập tức
    await TokenStorage.clearAuthData();

    // 3. Reset trạng thái app
    _resetAccountScopedState();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> fetchProfileDetail() async {
    _isProfileLoading = true;
    _profileErrorMessage = null;
    notifyListeners();

    try {
      final profileData = await _profileRepository.getUserProfile();
      final preferredLanguageCode = await _preferredLanguageCode(
        profileData.languageCode,
      );
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
        languageCode: preferredLanguageCode,
      );

      // The dedicated Pet story-status endpoint is authoritative for routing.
      // Keep the profile value only as a temporary fallback if that request fails.
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

  Future<String> _preferredLanguageCode(String serverLanguageCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageCodeKey);
      if (savedLanguage != null && savedLanguage.isNotEmpty) {
        _hasLocalLanguagePreference = true;
        return savedLanguage;
      }
    } catch (e) {
      debugPrint('KhÃ´ng thá»ƒ Ä‘á»c ngÃ´n ngá»¯ Ä‘Ã£ lÆ°u: $e');
    }

    if (_hasLocalLanguagePreference && _settings.languageCode.isNotEmpty) {
      return _settings.languageCode;
    }
    if (serverLanguageCode.isNotEmpty) return serverLanguageCode;
    if (_settings.languageCode.isNotEmpty) return _settings.languageCode;
    return const GameSettings().languageCode;
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageCodeKey);
      if (savedLanguage == null || savedLanguage.isEmpty) return;
      _hasLocalLanguagePreference = true;
      if (savedLanguage == _settings.languageCode) return;

      _settings = _settings.copyWith(languageCode: savedLanguage);
      notifyListeners();
    } catch (e) {
      debugPrint('Không thể tải ngôn ngữ đã lưu: $e');
    }
  }

  Future<void> setLanguageCode(String languageCode) async {
    _hasLocalLanguagePreference = true;
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
  String? get _notificationPreferenceKey {
    final userId = _user?.id.trim() ?? '';
    final email = _user?.email.trim().toLowerCase() ?? '';
    final accountKey = userId.isNotEmpty && userId != '0' ? userId : email;
    if (accountKey.isEmpty) return null;
    return _notificationPreferenceKeyPrefix + accountKey;
  }

  Future<void> _saveNotificationPreference(bool enabled) async {
    final key = _notificationPreferenceKey;
    if (key == null) return;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(key, enabled);
      debugPrint('[NotificationFlow][State] local_preference_saved=$enabled');
    } catch (error) {
      debugPrint('Cannot save notification preference: $error');
    }
  }

  Future<void> _synchronizeNotificationsAfterLogin() async {
    final key = _notificationPreferenceKey;
    bool? savedPreference;
    if (key != null) {
      try {
        final preferences = await SharedPreferences.getInstance();
        savedPreference = preferences.getBool(key);
      } catch (error) {
        debugPrint('Cannot read notification preference: $error');
      }
    }

    final accountLabel = (_user?.id.isNotEmpty ?? false) && _user?.id != '0'
        ? _user!.id
        : 'email_fallback';
    debugPrint(
      '[NotificationFlow][State] login_sync account=$accountLabel '
      'saved_preference=$savedPreference first_device_login=${savedPreference == null}',
    );

    // First login for this account on this device: request OS permission.
    await _applyNotificationPreference(savedPreference ?? true);
  }

  Future<bool> setNotificationsEnabled(bool value) {
    debugPrint(
      '[NotificationFlow][Toggle] user_requested=$value '
      'current=${_settings.notifications}',
    );
    return _applyNotificationPreference(value);
  }

  Future<bool> _applyNotificationPreference(bool requestedValue) async {
    if (_isUpdatingNotifications) {
      debugPrint(
        '[NotificationFlow][State] request_ignored=update_in_progress',
      );
      return _settings.notifications;
    }

    debugPrint(
      '[NotificationFlow][State] apply_started requested=$requestedValue '
      'current=${_settings.notifications}',
    );
    final oldValue = _settings.notifications;
    _isUpdatingNotifications = true;
    notifyListeners();

    try {
      if (requestedValue) {
        final permissionGranted = await _fcmService.setupToken();
        debugPrint(
          '[NotificationFlow][State] device_activation=$permissionGranted',
        );
        if (!permissionGranted) {
          _settings = _settings.copyWith(notifications: false);
          await _saveNotificationPreference(false);
          try {
            await _notificationRepository.updateNotification(false);
            debugPrint(
              '[NotificationFlow][Backend] notifications_enabled=false '
              'reason=permission_denied',
            );
          } catch (error) {
            debugPrint(
              'Cannot synchronize denied notification permission: $error',
            );
          }
          return false;
        }

        try {
          await _notificationRepository.updateNotification(true);
          debugPrint('[NotificationFlow][Backend] notifications_enabled=true');
          _settings = _settings.copyWith(notifications: true);
          await _saveNotificationPreference(true);
          return true;
        } catch (error) {
          await _fcmService.deactivateToken();
          _settings = _settings.copyWith(notifications: false);
          await _saveNotificationPreference(false);
          debugPrint('Cannot enable notifications on server: $error');
          return false;
        }
      }

      try {
        await _notificationRepository.updateNotification(false);
        debugPrint(
          '[NotificationFlow][Backend] notifications_enabled=false '
          'reason=user_toggle',
        );
        await _fcmService.deactivateToken();
        _settings = _settings.copyWith(notifications: false);
        await _saveNotificationPreference(false);
        return true;
      } catch (error) {
        _settings = _settings.copyWith(notifications: oldValue);
        debugPrint('Cannot disable notifications: $error');
        return false;
      }
    } finally {
      _isUpdatingNotifications = false;
      debugPrint(
        '[NotificationFlow][State] apply_finished '
        'toggle=${_settings.notifications}',
      );
      notifyListeners();
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
      final cleanBio = bio.trim();
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
    bool? backgroundMusicEnabled,
    bool? notifications,
  }) {
    _settings = _settings.copyWith(
      darkMode: darkMode,
      soundEnabled: soundEnabled,
      backgroundMusicEnabled: backgroundMusicEnabled,
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

  /// Loads affinity/stage/animation from `/api/pet/me` + current-animation.
  Future<bool> fetchPetVisual() async {
    try {
      final overview = await _petRepository.getPetOverview();
      final code = overview.affinityCode.trim();
      if (code.isNotEmpty) {
        _affinityCode = code;
      }
      _petStageNo = overview.stageNo;
      if (overview.animationType.trim().isNotEmpty) {
        _animationType = overview.animationType.trim();
      }
      if (overview.nickname.trim().isNotEmpty) {
        _spiritName = overview.nickname.trim();
        _hasStarterPet = true;
      }
      if (overview.formName.trim().isNotEmpty) {
        _spiritInfo = '${overview.formName} đang sẵn sàng khám phá.';
      }
      if (overview.level > 0) {
        _spiritLevel = overview.level;
      }
      _spiritExp = overview.currentExp;
      _spiritEnergy = overview.currentEnergy;
      _spiritHealth = overview.currentLifeForce;
      _bondingLevel = overview.currentBond;

      try {
        final anim = await _petRepository.getCurrentAnimation();
        if (anim.animationType.trim().isNotEmpty) {
          _animationType = anim.animationType.trim();
        }
        if (anim.stageNo > 0) {
          _petStageNo = anim.stageNo;
        }
        if (anim.stageName.trim().isNotEmpty) {
          _petStageName = anim.stageName.trim();
          _spiritInfo = '${anim.stageName} · $_animationType';
        }
        final fromUrl = _affinityFromAnimationUrl(anim.animationUrl);
        if (fromUrl != null) {
          _affinityCode = fromUrl;
        }
      } catch (e) {
        debugPrint('Lỗi khi tải animation hiện tại: $e');
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Lỗi khi tải visual thú cưng: $e');
      return false;
    }
  }

  String? _affinityFromAnimationUrl(String url) {
    final normalized = url.trim();
    if (normalized.isEmpty) return null;
    final withoutScheme = normalized.replaceFirst(RegExp(r'^asset://'), '');
    final parts = withoutScheme.split('/');
    if (parts.length < 2) return null;
    final code = parts[1].trim().toLowerCase();
    const known = {'sprout', 'warm_sun', 'dawn', 'moonlight'};
    return known.contains(code) ? code : null;
  }

  Future<bool> preparePetForHome() async {
    debugPrint('[AccountState] Preparing pet data before opening Home');
    final hasPet = await fetchPetName();
    if (!hasPet) {
      debugPrint('[AccountState] Home preparation stopped: no pet');
      return false;
    }

    final results = await Future.wait<bool>([
      fetchPetStatus(),
      fetchPetVisual(),
    ]);
    debugPrint(
      '[AccountState] Home preparation complete '
      'status=${results[0]} visual=${results[1]} '
      'affinity=$_affinityCode stage=$_petStageNo',
    );
    return true;
  }

  Future<bool> fetchPetName() async {
    try {
      final petName = await _petRepository.getPetName();
      final hasName = petName?.hasName ?? false;

      _hasStarterPet = hasName;
      if (hasName) {
        _spiritName = petName!.petName.trim();
      }

      notifyListeners();
      return hasName;
    } catch (e) {
      debugPrint('Lỗi khi tải tên thú cưng: $e');
      return false;
    }
  }

  Future<bool> createStarterPet(String petName) async {
    try {
      final createdPet = await _petRepository.createStarterPet(petName.trim());
      final resolvedName = createdPet?.petName.trim();

      if (resolvedName != null && resolvedName.isNotEmpty) {
        _spiritName = resolvedName;
      } else {
        _spiritName = petName.trim();
      }

      // Creating/naming the starter pet is the final onboarding action. The
      // backend persists HasSeenStory as part of this successful operation.
      _hasStarterPet = true;
      _hasSeenStory = true;
      _hasCompletedStoryThisSession = false;
      notifyListeners();

      try {
        final serverSeen = await _petRepository.getStoryStatus();
        debugPrint('[Onboarding] story-status after pet creation: $serverSeen');
        if (serverSeen && !_hasSeenStory) {
          _hasSeenStory = true;
          notifyListeners();
        }
      } catch (error) {
        debugPrint(
          '[Onboarding] could not confirm story-status after pet creation: '
          '$error',
        );
      }
      return true;
    } catch (e) {
      debugPrint('Lỗi khi tạo thú cưng khởi đầu: $e');
      return false;
    }
  }

  // ── Feed Spirit with API call ──
  Future<bool> feedSpirit() async {
    if (_isFeedingSpirit) {
      _lastFeedFailure = PetFeedFailureReason.busy;
      return false;
    }

    if (_spiritHealth >= 100) {
      _lastFeedFailure = PetFeedFailureReason.fullLifeForce;
      return false;
    }

    _isFeedingSpirit = true;
    _lastFeedFailure = PetFeedFailureReason.none;
    try {
      final previousEnergy = _spiritEnergy;
      final previousLifeForce = _spiritHealth;
      final previousBond = _bondingLevel;
      final result = await _petRepository.feedSpirit();

      debugPrint(
        '[PetFeed] Energy: $previousEnergy -> ${result.currentEnergy}; '
        'LifeForce: $previousLifeForce -> ${result.currentLifeForce}; '
        'Bond: $previousBond -> ${result.currentBond}',
      );

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
      final message = e.toString().toLowerCase();
      if (message.contains('life force') ||
          message.contains('lifeforce') ||
          message.contains('sinh mệnh lực')) {
        _lastFeedFailure = PetFeedFailureReason.fullLifeForce;
      } else if ((e is PetFeedException && e.status == 429) ||
          message.contains('limit') ||
          message.contains('too many') ||
          message.contains('cooldown') ||
          message.contains('maximum') ||
          message.contains('rate limit') ||
          message.contains('giới hạn')) {
        _lastFeedFailure = PetFeedFailureReason.limitReached;
      } else if (message.contains('insufficient') ||
          message.contains('not enough') ||
          message.contains('balance') ||
          message.contains('wallet') ||
          message.contains('không đủ')) {
        _lastFeedFailure = PetFeedFailureReason.insufficientDew;
      } else {
        _lastFeedFailure = PetFeedFailureReason.failed;
      }
      return false;
    } finally {
      _isFeedingSpirit = false;
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

  Future<void> _persistResolvedUserId(String userId) async {
    if (userId.isEmpty) return;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString('user_id', userId);
  }

  Future<bool> loadHasSeenStory() async {
    try {
      final serverSeen = await _petRepository.getStoryStatus();
      if (serverSeen != _hasSeenStory) {
        _hasSeenStory = serverSeen;
        notifyListeners();
      }
      debugPrint(
        '[Onboarding] GET /api/Pet/story-status => $serverSeen '
        'account=${_user?.id ?? ''}',
      );
      return serverSeen;
    } catch (error) {
      debugPrint(
        '[Onboarding] story-status request failed; using profile fallback '
        '($_hasSeenStory): $error',
      );
      return _hasSeenStory;
    }
  }

  void markStoryCompletedForCurrentFlow() {
    if (_hasCompletedStoryThisSession) return;
    _hasCompletedStoryThisSession = true;
    debugPrint(
      '[Onboarding] story completed in this session; waiting for pet name '
      'before marking it seen',
    );
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

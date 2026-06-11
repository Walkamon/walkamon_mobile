import 'package:flutter/foundation.dart';

import '../core/auth/token_storage.dart';
import '../core/utils/login_screen_error_translator.dart';
import '../data/repositories/login_screen_repository.dart';
import '../data/repositories/setting_screen_repository.dart';

class GameUser {
  const GameUser({
    required this.name,
    required this.level,
    required this.steps,
    required this.coins,
  });

  final String name;
  final int level;
  final int steps;
  final int coins;
}

class GameSettings {
  const GameSettings({
    this.darkMode = false,
    this.soundEnabled = true,
    this.notifications = true,
  });

  final bool darkMode;
  final bool soundEnabled;
  final bool notifications;

  GameSettings copyWith({
    bool? darkMode,
    bool? soundEnabled,
    bool? notifications,
  }) {
    return GameSettings(
      darkMode: darkMode ?? this.darkMode,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      notifications: notifications ?? this.notifications,
    );
  }
}

class GameStateProvider extends ChangeNotifier {
  final LoginScreenRepository _loginRepository = LoginScreenRepository();
  final SettingScreenRepository _settingRepository = SettingScreenRepository();

  GameUser? _user;
  GameSettings _settings = const GameSettings();
  int _bondingLevel = 0;
  bool _hasSeenStory = false;

  bool _isLoading = false;
  String? _errorMessage;

  GameUser? get user => _user;
  GameSettings get settings => _settings;
  bool get isAuthenticated => _user != null;
  int get bondingLevel => _bondingLevel;
  bool get hasSeenStory => _hasSeenStory;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setUser(GameUser? user) {
    _user = user;
    notifyListeners();
  }

  // Chuyển thành Future<bool> và nhận diện dữ liệu email, password từ UI truyền xuống
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final response = await _loginRepository.login(
      email: email,
      password: password,
    );

    _isLoading = false;

    // Kiểm tra dựa trên flag 'success' và 'data' từ cấu trúc ApiResponse thực tế của bạn
    if (response.success && response.data != null) {
      // Đăng nhập thành công -> Map data từ LoginResponse vào GameUser cũ
      TokenStorage.setToken(response.data!.token);
      _user = GameUser(
        name:
            response.data!.username ??
            'Walker',
        level: 12,
        steps: 12000,
        coins: 1500,
      );
      notifyListeners();
      return true;
    } else {
      // Đọc chính xác thuộc tính 'message' từ ApiResponse để mang đi thông dịch sang tiếng Việt
      _errorMessage = translateError(response.message);
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _settingRepository.logout();

    TokenStorage.clear();
    _user = null;
    _isLoading = false;
    notifyListeners();
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

    _user = GameUser(
      name: _user!.name,
      level: _user!.level,
      steps: _user!.steps,
      coins: _user!.coins - price,
    );
    notifyListeners();
    return true;
  }
}

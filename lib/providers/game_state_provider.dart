import 'package:flutter/foundation.dart';

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
  GameUser? _user;
  GameSettings _settings = const GameSettings();
  int _bondingLevel = 0;
  bool _hasSeenStory = false;

  GameUser? get user => _user;
  GameSettings get settings => _settings;
  bool get isAuthenticated => _user != null;
  int get bondingLevel => _bondingLevel;
  bool get hasSeenStory => _hasSeenStory;

  void setUser(GameUser? user) {
    _user = user;
    notifyListeners();
  }

  void login() {
    _user = const GameUser(
      name: 'Walker',
      level: 12,
      steps: 12000,
      coins: 1500,
    );
    notifyListeners();
  }

  void logout() {
    _user = null;
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
}

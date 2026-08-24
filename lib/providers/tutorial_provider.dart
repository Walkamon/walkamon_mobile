import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HomeTutorialStep { pet, feed, stats, steps, missions, complete }

enum PvpTutorialStep {
  lobby,
  matchmaking,
  race,
  items,
  finish,
  result,
  complete,
}

/// Versioned, account-scoped tutorial progress.
///
/// Home is opt-in: only the successful Name Pet flow marks an account as
/// eligible. This prevents an update from forcing onboarding over existing
/// players. PvP starts contextually the first time an eligible account opens
/// its waiting room and can always be replayed from Settings.
class TutorialProvider extends ChangeNotifier {
  TutorialProvider({SharedPreferences? preferences})
    : _preferences = preferences;

  static const int homeVersion = 1;
  static const int pvpVersion = 1;
  static const String _prefix = 'walkamon.tutorial';

  SharedPreferences? _preferences;
  String? _accountKey;
  bool _loaded = false;
  bool _homeEligible = false;
  HomeTutorialStep _homeStep = HomeTutorialStep.complete;
  PvpTutorialStep _pvpStep = PvpTutorialStep.complete;

  bool get isLoaded => _loaded;
  String? get accountKey => _accountKey;
  bool get homeEligible => _homeEligible;
  HomeTutorialStep get homeStep => _homeStep;
  PvpTutorialStep get pvpStep => _pvpStep;
  bool get shouldShowHome =>
      _loaded && _homeEligible && _homeStep != HomeTutorialStep.complete;
  bool get shouldShowPvp =>
      _loaded && _homeEligible && _pvpStep != PvpTutorialStep.complete;

  String _key(String suffix) => '$_prefix.${_accountKey!}.$suffix';

  Future<void> synchronizeAccount(String? rawAccountKey) async {
    final normalized = rawAccountKey?.trim();
    if (normalized == null || normalized.isEmpty) {
      if (_accountKey == null && _loaded) return;
      _accountKey = null;
      _loaded = true;
      _homeEligible = false;
      _homeStep = HomeTutorialStep.complete;
      _pvpStep = PvpTutorialStep.complete;
      notifyListeners();
      return;
    }
    if (_accountKey == normalized && _loaded) return;

    _accountKey = normalized;
    final requestedAccount = normalized;
    final prefs = _preferences ??= await SharedPreferences.getInstance();
    if (_accountKey != requestedAccount) return;
    final eligible =
        prefs.getBool(_key('home.v$homeVersion.eligible')) ?? false;
    final homeIndex = prefs.getInt(_key('home.v$homeVersion.step'));
    final pvpIndex = prefs.getInt(_key('pvp.v$pvpVersion.step'));

    _homeEligible = eligible;
    _homeStep = eligible
        ? _homeStepFromIndex(homeIndex ?? 0)
        : HomeTutorialStep.complete;
    // PvP is available only to accounts that entered through the new-player
    // Home tutorial flow. Existing accounts can opt in via Settings replay.
    _pvpStep = eligible
        ? _pvpStepFromIndex(pvpIndex ?? 0)
        : PvpTutorialStep.complete;
    _loaded = true;
    notifyListeners();
  }

  Future<void> markNewPlayerEligible(String rawAccountKey) async {
    final account = rawAccountKey.trim();
    if (account.isEmpty) return;
    await synchronizeAccount(account);
    final prefs = _preferences ??= await SharedPreferences.getInstance();
    _homeEligible = true;
    _homeStep = HomeTutorialStep.pet;
    _pvpStep = PvpTutorialStep.lobby;
    await Future.wait([
      prefs.setBool(_key('home.v$homeVersion.eligible'), true),
      prefs.setInt(_key('home.v$homeVersion.step'), _homeStep.index),
      prefs.setInt(_key('pvp.v$pvpVersion.step'), _pvpStep.index),
    ]);
    notifyListeners();
  }

  Future<void> advanceHome(HomeTutorialStep expected) async {
    if (!_loaded || !_homeEligible || _homeStep != expected) return;
    _homeStep =
        HomeTutorialStep.values[(_homeStep.index + 1).clamp(
          0,
          HomeTutorialStep.values.length - 1,
        )];
    await _persistHome();
    notifyListeners();
  }

  Future<void> advancePvp(PvpTutorialStep expected) async {
    if (!_loaded || !_homeEligible || _pvpStep != expected) return;
    _pvpStep =
        PvpTutorialStep.values[(_pvpStep.index + 1).clamp(
          0,
          PvpTutorialStep.values.length - 1,
        )];
    await _persistPvp();
    notifyListeners();
  }

  Future<void> enterPvpRaceContext() async {
    if (!shouldShowPvp || _pvpStep.index >= PvpTutorialStep.race.index) return;
    _pvpStep = PvpTutorialStep.race;
    await _persistPvp();
    notifyListeners();
  }

  Future<void> enterPvpResultContext() async {
    if (!shouldShowPvp || _pvpStep.index >= PvpTutorialStep.result.index) {
      return;
    }
    _pvpStep = PvpTutorialStep.result;
    await _persistPvp();
    notifyListeners();
  }

  Future<void> enterPvpFinishContext() async {
    if (!shouldShowPvp || _pvpStep.index >= PvpTutorialStep.finish.index) {
      return;
    }
    _pvpStep = PvpTutorialStep.finish;
    await _persistPvp();
    notifyListeners();
  }

  Future<void> skipHome() async {
    if (!_loaded || _accountKey == null) return;
    _homeStep = HomeTutorialStep.complete;
    await _persistHome();
    notifyListeners();
  }

  Future<void> skipPvp() async {
    if (!_loaded || _accountKey == null) return;
    _pvpStep = PvpTutorialStep.complete;
    await _persistPvp();
    notifyListeners();
  }

  Future<void> replayHome() async {
    if (!_loaded || _accountKey == null) return;
    _homeEligible = true;
    _homeStep = HomeTutorialStep.pet;
    final prefs = _preferences ??= await SharedPreferences.getInstance();
    await prefs.setBool(_key('home.v$homeVersion.eligible'), true);
    await _persistHome();
    notifyListeners();
  }

  Future<void> replayPvp() async {
    if (!_loaded || _accountKey == null) return;
    _homeEligible = true;
    _pvpStep = PvpTutorialStep.lobby;
    final prefs = _preferences ??= await SharedPreferences.getInstance();
    await prefs.setBool(_key('home.v$homeVersion.eligible'), true);
    await _persistPvp();
    notifyListeners();
  }

  Future<void> _persistHome() async {
    if (_accountKey == null) return;
    final prefs = _preferences ??= await SharedPreferences.getInstance();
    await prefs.setInt(_key('home.v$homeVersion.step'), _homeStep.index);
  }

  Future<void> _persistPvp() async {
    if (_accountKey == null) return;
    final prefs = _preferences ??= await SharedPreferences.getInstance();
    await prefs.setInt(_key('pvp.v$pvpVersion.step'), _pvpStep.index);
  }

  static HomeTutorialStep _homeStepFromIndex(int index) =>
      HomeTutorialStep.values[index.clamp(
        0,
        HomeTutorialStep.values.length - 1,
      )];

  static PvpTutorialStep _pvpStepFromIndex(int index) =>
      PvpTutorialStep.values[index.clamp(0, PvpTutorialStep.values.length - 1)];
}

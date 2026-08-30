import 'package:flutter/foundation.dart';
import '../core/network/app_failure.dart';
import '../data/repositories/daily_login_repository.dart';
import '../data/models/daily_login_model.dart';

class DailyLoginProvider extends ChangeNotifier {
  final DailyLoginRepository _repository;

  DailyLoginProvider(this._repository);

  bool _isLoading = false;
  String? _errorMessage;
  AppFailure? _failure;
  DailyLoginCalendarData? _calendarData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AppFailure? get failure => _failure;
  DailyLoginCalendarData? get calendarData => _calendarData;

  Future<void> loadDailyLoginStatus() async {
    _isLoading = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    try {
      _calendarData = await _repository.getDailyLoginStatus();
      _failure = null;
      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _failure = e is AppFailure
          ? e
          : const AppFailure(code: 'UNEXPECTED_RESPONSE', status: 0);
      _errorMessage = _failure!.fallbackMessage;
      notifyListeners();
    }
  }

  Future<ClaimDailyRewardData?> claimReward() async {
    if (_isLoading) return null;

    _isLoading = true;
    _errorMessage = null;
    _failure = null;
    notifyListeners();

    try {
      final data = await _repository.claimDailyReward();

      await loadDailyLoginStatus();

      return data; // Trả về object dữ liệu thành công
    } catch (e) {
      // print('Vị trí lỗi (Stack Trace):\n$stackTrace');
      _isLoading = false;
      _failure = e is AppFailure
          ? e
          : const AppFailure(code: 'UNEXPECTED_RESPONSE', status: 0);
      _errorMessage = _failure!.fallbackMessage;
      notifyListeners();
      return null; // Trả về null nếu xảy ra lỗi
    }
  }
}

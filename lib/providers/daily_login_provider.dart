import 'package:flutter/foundation.dart';
import '../data/repositories/daily_login_repository.dart';
import '../data/models/daily_login_model.dart';

class DailyLoginProvider extends ChangeNotifier {
  final DailyLoginRepository _repository;

  DailyLoginProvider(this._repository);

  bool _isLoading = false;
  String? _errorMessage;
  DailyLoginCalendarData? _calendarData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DailyLoginCalendarData? get calendarData => _calendarData;

  Future<void> loadDailyLoginStatus() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _calendarData = await _repository.getDailyLoginStatus();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<ClaimDailyRewardData?> claimReward() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final data = await _repository.claimDailyReward();

      await loadDailyLoginStatus();

      return data; // Trả về object dữ liệu thành công
    } catch (e, stackTrace) {
      // print('Vị trí lỗi (Stack Trace):\n$stackTrace');
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null; // Trả về null nếu xảy ra lỗi
    }
  }
}

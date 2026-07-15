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

  Future<bool> claimReward() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _repository.claimDailyReward();
      if (success) {
        // Tải lại list sau khi claim thành công
        await loadDailyLoginStatus();
        
        // Bạn có thể cân nhắc cập nhật lại số coin trong GameStateProvider tại đây
        // _gameStateProvider.fetchProfileDetail(); // ví dụ
        return true;
      }
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}

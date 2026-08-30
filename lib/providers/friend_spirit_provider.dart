import 'package:flutter/material.dart';
import '../core/network/app_failure.dart';
import '../data/models/friend_spirit_response.dart';
import '../data/repositories/friend_spirit_repository.dart';

class FriendSpiritProvider extends ChangeNotifier {
  final FriendSpiritRepository _repository;

  FriendSpiritProvider(this._repository);

  FriendSpiritResponse? _friendSpirit;
  bool _isLoading = false;
  String _errorMessage = '';
  AppFailure? _failure;

  FriendSpiritResponse? get friendSpirit => _friendSpirit;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  AppFailure? get failure => _failure;

  Future<void> fetchFriendSpirit(String friendUserId) async {
    _isLoading = true;
    _errorMessage = '';
    _failure = null;
    notifyListeners();

    try {
      final response = await _repository.getFriendSpirit(friendUserId);
      _friendSpirit = response;
      _failure = null;
    } catch (e) {
      _failure = e is AppFailure
          ? e
          : const AppFailure(code: 'UNEXPECTED_RESPONSE', status: 0);
      _errorMessage = _failure!.fallbackMessage;
      _friendSpirit = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

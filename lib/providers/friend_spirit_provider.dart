import 'package:flutter/material.dart';
import '../data/models/friend_spirit_response.dart';
import '../data/repositories/friend_spirit_repository.dart';

class FriendSpiritProvider extends ChangeNotifier {
  final FriendSpiritRepository _repository;

  FriendSpiritProvider(this._repository);

  FriendSpiritResponse? _friendSpirit;
  bool _isLoading = false;
  String _errorMessage = '';

  FriendSpiritResponse? get friendSpirit => _friendSpirit;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  Future<void> fetchFriendSpirit(String friendUserId) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _repository.getFriendSpirit(friendUserId);
      _friendSpirit = response;
    } catch (e) {
      _errorMessage = e.toString().replaceAll("Exception: ", "");
      _friendSpirit = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

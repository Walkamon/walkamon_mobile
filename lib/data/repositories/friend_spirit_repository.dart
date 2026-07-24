import '../datasources/remote/friend_spirit_datasource.dart';
import '../models/friend_spirit_response.dart';

class FriendSpiritRepository {
  final FriendSpiritDatasource remoteDatasource;

  FriendSpiritRepository({required this.remoteDatasource});

  Future<FriendSpiritResponse> getFriendSpirit(String friendUserId) async {
    try {
      return await remoteDatasource.getFriendSpirit(friendUserId);
    } catch (e) {
      rethrow;
    }
  }
}

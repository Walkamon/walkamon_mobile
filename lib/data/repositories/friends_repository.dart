import '../datasources/remote/friends_datasource.dart';
import '../models/friends_response.dart';

class FriendsRepository {
  final FriendsDatasource datasource;

  FriendsRepository(this.datasource);

  // Thêm hàm lấy danh sách gợi ý
  Future<List<FriendsResponse>> getAvailableUsers() {
    return datasource.getAvailableUsers();
  }

  Future<void> removeFriend(String friendId) {
    return datasource.removeFriend(friendId);
  }

  Future<List<FriendsResponse>> getFriends() {
    return datasource.getFriends();
  }

  Future<List<FriendRequestResponse>> getReceivedFriendRequests() {
    return datasource.getReceivedFriendRequests();
  }

  Future<void> respondToFriendRequest(String requestId, bool isAccepted) {
    return datasource.respondToFriendRequest(requestId, isAccepted);
  }

  Future<List<FriendsResponse>> searchPlayers(String query) {
    return datasource.searchPlayers(query);
  }

  Future<void> sendFriendRequest(String receiverId) {
    return datasource.sendFriendRequest(receiverId);
  }

  Future<List<FriendRequestResponse>> getSentFriendRequests() {
    return datasource.getSentFriendRequests();
  }

  Future<void> cancelFriendRequest(String requestId) {
    return datasource.cancelFriendRequest(requestId);
  }
}

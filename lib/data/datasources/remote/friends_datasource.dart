import '../../models/friends_response.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class FriendsDatasource {
  final ApiClient apiClient;

  FriendsDatasource(this.apiClient);

  Future<void> removeFriend(String friendId) async {
    try {
      final response = await apiClient.delete(
        ApiConstants.removeFriend(friendId),
      );

      if (!response.success &&
          !response.message.toLowerCase().contains('success')) {
        throw Exception(
          response.message.isNotEmpty
              ? response.message
              : "Xóa bạn bè thất bại",
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<FriendsResponse>> getFriends() async {
    try {
      final response = await apiClient.get<List<FriendsResponse>>(
        ApiConstants.friends,
        fromJsonT: (json) {
          if (json is List) {
            return json
                .map(
                  (e) => FriendsResponse.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList();
          }
          return [];
        },
      );
      return response.data ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<FriendRequestResponse>> getReceivedFriendRequests() async {
    try {
      final response = await apiClient.get<List<FriendRequestResponse>>(
        ApiConstants.receivedFriendRequests,
        fromJsonT: (json) {
          if (json is List) {
            return json
                .map(
                  (e) => FriendRequestResponse.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList();
          }
          return [];
        },
      );
      return response.data ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> respondToFriendRequest(String requestId, bool isAccepted) async {
    try {
      final response = await apiClient.put(
        ApiConstants.respondToFriendRequest(requestId),
        data: {'isAccepted': isAccepted}, // Payload chuẩn theo backend của bạn
      );

      if (!response.success &&
          !response.message.toLowerCase().contains("success")) {
        throw Exception(
          response.message.isNotEmpty ? response.message : "Thao tác thất bại",
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<FriendRequestResponse>> getSentFriendRequests() async {
    try {
      final response = await apiClient.get<List<FriendRequestResponse>>(
        ApiConstants.sentFriendRequests,
        fromJsonT: (json) {
          if (json is List) {
            return json
                .map(
                  (e) => FriendRequestResponse.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList();
          }
          return [];
        },
      );
      return response.data ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> cancelFriendRequest(String requestId) async {
    try {
      final response = await apiClient.delete(
        ApiConstants.cancelFriendRequest(requestId),
      );

      if (!response.success &&
          !response.message.toLowerCase().contains('success')) {
        throw Exception(
          response.message.isNotEmpty
              ? response.message
              : "Hủy yêu cầu kết bạn thất bại",
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<FriendsResponse>> getAvailableUsers() async {
    try {
      final response = await apiClient.get<List<FriendsResponse>>(
        ApiConstants.searchPlayers,
        fromJsonT: (json) {
          if (json is List) {
            return json
                .map(
                  (e) => FriendsResponse.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList();
          }
          return [];
        },
      );

      return response.data ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<FriendsResponse>> searchPlayers(String query) async {
    try {
      final response = await apiClient.get<List<FriendsResponse>>(
        ApiConstants.searchPlayers,
        queryParameters: {'q': query},
        fromJsonT: (json) {
          if (json is List) {
            final allUsers = json
                .map(
                  (e) => FriendsResponse.fromJson(
                    Map<String, dynamic>.from(e as Map),
                  ),
                )
                .toList();

            if (query.isNotEmpty) {
              return allUsers.where((user) {
                return user.username.toLowerCase().contains(
                  query.toLowerCase(),
                );
              }).toList();
            }

            return allUsers;
          }
          return [];
        },
      );

      return response.data ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<void> sendFriendRequest(String receiverId) async {
    final response = await apiClient.post(
      ApiConstants.sendFriendRequest,
      data: {'receiverUserId': receiverId},
    );
    if (!response.success && !response.message.contains("successfully")) {
      throw Exception(
        response.message.isNotEmpty ? response.message : "Gửi lời mời thất bại",
      );
    }
  }
}

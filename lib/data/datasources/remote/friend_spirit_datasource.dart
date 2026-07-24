import '../../models/friend_spirit_response.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

class FriendSpiritDatasource {
  final ApiClient apiClient;

  FriendSpiritDatasource(this.apiClient);

  Future<FriendSpiritResponse> getFriendSpirit(String friendUserId) async {
    try {
      final response = await apiClient.get<FriendSpiritResponse>(
        ApiConstants.friendPet(friendUserId),
        fromJsonT: (json) {
          return FriendSpiritResponse.fromJson(json as Map<String, dynamic>);
        },
      );

      if (response.data == null) {
        throw Exception("Không thể tải thông tin Spirit của bạn bè.");
      }

      return response.data!;
    } catch (e) {
      rethrow;
    }
  }
}

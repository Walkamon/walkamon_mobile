import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../models/friend_profile_response.dart';

class FriendProfileDatasource {
  FriendProfileDatasource(this._apiClient);

  final ApiClient _apiClient;

  Future<ApiResponse<FriendProfileResponse>> getFriendProfile(
    String userId,
  ) {
    return _apiClient.get<FriendProfileResponse>(
      ApiConstants.friendProfile(userId),
      fromJsonT: (json) =>
          FriendProfileResponse.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }

  Future<ApiResponse<FriendSpiritResponse>> getFriendSpirit(
    String friendUserId,
  ) {
    return _apiClient.get<FriendSpiritResponse>(
      ApiConstants.friendPet(friendUserId),
      fromJsonT: (json) =>
          FriendSpiritResponse.fromJson(Map<String, dynamic>.from(json as Map)),
    );
  }
}

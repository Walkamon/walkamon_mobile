import '../datasources/remote/friend_profile_datasource.dart';
import '../models/friend_profile_response.dart';

class FriendProfileRepository {
  FriendProfileRepository(this._datasource);

  final FriendProfileDatasource _datasource;

  Future<FriendPlayerProfile> getFriendPlayerProfile(String userId) async {
    FriendProfileResponse? profile;
    FriendSpiritResponse? spirit;
    Object? profileError;
    Object? spiritError;

    try {
      final response = await _datasource.getFriendProfile(userId);
      if (response.success) {
        profile = response.data;
      } else {
        profileError = response.message;
      }
    } catch (e) {
      profileError = e;
    }

    try {
      final response = await _datasource.getFriendSpirit(userId);
      if (response.success) {
        spirit = response.data;
      } else {
        spiritError = response.message;
      }
    } catch (e) {
      spiritError = e;
    }

    if (profile == null && spirit == null) {
      throw Exception(profileError ?? spiritError ?? 'Friend profile not found');
    }

    return FriendPlayerProfile(userId: userId, profile: profile, spirit: spirit);
  }

  Future<FriendSpiritResponse> getFriendSpirit(String userId) async {
    final response = await _datasource.getFriendSpirit(userId);
    if (response.success && response.data != null) return response.data!;

    throw Exception(
      response.message.isNotEmpty
          ? response.message
          : 'Friend spirit not found',
    );
  }
}

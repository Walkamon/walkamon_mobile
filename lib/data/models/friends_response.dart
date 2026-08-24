class FriendsResponse {
  final String userId;
  final String username;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final bool isOnline;

  /// Trạng thái PvP: 'available' | 'busy' | 'offline'
  /// Backend tính khi trả response dựa trên PvpPresenceTracker.
  final String pvpAvailabilityCode;

  FriendsResponse({
    required this.userId,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.isOnline = false,
    this.pvpAvailabilityCode = 'offline',
  });

  factory FriendsResponse.fromJson(Map<String, dynamic> json) {
    final online =
        json['isOnline'] == true ||
        json['is_online'] == true ||
        json['online'] == true ||
        json['status'] == 'online' ||
        json['status'] == 'Online' ||
        json['isUserOnline'] == true;

    // pvpAvailabilityCode do backend trả, fallback theo isOnline nếu field chưa có
    final rawCode =
        json['pvpAvailabilityCode'] as String? ??
        json['pvp_availability_code'] as String?;
    final pvpCode = rawCode?.isNotEmpty == true
        ? rawCode!
        : (online ? 'available' : 'offline');

    return FriendsResponse(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      bio: json['bio'],
      isOnline: online,
      pvpAvailabilityCode: pvpCode,
    );
  }

  /// Bạn bè có thể bị thách đấu: online và không bận
  bool get isPvpAvailable => isOnline && pvpAvailabilityCode == 'available';

  /// Bạn bè online nhưng đang bận (trong trận hoặc invite đang pending)
  bool get isPvpBusy => isOnline && pvpAvailabilityCode == 'busy';

  /// Tạo bản sao với presence mới (để cập nhật từ SignalR presence.changed)
  FriendsResponse copyWithPresence({
    required bool isOnline,
    required String pvpAvailabilityCode,
  }) {
    return FriendsResponse(
      userId: userId,
      username: username,
      email: email,
      avatarUrl: avatarUrl,
      bio: bio,
      isOnline: isOnline,
      pvpAvailabilityCode: pvpAvailabilityCode,
    );
  }
}

class FriendRequestResponse {
  final String requestId;
  final String statusCode;
  final String createdAt;
  final FriendsResponse user;

  FriendRequestResponse({
    required this.requestId,
    required this.statusCode,
    required this.createdAt,
    required this.user,
  });

  factory FriendRequestResponse.fromJson(Map<String, dynamic> json) {
    return FriendRequestResponse(
      requestId: json['requestId'] ?? '',
      statusCode: json['statusCode'] ?? '',
      createdAt: json['createdAt'] ?? '',
      user: FriendsResponse.fromJson(
        Map<String, dynamic>.from(json['user'] ?? {}),
      ),
    );
  }
}

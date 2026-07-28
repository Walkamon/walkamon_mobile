class FriendsResponse {
  final String userId;
  final String username;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final bool isOnline;

  FriendsResponse({
    required this.userId,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.bio,
    this.isOnline = false,
  });

  factory FriendsResponse.fromJson(Map<String, dynamic> json) {
    return FriendsResponse(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      bio: json['bio'],
      isOnline: json['isOnline'] == true ||
          json['is_online'] == true ||
          json['online'] == true ||
          json['status'] == 'online' ||
          json['status'] == 'Online' ||
          json['isUserOnline'] == true,
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

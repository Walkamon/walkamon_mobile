class FriendsResponse {
  final String userId;
  final String username;
  final String email;
  final String? avatarUrl;

  FriendsResponse({
    required this.userId,
    required this.username,
    required this.email,
    this.avatarUrl,
  });

  factory FriendsResponse.fromJson(Map<String, dynamic> json) {
    return FriendsResponse(
      userId: json['userId'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
    );
  }
}

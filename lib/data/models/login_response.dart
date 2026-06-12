class LoginResponse {
  final String token;
  final String? username;
  final String? userId;

  LoginResponse({required this.token, this.username, this.userId});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      // Map đúng key từ API trả về (ví dụ: 'token' hoặc 'jwt')
      token: json['token'] ?? json['jwt'] ?? '',
      username: json['username'] ?? json['user']?['username'],
      userId: json['userId'] ?? json['user']?['id']?.toString(),
    );
  }
}

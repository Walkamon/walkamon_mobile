class ProfileViewResponse {
  final String email;
  final String username;
  final String bio;
  final String gender;
  final DateTime? dob;
  final String avatarUrl;
  final String languageCode;
  final String themeCode;
  final bool hasSeenStory;
  final bool notificationsEnabled;
  final String createdAt;

  ProfileViewResponse({
    required this.email,
    required this.username,
    required this.bio,
    required this.gender,
    this.dob,
    required this.avatarUrl,
    required this.languageCode,
    required this.themeCode,
    required this.hasSeenStory,
    required this.notificationsEnabled,
    required this.createdAt,
  });

  factory ProfileViewResponse.fromJson(Map<String, dynamic> json) {
    return ProfileViewResponse(
      email: (json['email'] as String?)?.trim() ?? '',
      username: (json['username'] as String?)?.trim() ?? '',
      // Keep an empty bio empty so the UI can render the localized fallback.
      bio: (json['bio'] as String?)?.trim() ?? '',
      gender: (json['gender'] as String?)?.trim() ?? '',
      dob: json['dob'] != null ? DateTime.parse(json['dob']) : null,
      avatarUrl: json['avatarUrl'] ?? '',
      languageCode: json['languageCode'] ?? 'vi-VN',
      themeCode: (json['themeCode'] ?? 'light').toString().toLowerCase(),
      hasSeenStory: json['hasSeenStory'] ?? false,
      notificationsEnabled: json['notificationsEnabled'] ?? true,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }

  String get formattedDob {
    if (dob == null) return '';
    return '${dob!.day.toString().padLeft(2, '0')}/${dob!.month.toString().padLeft(2, '0')}/${dob!.year}';
  }
}

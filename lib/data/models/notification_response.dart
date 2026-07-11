class NotificationResponse {
  final bool notificationsEnabled;
  final DateTime? updatedAt;

  NotificationResponse({required this.notificationsEnabled, this.updatedAt});

  factory NotificationResponse.fromJson(Map<String, dynamic> json) {
    return NotificationResponse(
      notificationsEnabled: json['notificationsEnabled'] ?? false,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }
}

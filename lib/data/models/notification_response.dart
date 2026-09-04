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

class NotificationItem {
  final String notificationId;
  final String title;
  final String shortBody;
  final DateTime createdAt;
  bool isRead;
  final String? typeCode;
  final String? contentCode;
  final Map<String, dynamic> params;

  NotificationItem({
    required this.notificationId,
    required this.title,
    required this.shortBody,
    required this.createdAt,
    required this.isRead,
    this.typeCode,
    this.contentCode,
    this.params = const {},
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      notificationId: json['notificationId']?.toString() ?? '',
      title: json['title'] ?? '', //[cite: 2]
      shortBody: json['shortBody'] ?? '', //[cite: 2]
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false, //[cite: 2]
      typeCode: json['typeCode'], //[cite: 2]
      contentCode: json['contentCode']?.toString(),
      params: json['params'] is Map
          ? Map<String, dynamic>.from(json['params'] as Map)
          : const {},
    );
  }
}

class NotificationDetail {
  final String notificationId;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? typeCode;
  final String? icon;
  final String? imageUrl;
  final bool isRead;
  final DateTime? readAt;
  final String? contentCode;
  final Map<String, dynamic> params;

  NotificationDetail({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.createdAt,
    this.typeCode,
    this.icon,
    this.imageUrl,
    required this.isRead,
    this.readAt,
    this.contentCode,
    this.params = const {},
  });

  factory NotificationDetail.fromJson(Map<String, dynamic> json) {
    return NotificationDetail(
      notificationId: json['notificationId']?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      typeCode: json['typeCode'],
      icon: json['icon'],
      imageUrl: json['imageUrl'],
      isRead: json['isRead'] ?? false,
      readAt: json['readAt'] != null ? DateTime.parse(json['readAt']) : null,
      contentCode: json['contentCode']?.toString(),
      params: json['params'] is Map
          ? Map<String, dynamic>.from(json['params'] as Map)
          : const {},
    );
  }
}

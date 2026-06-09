class ItemResponse {
  final String itemId;
  final String itemName;
  final String itemTypeName;
  final String? effectTypeCode;
  final int? effectValue;
  final bool isActive;

  ItemResponse({
    required this.itemId,
    required this.itemName,
    required this.itemTypeName,
    this.effectTypeCode,
    this.effectValue,
    required this.isActive,
  });

  factory ItemResponse.fromJson(Map<String, dynamic> json) {
    return ItemResponse(
      itemId: json['itemId'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      itemTypeName: json['itemTypeName'] as String? ?? '',
      effectTypeCode: json['effectTypeCode'] as String?,
      effectValue: json['effectValue'] as int?,
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'itemTypeName': itemTypeName,
      'effectTypeCode': effectTypeCode,
      'effectValue': effectValue,
      'isActive': isActive,
    };
  }
}

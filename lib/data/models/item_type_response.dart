class ItemTypeResponse {
  final String itemTypeId;
  final String itemTypeName;

  ItemTypeResponse({
    required this.itemTypeId,
    required this.itemTypeName,
  });

  factory ItemTypeResponse.fromJson(Map<String, dynamic> json) {
    return ItemTypeResponse(
      itemTypeId: json['itemTypeId'] as String? ?? '',
      itemTypeName: json['itemTypeName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemTypeId': itemTypeId,
      'itemTypeName': itemTypeName,
    };
  }
}

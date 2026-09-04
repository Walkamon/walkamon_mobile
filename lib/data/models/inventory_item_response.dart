class InventoryItemResponse {
  final String itemId;
  final String itemName;
  final String itemTypeName;
  final String? image;
  final String? effectTypeCode;
  final int? effectValue;
  final String? description;
  final String usageContextCode;
  final bool canUseNow;
  final bool canEquipForPvp;
  final String? itemNameVi;
  final String? itemNameEn;
  final String? descriptionVi;
  final String? descriptionEn;
  final int quantity;

  InventoryItemResponse({
    required this.itemId,
    required this.itemName,
    required this.itemTypeName,
    this.image,
    this.effectTypeCode,
    this.effectValue,
    this.description,
    this.usageContextCode = 'none',
    this.canUseNow = false,
    this.canEquipForPvp = false,
    this.itemNameVi,
    this.itemNameEn,
    this.descriptionVi,
    this.descriptionEn,
    required this.quantity,
  });

  factory InventoryItemResponse.fromJson(Map<String, dynamic> json) {
    return InventoryItemResponse(
      itemId: json['itemId'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      itemTypeName: json['itemTypeName'] as String? ?? '',
      image: json['image'] as String?,
      effectTypeCode: json['effectTypeCode'] as String?,
      effectValue: json['effectValue'] is int
          ? json['effectValue'] as int
          : int.tryParse('${json['effectValue']}'),
      description: json['description'] as String?,
      usageContextCode: json['usageContextCode']?.toString() ?? 'none',
      canUseNow: json['canUseNow'] as bool? ?? false,
      canEquipForPvp: json['canEquipForPvp'] as bool? ?? false,
      itemNameVi: json['itemNameVi']?.toString(),
      itemNameEn: json['itemNameEn']?.toString(),
      descriptionVi: json['descriptionVi']?.toString(),
      descriptionEn: json['descriptionEn']?.toString(),
      quantity: json['quantity'] is int
          ? json['quantity'] as int
          : int.tryParse('${json['quantity']}') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'itemTypeName': itemTypeName,
      'image': image,
      'effectTypeCode': effectTypeCode,
      'effectValue': effectValue,
      'description': description,
      'usageContextCode': usageContextCode,
      'canUseNow': canUseNow,
      'canEquipForPvp': canEquipForPvp,
      'itemNameVi': itemNameVi,
      'itemNameEn': itemNameEn,
      'descriptionVi': descriptionVi,
      'descriptionEn': descriptionEn,
      'quantity': quantity,
    };
  }
}

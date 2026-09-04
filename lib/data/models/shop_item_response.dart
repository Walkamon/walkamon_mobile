class ShopItemResponse {
  final String shopItemId;
  final String? itemId;
  final String itemName;
  final int priceAmount;
  final bool isActive;
  final String? image;
  final String? itemTypeName;
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

  ShopItemResponse({
    required this.shopItemId,
    this.itemId,
    required this.itemName,
    required this.priceAmount,
    required this.isActive,
    this.image,
    this.itemTypeName,
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
  });

  factory ShopItemResponse.fromJson(Map<String, dynamic> json) {
    return ShopItemResponse(
      shopItemId: json['shopItemId'] as String? ?? '',
      itemId: json['itemId']?.toString(),
      itemName: json['itemName'] as String? ?? '',
      priceAmount: (json['priceAmount'] is int)
          ? json['priceAmount'] as int
          : int.tryParse('${json['priceAmount']}') ?? 0,
      // The active Shop endpoint predates isActive. Missing means the row was
      // already filtered by the server and must not become falsely disabled.
      isActive: json['isActive'] as bool? ?? true,
      image: json['image'] as String?,
      itemTypeName: json['itemTypeName'] as String?,
      effectTypeCode: json['effectTypeCode']?.toString(),
      effectValue: (json['effectValue'] as num?)?.toInt() ??
          int.tryParse('${json['effectValue']}'),
      description: json['description'] as String?,
      usageContextCode: json['usageContextCode']?.toString() ?? 'none',
      canUseNow: json['canUseNow'] as bool? ?? false,
      canEquipForPvp: json['canEquipForPvp'] as bool? ?? false,
      itemNameVi: json['itemNameVi']?.toString(),
      itemNameEn: json['itemNameEn']?.toString(),
      descriptionVi: json['descriptionVi']?.toString(),
      descriptionEn: json['descriptionEn']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shopItemId': shopItemId,
      'itemId': itemId,
      'itemName': itemName,
      'priceAmount': priceAmount,
      'isActive': isActive,
      'image': image,
      'itemTypeName': itemTypeName,
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
    };
  }
}

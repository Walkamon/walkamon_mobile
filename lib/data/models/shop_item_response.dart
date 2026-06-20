class ShopItemResponse {
  final String shopItemId;
  final String itemName;
  final int priceAmount;
  final bool isActive;
  final String? image;
  final String? itemTypeName;
  final String? description;

  ShopItemResponse({
    required this.shopItemId,
    required this.itemName,
    required this.priceAmount,
    required this.isActive,
    this.image,
    this.itemTypeName,
    this.description,
  });

  factory ShopItemResponse.fromJson(Map<String, dynamic> json) {
    return ShopItemResponse(
      shopItemId: json['shopItemId'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      priceAmount: (json['priceAmount'] is int)
          ? json['priceAmount'] as int
          : int.tryParse('${json['priceAmount']}') ?? 0,
      isActive: json['isActive'] as bool? ?? false,
      image: json['image'] as String?,
      itemTypeName: json['itemTypeName'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shopItemId': shopItemId,
      'itemName': itemName,
      'priceAmount': priceAmount,
      'isActive': isActive,
      'image': image,
      'itemTypeName': itemTypeName,
      'description': description,
    };
  }
}

class ShopItemResponse {
  final String shopItemId;
  final String itemName;
  final int priceAmount;
  final bool isActive;

  ShopItemResponse({
    required this.shopItemId,
    required this.itemName,
    required this.priceAmount,
    required this.isActive,
  });

  factory ShopItemResponse.fromJson(Map<String, dynamic> json) {
    return ShopItemResponse(
      shopItemId: json['shopItemId'] as String? ?? '',
      itemName: json['itemName'] as String? ?? '',
      priceAmount: json['priceAmount'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shopItemId': shopItemId,
      'itemName': itemName,
      'priceAmount': priceAmount,
      'isActive': isActive,
    };
  }
}

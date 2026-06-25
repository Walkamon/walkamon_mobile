import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../models/shop_item_response.dart';

class ShopScreenDatasource {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<ShopItemResponse>>> getAllShopItems() async {
    return await _apiClient.get<List<ShopItemResponse>>(
      ApiConstants.shopItems,
      fromJsonT: (json) {
        if (json is List) {
          return json
              .map((e) => ShopItemResponse.fromJson(e as Map<String, dynamic>))
              .toList();
        }
        return <ShopItemResponse>[];
      },
    );
  }

  Future<ApiResponse<ShopItemResponse>> getShopItemById(String id) async {
    return await _apiClient.get<ShopItemResponse>(
      ApiConstants.shopItemById(id),
      fromJsonT: (json) => ShopItemResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  /// Calls POST /api/shop/buy with body { shopItemId, quantity }
  Future<ApiResponse<dynamic>> buyShopItem(String shopItemId, {int quantity = 1}) async {
    final body = {'shopItemId': shopItemId, 'quantity': quantity};
    return await _apiClient.post<dynamic>(
      ApiConstants.buyShop,
      data: body,
      fromJsonT: (json) => json,
    );
  }
}

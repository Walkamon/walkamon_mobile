import '../datasources/remote/shop_screen_datasource.dart';
import '../models/shop_item_response.dart';
import '../../core/network/api_response.dart';

class ShopScreenRepository {
  final ShopScreenDatasource _remoteDataSource = ShopScreenDatasource();

  /// Returns list of ShopItemResponse from API; throws Exception on failure
  Future<List<ShopItemResponse>> getAllShopItems() async {
    final resp = await _remoteDataSource.getAllShopItems();
    if (resp.success && resp.data != null) {
      return resp.data!;
    }
    throw Exception(resp.message);
  }

  Future<ShopItemResponse> getShopItemById(String id) async {
    final resp = await _remoteDataSource.getShopItemById(id);
    if (resp.success && resp.data != null) {
      return resp.data!;
    }
    throw Exception(resp.message);
  }

  /// Returns ApiResponse from buy endpoint; response.data may contain updated wallet/inventory
  Future<ApiResponse<dynamic>> buyShopItem(String shopItemId, {int quantity = 1}) async {
    return await _remoteDataSource.buyShopItem(shopItemId, quantity: quantity);
  }
}

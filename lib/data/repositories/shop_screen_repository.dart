import '../datasources/remote/shop_screen_datasource.dart';
import '../models/shop_item_response.dart';

class ShopScreenRepository {
  final ShopScreenDatasource _remoteDataSource = ShopScreenDatasource();

  Future<List<ShopItemResponse>> getAllShopItems() {
    return _remoteDataSource.getAllShopItems();
  }

  Future<ShopItemResponse> getShopItemById(String id) {
    return _remoteDataSource.getShopItemById(id);
  }

  Future<bool> buyShopItem(String shopItemId, {int quantity = 1}) {
    return _remoteDataSource.buyShopItem(shopItemId, quantity: quantity);
  }
}

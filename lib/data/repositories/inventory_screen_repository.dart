import '../datasources/remote/inventory_screen_datasource.dart';
import '../models/item_response.dart';
import '../models/item_type_response.dart';

class InventoryScreenRepository {
  final InventoryScreenDatasource _remoteDataSource =
      InventoryScreenDatasource();

  Future<List<ItemResponse>> getAllItems() {
    return _remoteDataSource.getAllItems();
  }

  Future<List<ItemTypeResponse>> getAllItemTypes() {
    return _remoteDataSource.getAllItemTypes();
  }
}

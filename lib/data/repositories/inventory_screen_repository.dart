import '../../core/network/api_response.dart';
import '../../core/network/app_failure.dart';
import '../datasources/remote/inventory_screen_datasource.dart';
import '../models/inventory_item_response.dart';

class InventoryScreenRepository {
  final InventoryScreenDatasource _remoteDataSource =
      InventoryScreenDatasource();

  Future<List<InventoryItemResponse>> getInventory() async {
    final resp = await _remoteDataSource.getInventory();
    if (resp.success && resp.data != null) {
      return resp.data!;
    }
    throw resp.failure;
  }

  Future<InventoryItemResponse> getItemById(String itemId) async {
    final resp = await _remoteDataSource.getItemById(itemId);
    if (resp.success && resp.data != null) {
      return resp.data!;
    }
    throw resp.failure;
  }

  Future<ApiResponse<dynamic>> useItem(String itemId) async {
    return await _remoteDataSource.useItem(itemId);
  }
}

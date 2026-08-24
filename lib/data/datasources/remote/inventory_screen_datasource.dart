import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../models/inventory_item_response.dart';

class InventoryScreenDatasource {
  final ApiClient _apiClient = ApiClient();

  Future<ApiResponse<List<InventoryItemResponse>>> getInventory() async {
    return await _apiClient.get<List<InventoryItemResponse>>(
      ApiConstants.inventory,
      fromJsonT: (json) {
        if (json is List) {
          return json
              .map(
                (e) =>
                    InventoryItemResponse.fromJson(e as Map<String, dynamic>),
              )
              .toList();
        }
        return <InventoryItemResponse>[];
      },
    );
  }

  Future<ApiResponse<InventoryItemResponse>> getItemById(String itemId) async {
    return await _apiClient.get<InventoryItemResponse>(
      ApiConstants.inventoryItemById(itemId),
      fromJsonT: (json) =>
          InventoryItemResponse.fromJson(json as Map<String, dynamic>),
    );
  }

  Future<ApiResponse<dynamic>> useItem(String itemId) async {
    return await _apiClient.post<dynamic>(
      ApiConstants.useInventoryItem,
      data: {'itemId': itemId},
      fromJsonT: (json) => json,
    );
  }
}

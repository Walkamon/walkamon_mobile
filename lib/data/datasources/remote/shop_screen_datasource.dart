import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_provider.dart';
import '../../models/shop_item_response.dart';

class ShopScreenDatasource {
  final Dio _dio = DioProvider.instance;

  Future<List<ShopItemResponse>> getAllShopItems() async {
    final response = await _dio.get(ApiConstants.shopItems);
    final data = response.data;

    if (data is List) {
      return data
          .map((e) => ShopItemResponse.fromJson(e as Map<String, dynamic>))
          .where((item) => item.isActive)
          .toList();
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: 'Dữ liệu phản hồi không đúng định dạng.',
    );
  }

  Future<ShopItemResponse> getShopItemById(String id) async {
    final response = await _dio.get(ApiConstants.shopItemById(id));
    final data = response.data;

    if (data is Map<String, dynamic>) {
      return ShopItemResponse.fromJson(data);
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: 'Dữ liệu phản hồi không đúng định dạng.',
    );
  }

  Future<bool> buyShopItem(String shopItemId, {int quantity = 1}) async {
    try {
      final response = await _dio.post(
        ApiConstants.buyShopItem(shopItemId),
        data: {'quantity': quantity},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException {
      return false;
    }
  }
}

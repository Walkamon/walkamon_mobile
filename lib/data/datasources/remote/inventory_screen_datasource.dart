import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/dio_provider.dart';
import '../../models/item_response.dart';
import '../../models/item_type_response.dart';

class InventoryScreenDatasource {
  final Dio _dio = DioProvider.instance;

  Future<List<ItemResponse>> getAllItems() async {
    final response = await _dio.get(ApiConstants.items);
    final data = response.data;

    if (data is List) {
      return data
          .map((e) => ItemResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: 'Dữ liệu phản hồi không đúng định dạng.',
    );
  }

  Future<List<ItemTypeResponse>> getAllItemTypes() async {
    final response = await _dio.get(ApiConstants.itemTypes);
    final data = response.data;

    if (data is List) {
      return data
          .map((e) => ItemTypeResponse.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    throw DioException(
      requestOptions: response.requestOptions,
      message: 'Dữ liệu phản hồi không đúng định dạng.',
    );
  }
}

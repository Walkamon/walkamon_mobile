import '../../../core/network/api_client.dart';
import '../../../core/network/api_response.dart';
import '../../models/wallet_balance_response.dart';

class WalletDatasource {
  WalletDatasource([ApiClient? apiClient])
    : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<ApiResponse<WalletBalanceResponse>> getBalance() async {
    return _apiClient.get<WalletBalanceResponse>(
      '/api/wallet',
      fromJsonT: (json) => WalletBalanceResponse.fromJson(
        Map<String, dynamic>.from(json as Map),
      ),
    );
  }
}

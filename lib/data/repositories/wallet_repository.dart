import '../datasources/remote/wallet_datasource.dart';
import '../models/wallet_balance_response.dart';

class WalletRepository {
  WalletRepository({WalletDatasource? datasource})
    : _datasource = datasource ?? WalletDatasource();

  final WalletDatasource _datasource;

  Future<WalletBalanceResponse> getBalance() async {
    final apiResponse = await _datasource.getBalance();

    if (apiResponse.success && apiResponse.data != null) {
      return apiResponse.data!;
    }

    throw Exception(
      apiResponse.message.isNotEmpty
          ? apiResponse.message
          : 'Không thể tải số dư ví.',
    );
  }
}

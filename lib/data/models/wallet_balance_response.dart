class WalletBalanceResponse {
  final int balance;

  WalletBalanceResponse({required this.balance});

  factory WalletBalanceResponse.fromJson(Map<String, dynamic> json) {
    return WalletBalanceResponse(
      balance: int.tryParse(json['balance']?.toString() ?? '0') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'balance': balance};
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/data/models/player_challenge_response.dart';

void main() {
  group('Claim challenge reward response', () {
    test('parses reward items from API payload', () {
      final response = ClaimChallengeRewardResponse.fromJson({
        'userMissionId': 'mission-1',
        'walletAmount': 50,
        'walletBalance': 120,
        'rewardItems': [
          {'itemId': 'potion', 'itemName': 'Potion', 'quantity': 2},
          {'itemId': 'coin', 'itemName': 'Coin', 'quantity': 5},
        ],
      });

      expect(response.userMissionId, 'mission-1');
      expect(response.walletAmount, 50);
      expect(response.walletBalance, 120);
      expect(response.rewardItems.length, 2);
      expect(response.rewardItems.first.itemName, 'Potion');
      expect(response.rewardItems.first.quantity, 2);
    });
  });
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';

void main() {
  test('PvP interpolated messages are available in Vietnamese and English', () {
    final vi = lookupAppLocalizations(const Locale('vi'));
    final en = lookupAppLocalizations(const Locale('en'));

    expect(vi.pvpWaitingForFriend('An'), 'Đang chờ An phản hồi...');
    expect(en.pvpWaitingForFriend('An'), 'Waiting for An to respond...');
    expect(vi.pvpPageOf(2, 5), 'Trang 2 / 5');
    expect(en.pvpPageOf(2, 5), 'Page 2 / 5');
    expect(vi.pvpResultBeatOpponent('Minh'), 'Bạn đã đánh bại Minh');
    expect(en.pvpResultBeatOpponent('Minh'), 'You defeated Minh');
    expect(vi.pvpRaceProgress(75), 'Tiến độ đường đua: 75%');
    expect(en.pvpRaceProgress(75), 'Race progress: 75%');
    expect(en.pvpCoinReward(1), '+1 Dewdrop');
    expect(en.pvpCoinReward(2), '+2 Dewdrops');
    expect(en.pvpItemReward(1), 'x1 item');
    expect(en.pvpItemReward(2), 'x2 items');
    expect(vi.pvpMmr, 'MMR');
    expect(en.pvpMmr, 'MMR');
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:walkamon_mobile/main.dart';
import 'package:walkamon_mobile/providers/game_state_provider.dart';

void main() {
  testWidgets('Welcome screen renders Walkamon title', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GameStateProvider(),
        child: const WalkamonApp(),
      ),
    );

    expect(find.text('Walkamon'), findsOneWidget);
    expect(find.text('Khám Phá Ngay'), findsOneWidget);
  });
}

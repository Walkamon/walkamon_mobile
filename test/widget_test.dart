import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:walkamon_mobile/main.dart';
import 'package:walkamon_mobile/providers/game_state_provider.dart';
import 'package:walkamon_mobile/core/network/api_client.dart';
import 'package:walkamon_mobile/data/datasources/remote/profile_view_screen_datasource.dart';
import 'package:walkamon_mobile/data/repositories/profile_view_screen_repository.dart';

void main() {
  testWidgets('Welcome screen renders Walkamon title', (
    WidgetTester tester,
  ) async {
    final apiClient = ApiClient();
    final profileRepo = ProfileViewScreenRepository(
      ProfileViewScreenDatasource(apiClient),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GameStateProvider(profileRepo),
        child: const WalkamonApp(),
      ),
    );

    expect(find.text('Walkamon'), findsOneWidget);
    expect(find.text('Khám Phá Ngay'), findsOneWidget);
  });
}

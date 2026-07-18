import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/core/network/api_client.dart';
import 'package:walkamon_mobile/core/theme/app_theme.dart';
import 'package:walkamon_mobile/data/datasources/remote/notification_datasource.dart';
import 'package:walkamon_mobile/data/datasources/remote/pet_screen_datasource.dart';
import 'package:walkamon_mobile/data/datasources/remote/profile_view_screen_datasource.dart';
import 'package:walkamon_mobile/data/repositories/notification_repository.dart';
import 'package:walkamon_mobile/data/repositories/pet_screen_repository.dart';
import 'package:walkamon_mobile/data/repositories/profile_view_screen_repository.dart';
import 'package:walkamon_mobile/data/services/fcm_service.dart';
import 'package:walkamon_mobile/providers/game_state_provider.dart';
import 'package:walkamon_mobile/providers/step_tracking_provider.dart';
import 'package:walkamon_mobile/screen/auth/login_screen.dart';
import 'package:walkamon_mobile/widgets/layouts/auth_layout.dart';

void main() {
  testWidgets('Login sample fits a common phone viewport', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final apiClient = ApiClient();
    final notificationRepository = NotificationRepositoryImpl(
      datasource: NotificationDatasourceImpl(apiClient),
    );
    final gameState = GameStateProvider(
      ProfileViewScreenRepository(ProfileViewScreenDatasource(apiClient)),
      notificationRepository,
      FCMService(notificationRepository),
      PetScreenRepository(datasource: PetScreenDatasource(apiClient)),
    );
    final stepTracking = StepTrackingProvider();
    addTearDown(gameState.dispose);
    addTearDown(stepTracking.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: gameState),
          ChangeNotifierProvider.value(value: stepTracking),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const AuthLayout(fullBleed: true, child: LoginScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chào mừng trở lại!'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

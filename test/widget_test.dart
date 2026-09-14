import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:walkamon_mobile/main.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
import 'package:walkamon_mobile/core/auth/token_storage.dart';
import 'package:walkamon_mobile/providers/game_state_provider.dart';
import 'package:walkamon_mobile/core/network/api_client.dart';
import 'package:walkamon_mobile/core/permissions/startup_permission_service.dart';
import 'package:walkamon_mobile/data/datasources/remote/notification_datasource.dart';
import 'package:walkamon_mobile/data/datasources/remote/pet_screen_datasource.dart';
import 'package:walkamon_mobile/data/datasources/remote/profile_view_screen_datasource.dart';
import 'package:walkamon_mobile/data/repositories/achievement_screen_repository.dart';
import 'package:walkamon_mobile/data/repositories/notification_repository.dart';
import 'package:walkamon_mobile/data/repositories/pet_screen_repository.dart';
import 'package:walkamon_mobile/data/repositories/profile_view_screen_repository.dart';
import 'package:walkamon_mobile/data/services/fcm_service.dart';
import 'package:walkamon_mobile/screen/achievements/view_achievement_list_screen.dart';
import 'package:walkamon_mobile/data/models/achievement_response.dart';
import 'package:walkamon_mobile/data/datasources/remote/achievement_screen_datasource.dart';

class _FakeAchievementRepository extends AchievementScreenRepository {
  _FakeAchievementRepository()
    : super(AchievementScreenDatasource(ApiClient()));

  @override
  Future<List<AchievementResponse>> getAchievements() async {
    return const [];
  }
}

void main() {
  testWidgets('Achievements screen renders the title and tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('vi'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ViewAchievementListScreen(
          repository: _FakeAchievementRepository(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Kho Thành Tựu'), findsWidgets);
    expect(find.text('Đã Nhận'), findsWidgets);
    expect(find.text('Chưa Nhận'), findsWidgets);
  });

  testWidgets('Welcome screen renders Walkamon title', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final apiClient = ApiClient();
    final profileRepo = ProfileViewScreenRepository(
      ProfileViewScreenDatasource(apiClient),
    );
    final notificationRepository = NotificationRepositoryImpl(
      datasource: NotificationDatasourceImpl(apiClient),
    );
    final petRepository = PetScreenRepository(
      datasource: PetScreenDatasource(apiClient),
    );
    SharedPreferences.setMockInitialValues({});
    TokenStorage.clear();
    final gameState = GameStateProvider(
      profileRepo,
      notificationRepository,
      FCMService(notificationRepository),
      petRepository,
    );
    addTearDown(gameState.dispose);
    expect(await gameState.bootstrapAuthentication(), isFalse);

    await tester.pumpWidget(
      WalkamonApp(
        gameStateProvider: gameState,
        startupPermissionService: StartupPermissionService(
          permissionRequest: () async {},
        ),
      ),
    );

    // The logo is intentionally rendered as stacked outline/fill text.
    expect(find.text('Walkamon'), findsWidgets);
    expect(find.text('Khám Phá Ngay'), findsNothing);
    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.text('Đăng ký'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:walkamon_mobile/main.dart';
import 'package:walkamon_mobile/providers/game_state_provider.dart';
import 'package:walkamon_mobile/core/network/api_client.dart';
import 'package:walkamon_mobile/data/datasources/remote/notification_datasource.dart';
import 'package:walkamon_mobile/data/datasources/remote/pet_screen_datasource.dart';
import 'package:walkamon_mobile/data/datasources/remote/profile_view_screen_datasource.dart';
import 'package:walkamon_mobile/data/repositories/achievement_screen_repository.dart';
import 'package:walkamon_mobile/data/repositories/notification_repository.dart';
import 'package:walkamon_mobile/data/repositories/pet_screen_repository.dart';
import 'package:walkamon_mobile/data/repositories/profile_view_screen_repository.dart';
import 'package:walkamon_mobile/data/services/fcm_service.dart';
import 'package:walkamon_mobile/screen/achievements/View_achievement_list_screen.dart';
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
        home: ViewAchievementListScreen(
          repository: _FakeAchievementRepository(),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Kho Thành Tựu'), findsOneWidget);
    expect(find.text('Đã Nhận'), findsOneWidget);
    expect(find.text('Chưa Nhận'), findsOneWidget);
  });

  testWidgets('Welcome screen renders Walkamon title', (
    WidgetTester tester,
  ) async {
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

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => GameStateProvider(
          profileRepo,
          notificationRepository,
          FCMService(notificationRepository),
          petRepository,
        ),
        child: const WalkamonApp(),
      ),
    );

    expect(find.text('Walkamon'), findsOneWidget);
    expect(find.text('Khám Phá Ngay'), findsOneWidget);
  });
}

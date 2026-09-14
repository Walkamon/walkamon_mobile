import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walkamon_mobile/core/network/api_client.dart';
import 'package:walkamon_mobile/core/network/api_response.dart';
import 'package:walkamon_mobile/data/datasources/remote/notification_datasource.dart';
import 'package:walkamon_mobile/data/datasources/remote/pet_screen_datasource.dart';
import 'package:walkamon_mobile/data/datasources/remote/profile_view_screen_datasource.dart';
import 'package:walkamon_mobile/data/models/pet_evolution_models.dart';
import 'package:walkamon_mobile/data/models/pet_status_response.dart';
import 'package:walkamon_mobile/data/repositories/notification_repository.dart';
import 'package:walkamon_mobile/data/repositories/pet_screen_repository.dart';
import 'package:walkamon_mobile/data/repositories/profile_view_screen_repository.dart';
import 'package:walkamon_mobile/data/services/fcm_service.dart';
import 'package:walkamon_mobile/providers/game_state_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'an older /api/Pet/me response cannot overwrite a newer snapshot',
    () async {
      final datasource = _ControllablePetDatasource();
      final provider = _buildProvider(datasource);
      addTearDown(provider.dispose);

      final first = provider.fetchPetVisual();
      final second = provider.fetchPetVisual();
      datasource.overviewRequests[1].complete(
        _success(_overview(affinity: 'moonlight', stage: 2, state: 'sad')),
      );
      expect(await second, isTrue);

      datasource.overviewRequests[0].complete(
        _success(_overview(affinity: 'sprout', stage: 0, state: 'idle')),
      );
      expect(await first, isFalse);
      expect(provider.affinityCode, 'moonlight');
      expect(provider.petStageNo, 2);
      expect(provider.animationType, 'sad');
    },
  );

  test('Feed owns the action lock and rejects a concurrent Tap', () async {
    final datasource = _ControllablePetDatasource();
    final provider = _buildProvider(datasource);
    addTearDown(provider.dispose);

    final feed = provider.feedSpirit();
    expect(provider.isPetActionBusy, isTrue);
    expect(await provider.tapSpirit(), isFalse);
    expect(datasource.tapCalls, 0);

    datasource.feedRequests.single.complete(
      _success(
        PetStatusResponse(
          currentEnergy: 80,
          maxEnergy: 120,
          currentBond: 55,
          maxBond: 110,
          currentLifeForce: 95,
          maxLifeForce: 150,
        ),
      ),
    );
    expect(await feed, isTrue);
    expect(provider.isPetActionBusy, isFalse);
    expect(provider.spiritHealthMax, 150);
  });

  test('Feed full check uses the authoritative dynamic maximum', () async {
    final datasource = _ControllablePetDatasource();
    final provider = _buildProvider(datasource);
    addTearDown(provider.dispose);

    final load = provider.fetchPetVisual();
    datasource.overviewRequests.single.complete(
      _success(
        _overview(
          affinity: 'dawn',
          stage: 1,
          state: 'idle',
          lifeForce: 150,
          maxLifeForce: 150,
        ),
      ),
    );
    expect(await load, isTrue);

    expect(await provider.feedSpirit(), isFalse);
    expect(provider.lastFeedFailure, PetFeedFailureReason.fullLifeForce);
    expect(datasource.feedRequests, isEmpty);
  });
}

GameStateProvider _buildProvider(PetScreenDatasource datasource) {
  final apiClient = ApiClient();
  final notificationRepository = NotificationRepositoryImpl(
    datasource: NotificationDatasourceImpl(apiClient),
  );
  return GameStateProvider(
    ProfileViewScreenRepository(ProfileViewScreenDatasource(apiClient)),
    notificationRepository,
    FCMService(notificationRepository),
    PetScreenRepository(datasource: datasource),
  );
}

ApiResponse<T> _success<T>(T data) =>
    ApiResponse<T>(success: true, status: 200, message: '', data: data);

PetOverviewResponse _overview({
  required String affinity,
  required int stage,
  required String state,
  int lifeForce = 70,
  int maxLifeForce = 100,
}) => PetOverviewResponse(
  petId: 'pet-1',
  nickname: 'Lumina',
  formName: affinity,
  affinityCode: affinity,
  level: 3,
  currentExp: 20,
  maxExp: 100,
  currentEnergy: 60,
  maxEnergy: 100,
  currentLifeForce: lifeForce,
  maxLifeForce: maxLifeForce,
  currentBond: 40,
  maxBond: 100,
  stageNo: stage,
  stageName: 'Stage $stage',
  animationType: state,
  canEvolve: false,
  nextEvolutionLevel: 0,
);

class _ControllablePetDatasource extends PetScreenDatasource {
  final List<Completer<ApiResponse<PetOverviewResponse>>> overviewRequests = [];
  final List<Completer<ApiResponse<PetStatusResponse>>> feedRequests = [];
  int tapCalls = 0;

  @override
  Future<ApiResponse<PetOverviewResponse>> getPetOverview() {
    final completer = Completer<ApiResponse<PetOverviewResponse>>();
    overviewRequests.add(completer);
    return completer.future;
  }

  @override
  Future<ApiResponse<PetStatusResponse>> feedSpirit() {
    final completer = Completer<ApiResponse<PetStatusResponse>>();
    feedRequests.add(completer);
    return completer.future;
  }

  @override
  Future<ApiResponse<PetStatusResponse>> tapSpirit() {
    tapCalls++;
    return Future.value(
      _success(
        PetStatusResponse(
          currentEnergy: 60,
          maxEnergy: 100,
          currentBond: 40,
          maxBond: 100,
          currentLifeForce: 70,
          maxLifeForce: 100,
        ),
      ),
    );
  }
}

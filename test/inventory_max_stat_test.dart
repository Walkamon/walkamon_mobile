import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walkamon_mobile/core/constants/care_item_policy.dart';
import 'package:walkamon_mobile/core/network/api_response.dart';
import 'package:walkamon_mobile/data/models/inventory_item_response.dart';
import 'package:walkamon_mobile/data/repositories/inventory_screen_repository.dart';
import 'package:walkamon_mobile/data/repositories/profile_view_screen_repository.dart';
import 'package:walkamon_mobile/data/repositories/notification_repository.dart';
import 'package:walkamon_mobile/data/repositories/pet_screen_repository.dart';
import 'package:walkamon_mobile/data/services/fcm_service.dart';
import 'package:walkamon_mobile/providers/game_state_provider.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
import 'package:walkamon_mobile/screen/inventory/inventory_screen.dart';

class _Profile extends Fake implements ProfileViewScreenRepository {}

class _Notifications extends Fake implements NotificationRepository {}

class _Fcm extends Fake implements FCMService {}

class _Pet extends Fake implements PetScreenRepository {}

class _State extends GameStateProvider {
  _State() : super(_Profile(), _Notifications(), _Fcm(), _Pet());
  int energy = 150;
  @override
  int get spiritEnergy => energy;
  @override
  int get spiritEnergyMax => 150;
  @override
  Future<bool> fetchPetStatus() async => true;
  @override
  Future<bool> fetchPetVisual() async => true;
  void drain() {
    energy = 140;
    notifyListeners();
  }
}

class _Inventory extends InventoryScreenRepository {
  final String effect;
  _Inventory([this.effect = 'energy']);
  int calls = 0;
  final result = Completer<ApiResponse<dynamic>>();
  @override
  Future<List<InventoryItemResponse>> getInventory() async => [
    InventoryItemResponse(
      itemId: 'item',
      itemName: 'Potion',
      itemTypeName: 'consumable',
      effectTypeCode: effect,
      effectValue: 10,
      quantity: 2,
    ),
  ];
  @override
  Future<ApiResponse<dynamic>> useItem(String id) {
    calls++;
    return result.future;
  }
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('PvP item still opens loadout when care stats are full', (
    tester,
  ) async {
    final state = _State();
    final inventory = _Inventory('pvp_speed_up');
    addTearDown(state.dispose);
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ChangeNotifierProvider<GameStateProvider>.value(
        value: state,
        child: MaterialApp(
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routes: {'/pvp': (_) => const Scaffold(body: Text('Loadout route'))},
          home: InventoryScreen(repository: inventory),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('item')));
    await tester.pumpAndSettle();
    expect(find.text('Chỉ số đã đầy'), findsNothing);
    final label = AppLocalizations.of(
      tester.element(find.byType(InventoryScreen)),
    ).pvpLoadoutTitle;
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
    expect(find.text('Loadout route'), findsOneWidget);
    expect(inventory.calls, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  test(
    'care cap uses each server maximum; unknown and PvP effects are not care',
    () {
      bool full(String? effect, {int current = 150, int maximum = 150}) =>
          isCareItemStatFull(
            effectTypeCode: effect,
            energy: current,
            maxEnergy: maximum,
            lifeForce: current,
            maxLifeForce: maximum,
            bond: current,
            maxBond: maximum,
          );
      for (final effect in [
        'energy',
        'life_force',
        'sml',
        'bond',
        ' ENERGY ',
      ]) {
        expect(full(effect), isTrue);
        expect(full(effect, current: 149), isFalse);
        expect(full(effect, current: 160), isTrue);
        expect(full(effect, maximum: 0), isFalse);
      }
      for (final effect in [null, 'unknown', 'pvp_speed_up', 'pvp_energy']) {
        expect(full(effect), isFalse);
      }
    },
  );

  testWidgets(
    'full item is disabled and a new stat snapshot enables one request',
    (tester) async {
      final state = _State();
      final inventory = _Inventory();
      addTearDown(state.dispose);
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ChangeNotifierProvider<GameStateProvider>.value(
          value: state,
          child: MaterialApp(
            locale: const Locale('vi'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: InventoryScreen(repository: inventory),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('item')));
      await tester.pumpAndSettle();
      expect(find.text('Chỉ số đã đầy'), findsWidgets);
      final blocked = find
          .ancestor(
            of: find.text('Chỉ số đã đầy').last,
            matching: find.byType(InkWell),
          )
          .first;
      expect(tester.widget<InkWell>(blocked).onTap, isNull);
      await tester.tap(find.text('Chỉ số đã đầy').last);
      expect(inventory.calls, 0);
      state.drain();
      await tester.pumpAndSettle();
      expect(find.text('Chỉ số đã đầy'), findsNothing);
      final use = find.text('Sử Dụng').last;
      final position = tester.getCenter(use);
      await tester.tap(use);
      await tester.pump();
      await tester.tapAt(position);
      expect(inventory.calls, 1);
      inventory.result.complete(
        ApiResponse(success: true, status: 200, message: 'ok'),
      );
      await tester.pumpAndSettle();
      expect(find.text('x2'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:walkamon_mobile/data/models/step_sensor_models.dart';
import 'package:walkamon_mobile/data/services/android_step_bridge.dart';
import 'package:walkamon_mobile/data/services/step_tracking_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('periodically recovers the latest native accepted total', () async {
    SharedPreferences.setMockInitialValues({});
    final bridge = _FakeAndroidStepBridge(
      const NativeTrackingStatus(
        running: true,
        userId: 'user-1',
        acceptedTotal: 6,
        pendingSteps: 2,
        nextSequence: 5,
        attested: true,
      ),
    );
    final motionEvents = StreamController<NativeMotionEvent>();
    final recovered = Completer<int>();
    final service = StepTrackingService(
      androidBridge: bridge,
      motionStreamFactory: () => motionEvents.stream,
      activityPermissionChecker: () async => true,
      syncInterval: const Duration(milliseconds: 10),
    );
    service.onStepsChanged = (steps) {
      if (steps == 32 && !recovered.isCompleted) recovered.complete(steps);
    };

    await service.startForUser('user-1');
    expect(service.currentStepCount, 6);
    expect(service.pendingStepCount, 2);
    expect(service.localPendingStepCount, 2);
    expect(service.serverPendingStepCount, 0);
    expect(service.displayedStepCount, 8);

    bridge.status = const NativeTrackingStatus(
      running: true,
      userId: 'user-1',
      acceptedTotal: 32,
      pendingSteps: 3,
      nextSequence: 6,
      attested: true,
    );

    expect(await recovered.future.timeout(const Duration(seconds: 1)), 32);
    expect(service.currentStepCount, 32);
    expect(service.pendingStepCount, 3);
    expect(service.localPendingStepCount, 3);
    expect(service.displayedStepCount, 35);

    service.dispose();
    await motionEvents.close();
  });

  test(
    'counter settlement replaces detector estimate without double count',
    () async {
      SharedPreferences.setMockInitialValues({});
      final bridge = _FakeAndroidStepBridge(
        const NativeTrackingStatus(
          running: true,
          userId: 'user-1',
          acceptedTotal: 1000,
          pendingSteps: 60,
          localPendingSteps: 20,
          serverPendingSteps: 40,
          nextSequence: 5,
          attested: true,
        ),
      );
      final motionEvents = StreamController<NativeMotionEvent>();
      final settled = Completer<void>();
      final service = StepTrackingService(
        androidBridge: bridge,
        motionStreamFactory: () => motionEvents.stream,
        activityPermissionChecker: () async => true,
        syncInterval: const Duration(milliseconds: 10),
      );

      await service.startForUser('user-1');
      expect(service.displayedStepCount, 1060);

      service.onStepCountChanged = (accepted, pending) {
        if (accepted == 1090 && pending == 0 && !settled.isCompleted) {
          settled.complete();
        }
      };
      bridge.status = const NativeTrackingStatus(
        running: true,
        userId: 'user-1',
        acceptedTotal: 1090,
        pendingSteps: 0,
        localPendingSteps: 0,
        serverPendingSteps: 0,
        nextSequence: 6,
        attested: true,
      );

      await settled.future.timeout(const Duration(seconds: 1));
      expect(service.currentStepCount, 1090);
      expect(service.pendingStepCount, 0);
      expect(service.displayedStepCount, 1090);

      service.dispose();
      await motionEvents.close();
    },
  );

  test('blocked counter interval removes pending estimate once', () async {
    SharedPreferences.setMockInitialValues({});
    final bridge = _FakeAndroidStepBridge(
      const NativeTrackingStatus(
        running: true,
        userId: 'user-1',
        acceptedTotal: 1000,
        pendingSteps: 60,
        nextSequence: 5,
        attested: true,
      ),
    );
    final motionEvents = StreamController<NativeMotionEvent>();
    final settled = Completer<void>();
    final service = StepTrackingService(
      androidBridge: bridge,
      motionStreamFactory: () => motionEvents.stream,
      activityPermissionChecker: () async => true,
      syncInterval: const Duration(milliseconds: 10),
    );

    await service.startForUser('user-1');
    service.onStepBreakdownChanged = (accepted, local, server, rejected) {
      if (accepted == 1000 &&
          local == 0 &&
          server == 0 &&
          rejected == 60 &&
          !settled.isCompleted) {
        settled.complete();
      }
    };
    bridge.status = const NativeTrackingStatus(
      running: true,
      userId: 'user-1',
      acceptedTotal: 1000,
      pendingSteps: 0,
      lastRejectedSteps: 60,
      nextSequence: 6,
      attested: true,
    );

    await settled.future.timeout(const Duration(seconds: 1));
    expect(service.currentStepCount, 1000);
    expect(service.pendingStepCount, 0);
    expect(service.displayedStepCount, 1000);

    service.dispose();
    await motionEvents.close();
  });
}

class _FakeAndroidStepBridge extends AndroidStepBridge {
  _FakeAndroidStepBridge(this.status);

  NativeTrackingStatus status;

  @override
  Future<NativeTrackingStatus> getTrackingStatus() async => status;
}

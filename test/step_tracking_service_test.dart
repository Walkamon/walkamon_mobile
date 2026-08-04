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

    bridge.status = const NativeTrackingStatus(
      running: true,
      userId: 'user-1',
      acceptedTotal: 32,
      nextSequence: 6,
      attested: true,
    );

    expect(await recovered.future.timeout(const Duration(seconds: 1)), 32);
    expect(service.currentStepCount, 32);

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

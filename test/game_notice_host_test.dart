import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/constants/app_assets.dart';
import 'package:walkamon_mobile/widgets/common/game_button_label.dart';
import 'package:walkamon_mobile/widgets/common/game_notice_host.dart';

void main() {
  testWidgets('reward notice uses the cozy frame and reward artwork', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: GameNoticeHost(
          key: GameNoticeHost.globalKey,
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );

    showGameNotice('Reward claimed', type: GameNoticeType.reward);
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    expect(find.text('Reward claimed'), findsOneWidget);
    expect(
      find.image(const AssetImage(AppAssets.toastFeedbackFrame)),
      findsOneWidget,
    );
    expect(
      find.image(const AssetImage(AppAssets.notificationRewardClaim)),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('shared button label leaves room for Vietnamese tone marks', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: GameButtonLabel('Nhận'))),
      ),
    );

    final text = tester.widget<Text>(find.text('Nhận'));
    expect(text.style?.height, greaterThan(1));
    expect(text.style?.leadingDistribution, TextLeadingDistribution.even);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long notice stays inside the compact cozy frame', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: GameNoticeHost(
          key: GameNoticeHost.globalKey,
          child: const Scaffold(body: SizedBox.expand()),
        ),
      ),
    );

    showGameNotice(
      'Your pet has reached its Life Force limit.',
      type: GameNoticeType.error,
    );
    await tester.pump(const Duration(milliseconds: 300));

    final frame = find.image(const AssetImage(AppAssets.toastFeedbackFrame));
    expect(frame, findsOneWidget);
    expect(tester.getSize(frame).width, lessThanOrEqualTo(312));
    expect(tester.getSize(frame).height, lessThanOrEqualTo(112));
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact claim label can render without muddy outline shadows', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: GameButtonLabel('Nhận', fontSize: 13.5, outlineWidth: 0),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text('Nhận'));
    expect(text.style?.shadows, isEmpty);
    expect(text.style?.height, greaterThan(1));
    expect(tester.takeException(), isNull);
  });
}

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:walkamon_mobile/core/network/api_response.dart';
import 'package:walkamon_mobile/core/theme/app_theme.dart';
import 'package:walkamon_mobile/data/repositories/change_password_screen_repository.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
import 'package:walkamon_mobile/screen/auth/change_password_screen.dart';
import 'package:walkamon_mobile/widgets/layouts/auth_layout.dart';

class FakePasswordRepository implements ChangePasswordScreenRepository {
  final requests = <({String current, String next})>[];
  final response = Completer<ApiResponse<void>>();

  @override
  Future<ApiResponse<void>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) {
    requests.add((current: currentPassword, next: newPassword));
    return response.future;
  }
}

const currentKey = ValueKey('change-password-current');
const newKey = ValueKey('change-password-new');
const saveKey = ValueKey('change-password-save');
const previewKey = ValueKey('password-preview');

Future<GlobalKey<NavigatorState>> showScreen(
  WidgetTester tester,
  FakePasswordRepository repository, {
  Size size = const Size(390, 844),
  String language = 'vi',
  bool dark = false,
  double scale = 1,
  double keyboard = 0,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      locale: Locale(language),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: const Scaffold(body: Text('Settings marker')),
    ),
  );
  navigator.currentState!.push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/auth/change-password'),
      builder: (_) => RepaintBoundary(
        key: previewKey,
        child: AuthLayout(
          fullBleed: true,
          child: ChangePasswordScreen(repository: repository),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return navigator;
}

Future<void> fillPasswords(
  WidgetTester tester, {
  String current = 'OldPass7!',
  String next = 'NewPass8@',
}) async {
  await tester.ensureVisible(find.byKey(currentKey));
  await tester.enterText(find.byKey(currentKey), current);
  await tester.ensureVisible(find.byKey(newKey));
  await tester.enterText(find.byKey(newKey), next);
  tester.testTextInput.hide();
  await tester.pump();
}

Future<void> save(WidgetTester tester) async {
  await tester.ensureVisible(find.byKey(saveKey));
  await tester.tap(find.byKey(saveKey));
  await tester.pump();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final textFont = FontLoader('Quicksand')
      ..addFont(
        rootBundle.load(
          'assets/fonts/Quicksand/Quicksand-VariableFont_wght.ttf',
        ),
      );
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await textFont.load();
    await icons.load();
  });
  testWidgets(
    'Settings password form contains old/new only, never email or OTP',
    (tester) async {
      final repo = FakePasswordRepository();
      await showScreen(tester, repo);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Mật khẩu hiện tại'), findsOneWidget);
      expect(find.text('Mật khẩu mới'), findsOneWidget);
      expect(find.textContaining('OTP'), findsNothing);
      expect(find.text('Email'), findsNothing);
      expect(repo.requests, isEmpty);
      for (final field in tester.widgetList<TextField>(
        find.byType(TextField),
      )) {
        expect(field.obscureText, isTrue);
        expect(field.autocorrect, isFalse);
        expect(field.enableSuggestions, isFalse);
      }
      await tester.tap(find.byTooltip('Hiện mật khẩu').first);
      await tester.pump();
      expect(
        tester.widgetList<TextField>(find.byType(TextField)).first.obscureText,
        isFalse,
      );
      expect(
        tester.widgetList<TextField>(find.byType(TextField)).last.obscureText,
        isTrue,
      );
    },
  );

  testWidgets(
    'Client rejects empty, weak and unchanged passwords without a request',
    (tester) async {
      final repo = FakePasswordRepository();
      await showScreen(tester, repo);
      await save(tester);
      expect(
        find.text('Mật khẩu hiện tại không được để trống.'),
        findsOneWidget,
      );
      for (final next in [
        'abc',
        'lowercase7!',
        'UPPERCASE7!',
        'NoNumber!',
        'NoSymbol7',
        'OldPass7!',
      ]) {
        await fillPasswords(tester, next: next);
        await save(tester);
        expect(repo.requests, isEmpty);
      }
      expect(
        find.text('Mật khẩu mới phải khác mật khẩu hiện tại.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Save is single-flight, preserves exact passwords and succeeds without navigation to auth',
    (tester) async {
      final repo = FakePasswordRepository();
      await showScreen(tester, repo);
      await fillPasswords(tester, current: ' OldPass7! ', next: ' NewPass8@ ');
      final controls = tester
          .widgetList<TextFormField>(find.byType(TextFormField))
          .map((w) => w.controller!)
          .toList();
      final submit = tester
          .widget<FilledButton>(find.byKey(saveKey))
          .onPressed!;
      submit();
      submit();
      await tester.pump();
      expect(repo.requests.length, 1);
      expect(repo.requests.single, (
        current: ' OldPass7! ',
        next: ' NewPass8@ ',
      ));
      expect(
        tester.widget<FilledButton>(find.byKey(saveKey)).onPressed,
        isNull,
      );
      expect(find.text('Đổi mật khẩu thành công!'), findsNothing);
      repo.response.complete(
        ApiResponse(
          success: true,
          status: 200,
          message: 'Change password success',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Đổi mật khẩu thành công!'), findsOneWidget);
      expect(controls.every((controller) => controller.text.isEmpty), isTrue);
      expect(find.textContaining('OTP'), findsNothing);
      await tester.tap(find.text('Quay lại cài đặt'));
      await tester.pumpAndSettle();
      expect(find.text('Settings marker'), findsOneWidget);
      expect(repo.requests.length, 1);
    },
  );

  testWidgets(
    'Wrong current password shows server failure, keeps fields and allows correction',
    (tester) async {
      final repo = FakePasswordRepository();
      await showScreen(tester, repo);
      await fillPasswords(tester);
      await save(tester);
      repo.response.complete(
        ApiResponse(
          success: false,
          status: 400,
          message: 'Current password is invalid',
          errorCode: 'AUTH_CURRENT_PASSWORD_INVALID',
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Mật khẩu hiện tại không đúng.'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Đổi mật khẩu thành công!'), findsNothing);
      expect(
        tester.widget<FilledButton>(find.byKey(saveKey)).onPressed,
        isNotNull,
      );
      await tester.enterText(find.byKey(currentKey), 'CorrectPass7!');
      await tester.pump();
      expect(find.text('Mật khẩu hiện tại không đúng.'), findsNothing);
    },
  );

  testWidgets(
    'Exception ends loading without a fake success or request retry',
    (tester) async {
      final repo = FakePasswordRepository();
      await showScreen(tester, repo);
      await fillPasswords(tester);
      await save(tester);
      repo.response.completeError(Exception('Network test failure'));
      await tester.pumpAndSettle();
      expect(
        find.text('Đổi mật khẩu thất bại. Vui lòng thử lại.'),
        findsOneWidget,
      );
      expect(repo.requests.length, 1);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    },
  );

  testWidgets(
    'Back while pending does not navigate or setState after disposal',
    (tester) async {
      final repo = FakePasswordRepository();
      final navigator = await showScreen(tester, repo);
      await fillPasswords(tester);
      await save(tester);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      repo.response.complete(
        ApiResponse(success: true, status: 200, message: 'OK'),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Settings marker'), findsOneWidget);
    },
  );

  for (final config in [
    (
      size: const Size(360, 640),
      language: 'vi',
      dark: false,
      scale: 1.5,
      keyboard: 260.0,
    ),
    (
      size: const Size(390, 844),
      language: 'vi',
      dark: false,
      scale: 1.0,
      keyboard: 0.0,
    ),
    (
      size: const Size(412, 915),
      language: 'en',
      dark: true,
      scale: 1.5,
      keyboard: 280.0,
    ),
  ]) {
    testWidgets(
      'Password layout ${config.size} ${config.language} dark=${config.dark}',
      (tester) async {
        await showScreen(
          tester,
          FakePasswordRepository(),
          size: config.size,
          language: config.language,
          dark: config.dark,
          scale: config.scale,
          keyboard: config.keyboard,
        );
        await tester.ensureVisible(find.byKey(newKey));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.byKey(saveKey));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byKey(saveKey).hitTestable(), findsOneWidget);
        if (const bool.fromEnvironment('CAPTURE_CHANGE_PASSWORD_QA')) {
          await tester.runAsync(() async {
            final boundary = tester.renderObject<RenderRepaintBoundary>(
              find.byKey(previewKey),
            );
            final image = await boundary.toImage(pixelRatio: 2);
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final output = File(
              'build/change-password-qa/${config.size.width.toInt()}-${config.language}.png',
            );
            await output.parent.create(recursive: true);
            await output.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      },
    );
  }
}

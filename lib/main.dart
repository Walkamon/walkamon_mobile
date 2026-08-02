import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/l10n/app_localizations.dart';
import 'package:walkamon_mobile/screen/home/home_screen.dart';

import 'core/l10n/locale_helper.dart';
import 'core/audio/app_audio_service.dart';
import 'core/audio/app_tap_sound_region.dart';
import 'core/navigation/app_route_observer.dart';

import 'core/network/api_client.dart';
import 'core/permissions/startup_permission_service.dart';
import 'data/datasources/remote/profile_view_screen_datasource.dart';
import 'data/repositories/profile_view_screen_repository.dart';
import 'data/datasources/remote/friends_datasource.dart';
import 'data/repositories/friends_repository.dart';
import 'data/datasources/remote/pet_screen_datasource.dart';
import 'data/repositories/pet_screen_repository.dart';

import 'core/theme/app_theme.dart';
import 'providers/game_state_provider.dart';
import 'providers/presence_provider.dart';
import 'providers/step_tracking_provider.dart';
import 'providers/daily_login_provider.dart';
import 'data/repositories/daily_login_repository.dart';
import 'widgets/layouts/root_layout.dart';
import 'widgets/layouts/auth_layout.dart';
import 'widgets/layouts/main_layout.dart';
import 'widgets/common/home_page_backdrop.dart';
import 'screen/friends/friends_spirit_screen.dart' as fs;

import 'screen/auth/forgot_password_screen.dart';
import 'screen/auth/login_screen.dart';
import 'screen/auth/otp_verification_screen.dart';
import 'screen/auth/otp_register_screen.dart';
import 'screen/auth/register_screen.dart';
import 'screen/auth/reset_password_screen.dart';
import 'screen/auth/change_password_screen.dart';
import 'screen/auth/privacy_policy_screen.dart';
import 'screen/spirit/spirit_detail_screen.dart';
import 'screen/social/social_screen.dart';
import 'screen/gameplay/pvp_screen.dart';
import 'screen/welcome/daily_reward_screen.dart';
import 'screen/welcome/story_screen.dart';
import 'screen/welcome/name_pet_screen.dart';
import 'screen/welcome/seed_screen.dart';
import 'screen/notifications/notifications_screen.dart';
import 'screen/daily_login/daily_login_screen.dart';

import 'screen/inventory/inventory_screen.dart';
import 'screen/missions/missions_screen.dart';
import 'screen/settings/seting_screen.dart';
import 'screen/shop/shop_screen.dart';

import 'screen/welcome/welcome_screen.dart';
import 'screen/profile/profile_menu_screen.dart';
import 'screen/profile/activity_stats_screen.dart';
import 'screen/profile/profile_view_screen.dart';
import 'screen/profile/friend_player_profile_screen.dart';
import 'screen/profile/edit_profile_screen.dart';
import 'screen/profile/step_goal_screen.dart';
import 'screen/profile/streak_screen.dart';
import 'screen/achievements/View_achievement_list_screen.dart';

import 'data/datasources/remote/notification_datasource.dart';
import 'data/repositories/notification_repository.dart';

import 'data/services/fcm_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppAudioService.instance.initialize();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const WalkamonApp());
}

class _HiddenScrollbarBehavior extends MaterialScrollBehavior {
  const _HiddenScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

class WalkamonApp extends StatefulWidget {
  const WalkamonApp({super.key, this.startupPermissionService});

  final StartupPermissionService? startupPermissionService;

  @override
  State<WalkamonApp> createState() => _WalkamonAppState();
}

class _WalkamonAppState extends State<WalkamonApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await (widget.startupPermissionService ?? StartupPermissionService())
          .requestOnce();
    });
  }

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final profileRepository = ProfileViewScreenRepository(
      ProfileViewScreenDatasource(apiClient),
    );
    final friendsRepository = FriendsRepository(FriendsDatasource(apiClient));
    final petRepository = PetScreenRepository(
      datasource: PetScreenDatasource(apiClient),
    );

    final notificationDatasource = NotificationDatasourceImpl(apiClient);
    final notificationRepository = NotificationRepositoryImpl(
      datasource: notificationDatasource,
    );

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => GameStateProvider(
            profileRepository,
            notificationRepository,
            FCMService(notificationRepository),
            petRepository,
          ),
        ),
        ChangeNotifierProxyProvider<GameStateProvider, PresenceProvider>(
          create: (_) => PresenceProvider(),
          update: (_, gameState, presence) {
            final provider = presence ?? PresenceProvider();
            scheduleMicrotask(
              () => unawaited(
                provider.synchronizeAuthentication(gameState.isAuthenticated),
              ),
            );
            return provider;
          },
        ),
        ChangeNotifierProvider(create: (_) => StepTrackingProvider()),
        ChangeNotifierProvider(
          create: (_) => DailyLoginProvider(DailyLoginRepository()),
        ),
        Provider<FriendsRepository>(create: (_) => friendsRepository),
      ],
      child: Consumer<GameStateProvider>(
        builder: (context, gameState, _) {
          AppAudioService.instance.setEffectsEnabled(
            gameState.settings.soundEnabled,
          );
          AppAudioService.instance.setBackgroundEnabled(
            gameState.settings.backgroundMusicEnabled,
          );
          return MaterialApp(
            title: 'Walkamon',
            debugShowCheckedModeBanner: false,
            scrollBehavior: const _HiddenScrollbarBehavior(),
            navigatorObservers: [appRouteObserver],
            locale: gameState.locale,
            supportedLocales: LocaleHelper.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // ── Theme ──────────────────────────────────────────────────
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: gameState.settings.darkMode
                ? ThemeMode.dark
                : ThemeMode.light,

            scaffoldMessengerKey: RootLayout.messengerKey,
            builder: (context, child) =>
                AppTapSoundRegion(child: RootLayout(child: child!)),

            // ── CẤU HÌNH ĐIỀU HƯỚNG AN TOÀN (ROUTE GUARD) ──────────────────
            initialRoute: '/',

            onGenerateRoute: (settings) {
              // 1. Lấy trạng thái đăng nhập thực tế của người dùng từ Provider
              final bool isLogged = gameState.isAuthenticated;
              final String? routeName = settings.name;

              WidgetBuilder withPetBackground(
                WidgetBuilder pageBuilder, {
                required String? targetRoute,
              }) {
                return (context) {
                  final page = pageBuilder(context);
                  if (targetRoute == '/pvp' ||
                      targetRoute == '/' ||
                      (targetRoute?.startsWith('/auth/') ?? false)) {
                    return page;
                  }

                  return HomePageBackdrop(
                    child: Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(scaffoldBackgroundColor: Colors.transparent),
                      child: page,
                    ),
                  );
                };
              }

              // 2. Định nghĩa danh sách các Route cần bảo mật (Private)
              final privateRoutes = [
                '/home',
                '/inventory',
                '/shop',
                '/missions',
                '/settings',
                '/profile',
                '/profile/view',
                '/profile/friend',
                '/profile/activity',
                '/profile/edit',
                '/profile/achievements',
                '/step-goal',
                '/streak',
                '/auth/change-password',
                '/friends',
                '/social',
                '/pvp',
                '/daily-reward',
                '/daily-login-calendar',
                '/notifications',
                '/spirit/detail',
                '/spirit/friend',

                '/seed',
                '/name-pet',
              ];

              // 3. LOGIC CHẶN CỬA 1: Chưa đăng nhập mà đòi vào trang Private -> Đưa về trang Login
              if (!isLogged && privateRoutes.contains(routeName)) {
                return MaterialPageRoute(
                  builder: withPetBackground(
                    (_) =>
                        const AuthLayout(fullBleed: true, child: LoginScreen()),
                    targetRoute: '/auth/login',
                  ),
                  settings: const RouteSettings(
                    name: '/auth/login',
                  ), // Giữ đúng lịch sử định tuyến
                );
              }

              // 4. LOGIC CHẶN CỬA 2 (Tùy chọn UX): Đã đăng nhập rồi mà cố quay lại trang Welcome hoặc Login
              // -> Đi qua /seed để kiểm tra onboarding thú cưng trước khi vào home.
              if (isLogged &&
                  (routeName == '/' ||
                      routeName == '/auth/login' ||
                      routeName == '/auth/register')) {
                return MaterialPageRoute(
                  builder: withPetBackground(
                    (_) => const SeedScreen(),
                    targetRoute: '/seed',
                  ),
                  settings: const RouteSettings(name: '/seed'),
                );
              }

              // 5. Nếu vượt qua các bộ lọc trên, tiến hành phân phối màn hình như bình thường
              WidgetBuilder builder;
              switch (routeName) {
                // Các tuyến đường Public công cộng
                case '/':
                  builder = (_) => const WelcomeScreen();
                  break;
                case '/auth/login':
                  builder = (_) =>
                      const AuthLayout(fullBleed: true, child: LoginScreen());
                  break;
                case '/auth/register':
                  builder = (_) => const AuthLayout(
                    fullBleed: true,
                    child: RegisterScreen(),
                  );
                  break;
                case '/auth/forgot':
                  builder = (_) => const AuthLayout(
                    fullBleed: true,
                    child: ForgotPasswordScreen(),
                  );
                  break;
                case '/auth/reset-password':
                  builder = (_) =>
                      const AuthLayout(child: ResetPasswordScreen());
                  break;
                case '/auth/change-password':
                  builder = (_) => const AuthLayout(
                    fullBleed: true,
                    child: ChangePasswordScreen(),
                  );
                  break;
                case '/auth/otp_verification':
                  builder = (_) => const AuthLayout(
                    fullBleed: true,
                    child: OTP_Verification(),
                  );
                  break;

                case '/auth/otp_register':
                  builder = (_) =>
                      const AuthLayout(fullBleed: true, child: OTP_Register());
                  break;
                case '/auth/privacy':
                  builder = (_) => const AuthLayout(
                    fullBleed: true,
                    child: PrivacyPolicyScreen(),
                  );
                  break;

                // Các tuyến đường Private bảo mật
                case '/home':
                  builder = (_) => const HomeScreen(title: 'Home');
                  break;
                case '/inventory':
                  builder = (_) => const InventoryScreen();
                  break;
                case '/shop':
                  builder = (_) => const ShopScreen(); // Đã thêm màn hình Shop
                  break;
                case '/missions':
                  builder = (_) => const MissionsScreen();
                  break;
                case '/settings':
                  builder = (_) =>
                      const SettingScreen(); // Đã thêm màn hình Settings
                  break;
                case '/profile':
                  builder = (_) => const ProfileMenuScreen();
                  break;
                case '/profile/view':
                  builder = (_) => const ProfileViewScreen();
                  break;
                case '/profile/friend':
                  final args = settings.arguments;
                  if (args is FriendPlayerProfileArguments) {
                    builder = (_) => FriendPlayerProfileScreen(
                      userId: args.userId,
                      initialName: args.initialName,
                      initialAvatarUrl: args.initialAvatarUrl,
                    );
                  } else {
                    builder = (_) => FriendPlayerProfileScreen(
                      userId: args?.toString() ?? '',
                    );
                  }
                  break;
                case '/profile/activity':
                  builder = (_) => const ActivityStatsScreen();
                  break;
                case '/step-goal':
                  builder = (_) => const StepGoalScreen();
                  break;

                case '/streak':
                  builder = (_) => const StreakScreen();
                  break;

                case '/profile/edit':
                  builder = (_) => const EditProfileScreen();
                  break;
                case '/profile/achievements':
                  builder = (_) => const ViewAchievementListScreen();
                  break;
                case '/friends':
                  builder = (_) => const MainLayout(child: SocialScreen());
                  break;
                case '/social':
                  builder = (_) => const MainLayout(child: SocialScreen());
                  break;
                case '/pvp':
                  builder = (_) => const PvPScreen();
                  break;
                case '/daily-reward':
                  builder = (_) => const DailyRewardScreen();
                  break;
                case '/daily-login-calendar':
                  builder = (_) => const DailyLoginScreen();
                  break;
                case '/notifications':
                  builder = (_) => const NotificationsScreen();
                  break;
                case '/spirit/detail':
                  builder = (_) => const SpiritDetailScreen();
                  break;
                case '/spirit/friend':
                  builder = (_) => fs.FriendSpiritScreen(
                    userId: settings.arguments?.toString() ?? '',
                  );
                  break;
                case '/story':
                  builder = (_) => const StoryScreen();
                  break;
                case '/seed':
                  builder = (_) => const SeedScreen();
                  break;
                case '/name-pet':
                  builder = (_) => const NamePetScreen();
                  break;

                // Trường hợp gõ bậy bạ route không tồn tại -> Cho về màn hình chào mừng
                default:
                  builder = (_) => const WelcomeScreen();
              }

              return MaterialPageRoute(
                builder: withPetBackground(builder, targetRoute: routeName),
                settings: settings,
              );
            },
          );
        },
      ),
    );
  }
}

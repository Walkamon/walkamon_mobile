import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:walkamon_mobile/screen/home/home_screen.dart';

import 'core/network/api_client.dart';
import 'data/datasources/remote/profile_view_screen_datasource.dart';
import 'data/repositories/profile_view_screen_repository.dart';

import 'core/theme/app_theme.dart';
import 'providers/game_state_provider.dart';
import 'widgets/layouts/root_layout.dart';
import 'widgets/layouts/auth_layout.dart';

import 'screen/auth/forgot_password_screen.dart';
import 'screen/auth/login_screen.dart';
import 'screen/auth/otp_verification_screen.dart';
import 'screen/auth/otp_register_screen.dart';
import 'screen/auth/register_screen.dart';
import 'screen/auth/reset_password_screen.dart';
import 'screen/auth/change_password_screen.dart';
import 'screen/auth/privacy_policy_screen.dart';
import 'screen/spirit/spirit_detail_screen.dart';
import 'screen/friends/friends_screen.dart';
import 'screen/gameplay/pvp_screen.dart';
import 'screen/welcome/daily_reward_screen.dart';
import 'screen/welcome/story_screen.dart';
import 'screen/welcome/name_pet_screen.dart';
import 'screen/welcome/seed_screen.dart';
import 'screen/notifications/notifications_screen.dart';

import 'screen/inventory/inventory_screen.dart';
import 'screen/missions/missions_screen.dart';
import 'screen/settings/seting_screen.dart';
import 'screen/shop/shop_screen.dart';

import 'screen/welcome/welcome_screen.dart';
import 'screen/profile/profile_menu_screen.dart';
import 'screen/profile/profile_view_screen.dart';
import 'screen/profile/edit_profile_screen.dart';

void main() {
  runApp(const WalkamonApp());
}

class WalkamonApp extends StatelessWidget {
  const WalkamonApp({super.key});

  @override
  Widget build(BuildContext context) {
    final apiClient = ApiClient();
    final profileRepository = ProfileViewScreenRepository(
      ProfileViewScreenDatasource(apiClient),
    );

    return ChangeNotifierProvider(
      create: (_) => GameStateProvider(profileRepository),
      child: Consumer<GameStateProvider>(
        builder: (context, gameState, _) {
          return MaterialApp(
            title: 'Walkamon',
            debugShowCheckedModeBanner: false,

            // ── Theme ──────────────────────────────────────────────────
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: gameState.settings.darkMode
                ? ThemeMode.dark
                : ThemeMode.light,

            scaffoldMessengerKey: RootLayout.messengerKey,
            builder: (context, child) => RootLayout(child: child!),

            // ── CẤU HÌNH ĐIỀU HƯỚNG AN TOÀN (ROUTE GUARD) ──────────────────
            initialRoute: '/',

            onGenerateRoute: (settings) {
              // 1. Lấy trạng thái đăng nhập thực tế của người dùng từ Provider
              final bool isLogged = gameState.isAuthenticated;
              final String? routeName = settings.name;

              // 2. Định nghĩa danh sách các Route cần bảo mật (Private)
              final privateRoutes = [
                '/home',
                '/inventory',
                '/shop',
                '/missions',
                '/settings',
                '/profile',
                '/profile/view',
                '/profile/edit',
                '/auth/change-password',
                '/friends',
                '/pvp',
                '/daily-reward',
                '/notifications',
                '/spirit/detail',
               
                '/seed',
                '/name-pet',
              ];

              // 3. LOGIC CHẶN CỬA 1: Chưa đăng nhập mà đòi vào trang Private -> Đưa về trang Login
              if (!isLogged && privateRoutes.contains(routeName)) {
                return MaterialPageRoute(
                  builder: (_) => const AuthLayout(child: LoginScreen()),
                  settings: const RouteSettings(
                    name: '/auth/login',
                  ), // Giữ đúng lịch sử định tuyến
                );
              }

              // 4. LOGIC CHẶN CỬA 2 (Tùy chọn UX): Đã đăng nhập rồi mà cố quay lại trang Welcome hoặc Login
              // -> Tự động chuyển thẳng họ vào trang chủ /home luôn cho tiện.
              if (isLogged &&
                  (routeName == '/' ||
                      routeName == '/auth/login' ||
                      routeName == '/auth/register')) {
                return MaterialPageRoute(
                  builder: (_) => const HomeScreen(title: 'Home'),
                  settings: const RouteSettings(name: '/home'),
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
                  builder = (_) => const AuthLayout(child: LoginScreen());
                  break;
                case '/auth/register':
                  builder = (_) => const AuthLayout(child: RegisterScreen());
                  break;
                case '/auth/forgot':
                  builder = (_) =>
                      const AuthLayout(child: ForgotPasswordScreen());
                  break;
                case '/auth/reset-password':
                  builder = (_) =>
                      const AuthLayout(child: ResetPasswordScreen());
                  break;
                case '/auth/change-password':
                  builder = (_) => const ChangePasswordScreen();
                  break;
                case '/auth/otp_verification':
                  builder = (_) => const AuthLayout(child: OTP_Verification());
                  break;

                case '/auth/otp_register':
                  builder = (_) => const AuthLayout(child: OTP_Register());
                  break;
                case '/auth/privacy':
                  builder = (_) => const AuthLayout(child: PrivacyPolicyScreen());
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

                case '/profile/edit':
                  builder = (_) => const EditProfileScreen();
                  break;
                case '/friends':
                  builder = (_) => const FriendsScreen();
                  break;
                case '/pvp':
                  builder = (_) => const PvPScreen();
                  break;
                case '/daily-reward':
                  builder = (_) => const DailyRewardScreen();
                  break;
                case '/notifications':
                  builder = (_) => const NotificationsScreen();
                  break;
                case '/spirit/detail':
                  builder = (_) => const SpiritDetailScreen();
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

              return MaterialPageRoute(builder: builder, settings: settings);
            },
          );
        },
      ),
    );
  }
}

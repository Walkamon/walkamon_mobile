import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/game_state_provider.dart';
import 'widgets/layouts/root_layout.dart';
import 'widgets/layouts/auth_layout.dart';

import 'screen/auth/forgot_password_screen.dart';
import 'screen/auth/login_screen.dart';
import 'screen/auth/otp_verification_screen.dart';
import 'screen/auth/register_screen.dart';
import 'screen/auth/reset_password_screen.dart';
import 'screen/inventory/inventory_screen.dart';
import 'screen/placeholder/placeholder_screen.dart';
import 'screen/settings/seting.dart';
import 'screen/shop/shop_screen.dart';
import 'screen/welcome/welcome_screen.dart';

void main() {
  runApp(const WalkamonApp());
}

class WalkamonApp extends StatelessWidget {
  const WalkamonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameStateProvider(),
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

            // ── RootLayout + Toaster (replaces ThemeProvider + Sonner) ─
            // Wraps every screen in the paw-print background texture.
            scaffoldMessengerKey: RootLayout.messengerKey,
            builder: (context, child) => RootLayout(child: child!),

            // ── Routes ─────────────────────────────────────────────────
            initialRoute: '/',
            routes: {
              // Welcome — full-screen, no auth chrome
              '/': (_) => const WelcomeScreen(),

              // Story placeholder
              '/story': (_) => const PlaceholderScreen(title: 'Story'),

              // Auth screens — wrapped in AuthLayout (scrollable, max-w-md)
              '/auth/login': (_) => const AuthLayout(child: LoginScreen()),
              '/auth/register': (_) =>
                  const AuthLayout(child: RegisterScreen()),
              '/auth/forgot': (_) =>
                  const AuthLayout(child: ForgotPasswordScreen()),
                '/auth/reset-password': (_) =>
                  const AuthLayout(child: ResetPasswordScreen()),
              '/auth/otp': (_) => const AuthLayout(child: OTPScreen()),

              // Main app — will be wrapped in MainLayout once BottomNav is ready
              '/home': (_) => const PlaceholderScreen(title: 'Home'),
              '/inventory': (_) => const InventoryScreen(),
              '/shop': (_) => const ShopScreen(),
              '/settings': (_) => const SettingScreen(),
            },
          );
        },
      ),
    );
  }
}

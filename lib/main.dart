import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/game_state_provider.dart';
import 'widgets/layouts/root_layout.dart';
import 'widgets/layouts/auth_layout.dart';

import 'features/auth/forgot_password_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/otp_screen.dart';
import 'features/placeholder/placeholder_screen.dart';
import 'features/welcome/welcome_screen.dart';

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
                  const AuthLayout(child: PlaceholderScreen(title: 'Đăng Ký')),
              '/auth/forgot': (_) =>
                  const AuthLayout(child: ForgotPasswordScreen()),
              '/auth/otp': (_) => const AuthLayout(child: OTPScreen()),

              // Main app — will be wrapped in MainLayout once BottomNav is ready
              '/home': (_) => const PlaceholderScreen(title: 'Home'),
            },
          );
        },
      ),
    );
  }
}

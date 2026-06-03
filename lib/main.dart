import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/game_state_provider.dart';
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
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: gameState.settings.darkMode
                ? ThemeMode.dark
                : ThemeMode.light,
            initialRoute: '/',
            routes: {
              '/': (_) => const WelcomeScreen(),
              '/story': (_) => const PlaceholderScreen(title: 'Story'),
              '/auth/login': (_) => const LoginScreen(),
              '/auth/register': (_) =>
                  const PlaceholderScreen(title: 'Đăng Ký'),
              '/auth/forgot': (_) => const ForgotPasswordScreen(),
              '/auth/otp': (_) => const OTPScreen(),
              '/home': (_) => const PlaceholderScreen(title: 'Home'),
            },
          );
        },
      ),
    );
  }
}

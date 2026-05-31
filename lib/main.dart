import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/game_state_provider.dart';
import 'screens/placeholder/placeholder_screen.dart';
import 'screens/welcome/welcome_screen.dart';

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
            themeMode:
                gameState.settings.darkMode ? ThemeMode.dark : ThemeMode.light,
            initialRoute: '/',
            routes: {
              '/': (_) => const WelcomeScreen(),
              '/story': (_) => const PlaceholderScreen(title: 'Story'),
              '/auth/login': (_) =>
                  const PlaceholderScreen(title: 'Đăng Nhập'),
              '/auth/register': (_) =>
                  const PlaceholderScreen(title: 'Đăng Ký'),
              '/home': (_) => const PlaceholderScreen(title: 'Home'),
            },
          );
        },
      ),
    );
  }
}

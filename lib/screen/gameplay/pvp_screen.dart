import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../../providers/presence_provider.dart';
import '../../providers/pvp_provider.dart';
import '../../widgets/common/bottom_navigation.dart';
import 'pvp/pvp_screen.dart';

class PvPScreen extends StatelessWidget {
  const PvPScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final presenceProvider = context.read<PresenceProvider>();
    return ChangeNotifierProvider(
      create: (_) =>
          PvpProvider(presenceProvider: presenceProvider)
            ..fetchWaitingRoomData(),
      child: const Scaffold(
        extendBody: true,
        body: const PvPMainScreen(),
        bottomNavigationBar: BottomNavigation(),
      ),
    );
  }
}

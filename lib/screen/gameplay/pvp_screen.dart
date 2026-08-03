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
      child: Consumer<PvpProvider>(
        builder: (context, pvpProvider, _) {
          final hideBottomNavigation =
              pvpProvider.matchmakingState == PvpMatchmakingState.connecting ||
              pvpProvider.matchmakingState == PvpMatchmakingState.waiting ||
              pvpProvider.matchmakingState == PvpMatchmakingState.countdown ||
              pvpProvider.matchmakingState == PvpMatchmakingState.running ||
              pvpProvider.matchmakingState == PvpMatchmakingState.finished ||
              pvpProvider.isRaceFinished;

          return Scaffold(
            extendBody: true,
            body: const PvPMainScreen(),
            bottomNavigationBar: hideBottomNavigation
                ? null
                : const BottomNavigation(),
          );
        },
      ),
    );
  }
}

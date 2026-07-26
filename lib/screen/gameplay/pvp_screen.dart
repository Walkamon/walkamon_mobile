import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import '../../providers/pvp_provider.dart';
import 'pvp/pvp_screen.dart';

class PvPScreen extends StatelessWidget {
  const PvPScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PvpProvider()..fetchWaitingRoomData(),
      child: const Scaffold(body: SafeArea(child: PvPMainScreen())),
    );
  }
}

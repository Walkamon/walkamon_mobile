import 'package:flutter/material.dart';

import 'pvp/pvp_sprint_screen.dart';

class PvPScreen extends StatelessWidget {
  const PvPScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: PvPSprintScreen()));
  }
}

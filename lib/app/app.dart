import 'package:flutter/material.dart';
import 'package:lane_keeper/core/theme/app_theme.dart';
import 'package:lane_keeper/features/auth/ui/auth_gate.dart';

class LaneKeeperApp extends StatelessWidget {
  const LaneKeeperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LaneKeeper',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthGate(),
    );
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lane_keeper/app/app.dart';
import 'package:lane_keeper/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint("Firebase init failed (expected during prototype w/o config): $e");
    // Continue running app, but Auth/Firestore will fail until configured.
  }

  runApp(
    const ProviderScope(
      child: LaneKeeperApp(),
    ),
  );
}

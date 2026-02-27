import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'shared/services/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive local storage
  await HiveService.init();

  // Initialize Firebase
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase not configured locally yet - continue without fatal error
  }

  runApp(const ProviderScope(child: App()));
}

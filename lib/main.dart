import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/theme_controller.dart';
import 'core/firebase/firebase_sync_service.dart';
import 'core/firebase/firebase_authentication_service.dart';
import 'data/repositories/academya_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = ThemeController(
    preferences: SharedPreferencesAsync(),
  );
  await themeController.load();

  final firebaseSyncService = FirebaseSyncService();
  final firebaseStatus = await firebaseSyncService.initialize();
  final repository = AcademyaRepository(
    firebaseSyncService: firebaseSyncService,
    authenticationService: FirebaseAuthenticationService(
      auth: firebaseStatus.isConnected ? FirebaseAuth.instance : null,
      unavailableReason: firebaseStatus.message,
    ),
  );

  await repository.initializeSession();

  runApp(
    AcademiaApp(
      repository: repository,
      firebaseStatus: firebaseStatus,
      themeController: themeController,
    ),
  );
}

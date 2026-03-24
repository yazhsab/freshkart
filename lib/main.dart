import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import 'package:freshkart/core/notifications/notification_service.dart';
import 'package:freshkart/core/router/app_router.dart';
import 'package:freshkart/core/storage/local_storage.dart';
import 'package:freshkart/core/supabase/client.dart';
import 'package:freshkart/core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initializeFirebase();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  initAdminClient();

  await LocalStorage.initialize();

  runApp(const ProviderScope(child: FreshKartApp()));
}

Future<void> _initializeFirebase() {
  if (!kIsWeb) {
    return Firebase.initializeApp();
  }

  return Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: String.fromEnvironment(
        'FIREBASE_API_KEY',
        defaultValue: 'placeholder-api-key',
      ),
      appId: String.fromEnvironment(
        'FIREBASE_APP_ID',
        defaultValue: '1:1234567890:web:placeholder',
      ),
      messagingSenderId: String.fromEnvironment(
        'FIREBASE_MESSAGING_SENDER_ID',
        defaultValue: '1234567890',
      ),
      projectId: String.fromEnvironment(
        'FIREBASE_PROJECT_ID',
        defaultValue: 'freshkart-local',
      ),
      authDomain: String.fromEnvironment(
        'FIREBASE_AUTH_DOMAIN',
        defaultValue: 'freshkart-local.firebaseapp.com',
      ),
      storageBucket: String.fromEnvironment(
        'FIREBASE_STORAGE_BUCKET',
        defaultValue: 'freshkart-local.appspot.com',
      ),
    ),
  );
}

class FreshKartApp extends ConsumerStatefulWidget {
  const FreshKartApp({super.key});

  @override
  ConsumerState<FreshKartApp> createState() => _FreshKartAppState();
}

class _FreshKartAppState extends ConsumerState<FreshKartApp> {
  bool _notificationsInitialized = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    // Initialize notifications after the router is available.
    if (!_notificationsInitialized) {
      _notificationsInitialized = true;
      NotificationService.initialize(router);
    }

    return MaterialApp.router(
      title: 'FreshKart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}

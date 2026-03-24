import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import 'package:freshkart_worker/core/config/app_config.dart';
import 'package:freshkart_worker/core/config/locale_provider.dart';
import 'package:freshkart_worker/core/notifications/notification_service.dart';
import 'package:freshkart_worker/core/router/app_router.dart';
import 'package:freshkart_worker/core/storage/local_storage.dart';
import 'package:freshkart_worker/core/theme/app_theme.dart';
import 'package:freshkart_worker/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  await _initializeFirebase();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  await LocalStorage.initialize();

  runApp(const ProviderScope(child: FreshKartWorkerApp()));
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: String.fromEnvironment(
          'FIREBASE_API_KEY',
          defaultValue: 'placeholder-api-key',
        ),
        appId: String.fromEnvironment(
          'FIREBASE_APP_ID',
          defaultValue: '1:1234567890:android:placeholder',
        ),
        messagingSenderId: String.fromEnvironment(
          'FIREBASE_MESSAGING_SENDER_ID',
          defaultValue: '1234567890',
        ),
        projectId: String.fromEnvironment(
          'FIREBASE_PROJECT_ID',
          defaultValue: 'freshkart-local',
        ),
        authDomain: kIsWeb
            ? const String.fromEnvironment(
                'FIREBASE_AUTH_DOMAIN',
                defaultValue: 'freshkart-local.firebaseapp.com',
              )
            : null,
        storageBucket: String.fromEnvironment(
          'FIREBASE_STORAGE_BUCKET',
          defaultValue: 'freshkart-local.appspot.com',
        ),
      ),
    );
  }
}

class FreshKartWorkerApp extends ConsumerStatefulWidget {
  const FreshKartWorkerApp({super.key});

  @override
  ConsumerState<FreshKartWorkerApp> createState() => _FreshKartWorkerAppState();
}

class _FreshKartWorkerAppState extends ConsumerState<FreshKartWorkerApp> {
  bool _notificationsInitialized = false;

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    if (!_notificationsInitialized) {
      _notificationsInitialized = true;
      NotificationService.initialize(router);
    }

    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'FreshKart Worker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}

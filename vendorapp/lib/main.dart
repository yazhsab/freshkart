import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import 'package:freshkart_vendor/core/config/locale_provider.dart';
import 'package:freshkart_vendor/core/notifications/notification_service.dart';
import 'package:freshkart_vendor/core/router/app_router.dart';
import 'package:freshkart_vendor/core/storage/local_storage.dart';
import 'package:freshkart_vendor/core/theme/app_theme.dart';
import 'package:freshkart_vendor/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Supabase
  await Supabase.initialize(
    url: const String.fromEnvironment(
      'SUPABASE_URL',
      defaultValue: 'https://placeholder.supabase.co',
    ),
    anonKey: const String.fromEnvironment(
      'SUPABASE_ANON_KEY',
      defaultValue: '',
    ),
  );

  // Initialize local storage
  await LocalStorage.instance.initialize();

  // Initialize notification service
  await VendorNotificationService.initialize();

  runApp(const ProviderScope(child: VendorApp()));
}

class VendorApp extends ConsumerWidget {
  const VendorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'FreshKart Vendor',
      debugShowCheckedModeBanner: false,
      theme: VendorTheme.lightTheme,
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

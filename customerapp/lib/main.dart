import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;

import 'package:freshkart_customer/core/config/locale_provider.dart';
import 'package:freshkart_customer/core/notifications/notification_service.dart';
import 'package:freshkart_customer/core/router/app_router.dart';
import 'package:freshkart_customer/core/storage/local_storage.dart';
import 'package:freshkart_customer/core/theme/app_theme.dart';
import 'package:freshkart_customer/l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  await LocalStorage.initialize();

  runApp(const ProviderScope(child: FreshKartApp()));
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

    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'FreshKart',
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

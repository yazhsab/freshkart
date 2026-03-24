import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:freshkart_delivery/core/config/locale_provider.dart';
import 'package:freshkart_delivery/core/config/supabase_config.dart';
import 'package:freshkart_delivery/core/storage/local_storage.dart';
import 'package:freshkart_delivery/core/notifications/notification_service.dart';
import 'package:freshkart_delivery/core/theme/app_theme.dart';
import 'package:freshkart_delivery/core/router/app_router.dart';
import 'package:freshkart_delivery/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await SupabaseConfig.initialize();
  await LocalStorage.initialize();
  await NotificationService.instance.initialize();

  runApp(const ProviderScope(child: DeliveryApp()));
}

class DeliveryApp extends ConsumerWidget {
  const DeliveryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'FreshKart Delivery',
      theme: DeliveryTheme.lightTheme,
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

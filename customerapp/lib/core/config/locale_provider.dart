import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../storage/local_storage.dart';

const String kLocaleKey = 'preferred_locale';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>(
  (ref) => LocaleNotifier(),
);

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final saved = LocalStorage.getString(kLocaleKey);
    if (saved != null) {
      state = Locale(saved);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await LocalStorage.setString(kLocaleKey, locale.languageCode);
  }

  Future<void> toggleLocale() async {
    final newLocale = state.languageCode == 'en'
        ? const Locale('ta')
        : const Locale('en');
    await setLocale(newLocale);
  }
}

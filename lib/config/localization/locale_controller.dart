import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage {
  english('English', Locale('en', 'US')),
  spanish('Español', Locale('es', 'ES')),
  german('Deutsch', Locale('de', 'DE'));

  const AppLanguage(this.label, this.locale);
  final String label;
  final Locale locale;

  static AppLanguage fromTag(String? value) => AppLanguage.values.firstWhere(
    (language) => language.locale.toLanguageTag() == value,
    orElse: () => AppLanguage.english,
  );
}

class LocaleController {
  LocaleController._();
  static final instance = LocaleController._();
  static const _preferenceKey = 'app_locale';
  final ValueNotifier<AppLanguage> language = ValueNotifier(
    AppLanguage.english,
  );

  Locale get locale => language.value.locale;

  Future<void> init() async {
    final preferences = await SharedPreferences.getInstance();
    language.value = AppLanguage.fromTag(preferences.getString(_preferenceKey));
  }

  Future<void> setLanguage(AppLanguage value) async {
    language.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_preferenceKey, value.locale.toLanguageTag());
  }
}

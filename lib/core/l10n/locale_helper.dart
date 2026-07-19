import 'package:flutter/material.dart';

class LocaleHelper {
  static const supportedLocales = [Locale('vi'), Locale('en')];

  static Locale localeFromCode(String languageCode) {
    final normalized = languageCode.toLowerCase();
    if (normalized.startsWith('en')) {
      return const Locale('en');
    }
    return const Locale('vi');
  }

  static String codeFromLocale(Locale locale) {
    return locale.languageCode == 'en' ? 'en-US' : 'vi-VN';
  }

  static bool isVietnamese(String languageCode) {
    return languageCode.toLowerCase().startsWith('vi');
  }
}

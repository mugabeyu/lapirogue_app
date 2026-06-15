import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LanguageController extends ChangeNotifier {
  LanguageController._();

  static final LanguageController instance = LanguageController._();

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  bool get isEnglish => _locale.languageCode == 'en';

  void setLocale(Locale locale) {
    if (_locale == locale) {
      return;
    }

    _locale = locale;
    Intl.defaultLocale = locale.languageCode;
    notifyListeners();
  }

  void toggleEnglishFrench() {
    setLocale(isEnglish ? const Locale('fr') : const Locale('en'));
  }
}

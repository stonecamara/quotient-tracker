import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LocaleService extends ChangeNotifier {
  static const String _localeKey = 'appLocale';
  static final Box _settings = Hive.box('settings');

  String _locale = 'fr';

  String get locale => _locale;
  bool get isFrench => _locale == 'fr';

  LocaleService() {
    _locale = _settings.get(_localeKey, defaultValue: 'fr');
  }

  Future<void> setLocale(String lang) async {
    _locale = lang;
    await _settings.put(_localeKey, lang);
    notifyListeners();
  }

  // ── Static helpers pour traduire sans Provider ──
  static String _t(String fr, String en, String locale) {
    return locale == 'fr' ? fr : en;
  }

  static String t(String locale, {required String fr, required String en}) {
    return _t(fr, en, locale);
  }
}

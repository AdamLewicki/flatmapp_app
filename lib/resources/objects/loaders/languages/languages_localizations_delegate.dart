import 'dart:async';

import 'package:flutter/material.dart';

import 'languages_loader.dart';

class LanguagesLocalizationsDelegate
    extends LocalizationsDelegate<LanguagesLoader> {
  const LanguagesLocalizationsDelegate();

  // TODO add all languages available here
  @override
  bool isSupported(Locale locale) =>
      ['pl', 'en', 'es'].contains(locale.languageCode);

  @override
  Future<LanguagesLoader> load(Locale locale) async {

    LanguagesLoader localizations = new LanguagesLoader(locale);
    await localizations.load();

    print("Loading ${locale.languageCode} language...");

    return localizations;
  }

  @override
  bool shouldReload(LanguagesLocalizationsDelegate old) => false;
}

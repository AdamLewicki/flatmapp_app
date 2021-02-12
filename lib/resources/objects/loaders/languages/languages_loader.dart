import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LanguagesLoader {
  LanguagesLoader(this.locale);

  final Locale locale;

  static LanguagesLoader of(BuildContext context) {
    return Localizations.of<LanguagesLoader>(context, LanguagesLoader);
  }

  Map<String, String> _sentences;

  Future<bool> load() async {
    String data = await rootBundle
        .loadString('assets/lang/${this.locale.languageCode}.json');
    Map<String, dynamic> _result = json.decode(data);

    this._sentences = new Map();
    _result.forEach((String key, dynamic value) {
      this._sentences[key] = value.toString();
    });

    return true;
  }

  String translate(String key) {
    return this._sentences[key] ?? " ";
  }

  String getKey(String value) {
    print("loading key for: " + value);
    print("key: " +
        this._sentences.keys.firstWhere((k) => this._sentences[k] == value,
            orElse: () => null));
    return this
        ._sentences
        .keys
        .firstWhere((k) => this._sentences[k] == value, orElse: () => null);
  }
}

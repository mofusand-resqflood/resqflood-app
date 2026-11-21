import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:resqflood_app/main.dart';

void main() {
  test('ResQFlood default language is English', () {
    expect(appLocale.value, const Locale('en'));
  });
}

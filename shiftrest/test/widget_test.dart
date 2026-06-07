import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:shift_rest/app.dart';
import 'package:shift_rest/core/providers.dart';

void main() {
  testWidgets('ShiftRest app builds without crashing', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: ShiftRestApp(prefs: prefs),
      ),
    );

    expect(find.byType(MaterialApp), findsWidgets);
  });
}

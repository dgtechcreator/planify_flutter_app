import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:planify_app/main.dart';

void main() {
  testWidgets('Shows login screen when no token is saved',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const PlanifyApp());
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Planify'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email or Username'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
  });
}

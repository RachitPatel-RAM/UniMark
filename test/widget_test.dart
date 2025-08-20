// This is a basic Flutter widget test for UniMark app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:unimark/main.dart';

void main() {
  testWidgets('UniMark app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const UniMarkApp());

    // Verify that the splash screen loads
    expect(find.text('UniMark'), findsOneWidget);
    expect(find.text('Smart Attendance System'), findsOneWidget);

    // Wait for splash screen to complete
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Verify that we navigate to login screen
    expect(find.text('Welcome Back'), findsOneWidget);
  });
}

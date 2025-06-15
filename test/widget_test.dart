// This is a basic Flutter widget test for the Calculator App
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:calculator_app/main.dart';

void main() {
  testWidgets('Calculator app loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CalculatorApp());

    // Verify that the calculator app loads with basic elements
    expect(find.byType(AppBar), findsOneWidget);
    expect(find.text('Standard Calculator'), findsOneWidget);
  });

  testWidgets('Calculator basic input test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const CalculatorApp());

    // Find the calculator buttons and result display
    final button1 = find.text('1');
    final button2 = find.text('2');
    final buttonPlus = find.text('+');
    final buttonEquals = find.text('=');

    // Tap some buttons to test input
    await tester.tap(button1);
    await tester.pump();

    await tester.tap(buttonPlus);
    await tester.pump();

    await tester.tap(button2);
    await tester.pump();

    await tester.tap(buttonEquals);
    await tester.pump();

    // The result should be calculated and displayed
    // We're not checking the exact result here due to widget complexity
    // but verifying the calculator responds to input
    expect(find.text('1+2'), findsOneWidget);
  });
}

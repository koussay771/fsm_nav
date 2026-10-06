// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsm_nav/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const FsmNavApp());
    await tester.pump(const Duration(milliseconds: 500));
    // Verify the app scaffold renders
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

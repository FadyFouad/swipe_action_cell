import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('SwipeActionCell', () {
    testWidgets('renders child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwipeActionCell(
              child: Text('hello'),
            ),
          ),
        ),
      );
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('renders child when enabled is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwipeActionCell(
              enabled: true,
              child: Text('enabled'),
            ),
          ),
        ),
      );
      expect(find.text('enabled'), findsOneWidget);
    });

    testWidgets('renders child when enabled is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwipeActionCell(
              enabled: false,
              child: Text('disabled'),
            ),
          ),
        ),
      );
      expect(find.text('disabled'), findsOneWidget);
    });
  });
}

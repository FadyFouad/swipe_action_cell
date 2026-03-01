import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('SwipeActionCell.counter()', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCell.counter(
            child: const ListTile(title: Text('Counter item')),
            count: 3,
            onCountChanged: (_) {},
          ),
        ),
      ));
      expect(find.text('Counter item'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('SwipeActionCell.delete()', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCell.delete(
            child: const ListTile(title: Text('Delete item')),
            onDeleted: () {},
          ),
        ),
      ));
      expect(find.text('Delete item'), findsOneWidget);
    });
  });

  group('SwipeActionCell.archive()', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCell.archive(
            child: const ListTile(title: Text('Archive item')),
            onArchived: () {},
          ),
        ),
      ));
      expect(find.text('Archive item'), findsOneWidget);
    });
  });
}

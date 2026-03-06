import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('SwipeActionCell.favorite()', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCell.favorite(
            child: const ListTile(title: Text('Favorite item')),
            isFavorited: false,
            onToggle: (_) {},
          ),
        ),
      ));
      expect(find.text('Favorite item'), findsOneWidget);
    });

    testWidgets('does NOT have fullSwipeConfig', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCell.favorite(
            child: const ListTile(title: Text('Favorite item')),
            isFavorited: false,
            onToggle: (_) {},
          ),
        ),
      ));
      final cell = tester.widget<SwipeActionCell>(find.byType(SwipeActionCell));
      expect(cell.rightSwipeConfig?.fullSwipeConfig, isNull);
    });
  });

  group('SwipeActionCell.checkbox()', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCell.checkbox(
            child: const ListTile(title: Text('Checkbox item')),
            isChecked: false,
            onChanged: (_) {},
          ),
        ),
      ));
      expect(find.text('Checkbox item'), findsOneWidget);
    });

    testWidgets('does NOT have fullSwipeConfig', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCell.checkbox(
            child: const ListTile(title: Text('Checkbox item')),
            isChecked: false,
            onChanged: (_) {},
          ),
        ),
      ));
      final cell = tester.widget<SwipeActionCell>(find.byType(SwipeActionCell));
      expect(cell.rightSwipeConfig?.fullSwipeConfig, isNull);
    });
  });
}

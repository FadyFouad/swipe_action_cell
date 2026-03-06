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

    testWidgets('full-swipe triggers onDeleted', (tester) async {
      bool deleted = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell.delete(
                child: const SizedBox(height: 100, child: Text('Delete item')),
                onDeleted: () => deleted = true,
              ),
            ),
          ),
        ),
      ));

      // Drag 80% (320 pixels on 400 width)
      await tester.drag(find.text('Delete item'), const Offset(-320, 0));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });

    testWidgets('full-swipe can be disabled by passing null', (tester) async {
      bool deleted = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell.delete(
                child: const SizedBox(height: 100, child: Text('Delete item')),
                onDeleted: () => deleted = true,
                fullSwipeConfig: null,
              ),
            ),
          ),
        ),
      ));

      // Drag 80% (320 pixels on 400 width)
      await tester.drag(find.text('Delete item'), const Offset(-320, 0));
      await tester.pumpAndSettle();

      expect(deleted, isFalse);
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

    testWidgets('full-swipe triggers onArchived', (tester) async {
      bool archived = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell.archive(
                child: const SizedBox(height: 100, child: Text('Archive item')),
                onArchived: () => archived = true,
              ),
            ),
          ),
        ),
      ));

      // Drag 80% (320 pixels on 400 width)
      await tester.drag(find.text('Archive item'), const Offset(-320, 0));
      await tester.pumpAndSettle();

      expect(archived, isTrue);
    });

    testWidgets('full-swipe can be disabled by passing null', (tester) async {
      bool archived = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell.archive(
                child: const SizedBox(height: 100, child: Text('Archive item')),
                onArchived: () => archived = true,
                fullSwipeConfig: null,
              ),
            ),
          ),
        ),
      ));

      // Drag 80% (320 pixels on 400 width)
      await tester.drag(find.text('Archive item'), const Offset(-320, 0));
      await tester.pumpAndSettle();

      expect(archived, isFalse);
    });
  });
}

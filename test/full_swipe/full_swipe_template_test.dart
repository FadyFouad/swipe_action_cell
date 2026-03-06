import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('Full-Swipe US5 Template Integration', () {
    testWidgets('SwipeActionCell.delete has full-swipe enabled by default', (tester) async {
      bool deleted = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell.delete(
                child: const SizedBox(height: 100, child: Text('Item')),
                onDeleted: () => deleted = true,
              ),
            ),
          ),
        ),
      ));

      // Release at 80% (320px)
      await tester.drag(find.text('Item'), const Offset(-320, 0));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });

    testWidgets('SwipeActionCell.archive has full-swipe enabled by default', (tester) async {
      bool archived = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell.archive(
                child: const SizedBox(height: 100, child: Text('Item')),
                onArchived: () => archived = true,
              ),
            ),
          ),
        ),
      ));

      await tester.drag(find.text('Item'), const Offset(-320, 0));
      await tester.pumpAndSettle();

      expect(archived, isTrue);
    });
  });
}

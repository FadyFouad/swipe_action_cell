import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('SwipeActionCell.standard()', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCell.standard(
            child: const ListTile(title: Text('Standard item')),
            onFavorited: (_) {},
            actions: [
              SwipeAction(
                icon: const Icon(Icons.reply),
                label: 'Reply',
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                onTap: () {},
              ),
            ],
          ),
        ),
      ));
      expect(find.text('Standard item'), findsOneWidget);
    });

    testWidgets('full-swipe triggers first action in panel', (tester) async {
      bool actionFired = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell.standard(
                child: const SizedBox(height: 100, child: Text('Standard item')),
                actions: [
                  SwipeAction(
                    icon: const Icon(Icons.reply),
                    label: 'Reply',
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    onTap: () => actionFired = true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ));

      // Drag 80% (320 pixels on 400 width)
      await tester.drag(find.text('Standard item'), const Offset(-320, 0));
      await tester.pumpAndSettle();

      expect(actionFired, isTrue);
    });

    testWidgets('full-swipe can be disabled by passing null', (tester) async {
      bool actionFired = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell.standard(
                child: const SizedBox(height: 100, child: Text('Standard item')),
                fullSwipeConfig: null,
                actions: [
                  SwipeAction(
                    icon: const Icon(Icons.reply),
                    label: 'Reply',
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    onTap: () => actionFired = true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ));

      // Drag 80% (320 pixels on 400 width)
      await tester.drag(find.text('Standard item'), const Offset(-320, 0));
      await tester.pumpAndSettle();

      expect(actionFired, isFalse);
    });
  });
}

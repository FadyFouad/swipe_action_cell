import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('SwipeActionCell Migration (US1)', () {
    testWidgets('rightSwipeConfig fires callbacks identical to old API',
        (tester) async {
      double? value;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCell(
            key: Key("cell1"),
            rightSwipeConfig: RightSwipeConfig(
              stepValue: 20,
              maxValue: 100,
              onSwipeCompleted: (v) => value = v,
            ),
            child: const SizedBox(width: 400, height: 100, child: Text('cell')),
          ),
        ),
      ));

      // Simulate swipe to 30 (past step 20)
      final gesture = await tester.startGesture(const Offset(10, 10));
      await gesture.moveBy(const Offset(200, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(value, greaterThan(0));
    });

    testWidgets('leftSwipeConfig autoTrigger fires onActionTriggered',
        (tester) async {
      bool triggered = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCell(
            key: Key("cell1"),
            leftSwipeConfig: LeftSwipeConfig(
              mode: LeftSwipeMode.autoTrigger,
              onActionTriggered: () => triggered = true,
            ),
            child: const SizedBox(width: 400, height: 100, child: Text('cell')),
          ),
        ),
      ));

      // Simulate swipe left past threshold
      final gesture = await tester.startGesture(const Offset(300, 10));
      await gesture.moveBy(const Offset(-260, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(triggered, isTrue);
    });

    testWidgets('visualConfig renders backgrounds', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCell(
            key: Key("cell1"),
            visualConfig: SwipeVisualConfig(
              leftBackground: (context, progress) => const Text('LEFT_BG'),
              rightBackground: (context, progress) => const Text('RIGHT_BG'),
            ),
            child: const SizedBox(width: 400, height: 100, child: Text('cell')),
          ),
        ),
      ));

      // Swipe right to reveal right background
      await tester.drag(find.text('cell'), const Offset(50, 0));
      await tester.pump();
      expect(find.text('RIGHT_BG'), findsOneWidget);

      // Reset and swipe left
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCell(
            key: Key("cell2"),
            visualConfig: SwipeVisualConfig(
              leftBackground: (context, progress) => const Text('LEFT_BG'),
              rightBackground: (context, progress) => const Text('RIGHT_BG'),
            ),
            child: const SizedBox(width: 400, height: 100, child: Text('cell')),
          ),
        ),
      ));
      await tester.drag(find.text('cell'), const Offset(-50, 0));
      await tester.pump();
      expect(find.text('LEFT_BG'), findsOneWidget);
    });

    testWidgets(
        '(c) leftSwipeConfig reveal mode shows action panel after swipe',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCell(
            key: const Key('cell-reveal'),
            leftSwipeConfig: LeftSwipeConfig(
              mode: LeftSwipeMode.reveal,
              actions: [
                SwipeAction(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.delete),
                  onTap: () {},
                ),
              ],
            ),
            child: const SizedBox(width: 400, height: 100, child: Text('cell')),
          ),
        ),
      ));

      // Swipe left far enough to trigger reveal
      final gesture = await tester.startGesture(const Offset(300, 10));
      await gesture.moveBy(const Offset(-260, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      // The SwipeActionPanel should now be visible in the tree
      expect(find.byType(SwipeActionPanel), findsOneWidget);
    });

    testWidgets('enabled: false passes through touches', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCell(
            key: Key("cell1"),
            enabled: false,
            rightSwipeConfig: RightSwipeConfig(stepValue: 20, maxValue: 100),
            child: GestureDetector(
              onTap: () => tapped = true,
              child:
                  const SizedBox(width: 400, height: 100, child: Text('cell')),
            ),
          ),
        ),
      ));

      await tester.tap(find.text('cell'));
      expect(tapped, isTrue);
    });

    testWidgets('(f) no-config cell renders without error', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: SwipeActionCell(
            child: Text('bare cell'),
          ),
        ),
      ));
      expect(find.text('bare cell'), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  const rightKey = Key('right_bg');
  const leftKey = Key('left_bg');
  const childKey = Key('child');

  group('SwipeActionCell Core (F1 & F2)', () {
    testWidgets('renders background widgets correctly during swipe',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionCell(
              visualConfig: SwipeVisualConfig(
                rightBackground: (context, progress) =>
                    const SizedBox(key: rightKey),
                leftBackground: (context, progress) =>
                    const SizedBox(key: leftKey),
              ),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      // Swipe right -> reveal rightBackground
      await tester.drag(find.byType(SwipeActionCell), const Offset(50, 0));
      await tester.pump();
      expect(find.byKey(rightKey), findsOneWidget);
      expect(find.byKey(leftKey), findsNothing);

      // Reset and swipe left -> reveal leftBackground
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionCell(
              key: const Key('cell2'),
              visualConfig: SwipeVisualConfig(
                rightBackground: (context, progress) =>
                    const SizedBox(key: rightKey),
                leftBackground: (context, progress) =>
                    const SizedBox(key: leftKey),
              ),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );
      await tester.drag(find.byType(SwipeActionCell), const Offset(-50, 0));
      await tester.pump();
      expect(find.byKey(leftKey), findsOneWidget);
      expect(find.byKey(rightKey), findsNothing);
    });

    testWidgets('gestureConfig.enabledDirections restricts movement',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionCell(
              visualConfig: SwipeVisualConfig(
                rightBackground: (context, progress) =>
                    const SizedBox(key: rightKey),
                leftBackground: (context, progress) =>
                    const SizedBox(key: leftKey),
              ),
              gestureConfig: const SwipeGestureConfig(
                enabledDirections: {SwipeDirection.right},
              ),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      // Try swiping left
      await tester.drag(find.byType(SwipeActionCell), const Offset(-50, 0));
      await tester.pump();
      expect(find.byKey(leftKey), findsNothing);

      // Try swiping right
      await tester.drag(find.byType(SwipeActionCell), const Offset(50, 0));
      await tester.pump();
      expect(find.byKey(rightKey), findsOneWidget);
    });

    testWidgets('enabled: false disables all swipe gestures', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionCell(
              enabled: false,
              visualConfig: SwipeVisualConfig(
                rightBackground: (context, progress) =>
                    const SizedBox(key: rightKey),
              ),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      await tester.drag(find.byType(SwipeActionCell), const Offset(50, 0));
      await tester.pump();
      expect(find.byKey(rightKey), findsNothing);
    });
  });
}

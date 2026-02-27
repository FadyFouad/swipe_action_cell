import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';
import 'package:swipe_action_cell/src/actions/intentional/swipe_action_panel.dart';

void main() {
  group('SwipeActionCell Progressive Reveal (F003)', () {
    testWidgets('action panel expands smoothly during left swipe', (tester) async {
      const panelWidth = 160.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionCell(
              leftSwipeConfig: LeftSwipeConfig(
                mode: LeftSwipeMode.reveal,
                actionPanelWidth: panelWidth,
                actions: [
                  SwipeAction(
                    icon: const Icon(Icons.delete),
                    onTap: () {},
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  SwipeAction(
                    icon: const Icon(Icons.archive),
                    onTap: () {},
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ],
              ),
              child: const SizedBox(width: 400, height: 100),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(tester.getCenter(find.byType(SwipeActionCell)));
      
      // Swipe 50px left
      await gesture.moveBy(const Offset(-50, 0));
      await tester.pump();

      // Find the SwipeActionPanel and check its width in the RenderBox
      final panelFinder = find.byType(SwipeActionPanel);
      expect(panelFinder, findsOneWidget);
      
      var size = tester.getSize(panelFinder);
      expect(size.width, closeTo(50.0, 1.0));

      // Swipe 100px left total
      await gesture.moveBy(const Offset(-50, 0));
      await tester.pump();
      
      size = tester.getSize(panelFinder);
      expect(size.width, closeTo(100.0, 1.0));

      // Swipe past panelWidth (160px)
      await gesture.moveBy(const Offset(-100, 0)); // Total 200px
      await tester.pump();
      
      size = tester.getSize(panelFinder);
      expect(size.width, closeTo(panelWidth, 1.0));
      
      // Verify clamping: controller value should be clamped to panelWidth (160)
      // because we set resistance to 0 for this mode.
      final cellState = tester.state<SwipeActionCellState>(find.byType(SwipeActionCell));
      expect(cellState.swipeOffsetListenable.value.abs(), closeTo(panelWidth, 1.0));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('snaps back when released below threshold', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionCell(
              leftSwipeConfig: LeftSwipeConfig(
                mode: LeftSwipeMode.reveal,
                actionPanelWidth: 100,
                actions: [
                  SwipeAction(
                    icon: const Icon(Icons.delete),
                    onTap: () {},
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ],
              ),
              animationConfig: const SwipeAnimationConfig(
                activationThreshold: 0.5,
              ),
              child: const SizedBox(width: 400, height: 100),
            ),
          ),
        ),
      );

      // Drag 40px (below 50% of 100px threshold)
      await tester.drag(find.byType(SwipeActionCell), const Offset(-40, 0), warnIfMissed: false);
      await tester.pumpAndSettle();

      final cellState = tester.state<SwipeActionCellState>(find.byType(SwipeActionCell));
      expect(cellState.swipeOffsetListenable.value, closeTo(0.0, 0.01));
    });

    testWidgets('snaps open when released above threshold', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionCell(
              leftSwipeConfig: LeftSwipeConfig(
                mode: LeftSwipeMode.reveal,
                actionPanelWidth: 100,
                actions: [
                  SwipeAction(
                    icon: const Icon(Icons.delete),
                    onTap: () {},
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ],
              ),
              animationConfig: const SwipeAnimationConfig(
                activationThreshold: 0.5,
              ),
              child: const SizedBox(width: 400, height: 100),
            ),
          ),
        ),
      );

      // Drag 60px (above 50% of 100px threshold)
      await tester.drag(find.byType(SwipeActionCell), const Offset(-60, 0), warnIfMissed: false);
      await tester.pumpAndSettle();

      final cellState = tester.state<SwipeActionCellState>(find.byType(SwipeActionCell));
      expect(cellState.swipeOffsetListenable.value, closeTo(-100.0, 0.01));
    });

    group('SwipeActionCell Regression', () {
      testWidgets('does not show panel for right swipes', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SwipeActionCell(
                leftSwipeConfig: LeftSwipeConfig(
                  mode: LeftSwipeMode.reveal,
                  actions: [
                    SwipeAction(
                      icon: const Icon(Icons.delete),
                      onTap: () {},
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ],
                ),
                rightSwipeConfig: const RightSwipeConfig(
                  onSwipeCompleted: null,
                ),
                child: const SizedBox(width: 400, height: 100),
              ),
            ),
          ),
        );

        await tester.drag(find.byType(SwipeActionCell), const Offset(50, 0), warnIfMissed: false);
        await tester.pump();

        expect(find.byType(SwipeActionPanel), findsNothing);
      });
    });
  });
}

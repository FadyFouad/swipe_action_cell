import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';
import 'package:swipe_action_cell/src/actions/intentional/swipe_action_panel.dart';

void main() {
  group('Full-Swipe Expansion Bugs Fix', () {
    testWidgets('BUG 2: Expansion starts immediately from 0.0', (tester) async {
      final deleteAction = SwipeAction(
        icon: const Icon(Icons.delete),
        label: 'Delete',
        onTap: () {},
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      );

      double? capturedRatio;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell(
                onProgressChanged: (p) => capturedRatio = p.fullSwipeRatio,
                leftSwipeConfig: LeftSwipeConfig(
                  mode: LeftSwipeMode.reveal,
                  actions: [
                    SwipeAction(
                      icon: const Icon(Icons.archive),
                      label: 'Archive',
                      onTap: () {},
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    deleteAction,
                  ],
                  fullSwipeConfig: FullSwipeConfig(
                    enabled: true,
                    threshold: 0.8,
                    action: deleteAction,
                    expandAnimation: true,
                  ),
                ),
                child: const SizedBox(height: 100, child: Text('Cell')),
              ),
            ),
          ),
        ),
      ));

      final gesture = await tester.startGesture(tester.getCenter(find.text('Cell')));
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
      
      expect(capturedRatio, closeTo(0.0625, 0.001));
      
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('BUG 1: Only designated action expands, others shrink', (tester) async {
      final deleteAction = SwipeAction(
        icon: const Icon(Icons.delete),
        label: 'Delete',
        onTap: () {},
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell(
                leftSwipeConfig: LeftSwipeConfig(
                  mode: LeftSwipeMode.reveal,
                  actions: [
                    SwipeAction(
                      icon: const Icon(Icons.archive),
                      label: 'Archive',
                      onTap: () {},
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    deleteAction,
                  ],
                  fullSwipeConfig: FullSwipeConfig(
                    enabled: true,
                    threshold: 0.75,
                    action: deleteAction,
                    expandAnimation: true,
                  ),
                ),
                child: const SizedBox(height: 100, child: Text('Cell')),
              ),
            ),
          ),
        ),
      ));

      // Swipe to midpoint of fullSwipeThreshold (0.375 ratio = 150 pixels)
      final gesture = await tester.startGesture(tester.getCenter(find.text('Cell')));
      await gesture.moveBy(const Offset(-150, 0));
      await tester.pump();

      // Find SizedBoxes in SwipeActionPanel
      final panelSizedBoxes = find.descendant(
        of: find.byType(SwipeActionPanel),
        matching: find.byType(SizedBox),
      ).evaluate().where((e) => (e.widget as SizedBox).child is ClipRect).map((e) => e.widget as SizedBox).toList();

      expect(panelSizedBoxes.length, 2);
      
      // totalRevealedWidth = 150.
      // progress = 0.375 / 0.75 = 0.5.
      // normalWidth = 150 / 2 = 75.
      // Archive (shrinking) = 75 * (1 - 0.5) = 37.5.
      // Delete (expanding) = 150 - 37.5 = 112.5.
      
      expect(panelSizedBoxes[0].width, closeTo(37.5, 0.001));
      expect(panelSizedBoxes[1].width, closeTo(112.5, 0.001));

      final opacity = tester.widget<Opacity>(find.descendant(
        of: find.byType(SwipeActionPanel),
        matching: find.byType(Opacity),
      ).first);
      expect(opacity.opacity, closeTo(0.5, 0.001));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('Single action fills full width always', (tester) async {
      final deleteAction = SwipeAction(
        icon: const Icon(Icons.delete),
        label: 'Delete',
        onTap: () {},
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell(
                leftSwipeConfig: LeftSwipeConfig(
                  mode: LeftSwipeMode.reveal,
                  actions: [deleteAction],
                  fullSwipeConfig: FullSwipeConfig(
                    enabled: true,
                    threshold: 0.75,
                    action: deleteAction,
                    expandAnimation: true,
                  ),
                ),
                child: const SizedBox(height: 100, child: Text('Cell')),
              ),
            ),
          ),
        ),
      ));

      final gesture = await tester.startGesture(tester.getCenter(find.text('Cell')));
      await gesture.moveBy(const Offset(-100, 0));
      await tester.pump();

      final panelSizedBoxes = find.descendant(
        of: find.byType(SwipeActionPanel),
        matching: find.byType(SizedBox),
      ).evaluate().where((e) => (e.widget as SizedBox).child is ClipRect).map((e) => e.widget as SizedBox).toList();

      expect(panelSizedBoxes[0].width, closeTo(100.0, 0.001));

      await gesture.moveBy(const Offset(-100, 0));
      await tester.pump();

      final panelSizedBoxes2 = find.descendant(
        of: find.byType(SwipeActionPanel),
        matching: find.byType(SizedBox),
      ).evaluate().where((e) => (e.widget as SizedBox).child is ClipRect).map((e) => e.widget as SizedBox).toList();

      expect(panelSizedBoxes2[0].width, closeTo(200.0, 0.001));

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}

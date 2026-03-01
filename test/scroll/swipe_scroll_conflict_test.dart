import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

Widget _buildTestList({
  SwipeGestureConfig config = const SwipeGestureConfig(),
  ScrollController? scrollController,
}) {
  return MaterialApp(
    home: Scaffold(
      body: ListView.builder(
        controller: scrollController,
        itemCount: 20,
        itemBuilder: (context, index) {
          return SwipeActionCell(
            key: ValueKey('cell_$index'),
            gestureConfig: config,
            leftSwipeConfig: LeftSwipeConfig(
              mode: LeftSwipeMode.reveal,
              actions: [
                SwipeAction(
                  icon: const Icon(Icons.delete),
                  label: 'Delete',
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  onTap: () {},
                ),
              ],
            ),
            child: SizedBox(
              height: 60,
              width: double.infinity,
              child: Text('Item $index'),
            ),
          );
        },
      ),
    ),
  );
}

Widget _buildNestedPageView() {
  return MaterialApp(
    home: Scaffold(
      body: PageView(
        children: [
          _buildTestList(),
          const Center(child: Text('Page 2')),
        ],
      ),
    ),
  );
}

void main() {
  group('Scroll Conflict Resolution (F007)', () {
    // ── US1: Swipe and Scroll Coexist ────────────────────────────
    testWidgets('SC-01: Vertical scroll in ListView does not trigger swipe',
        (tester) async {
      final scrollController = ScrollController();
      await tester
          .pumpWidget(_buildTestList(scrollController: scrollController));

      // Fling downward — should scroll the list, not activate a swipe.
      await tester.fling(
          find.byKey(const ValueKey('cell_2')), const Offset(0, -300), 1000);
      await tester.pumpAndSettle();

      expect(scrollController.offset, greaterThan(0));
      // No action panel revealed.
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets(
        'SC-02: Horizontal swipe (left) in ListView triggers swipe, no scroll',
        (tester) async {
      final scrollController = ScrollController();
      await tester
          .pumpWidget(_buildTestList(scrollController: scrollController));

      // Swipe LEFT to reveal the panel (negative dx).
      final gesture = await tester
          .startGesture(tester.getCenter(find.byKey(const ValueKey('cell_1'))));
      // Move purely horizontal in small steps so recognizer accumulates.
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(scrollController.offset, 0.0);
      expect(find.text('Delete'), findsWidgets);
    });

    testWidgets('SC-03: Diagonal gesture — horizontal dominant (ratio 1.5)',
        (tester) async {
      final scrollController = ScrollController();
      await tester
          .pumpWidget(_buildTestList(scrollController: scrollController));

      // dx = -200, dy = 50 → |dx|/|dy| = 4 which is > 1.5 → swipe wins
      final gesture = await tester
          .startGesture(tester.getCenter(find.byKey(const ValueKey('cell_2'))));
      await gesture.moveBy(const Offset(-50, 12));
      await gesture.moveBy(const Offset(-50, 13));
      await gesture.moveBy(const Offset(-50, 12));
      await gesture.moveBy(const Offset(-50, 13));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(scrollController.offset, 0.0);
      expect(find.text('Delete'), findsWidgets);
    });

    testWidgets('SC-04: Diagonal with tight ratio 2.5 — vertical wins',
        (tester) async {
      final scrollController = ScrollController();
      await tester.pumpWidget(_buildTestList(
        scrollController: scrollController,
        config: SwipeGestureConfig.tight(), // ratio 2.5, deadZone 24
      ));

      // dx = -100, dy = -80 → |dx|/|dy| = 1.25 which is < 2.5 → scroll wins
      final gesture = await tester
          .startGesture(tester.getCenter(find.byKey(const ValueKey('cell_2'))));
      await gesture.moveBy(const Offset(-25, -20));
      await gesture.moveBy(const Offset(-25, -20));
      await gesture.moveBy(const Offset(-25, -20));
      await gesture.moveBy(const Offset(-25, -20));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(scrollController.offset, greaterThan(0.0));
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('SC-08: Fast mostly-vertical fling does not trigger swipe',
        (tester) async {
      final scrollController = ScrollController();
      await tester
          .pumpWidget(_buildTestList(scrollController: scrollController));

      await tester.fling(
          find.byKey(const ValueKey('cell_1')), const Offset(30, -300), 2000);
      await tester.pumpAndSettle();

      expect(scrollController.offset, greaterThan(0));
      expect(find.text('Delete'), findsNothing);
    });

    // ── US2: Open Panels Close Automatically on Scroll ───────────

    testWidgets('SC-05: closeOnScroll auto-closes open panel on user scroll',
        (tester) async {
      final scrollController = ScrollController();
      await tester
          .pumpWidget(_buildTestList(scrollController: scrollController));

      // Open panel via left swipe.
      final gesture = await tester
          .startGesture(tester.getCenter(find.byKey(const ValueKey('cell_1'))));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsWidgets);

      // User drags vertically (scroll).
      await tester.drag(find.text('Item 5'), const Offset(0, -100));
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('SC-06: closeOnScroll: false keeps panel open during scroll',
        (tester) async {
      final scrollController = ScrollController();
      await tester.pumpWidget(_buildTestList(
        scrollController: scrollController,
        config: const SwipeGestureConfig(closeOnScroll: false),
      ));

      // Open panel.
      final gesture = await tester
          .startGesture(tester.getCenter(find.byKey(const ValueKey('cell_1'))));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      // Small scroll — panel should remain.
      scrollController.jumpTo(5.0);
      await tester.pumpAndSettle();

      // Panel should still be visible (closeOnScroll is false).
      expect(find.text('Delete'), findsWidgets);
    });

    testWidgets('SC-07: Programmatic scroll does not auto-close',
        (tester) async {
      final scrollController = ScrollController();
      await tester
          .pumpWidget(_buildTestList(scrollController: scrollController));

      // Open panel.
      final gesture = await tester
          .startGesture(tester.getCenter(find.byKey(const ValueKey('cell_1'))));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsWidgets);

      // Programmatic scroll — no dragDetails, should NOT close.
      scrollController.jumpTo(10.0);
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsWidgets);
    });

    // ── US3: Nested Scrollable Containers ────────────────────────

    testWidgets('SC-09: PageView > ListView > SwipeActionCell', (tester) async {
      await tester.pumpWidget(_buildNestedPageView());

      // Swipe cell left slowly → swipe triggers, page does not turn.
      final gesture = await tester
          .startGesture(tester.getCenter(find.byKey(const ValueKey('cell_1'))));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsWidgets);
      expect(find.text('Page 2'), findsNothing); // didn't turn the page
    });

    // ── US4: Platform Back-Navigation Gesture ────────────────────

    testWidgets('SC-10: respectEdgeGestures true — edge drag does not swipe',
        (tester) async {
      await tester.pumpWidget(_buildTestList());

      // Start drag at dx=10 (inside 20px edge zone).
      final gesture = await tester.startGesture(const Offset(10, 300));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('SC-11: respectEdgeGestures false — edge drag swipes normally',
        (tester) async {
      await tester.pumpWidget(_buildTestList(
        config: const SwipeGestureConfig(respectEdgeGestures: false),
      ));

      // Start drag at dx=10 but respectEdgeGestures is false.
      final gesture = await tester.startGesture(const Offset(10, 300));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.moveBy(const Offset(-50, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Delete'), findsWidgets);
    });
  });
}

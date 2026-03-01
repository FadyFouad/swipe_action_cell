import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:swipe_action_cell/swipe_action_cell.dart";
import "package:swipe_action_cell/src/testing/swipe_tester.dart";
import "package:swipe_action_cell/src/actions/intentional/swipe_action_panel.dart";

Widget buildTestCell({
  LeftSwipeConfig? left,
  RightSwipeConfig? right,
  Widget? child,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SwipeActionCell(
        leftSwipeConfig: left,
        rightSwipeConfig: right,
        child: child ??
            const SizedBox(width: 400, height: 100, child: Text("Cell")),
      ),
    ),
  );
}

void main() {
  group("SwipeTester US1 Tests", () {
    testWidgets("swipeLeft default ratio", (tester) async {
      bool fired = false;
      await tester.pumpWidget(buildTestCell(
        left: LeftSwipeConfig(
          mode: LeftSwipeMode.reveal,
          onPanelOpened: () => fired = true,
          actions: [
            SwipeAction(
                icon: const Icon(Icons.edit),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                onTap: () {})
          ],
        ),
      ));
      await SwipeTester.swipeLeft(tester, find.byType(SwipeActionCell));
      expect(fired, isTrue);
    });

    testWidgets("swipeLeft custom ratio", (tester) async {
      bool fired = false;
      await tester.pumpWidget(buildTestCell(
        left: LeftSwipeConfig(
          mode: LeftSwipeMode.reveal,
          onPanelOpened: () => fired = true,
          actions: [
            SwipeAction(
                icon: const Icon(Icons.edit),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                onTap: () {})
          ],
        ),
      ));
      await SwipeTester.swipeLeft(tester, find.byType(SwipeActionCell),
          ratio: 0.9);
      expect(fired, isTrue);
    });

    testWidgets("swipeLeft cell with no config", (tester) async {
      await tester.pumpWidget(buildTestCell());
      await SwipeTester.swipeLeft(tester, find.byType(SwipeActionCell));
      final state =
          tester.state<SwipeActionCellState>(find.byType(SwipeActionCell));
      expect(state.currentSwipeState, SwipeState.revealed);
    });

    testWidgets("swipeRight", (tester) async {
      double p = 0;
      await tester.pumpWidget(buildTestCell(
        right: RightSwipeConfig(
          onProgressChanged: (value, prev) => p = value,
          onSwipeCompleted: (_) {},
        ),
      ));
      await SwipeTester.swipeRight(tester, find.byType(SwipeActionCell));
      expect(p, greaterThan(0));
    });

    testWidgets("flingLeft velocity clamp", (tester) async {
      bool fired = false;
      await tester.pumpWidget(buildTestCell(
        left: LeftSwipeConfig(
          mode: LeftSwipeMode.reveal,
          onPanelOpened: () => fired = true,
          actions: [
            SwipeAction(
                icon: const Icon(Icons.edit),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                onTap: () {})
          ],
        ),
      ));
      await SwipeTester.flingLeft(tester, find.byType(SwipeActionCell),
          velocity: -50);
      expect(fired, isTrue);
    });

    testWidgets("flingRight", (tester) async {
      bool fired = false;
      await tester.pumpWidget(buildTestCell(
        right: RightSwipeConfig(
          onSwipeCompleted: (_) => fired = true,
        ),
      ));
      await SwipeTester.flingRight(tester, find.byType(SwipeActionCell));
      expect(fired, isTrue);
    });

    testWidgets("dragTo mid-drag no settle", (tester) async {
      await tester.pumpWidget(buildTestCell(
        right: RightSwipeConfig(onSwipeCompleted: (_) {}),
      ));
      await SwipeTester.dragTo(
          tester, find.byType(SwipeActionCell), const Offset(100, 0));
      final state =
          tester.state<SwipeActionCellState>(find.byType(SwipeActionCell));
      expect(state.currentSwipeState, SwipeState.animatingToClose);
      expect(state.currentSwipeRatio, greaterThan(0));
    });

    testWidgets("dragTo zero-offset no-op", (tester) async {
      await tester.pumpWidget(buildTestCell(
        right: RightSwipeConfig(onSwipeCompleted: (_) {}),
      ));
      await SwipeTester.dragTo(
          tester, find.byType(SwipeActionCell), Offset.zero);
      final state =
          tester.state<SwipeActionCellState>(find.byType(SwipeActionCell));
      expect(state.currentSwipeState, SwipeState.idle);
    });

    testWidgets("tapAction revealed cell", (tester) async {
      int tappedIndex = -1;
      await tester.pumpWidget(buildTestCell(
        left: LeftSwipeConfig(
          mode: LeftSwipeMode.reveal,
          actions: [
            SwipeAction(
                icon: const Icon(Icons.abc),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                onTap: () => tappedIndex = 0),
            SwipeAction(
                icon: const Icon(Icons.edit),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                onTap: () => tappedIndex = 1),
          ],
        ),
      ));
      await SwipeTester.swipeLeft(tester, find.byType(SwipeActionCell),
          ratio: 0.9);
      await SwipeTester.tapAction(tester, find.byType(SwipeActionCell), 1);
      expect(tappedIndex, 1);
    });

    testWidgets("tapAction non-revealed failure message", (tester) async {
      await tester.pumpWidget(buildTestCell(
        left: LeftSwipeConfig(
          mode: LeftSwipeMode.reveal,
          actions: [
            SwipeAction(
                icon: const Icon(Icons.abc),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                onTap: () {})
          ],
        ),
      ));

      try {
        await SwipeTester.tapAction(tester, find.byType(SwipeActionCell), 0);
        fail("Should have thrown");
      } catch (e) {
        expect(e.toString(),
            contains("SwipeTester.tapAction: cell is not in revealed state"));
      }
    });

    testWidgets("tapAction out-of-bounds failure", (tester) async {
      await tester.pumpWidget(buildTestCell(
        left: LeftSwipeConfig(
          mode: LeftSwipeMode.reveal,
          actions: [
            SwipeAction(
                icon: const Icon(Icons.abc),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                onTap: () {})
          ],
        ),
      ));
      await SwipeTester.swipeLeft(tester, find.byType(SwipeActionCell),
          ratio: 0.9);

      try {
        await SwipeTester.tapAction(tester, find.byType(SwipeActionCell), 5);
        fail("Should have thrown");
      } catch (e) {
        expect(
            e.toString(),
            contains(
                "SwipeTester.tapAction: actionIndex 5 exceeds available actions (1)"));
      }
    });
  });
}

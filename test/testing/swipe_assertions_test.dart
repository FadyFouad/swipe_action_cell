import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:swipe_action_cell/swipe_action_cell.dart";
import "package:swipe_action_cell/src/testing/swipe_assertions.dart";
import "package:swipe_action_cell/src/testing/swipe_tester.dart";

void main() {
  group("SwipeAssertions US2", () {
    testWidgets("expectSwipeState passes on match", (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SwipeActionCell(
                child: const SizedBox(width: 400, height: 100))),
      ));
      tester.expectSwipeState(find.byType(SwipeActionCell), SwipeState.idle);
    });

    testWidgets("expectSwipeState fails with message on mismatch",
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SwipeActionCell(
                child: const SizedBox(width: 400, height: 100))),
      ));

      try {
        tester.expectSwipeState(
            find.byType(SwipeActionCell), SwipeState.revealed);
        fail("Should have thrown");
      } catch (e) {
        expect(e.toString(),
            contains("Expected SwipeState.revealed but found SwipeState.idle"));
      }
    });

    testWidgets("expectProgress passes within tolerance", (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SwipeActionCell(
                child: const SizedBox(width: 400, height: 100))),
      ));
      tester.expectProgress(find.byType(SwipeActionCell), 0.0, tolerance: 0.01);
    });

    testWidgets("expectProgress fails showing delta", (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SwipeActionCell(
                child: const SizedBox(width: 400, height: 100))),
      ));

      try {
        tester.expectProgress(find.byType(SwipeActionCell), 0.5,
            tolerance: 0.01);
        fail("Should have thrown");
      } catch (e) {
        expect(
            e.toString(),
            contains(
                "Expected progress 0.5 ± 0.01 but found 0.0 (delta: 0.5)"));
      }
    });

    testWidgets("expectRevealed and expectIdle shorthands", (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SwipeActionCell(
          leftSwipeConfig: LeftSwipeConfig(
            mode: LeftSwipeMode.reveal,
            actions: [
              SwipeAction(
                  icon: const Icon(Icons.edit),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  onTap: () {})
            ],
          ),
          child: const SizedBox(width: 400, height: 100),
        )),
      ));
      tester.expectIdle(find.byType(SwipeActionCell));

      await SwipeTester.swipeLeft(tester, find.byType(SwipeActionCell),
          ratio: 0.9);
      tester.expectRevealed(find.byType(SwipeActionCell));
    });
  });
}

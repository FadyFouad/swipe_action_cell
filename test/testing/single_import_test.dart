import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:swipe_action_cell/testing.dart"; // ← ONLY import needed

void main() {
  testWidgets("all utilities from one import", (tester) async {
    final mock = MockSwipeController(); // US3
    await tester.pumpWidget(SwipeTestHarness(
      // US4
      controller: mock,
      child: SwipeActionCell.delete(
        controller: mock,
        child: const ListTile(title: Text("item")),
        onDeleted: () {},
      ),
    ));
    await SwipeTester.swipeLeft(
        // US1
        tester,
        find.byType(SwipeActionCell),
        ratio: 0.9);
    tester.expectSwipeState(
        find.byType(SwipeActionCell), SwipeState.animatingOut); // US2
  });
}

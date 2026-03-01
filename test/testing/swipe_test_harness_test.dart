import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:swipe_action_cell/swipe_action_cell.dart";
import "package:swipe_action_cell/src/testing/swipe_test_harness.dart";
import "package:swipe_action_cell/src/testing/swipe_tester.dart";
import "package:swipe_action_cell/src/testing/swipe_assertions.dart";

void main() {
  group("SwipeTestHarness US4", () {
    testWidgets("pumps without ancestor errors and defaults correctly",
        (tester) async {
      await tester.pumpWidget(SwipeTestHarness(
        child: SwipeActionCell(
          leftSwipeConfig: LeftSwipeConfig(
            mode: LeftSwipeMode.autoTrigger,
            onActionTriggered: () {},
          ),
          child: const SizedBox(width: 390, height: 100, child: Text("Item")),
        ),
      ));
      expect(find.text("Item"), findsOneWidget);
    });

    testWidgets("textDirection rtl reverses semantics", (tester) async {
      bool fired = false;
      await tester.pumpWidget(SwipeTestHarness(
        textDirection: TextDirection.rtl,
        child: SwipeActionCell(
          leftSwipeConfig: LeftSwipeConfig(
            mode: LeftSwipeMode.autoTrigger,
            onActionTriggered: () => fired = true,
          ),
          child: const SizedBox(width: 390, height: 100, child: Text("Item")),
        ),
      ));

      // SwipeRight in RTL is leading edge (same as SwipeLeft in LTR)
      await SwipeTester.swipeRight(tester, find.byType(SwipeActionCell));
      expect(fired, isTrue);
    });

    testWidgets("screenSize propagates via MediaQuery", (tester) async {
      await tester.pumpWidget(SwipeTestHarness(
        screenSize: const Size(414, 896),
        child: Builder(builder: (context) {
          final size = MediaQuery.of(context).size;
          return Text("${size.width}x${size.height}");
        }),
      ));
      expect(find.text("414.0x896.0"), findsOneWidget);
    });
  });
}

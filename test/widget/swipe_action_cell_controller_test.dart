import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Build a minimal SwipeActionCell with left-swipe enabled + optional controller.
Widget _buildLeftCell({
  SwipeController? controller,
  Key? cellKey,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: SizedBox(
      width: 400,
      height: 60,
      child: SwipeActionCell(
        key: cellKey,
        controller: controller,
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.reveal,
          actions: [
            SwipeAction(
              icon: const Icon(IconData(0xe547, fontFamily: 'MaterialIcons')),
              label: 'Delete',
              backgroundColor: const Color(0xFFFF0000),
              foregroundColor: const Color(0xFFFFFFFF),
              onTap: () {},
            ),
          ],
        ),
        child: const SizedBox(height: 60, child: Text('Item')),
      ),
    ),
  );
}

/// Build a minimal SwipeActionCell with right-swipe enabled + optional controller.
Widget _buildRightCell({
  SwipeController? controller,
  Key? cellKey,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: SizedBox(
      width: 400,
      height: 60,
      child: SwipeActionCell(
        key: cellKey,
        controller: controller,
        rightSwipeConfig: RightSwipeConfig(
          stepValue: 1.0,
          maxValue: 10.0,
          initialValue: 0.0,
        ),
        child: const SizedBox(height: 60, child: Text('Item')),
      ),
    ),
  );
}

void main() {
  // ── T004: US1 — programmatic control widget tests ────────────────────────

  group('SwipeActionCell — programmatic control (US1)', () {
    // (a) openLeft() animates cell to revealed state
    testWidgets('controller.openLeft() transitions cell to revealed state',
        (tester) async {
      final controller = SwipeController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildLeftCell(controller: controller));
      await tester.pump();

      controller.openLeft();
      // Allow animation to settle.
      await tester.pumpAndSettle();

      expect(controller.isOpen, isTrue);
      expect(controller.currentState, SwipeState.revealed);
      // Verify the widget is still mounted and accessible.
      expect(find.byType(SwipeActionCell), findsOneWidget);
    });

    // (b) close() snaps cell back to idle
    testWidgets('controller.close() transitions cell back to idle state',
        (tester) async {
      final controller = SwipeController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildLeftCell(controller: controller));
      await tester.pump();

      // First open the cell.
      controller.openLeft();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);

      // Now close it.
      controller.close();
      await tester.pumpAndSettle();

      expect(controller.isOpen, isFalse);
      expect(controller.currentState, SwipeState.idle);
    });

    // (c) openRight() triggers progressive increment + snap-back
    testWidgets('controller.openRight() triggers progressive increment and snaps back',
        (tester) async {
      final controller = SwipeController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildRightCell(controller: controller));
      await tester.pump();

      controller.openRight();
      await tester.pumpAndSettle();

      // After snap-back the cell is idle and progress incremented by stepValue.
      expect(controller.currentState, SwipeState.idle);
      expect(controller.currentProgress, greaterThan(0.0));
    });

    // (d) resetProgress() resets currentProgress to initialValue
    testWidgets('controller.resetProgress() resets currentProgress to initialValue',
        (tester) async {
      final controller = SwipeController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildRightCell(controller: controller));
      await tester.pump();

      // Set progress then reset.
      controller.setProgress(7.0);
      await tester.pump();
      controller.resetProgress();
      await tester.pump();

      expect(controller.currentProgress, 0.0); // initialValue is 0.0
    });

    // (e) setProgress(5.0) sets currentProgress to 5.0
    testWidgets('controller.setProgress(5.0) sets currentProgress to 5.0',
        (tester) async {
      final controller = SwipeController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildRightCell(controller: controller));
      await tester.pump();

      controller.setProgress(5.0);
      await tester.pump();

      expect(controller.currentProgress, 5.0);
    });

    // (f) no controller provided → widget works normally
    testWidgets('widget without controller creates internal controller and works',
        (tester) async {
      await tester.pumpWidget(_buildLeftCell());
      expect(tester.takeException(), isNull);
    });

    // (g) controller swap on didUpdateWidget detaches old, attaches new without crash
    testWidgets('controller swap on rebuild detaches old and attaches new',
        (tester) async {
      final key = GlobalKey();
      final controllerA = SwipeController();
      final controllerB = SwipeController();
      addTearDown(controllerA.dispose);
      addTearDown(controllerB.dispose);

      await tester.pumpWidget(_buildLeftCell(controller: controllerA, cellKey: key));
      await tester.pump();

      // Swap controller.
      await tester.pumpWidget(_buildLeftCell(controller: controllerB, cellKey: key));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    // (h) rebuild with same controller does not re-attach or double-register
    testWidgets('rebuild with same controller does not double-attach', (tester) async {
      final controller = SwipeController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildLeftCell(controller: controller));
      await tester.pump();

      // Trigger rebuild — should not throw.
      await tester.pumpWidget(_buildLeftCell(controller: controller));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}

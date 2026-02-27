import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

/// Helper to build a testable SwipeActionCell with reduced motion control.
Widget _buildTestApp({
  bool disableAnimations = false,
  RightSwipeConfig? rightSwipeConfig,
  LeftSwipeConfig? leftSwipeConfig,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Center(
        child: SizedBox(
          width: 400,
          height: 80,
          child: SwipeActionCell(
            rightSwipeConfig: rightSwipeConfig,
            leftSwipeConfig: leftSwipeConfig,
            child: const Text('Cell'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('US4 — Reduced Motion', () {
    testWidgets(
        'disableAnimations: true — snap-back completes after single pump',
        (tester) async {
      SwipeState? lastState;
      await tester.pumpWidget(_buildTestApp(
        disableAnimations: true,
        rightSwipeConfig: RightSwipeConfig(
          onSwipeCompleted: (_) {},
        ),
      ));

      // Get the state reference.
      final state =
          tester.state<SwipeActionCellState>(find.byType(SwipeActionCell));

      // Start and abandon a drag (will trigger snap-back).
      final center = tester.getCenter(find.text('Cell'));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(50, 0));
      await gesture.up();

      // With disableAnimations, one pump should be enough.
      await tester.pump();

      // The controller should already be at 0.
      expect(state.swipeOffsetListenable.value, 0.0);
    });

    testWidgets(
        'disableAnimations: false — animation requires multiple frames',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        disableAnimations: false,
        rightSwipeConfig: RightSwipeConfig(
          onSwipeCompleted: (_) {},
        ),
      ));

      final state =
          tester.state<SwipeActionCellState>(find.byType(SwipeActionCell));

      final center = tester.getCenter(find.text('Cell'));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(50, 0));
      await gesture.up();

      // After a single pump, the offset should NOT be at 0 yet (spring animating).
      await tester.pump();
      expect(state.swipeOffsetListenable.value, isNot(0.0));

      // After settle, it should be close to 0.
      await tester.pumpAndSettle();
      expect(state.swipeOffsetListenable.value, closeTo(0.0, 0.01));
    });
  });
}

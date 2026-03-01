import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

/// Helper to build a testable SwipeActionCell inside a constrained context.
Widget _buildTestApp({
  TextDirection textDirection = TextDirection.ltr,
  RightSwipeConfig? rightSwipeConfig,
  LeftSwipeConfig? leftSwipeConfig,
  RightSwipeConfig? forwardSwipeConfig,
  LeftSwipeConfig? backwardSwipeConfig,
  ForceDirection forceDirection = ForceDirection.auto,
}) {
  return Directionality(
    textDirection: textDirection,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Center(
        child: SizedBox(
          width: 400,
          height: 80,
          child: SwipeActionCell(
            rightSwipeConfig: rightSwipeConfig,
            leftSwipeConfig: leftSwipeConfig,
            forwardSwipeConfig: forwardSwipeConfig,
            backwardSwipeConfig: backwardSwipeConfig,
            forceDirection: forceDirection,
            child: const Text('Cell'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('US3 — RTL: LTR baseline (regression guard)', () {
    testWidgets('LTR: right drag activates rightSwipeConfig (forward)',
        (tester) async {
      double progressValue = 0;
      await tester.pumpWidget(_buildTestApp(
        rightSwipeConfig: RightSwipeConfig(
          onSwipeCompleted: (v) => progressValue = v,
        ),
      ));

      final center = tester.getCenter(find.text('Cell'));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(200, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(progressValue, greaterThan(0));
    });

    testWidgets('LTR: left drag activates leftSwipeConfig (backward)',
        (tester) async {
      bool actionFired = false;
      await tester.pumpWidget(_buildTestApp(
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          onActionTriggered: () => actionFired = true,
        ),
      ));

      final center = tester.getCenter(find.text('Cell'));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(-200, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(actionFired, isTrue);
    });
  });

  group('US3 — RTL: Direction remapping', () {
    testWidgets('RTL: left drag activates rightSwipeConfig (forward)',
        (tester) async {
      double progressValue = 0;
      await tester.pumpWidget(_buildTestApp(
        textDirection: TextDirection.rtl,
        rightSwipeConfig: RightSwipeConfig(
          onSwipeCompleted: (v) => progressValue = v,
        ),
      ));

      final center = tester.getCenter(find.text('Cell'));
      final gesture = await tester.startGesture(center);
      // In RTL, forward = left drag.
      await gesture.moveBy(const Offset(-200, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(progressValue, greaterThan(0));
    });

    testWidgets('RTL: right drag activates leftSwipeConfig (backward)',
        (tester) async {
      bool actionFired = false;
      await tester.pumpWidget(_buildTestApp(
        textDirection: TextDirection.rtl,
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          onActionTriggered: () => actionFired = true,
        ),
      ));

      final center = tester.getCenter(find.text('Cell'));
      final gesture = await tester.startGesture(center);
      // In RTL, backward = right drag.
      await gesture.moveBy(const Offset(200, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(actionFired, isTrue);
    });
  });

  group('US3 — RTL: forwardSwipeConfig alias', () {
    testWidgets('LTR: forwardSwipeConfig activates on right drag',
        (tester) async {
      double progressValue = 0;
      await tester.pumpWidget(_buildTestApp(
        forwardSwipeConfig: RightSwipeConfig(
          onSwipeCompleted: (v) => progressValue = v,
        ),
      ));

      final center = tester.getCenter(find.text('Cell'));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(200, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(progressValue, greaterThan(0));
    });

    testWidgets('RTL: forwardSwipeConfig activates on left drag',
        (tester) async {
      double progressValue = 0;
      await tester.pumpWidget(_buildTestApp(
        textDirection: TextDirection.rtl,
        forwardSwipeConfig: RightSwipeConfig(
          onSwipeCompleted: (v) => progressValue = v,
        ),
      ));

      final center = tester.getCenter(find.text('Cell'));
      final gesture = await tester.startGesture(center);
      await gesture.moveBy(const Offset(-200, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(progressValue, greaterThan(0));
    });
  });

  group('US3 — RTL: forceDirection override', () {
    testWidgets('forceDirection: ltr in RTL context → behaves as LTR',
        (tester) async {
      double progressValue = 0;
      await tester.pumpWidget(_buildTestApp(
        textDirection: TextDirection.rtl,
        forceDirection: ForceDirection.ltr,
        rightSwipeConfig: RightSwipeConfig(
          onSwipeCompleted: (v) => progressValue = v,
        ),
      ));

      final center = tester.getCenter(find.text('Cell'));
      final gesture = await tester.startGesture(center);
      // With forceDirection: ltr, right drag = forward, even in RTL context.
      await gesture.moveBy(const Offset(200, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(progressValue, greaterThan(0));
    });

    testWidgets('forceDirection: rtl in LTR context → behaves as RTL',
        (tester) async {
      double progressValue = 0;
      await tester.pumpWidget(_buildTestApp(
        textDirection: TextDirection.ltr,
        forceDirection: ForceDirection.rtl,
        rightSwipeConfig: RightSwipeConfig(
          onSwipeCompleted: (v) => progressValue = v,
        ),
      ));

      final center = tester.getCenter(find.text('Cell'));
      final gesture = await tester.startGesture(center);
      // With forceDirection: rtl, left drag = forward, even in LTR context.
      await gesture.moveBy(const Offset(-200, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(progressValue, greaterThan(0));
    });
  });
}

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

/// Helper to build a testable SwipeActionCell with optional direction.
Widget _buildTestApp({
  TextDirection textDirection = TextDirection.ltr,
  RightSwipeConfig? rightSwipeConfig,
  LeftSwipeConfig? leftSwipeConfig,
  ForceDirection forceDirection = ForceDirection.auto,
}) {
  return Directionality(
    textDirection: textDirection,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: FocusScope(
        autofocus: true,
        child: Center(
          child: SizedBox(
            width: 400,
            height: 80,
            child: SwipeActionCell(
              rightSwipeConfig: rightSwipeConfig,
              leftSwipeConfig: leftSwipeConfig,
              forceDirection: forceDirection,
              child: const Text('Cell'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('US2 — Keyboard Navigation: Focus', () {
    testWidgets('cell wraps content with Focus widget', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        rightSwipeConfig: const RightSwipeConfig(),
      ));

      // Verify Focus exists as a descendant of SwipeActionCell.
      final cellFocus = find.descendant(
        of: find.byType(SwipeActionCell),
        matching: find.byType(Focus),
      );
      expect(cellFocus, findsOneWidget);
    });
  });

  group('US2 — Keyboard Navigation: Arrow keys', () {
    testWidgets('right arrow in LTR triggers forward action', (tester) async {
      double progressValue = 0;
      await tester.pumpWidget(_buildTestApp(
        rightSwipeConfig: RightSwipeConfig(
          onSwipeCompleted: (v) => progressValue = v,
        ),
      ));

      // Find the cell's Focus (the one inside SwipeActionCell) and focus it.
      final cellFocus = find.descendant(
        of: find.byType(SwipeActionCell),
        matching: find.byType(Focus),
      );
      final focusWidget = tester.widget<Focus>(cellFocus);
      focusWidget.focusNode!.requestFocus();
      await tester.pump();

      // Verify focus was acquired.
      expect(focusWidget.focusNode!.hasFocus, isTrue);

      // Simulate right arrow key press.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(progressValue, greaterThan(0));
    });

    testWidgets('left arrow in RTL triggers forward action', (tester) async {
      double progressValue = 0;
      await tester.pumpWidget(_buildTestApp(
        textDirection: TextDirection.rtl,
        rightSwipeConfig: RightSwipeConfig(
          onSwipeCompleted: (v) => progressValue = v,
        ),
      ));

      // Find the cell's Focus and focus it.
      final cellFocus = find.descendant(
        of: find.byType(SwipeActionCell),
        matching: find.byType(Focus),
      );
      final focusWidget = tester.widget<Focus>(cellFocus);
      focusWidget.focusNode!.requestFocus();
      await tester.pump();

      expect(focusWidget.focusNode!.hasFocus, isTrue);

      // In RTL, forward key is left arrow.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      expect(progressValue, greaterThan(0));
    });

    testWidgets('no forward config → no crash on arrow key', (tester) async {
      await tester.pumpWidget(_buildTestApp());

      final cellFocus = find.descendant(
        of: find.byType(SwipeActionCell),
        matching: find.byType(Focus),
      );
      final focusWidget = tester.widget<Focus>(cellFocus);
      focusWidget.focusNode!.requestFocus();
      await tester.pump();

      // Should not throw.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
    });
  });

  group('US2 — Keyboard Navigation: Escape', () {
    testWidgets('Escape when not revealed is ignored', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        rightSwipeConfig: const RightSwipeConfig(),
      ));

      final cellFocus = find.descendant(
        of: find.byType(SwipeActionCell),
        matching: find.byType(Focus),
      );
      final focusWidget = tester.widget<Focus>(cellFocus);
      focusWidget.focusNode!.requestFocus();
      await tester.pump();

      // Should not throw.
      await tester.sendKeyDownEvent(LogicalKeyboardKey.escape);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    });
  });
}

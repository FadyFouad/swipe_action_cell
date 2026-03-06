import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../actions/intentional/swipe_action_panel.dart';
import '../core/swipe_state.dart';
import '../widget/swipe_action_cell.dart';

/// Utility class for simulating swipe gestures in widget tests.
class SwipeTester {
  SwipeTester._();

  /// Drags the cell left by the specified [ratio] of its width.
  static Future<void> swipeLeft(WidgetTester tester, Finder finder,
      {double ratio = 0.5}) async {
    final rect = tester.getRect(finder);
    final clampedRatio = ratio.clamp(0.0, 1.0);
    await tester.drag(finder, Offset(-(rect.width * clampedRatio), 0),
        warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  /// Drags the cell right by the specified [ratio] of its width.
  static Future<void> swipeRight(WidgetTester tester, Finder finder,
      {double ratio = 0.5}) async {
    final rect = tester.getRect(finder);
    final clampedRatio = ratio.clamp(0.0, 1.0);
    await tester.drag(finder, Offset(rect.width * clampedRatio, 0),
        warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  /// Drags the cell fully to the right, crossing the full-swipe threshold,
  /// and pumps until settled.
  ///
  /// [ratio] is the drag distance as a fraction of the cell width (defaults
  /// to 1.0).  A ratio of 1.0 exceeds any [FullSwipeConfig.threshold] value
  /// (which is capped at 1.0).  Values up to 1.5 are accepted to give tests
  /// extra headroom; pass a larger value only when you intentionally want to
  /// simulate an over-drag.
  static Future<void> fullSwipeRight(WidgetTester tester, Finder finder,
      {double ratio = 1.0}) async {
    final rect = tester.getRect(finder);
    final clampedRatio = ratio.clamp(0.0, 1.5);
    await tester.drag(finder, Offset(rect.width * clampedRatio, 0),
        warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  /// Drags the cell fully to the left, crossing the full-swipe threshold,
  /// and pumps until settled.
  ///
  /// [ratio] is the drag distance as a fraction of the cell width (defaults
  /// to 1.0).  A ratio of 1.0 exceeds any [FullSwipeConfig.threshold] value
  /// (which is capped at 1.0).  Values up to 1.5 are accepted to give tests
  /// extra headroom; pass a larger value only when you intentionally want to
  /// simulate an over-drag.
  static Future<void> fullSwipeLeft(WidgetTester tester, Finder finder,
      {double ratio = 1.0}) async {
    final rect = tester.getRect(finder);
    final clampedRatio = ratio.clamp(0.0, 1.5);
    await tester.drag(finder, Offset(-(rect.width * clampedRatio), 0),
        warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  /// Flings the cell left with the specified [velocity].
  static Future<void> flingLeft(WidgetTester tester, Finder finder,
      {double velocity = 1000}) async {
    await tester.fling(
        finder, const Offset(-100, 0), velocity.clamp(100, double.infinity),
        warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  /// Flings the cell right with the specified [velocity].
  static Future<void> flingRight(WidgetTester tester, Finder finder,
      {double velocity = 1000}) async {
    await tester.fling(
        finder, const Offset(100, 0), velocity.clamp(100, double.infinity),
        warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  /// Drags the cell to the exact [offset] and pumps exactly one frame.
  static Future<void> dragTo(
      WidgetTester tester, Finder finder, Offset offset) async {
    await tester.drag(finder, offset, warnIfMissed: false);
    await tester.pump(); // Single frame — intentionally no pumpAndSettle
  }

  /// Taps the action button at [actionIndex] in a revealed cell.
  static Future<void> tapAction(
      WidgetTester tester, Finder cellFinder, int actionIndex) async {
    final state = tester.state<SwipeActionCellState>(cellFinder);
    if (state.currentSwipeState != SwipeState.revealed) {
      fail('SwipeTester.tapAction: cell is not in revealed state '
          '(actual: ${state.currentSwipeState}). '
          'Call swipeLeft/swipeRight and pumpAndSettle first.');
    }
    final panel = find.descendant(
        of: cellFinder, matching: find.byType(SwipeActionPanel));
    final actions =
        find.descendant(of: panel, matching: find.byType(GestureDetector));
    final count = tester.widgetList(actions).length;
    if (actionIndex >= count) {
      fail('SwipeTester.tapAction: actionIndex $actionIndex exceeds '
          'available actions ($count).');
    }
    await tester.tap(actions.at(actionIndex), warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}

import 'package:flutter_test/flutter_test.dart';
import '../core/swipe_state.dart';
import '../widget/swipe_action_cell.dart';

/// Assertion helpers for [SwipeActionCell] state, added to [WidgetTester].
extension SwipeAssertions on WidgetTester {
  /// Asserts that the [SwipeActionCell] matched by [finder] is in the [expected] state.
  void expectSwipeState(Finder finder, SwipeState expected) {
    final state = this.state<SwipeActionCellState>(finder);
    final actual = state.currentSwipeState;
    expect(actual, equals(expected),
        reason: 'Expected $expected but found $actual');
  }

  /// Asserts that the [SwipeActionCell] progress ratio is near [expected].
  void expectProgress(Finder finder, double expected,
      {double tolerance = 0.01}) {
    final state = this.state<SwipeActionCellState>(finder);
    final actual = state.currentSwipeRatio;
    final delta = (actual - expected).abs();
    expect(delta <= tolerance.abs(), isTrue,
        reason: 'Expected progress $expected ± $tolerance '
            'but found $actual (delta: $delta)');
  }

  /// Shorthand for asserting [SwipeState.revealed].
  void expectRevealed(Finder finder) =>
      expectSwipeState(finder, SwipeState.revealed);

  /// Shorthand for asserting [SwipeState.idle].
  void expectIdle(Finder finder) => expectSwipeState(finder, SwipeState.idle);
}

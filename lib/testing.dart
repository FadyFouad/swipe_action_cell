/// Test utilities for swipe_action_cell.
///
/// Import this library in widget tests to access all test helpers:
/// ```dart
/// import 'package:swipe_action_cell/testing.dart';
/// ```
///
/// Activates [SwipeAssertions] on [WidgetTester] automatically.
library;

export 'src/controller/swipe_controller.dart';
export 'src/core/swipe_direction.dart';
export 'src/core/swipe_progress.dart';
export 'src/core/swipe_state.dart';
export 'src/testing/mock_swipe_controller.dart';
export 'src/testing/swipe_assertions.dart';
export 'src/testing/swipe_test_harness.dart';
export 'src/testing/swipe_tester.dart';
export 'src/widget/swipe_action_cell.dart'
    show SwipeActionCellState, SwipeActionCell;

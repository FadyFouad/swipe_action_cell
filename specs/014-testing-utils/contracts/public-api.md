# Public API Contract: Consumer Testing Utilities (F015)

**Branch**: `014-testing-utils` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)

---

## `SwipeTester` Class

```dart
/// Utility class for simulating swipe gestures on [SwipeActionCell] in widget tests.
///
/// All methods are static — no instance creation needed.
///
/// ```dart
/// import 'package:swipe_action_cell/testing.dart';
///
/// testWidgets('delete fires after undo expires', (tester) async {
///   bool deleted = false;
///   await tester.pumpWidget(SwipeTestHarness(
///     child: SwipeActionCell.delete(
///       child: const ListTile(title: Text('Item')),
///       onDeleted: () => deleted = true,
///     ),
///   ));
///   await SwipeTester.swipeLeft(tester, find.byType(SwipeActionCell));
///   // Undo strip visible — not deleted yet
///   expect(deleted, isFalse);
/// });
/// ```
class SwipeTester {
  SwipeTester._(); // Prevent instantiation

  /// Drags the found widget to the left by [ratio] × widget width, then settles.
  ///
  /// [ratio] must be in [0.0, 1.0]; values are clamped. Default is 0.5.
  static Future<void> swipeLeft(
    WidgetTester tester,
    Finder finder, {
    double ratio = 0.5,
  }) async;

  /// Drags the found widget to the right by [ratio] × widget width, then settles.
  ///
  /// [ratio] must be in [0.0, 1.0]; values are clamped. Default is 0.5.
  static Future<void> swipeRight(
    WidgetTester tester,
    Finder finder, {
    double ratio = 0.5,
  }) async;

  /// Performs a fast left fling at [velocity] pixels/second, then settles.
  ///
  /// [velocity] must be positive. Zero or negative values are clamped to a
  /// minimum of 100 px/s.
  static Future<void> flingLeft(
    WidgetTester tester,
    Finder finder, {
    double velocity = 1000,
  }) async;

  /// Performs a fast right fling at [velocity] pixels/second, then settles.
  static Future<void> flingRight(
    WidgetTester tester,
    Finder finder, {
    double velocity = 1000,
  }) async;

  /// Drags the found widget by [offset] without calling pumpAndSettle.
  ///
  /// Use this to inspect mid-drag state. Callers are responsible for
  /// subsequent pump calls and restoring state.
  ///
  /// A single [pump()] is called after the drag to process the gesture event.
  static Future<void> dragTo(
    WidgetTester tester,
    Finder finder,
    Offset offset,
  ) async;

  /// Taps the action button at [actionIndex] in the cell's revealed panel.
  ///
  /// Fails immediately with a descriptive message if the cell is not in the
  /// [SwipeState.revealed] state. Settles after the tap.
  ///
  /// Throws a test failure if [actionIndex] is out of bounds.
  static Future<void> tapAction(
    WidgetTester tester,
    Finder cellFinder,
    int actionIndex,
  ) async;
}
```

---

## `SwipeAssertions` Extension

```dart
/// Assertion helpers for [SwipeActionCell] added to [WidgetTester].
///
/// Activated automatically when `testing.dart` is imported.
///
/// ```dart
/// tester.expectRevealed(find.byType(SwipeActionCell));
/// tester.expectProgress(find.byType(SwipeActionCell), 0.5, tolerance: 0.05);
/// ```
extension SwipeAssertions on WidgetTester {
  /// Asserts the [SwipeActionCell] found by [finder] is in [expected] state.
  ///
  /// Failure message: "Expected SwipeState.X but found SwipeState.Y"
  void expectSwipeState(Finder finder, SwipeState expected);

  /// Asserts the cell's animation ratio is within [tolerance] of [expected].
  ///
  /// [tolerance] defaults to 0.01. Failure message shows expected, actual,
  /// and delta values.
  void expectProgress(Finder finder, double expected, {double tolerance = 0.01});

  /// Asserts the cell is in [SwipeState.revealed].
  ///
  /// Equivalent to [expectSwipeState(finder, SwipeState.revealed)].
  void expectRevealed(Finder finder);

  /// Asserts the cell is in [SwipeState.idle].
  ///
  /// Equivalent to [expectSwipeState(finder, SwipeState.idle)].
  void expectIdle(Finder finder);
}
```

---

## `MockSwipeController` Class

```dart
/// A test double for [SwipeController] that records method calls and
/// provides configurable stub return values.
///
/// No additional packages are required. Simply extend or replace.
///
/// ```dart
/// final mock = MockSwipeController();
/// await tester.pumpWidget(SwipeTestHarness(
///   controller: mock,
///   child: SwipeActionCell(controller: mock, ...),
/// ));
/// mock.openLeft(); // Called externally — count incremented
/// expect(mock.openLeftCallCount, 1);
/// expect(mock.openCallCount, 1); // combined left + right
/// ```
class MockSwipeController extends SwipeController {
  /// Number of times [openLeft] was called.
  int get openLeftCallCount;

  /// Number of times [openRight] was called.
  int get openRightCallCount;

  /// Total number of [openLeft] + [openRight] calls.
  int get openCallCount;

  /// Number of times [close] was called.
  int get closeCallCount;

  /// Number of times [resetProgress] was called.
  int get resetProgressCallCount;

  /// Number of times [undo] was called.
  int get undoCallCount;

  /// Value returned by [currentState]. Set before the test to stub the getter.
  SwipeState stubbedState;

  /// Value returned by [currentProgress]. Set before the test to stub the getter.
  double stubbedProgress;

  /// Resets all call counts to 0. Does not change [stubbedState] or [stubbedProgress].
  void resetCalls();

  // Overridden methods — do NOT call super:
  @override void openLeft();
  @override void openRight();
  @override void close();
  @override void resetProgress();
  @override bool undo();
  @override SwipeState get currentState; // returns stubbedState
  @override double get currentProgress; // returns stubbedProgress
}
```

---

## `SwipeTestHarness` Widget

```dart
/// A minimal widget that wraps a [SwipeActionCell] with all required test
/// ancestors: [MediaQuery], [Localizations], [Directionality], and [Material].
///
/// Eliminates boilerplate in widget tests that need to pump a cell without
/// a full [MaterialApp].
///
/// ```dart
/// await tester.pumpWidget(SwipeTestHarness(
///   textDirection: TextDirection.rtl,
///   screenSize: const Size(414, 896),
///   child: SwipeActionCell.delete(
///     child: const ListTile(title: Text('Item')),
///     onDeleted: () {},
///   ),
/// ));
/// ```
class SwipeTestHarness extends StatelessWidget {
  const SwipeTestHarness({
    super.key,
    required this.child,
    this.textDirection = TextDirection.ltr,
    this.locale = const Locale('en'),
    this.screenSize = const Size(390, 844),
    this.controller,
  });

  /// The widget under test.
  final Widget child;

  /// Layout direction. Use [TextDirection.rtl] for RTL layout tests.
  final TextDirection textDirection;

  /// Locale forwarded to [Localizations].
  final Locale locale;

  /// Simulated screen size set via [MediaQueryData.size].
  /// Default: 390×844 (iPhone 14 logical pixels).
  final Size screenSize;

  /// Optional [SwipeController] reference. Not automatically wired — pass it
  /// to [SwipeActionCell.controller] manually.
  final SwipeController? controller;
}
```

---

## `SwipeActionCellState` Public Getters (added to existing class)

```dart
// In lib/src/widget/swipe_action_cell.dart — SwipeActionCellState class:

/// The current state of this cell's interaction state machine.
///
/// Exposed for use in widget tests:
/// ```dart
/// final state = tester.state<SwipeActionCellState>(find.byType(SwipeActionCell));
/// expect(state.currentSwipeState, SwipeState.idle);
/// ```
SwipeState get currentSwipeState => _state;

/// The current animation controller value (0.0 = closed, 1.0 = fully open).
///
/// Use [SwipeAssertions.expectProgress] for assertion-style checks.
double get currentSwipeRatio => _controller.value;
```

---

## `lib/testing.dart` Entry Point (updated exports)

```dart
/// Test utilities for swipe_action_cell.
///
/// Import this library in widget tests to access test helpers:
/// ```dart
/// import 'package:swipe_action_cell/testing.dart';
/// ```
///
/// This import activates the [SwipeAssertions] extension on [WidgetTester]
/// automatically. No other imports are needed.
library;

// Testing utilities
export 'src/testing/swipe_tester.dart';
export 'src/testing/swipe_assertions.dart';
export 'src/testing/mock_swipe_controller.dart';
export 'src/testing/swipe_test_harness.dart';

// Core types re-exported for single-import convenience
export 'src/core/swipe_state.dart';
export 'src/core/swipe_progress.dart';
export 'src/core/swipe_direction.dart';
export 'src/controller/swipe_controller.dart';
export 'src/widget/swipe_action_cell.dart' show SwipeActionCellState;
```

---

## Cross-Cutting Constraints

| Constraint | Source | Notes |
|---|---|---|
| Import only `flutter_test` | FR-014-022 | `flutter_test: sdk: flutter` in `dependencies` (not third-party) |
| All public members carry `///` | Constitution VIII | All classes, methods, getters, fields |
| `SwipeTester` is non-instantiable | API design | Private `._()` constructor |
| `SwipeTestHarness` is `const`-friendly | Constitution VI | All fields `final`, `const` constructor |
| `MockSwipeController` needs no mockito | FR-014-016 | Extends `SwipeController` directly |
| No new widget type in tests (harness is minimal) | Constitution I | `SwipeTestHarness` wraps, does not extend cells |
| `SwipeActionCellState` exported only from `testing.dart` | D9 decision | Not added to main `swipe_action_cell.dart` barrel |

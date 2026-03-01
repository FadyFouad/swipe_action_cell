# Data Model: Consumer Testing Utilities (F015)

**Branch**: `014-testing-utils` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)

---

## Public Types

### `SwipeTester` (class — public)

Location: `lib/src/testing/swipe_tester.dart`

A utility class exposing all gesture simulation methods as static functions. No instantiation required.

| Method | Signature | Settles? | Description |
|---|---|---|---|
| `swipeLeft` | `static Future<void> swipeLeft(WidgetTester, Finder, {double ratio = 0.5})` | ✅ Yes | Drags left by `ratio × cell width`, settles |
| `swipeRight` | `static Future<void> swipeRight(WidgetTester, Finder, {double ratio = 0.5})` | ✅ Yes | Drags right by `ratio × cell width`, settles |
| `flingLeft` | `static Future<void> flingLeft(WidgetTester, Finder, {double velocity = 1000})` | ✅ Yes | Fast left fling at given velocity, settles |
| `flingRight` | `static Future<void> flingRight(WidgetTester, Finder, {double velocity = 1000})` | ✅ Yes | Fast right fling at given velocity, settles |
| `dragTo` | `static Future<void> dragTo(WidgetTester, Finder, Offset)` | ❌ No | Drags to exact offset, single pump (for mid-drag inspection) |
| `tapAction` | `static Future<void> tapAction(WidgetTester, Finder, int)` | ✅ Yes | Taps action button at index in revealed panel; fails with message if not revealed |

**Constraints**:
- All methods are `static` — no state held in `SwipeTester` instances
- `ratio` must be in range `[0.0, 1.0]`; values outside this range are clamped internally
- `velocity` for fling must be positive; zero/negative treated as minimum meaningful velocity
- `tapAction` with out-of-bounds `actionIndex` fails with `"tapAction: actionIndex N exceeds available actions (M)"`

---

### `SwipeAssertions` (extension on `WidgetTester`)

Location: `lib/src/testing/swipe_assertions.dart`

Extension methods activated automatically when `testing.dart` is imported.

| Method | Signature | Description |
|---|---|---|
| `expectSwipeState` | `void expectSwipeState(Finder, SwipeState)` | Asserts state matches; fails with "Expected: X, Actual: Y" |
| `expectProgress` | `void expectProgress(Finder, double, {double tolerance = 0.01})` | Asserts animation ratio within tolerance; fails with actual value |
| `expectRevealed` | `void expectRevealed(Finder)` | Shorthand: `expectSwipeState(finder, SwipeState.revealed)` |
| `expectIdle` | `void expectIdle(Finder)` | Shorthand: `expectSwipeState(finder, SwipeState.idle)` |

**Failure message format**:
- State: `"Expected SwipeState.revealed but found SwipeState.idle"`
- Progress: `"Expected progress 0.50 ± 0.01 but found 0.73 (delta: 0.23)"`

**Constraints**:
- Finder must match exactly one `SwipeActionCell`; multiple matches throw `"finder matched N SwipeActionCell widgets; expectSwipeState requires exactly one"`
- `tolerance` must be ≥ 0; negative tolerance is treated as 0

---

### `MockSwipeController` (class — public)

Location: `lib/src/testing/mock_swipe_controller.dart`

Test double extending `SwipeController`. Tracks calls and accepts stub return values.

| Field/Method | Type | Description |
|---|---|---|
| `openLeftCallCount` | `int` (read-only) | Number of times `openLeft()` was called |
| `openRightCallCount` | `int` (read-only) | Number of times `openRight()` was called |
| `openCallCount` | `int` (computed) | `openLeftCallCount + openRightCallCount` |
| `closeCallCount` | `int` (read-only) | Number of times `close()` was called |
| `resetProgressCallCount` | `int` (read-only) | Number of times `resetProgress()` was called |
| `undoCallCount` | `int` (read-only) | Number of times `undo()` was called |
| `stubbedState` | `SwipeState` | Return value for `currentState` getter; defaults to `SwipeState.idle` |
| `stubbedProgress` | `double` | Return value for `currentProgress` getter; defaults to `0.0` |
| `resetCalls()` | `void` | Resets all call counts to 0 (does not reset stubs) |

**Overridden methods** (do not call super):
- `openLeft()`, `openRight()`, `close()`, `resetProgress()`, `undo()`
- `currentState` getter → returns `stubbedState`
- `currentProgress` getter → returns `stubbedProgress`

**Constraints**:
- `MockSwipeController` does NOT attach to any `SwipeCellHandle` — calling open/close methods is a no-op on the widget
- No additional packages required
- Safe to call `dispose()` — inherited `ChangeNotifier.dispose()` still works

---

### `SwipeTestHarness` (widget — public)

Location: `lib/src/testing/swipe_test_harness.dart`

A `StatelessWidget` that provides a pre-configured test ancestor tree.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `child` | `Widget` | required | The widget under test |
| `textDirection` | `TextDirection` | `TextDirection.ltr` | Controls layout directionality (use `rtl` for RTL tests) |
| `locale` | `Locale` | `Locale('en')` | Locale passed to `Localizations` |
| `screenSize` | `Size` | `Size(390, 844)` | Simulated device screen dimensions |
| `controller` | `SwipeController?` | `null` | Optional pre-configured controller to inject |

**Widget tree produced**:
```
MediaQuery(size: screenSize, devicePixelRatio: 1.0, textScaler: noScaling)
└── Localizations(locale, [DefaultWidgets..., DefaultMaterial...])
    └── Directionality(textDirection)
        └── Material(child)
```

**Constraints**:
- Does NOT use `MaterialApp` or `CupertinoApp`
- `controller` is not automatically wired to the child — the consumer must pass it to `SwipeActionCell.controller`; the parameter is a convenience reference holder for the test
- `screenSize` affects `MediaQuery.of(context).size` but does NOT change the actual render viewport in tests (use `tester.view.physicalSize` for that)

---

## Modified Types

### `SwipeActionCellState` (add public getters)

Location: `lib/src/widget/swipe_action_cell.dart` (MODIFIED)

Two public getters added to the existing `SwipeActionCellState` class:

| Getter | Type | Returns |
|---|---|---|
| `currentSwipeState` | `SwipeState` | Current state machine value (`_state` field) |
| `currentSwipeRatio` | `double` | Current animation controller value (0.0–1.0) |

These getters are used internally by `SwipeAssertions` and are also available for advanced consumers who access state via `tester.state<SwipeActionCellState>(finder)`.

---

## Modified Files

```text
lib/testing.dart                               ← MODIFIED: add exports for all 4 utility types
lib/src/widget/swipe_action_cell.dart          ← MODIFIED: +2 public getters to SwipeActionCellState
pubspec.yaml                                   ← MODIFIED: move flutter_test from dev_dependencies to dependencies
```

## New Files

```text
lib/src/testing/
├── swipe_tester.dart           ← SwipeTester (gesture simulation)
├── swipe_assertions.dart       ← SwipeAssertions extension on WidgetTester
├── mock_swipe_controller.dart  ← MockSwipeController
└── swipe_test_harness.dart     ← SwipeTestHarness widget
```

## New Test Files

```text
test/testing/
├── swipe_tester_test.dart          ← Tests for gesture simulation (US1)
├── swipe_assertions_test.dart      ← Tests for assertion extensions (US2)
├── mock_swipe_controller_test.dart ← Tests for mock controller (US3)
└── swipe_test_harness_test.dart    ← Tests for test harness widget (US4)
```

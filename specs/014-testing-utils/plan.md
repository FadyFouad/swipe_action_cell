# Implementation Plan: Consumer Testing Utilities (F015)

**Branch**: `014-testing-utils` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/014-testing-utils/spec.md`

---

## Summary

Add four consumer-facing test utilities to the `swipe_action_cell` package, exported exclusively from `lib/testing.dart`: `SwipeTester` (gesture simulation), `SwipeAssertions` (WidgetTester extension methods), `MockSwipeController` (test double), and `SwipeTestHarness` (test scaffold widget). Two minor additions to existing files: two public getters on `SwipeActionCellState`, and `flutter_test` moved to `dependencies` in `pubspec.yaml`. All utilities require only a single `import 'package:swipe_action_cell/testing.dart'`.

---

## Technical Context

**Language/Version**: Dart ≥ 3.4.0 < 4.0.0
**Primary Dependencies**: `flutter_test` (Flutter SDK — moved from dev_dependencies to dependencies to enable `lib/` imports)
**Storage**: N/A (stateless utility code)
**Testing**: `flutter test` (widget tests + unit tests)
**Target Platform**: All Flutter-supported platforms (utilities run in test environment only)
**Performance Goals**: Zero runtime overhead — utilities are excluded from production builds by tree-shaking
**Constraints**: No third-party packages (FR-014-022); all utilities in `lib/src/testing/` not `test/`; `SwipeActionCellState` must expose `currentSwipeState` getter
**Scale/Scope**: 4 new source files, 3 modified files, 4 new test files

---

## Constitution Check

*GATE: Must pass before implementation. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| I. Composition over Inheritance | ✅ PASS | `SwipeTestHarness` wraps any child widget; `MockSwipeController` extends `SwipeController` (not a custom widget subclass) |
| II. Explicit State Machine | ✅ PASS | No new states; utilities read existing `SwipeState` values; `MockSwipeController` stubs `currentState` without mutating the machine |
| III. Spring-Based Physics | ✅ PASS | No new animations; utilities work with existing spring animation system |
| IV. Zero External Runtime Deps | ⚠️ EXCEPTION | `flutter_test` added to `dependencies` — see Complexity Tracking |
| V. Controlled/Uncontrolled Pattern | ✅ PASS | `SwipeTestHarness.controller` is optional; utilities work without any controller |
| VI. Const-Friendly Configuration | ✅ PASS | `SwipeTestHarness` has a `const` constructor; `MockSwipeController` is mutable by design (test double) |
| VII. Test-First | ✅ PASS | Tests written before implementation in every cluster (NON-NEGOTIABLE) |
| VIII. Dartdoc Everything | ✅ PASS | All public classes, methods, and getters carry `///` documentation comments |
| IX. Null Config = Feature Disabled | ✅ PASS | No new config objects; `SwipeTestHarness.controller` is nullable and optional |
| X. 60 fps Budget | ✅ PASS | Utilities add zero runtime overhead; excluded from production by tree-shaking |

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Constitution IV: `flutter_test` added to `dependencies` (not just `dev_dependencies`) | Code in `lib/src/testing/` must import `WidgetTester`, `Finder`, and related flutter_test types. These are only available if `flutter_test` is in `dependencies`. | Keeping `flutter_test` in `dev_dependencies` prevents any `lib/` file from importing it. Alternatives: (a) separate pub package — rejected by spec (must be same package); (b) dynamic typing — rejected as unsafe and un-idiomatic. `flutter_test` is an SDK package (not third-party), is always available, and is tree-shaken from production release builds. |

---

## Project Structure

### Documentation (this feature)

```text
specs/014-testing-utils/
├── plan.md              ← This file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
├── contracts/
│   └── public-api.md    ← Phase 1 output
└── tasks.md             ← Phase 2 output (/speckit.tasks)
```

### Source Code

```text
lib/
├── testing.dart                         ← MODIFIED: add 4 utility exports + selective re-exports
└── src/
    ├── testing/                         ← NEW directory (F015)
    │   ├── swipe_tester.dart            ← SwipeTester (gesture simulation)
    │   ├── swipe_assertions.dart        ← SwipeAssertions extension on WidgetTester
    │   ├── mock_swipe_controller.dart   ← MockSwipeController
    │   └── swipe_test_harness.dart      ← SwipeTestHarness widget
    └── widget/
        └── swipe_action_cell.dart       ← MODIFIED: +2 public getters on SwipeActionCellState

pubspec.yaml                             ← MODIFIED: flutter_test moved to dependencies

test/
└── testing/                             ← NEW test directory
    ├── swipe_tester_test.dart
    ├── swipe_assertions_test.dart
    ├── mock_swipe_controller_test.dart
    └── swipe_test_harness_test.dart
```

**Structure Decision**: Single library package. New `lib/src/testing/` directory follows the feature-first pattern (alongside `gesture/`, `animation/`, `templates/`, etc.). The `testing.dart` entry point already exists — only its export list needs updating.

---

## Phase 0: Research Output

See [research.md](research.md) for all 10 architectural decisions (D1–D10).

Key decisions summary:
- **D1** State access via `SwipeActionCellState.currentSwipeState` + `currentSwipeRatio` (public getters added)
- **D2** Gesture simulation via `tester.drag()` with `getRect().width × ratio` pixel offset
- **D3** `dragTo` uses single `pump()` — no settle (for mid-drag inspection)
- **D4** `SwipeAssertions` is a Dart extension on `WidgetTester` — activated by import
- **D5** `MockSwipeController extends SwipeController` — overrides methods without calling super
- **D6** `SwipeTestHarness` uses `Directionality + MediaQuery + Material` (no MaterialApp)
- **D7** `tapAction` finds `SwipeActionPanel` descendants, pre-checks revealed state
- **D8** `flutter_test` moved to `dependencies` — only SDK package, tree-shaken in production
- **D9** `testing.dart` selectively re-exports `SwipeState`, `SwipeProgress`, `SwipeDirection`, `SwipeController`, `SwipeActionCellState`
- **D10** Files in `lib/src/testing/` — feature-first directory pattern

---

## Phase 1: Design Artifacts

- **Data Model**: [data-model.md](data-model.md) — types, fields, constraints, modified types
- **Public API Contract**: [contracts/public-api.md](contracts/public-api.md) — full Dart signatures, behavior tables, constraints
- **Quickstart**: [quickstart.md](quickstart.md) — 8 test scenarios, 35+ checkpoints

---

## Implementation Clusters

```
Cluster A ─────────────────────── Prerequisites (foundation)
  T001: Add currentSwipeState + currentSwipeRatio getters to SwipeActionCellState (RED test first)
  T002: Move flutter_test to dependencies in pubspec.yaml

Cluster B ─────────────────────── SwipeTester [US1, after A]
  T003: tests for SwipeTester.swipeLeft/swipeRight/flingLeft/flingRight (RED)
  T004: tests for SwipeTester.dragTo + tapAction (RED)
  T005: implement SwipeTester in lib/src/testing/swipe_tester.dart

Cluster C ─────────────────────── SwipeAssertions [US2, parallel with B after A]
  T006: tests for expectSwipeState / expectProgress / expectRevealed / expectIdle (RED)
  T007: implement SwipeAssertions extension in lib/src/testing/swipe_assertions.dart

Cluster D ─────────────────────── MockSwipeController [US3, parallel with B+C after A]
  T008: tests for MockSwipeController call counts + stub state (RED)
  T009: implement MockSwipeController in lib/src/testing/mock_swipe_controller.dart

Cluster E ─────────────────────── SwipeTestHarness [US4, parallel with B+C+D after A]
  T010: tests for SwipeTestHarness (ancestors, RTL, screenSize) (RED)
  T011: implement SwipeTestHarness in lib/src/testing/swipe_test_harness.dart

Cluster F ─────────────────────── Exports + integration [after B+C+D+E]
  T012: update lib/testing.dart with all exports + selective re-exports
  T013: verify single-import works (Scenario 7 from quickstart.md)

Cluster G ─────────────────────── Polish [after F]
  T014: flutter analyze + dart format
  T015: regression run (flutter test)
```

**Dependency graph**:
```
A → B [parallel]
A → C [parallel with B]
A → D [parallel with B, C]
A → E [parallel with B, C, D]
B + C + D + E → F
F → G
```

---

## Key Implementation Notes

### Adding Public Getters to `SwipeActionCellState`

In `lib/src/widget/swipe_action_cell.dart`, inside `SwipeActionCellState`:

```dart
/// The current state of this cell's interaction state machine.
///
/// Exposed for widget test inspection:
/// ```dart
/// final s = tester.state<SwipeActionCellState>(find.byType(SwipeActionCell));
/// expect(s.currentSwipeState, SwipeState.idle);
/// ```
SwipeState get currentSwipeState => _state;

/// The current animation controller value (0.0 = closed, 1.0 = fully open).
double get currentSwipeRatio => _controller.value;
```

### `SwipeTester` Implementation

```dart
// lib/src/testing/swipe_tester.dart

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import '../actions/intentional/swipe_action_panel.dart';
import '../core/swipe_state.dart';
import '../widget/swipe_action_cell.dart';

/// Utility class for simulating swipe gestures in widget tests.
class SwipeTester {
  SwipeTester._();

  static Future<void> swipeLeft(WidgetTester tester, Finder finder,
      {double ratio = 0.5}) async {
    final rect = tester.getRect(finder);
    final clampedRatio = ratio.clamp(0.0, 1.0);
    await tester.drag(finder, Offset(-(rect.width * clampedRatio), 0));
    await tester.pumpAndSettle();
  }

  static Future<void> swipeRight(WidgetTester tester, Finder finder,
      {double ratio = 0.5}) async {
    final rect = tester.getRect(finder);
    final clampedRatio = ratio.clamp(0.0, 1.0);
    await tester.drag(finder, Offset(rect.width * clampedRatio, 0));
    await tester.pumpAndSettle();
  }

  static Future<void> flingLeft(WidgetTester tester, Finder finder,
      {double velocity = 1000}) async {
    await tester.fling(finder, const Offset(-1, 0), velocity.clamp(100, double.infinity));
    await tester.pumpAndSettle();
  }

  static Future<void> flingRight(WidgetTester tester, Finder finder,
      {double velocity = 1000}) async {
    await tester.fling(finder, const Offset(1, 0), velocity.clamp(100, double.infinity));
    await tester.pumpAndSettle();
  }

  static Future<void> dragTo(WidgetTester tester, Finder finder,
      Offset offset) async {
    await tester.drag(finder, offset);
    await tester.pump(); // Single frame — intentionally no pumpAndSettle
  }

  static Future<void> tapAction(WidgetTester tester, Finder cellFinder,
      int actionIndex) async {
    final state = tester.state<SwipeActionCellState>(cellFinder);
    if (state.currentSwipeState != SwipeState.revealed) {
      fail('SwipeTester.tapAction: cell is not in revealed state '
          '(actual: ${state.currentSwipeState}). '
          'Call swipeLeft/swipeRight and pumpAndSettle first.');
    }
    final panel = find.descendant(
        of: cellFinder, matching: find.byType(SwipeActionPanel));
    final actions = find.descendant(
        of: panel, matching: find.byType(GestureDetector));
    final count = tester.widgetList(actions).length;
    if (actionIndex >= count) {
      fail('SwipeTester.tapAction: actionIndex $actionIndex exceeds '
          'available actions ($count).');
    }
    await tester.tap(actions.at(actionIndex));
    await tester.pumpAndSettle();
  }
}
```

### `SwipeAssertions` Extension

```dart
// lib/src/testing/swipe_assertions.dart

import 'package:flutter_test/flutter_test.dart';
import '../core/swipe_state.dart';
import '../widget/swipe_action_cell.dart';

/// Assertion helpers for [SwipeActionCell] state, added to [WidgetTester].
extension SwipeAssertions on WidgetTester {
  void expectSwipeState(Finder finder, SwipeState expected) {
    final state = this.state<SwipeActionCellState>(finder);
    final actual = state.currentSwipeState;
    expect(actual, equals(expected),
        reason: 'Expected SwipeState.$expected but found SwipeState.$actual');
  }

  void expectProgress(Finder finder, double expected,
      {double tolerance = 0.01}) {
    final state = this.state<SwipeActionCellState>(finder);
    final actual = state.currentSwipeRatio;
    final delta = (actual - expected).abs();
    expect(delta <= tolerance.abs(), isTrue,
        reason: 'Expected progress $expected ± $tolerance '
            'but found $actual (delta: $delta)');
  }

  void expectRevealed(Finder finder) =>
      expectSwipeState(finder, SwipeState.revealed);

  void expectIdle(Finder finder) =>
      expectSwipeState(finder, SwipeState.idle);
}
```

### `MockSwipeController`

```dart
// lib/src/testing/mock_swipe_controller.dart

import '../controller/swipe_controller.dart';
import '../core/swipe_state.dart';

/// Test double for [SwipeController] that records method invocations.
class MockSwipeController extends SwipeController {
  int _openLeft = 0;
  int _openRight = 0;
  int _close = 0;
  int _resetProgress = 0;
  int _undo = 0;

  /// Number of times [openLeft] was called.
  int get openLeftCallCount => _openLeft;
  /// Number of times [openRight] was called.
  int get openRightCallCount => _openRight;
  /// Combined [openLeft] + [openRight] call count.
  int get openCallCount => _openLeft + _openRight;
  /// Number of times [close] was called.
  int get closeCallCount => _close;
  /// Number of times [resetProgress] was called.
  int get resetProgressCallCount => _resetProgress;
  /// Number of times [undo] was called.
  int get undoCallCount => _undo;

  /// Stub return value for [currentState]. Default: [SwipeState.idle].
  SwipeState stubbedState = SwipeState.idle;
  /// Stub return value for [currentProgress]. Default: 0.0.
  double stubbedProgress = 0.0;

  @override SwipeState get currentState => stubbedState;
  @override double get currentProgress => stubbedProgress;

  @override void openLeft() => _openLeft++;
  @override void openRight() => _openRight++;
  @override void close() => _close++;
  @override void resetProgress() => _resetProgress++;
  @override bool undo() { _undo++; return false; }

  /// Resets all call counts to 0. Does not modify stubs.
  void resetCalls() => _openLeft = _openRight = _close = _resetProgress = _undo = 0;
}
```

### `SwipeTestHarness`

```dart
// lib/src/testing/swipe_test_harness.dart

import 'package:flutter/material.dart';
import '../controller/swipe_controller.dart';

/// Wraps a [SwipeActionCell] with all required test ancestors.
class SwipeTestHarness extends StatelessWidget {
  const SwipeTestHarness({
    super.key,
    required this.child,
    this.textDirection = TextDirection.ltr,
    this.locale = const Locale('en'),
    this.screenSize = const Size(390, 844),
    this.controller,
  });

  final Widget child;
  final TextDirection textDirection;
  final Locale locale;
  final Size screenSize;
  final SwipeController? controller;

  @override
  Widget build(BuildContext context) => MediaQuery(
    data: MediaQueryData(
      size: screenSize,
      devicePixelRatio: 1.0,
      textScaler: TextScaler.noScaling,
    ),
    child: Localizations(
      locale: locale,
      delegates: const [
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      child: Directionality(
        textDirection: textDirection,
        child: Material(child: child),
      ),
    ),
  );
}
```

### Updated `lib/testing.dart`

```dart
/// Test utilities for swipe_action_cell.
///
/// Import this library in widget tests to access all test helpers:
/// ```dart
/// import 'package:swipe_action_cell/testing.dart';
/// ```
///
/// Activates [SwipeAssertions] on [WidgetTester] automatically.
library;

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

## Post-Design Constitution Re-Check

All 10 principles confirmed compliant after design. One documented exception (Principle IV / `flutter_test` in `dependencies`) is justified and recorded in Complexity Tracking above. No gate violations. Proceed to `/speckit.tasks`.

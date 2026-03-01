# Research: Consumer Testing Utilities (F015)

**Branch**: `014-testing-utils` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)

---

## D1: How to Access SwipeActionCell State from Tests

**Decision**: Add two public getters to the already-public `SwipeActionCellState` class:
- `SwipeState get currentSwipeState => _state;`
- `double get currentSwipeRatio => _controller.value;`

Tests then access state via `tester.state<SwipeActionCellState>(finder).currentSwipeState`.

**Rationale**: `SwipeActionCellState` is already documented "Exposed for testing via `tester.state<SwipeActionCellState>(...)`" (line 661 comment in `swipe_action_cell.dart`). Adding public getters completes this intent without architectural change. The pattern mirrors `TextFieldState.text` and `FormFieldState.value` — exposing state for test inspection without exposing mutation.

**Alternatives considered**:
- Route through `SwipeController` — rejected: requires a controller for all state assertions, breaking the zero-configuration model (consumers without controllers couldn't use state assertions at all).
- Expose state via `InheritedWidget` — rejected: requires wrapping the cell in a provider; adds overhead; unsuitable for assertion helpers that take any `Finder`.
- Check widget tree for specific child types (e.g., look for undo overlay widget) — rejected: fragile; coupled to internal widget structure; breaks if internal rendering changes.

---

## D2: Gesture Simulation Mechanics

**Decision**: Use `WidgetTester.drag(finder, offset)` for `swipeLeft`/`swipeRight`, and `WidgetTester.fling(finder, offset, velocity)` for `flingLeft`/`flingRight`. Cell width is measured via `tester.getRect(finder).width` to compute the pixel offset from the `ratio` parameter.

**Rationale**: `tester.drag()` is the Flutter testing API for gesture simulation. It injects synthetic pointer events at the correct rate to trigger gesture recognizers. Using `getRect().width` to scale the ratio gives consistent results across different cell widths. Calling `pumpAndSettle()` after each gesture ensures animations complete before assertions.

**Wiring** (swipeLeft):
```dart
Future<void> swipeLeft(WidgetTester tester, Finder finder, {double ratio = 0.5}) async {
  final rect = tester.getRect(finder);
  await tester.drag(finder, Offset(-(rect.width * ratio), 0));
  await tester.pumpAndSettle();
}
```

**Wiring** (flingLeft):
```dart
Future<void> flingLeft(WidgetTester tester, Finder finder, {double velocity = 1000}) async {
  await tester.fling(finder, const Offset(-1, 0), velocity);
  await tester.pumpAndSettle();
}
```

**Alternatives considered**:
- Absolute pixel offsets — rejected: non-reusable across different cell widths; consumers would need to know exact dimensions.
- Gesture simulation via `WidgetController` API — equivalent to `tester.drag`; same underlying mechanism.

---

## D3: `dragTo` Does Not Settle — One `pump()` Only

**Decision**: `dragTo(tester, finder, offset)` calls `tester.drag(finder, offset)` followed by `tester.pump()` (single frame), NOT `pumpAndSettle()`.

**Rationale**: `dragTo` is specifically designed for mid-drag inspection (per FR-014-005 and spec US1 AS5). If `pumpAndSettle()` were called, the spring animation would settle and the mid-drag state would be lost. A single `pump()` advances one frame so the render tree reflects the drag position without triggering the settle-back animation.

**Alternatives considered**:
- No pump after drag — rejected: drag gesture is only fully processed after a pump; assertions immediately after drag without pump would see stale state.
- Two pumps — rejected: overkill; one frame is sufficient to render the drag offset.

---

## D4: WidgetTester Extension Methods

**Decision**: Implement state assertions as Dart extension methods on `WidgetTester`:

```dart
extension SwipeAssertions on WidgetTester {
  void expectSwipeState(Finder finder, SwipeState expected) { ... }
  void expectProgress(Finder finder, double expected, {double tolerance = 0.01}) { ... }
  void expectRevealed(Finder finder) => expectSwipeState(finder, SwipeState.revealed);
  void expectIdle(Finder finder) => expectSwipeState(finder, SwipeState.idle);
}
```

**Rationale**: Extension methods on `WidgetTester` are idiomatic in Flutter testing. They are called as `tester.expectRevealed(finder)` which reads naturally in test code. No explicit import of the extension class is needed — the `import 'package:swipe_action_cell/testing.dart'` import activates all extensions automatically.

**Alternatives considered**:
- Top-level functions `expectRevealed(tester, finder)` — valid but less readable and less discoverable via IDE autocomplete on `tester.`.
- Custom `SwipeWidgetTester` class wrapping `WidgetTester` — rejected: forces consumers to use a wrapper; incompatible with existing test helper patterns.

---

## D5: MockSwipeController Implementation Strategy

**Decision**: `MockSwipeController extends SwipeController`. Override `openLeft()`, `openRight()`, `close()`, `resetProgress()`, and `undo()` to record calls without invoking any actual animation logic. Override `currentState` and `currentProgress` getters to return stub values.

```dart
class MockSwipeController extends SwipeController {
  int openLeftCallCount = 0;
  int openRightCallCount = 0;
  int closeCallCount = 0;
  int resetProgressCallCount = 0;
  int undoCallCount = 0;

  SwipeState stubbedState = SwipeState.idle;
  double stubbedProgress = 0.0;

  @override SwipeState get currentState => stubbedState;
  @override double get currentProgress => stubbedProgress;

  @override void openLeft() => openLeftCallCount++;
  @override void openRight() => openRightCallCount++;
  @override void close() => closeCallCount++;
  @override void resetProgress() => resetProgressCallCount++;
  @override bool undo() { undoCallCount++; return false; }

  void resetCalls() {
    openLeftCallCount = openRightCallCount = closeCallCount =
        resetProgressCallCount = undoCallCount = 0;
  }
}
```

A convenience `openCallCount` getter returns `openLeftCallCount + openRightCallCount` for the common case where direction is irrelevant.

**Rationale**: Extending `SwipeController` gives `MockSwipeController` the full type compatibility — it can be assigned anywhere a `SwipeController` is expected. Overriding at the method level without calling `super` is safe because the base class methods require an attached `SwipeCellHandle`; in a mock there is no handle, so calling super would be a no-op or throw.

**Alternatives considered**:
- Implement `SwipeCellHandle` directly — rejected: `MockSwipeController` needs to satisfy the `SwipeController` type, not just the internal handle interface.
- Use `mockito` generated mock — rejected: FR-014-016 prohibits additional packages; hand-rolled mock is sufficient.

---

## D6: SwipeTestHarness Minimal Ancestors

**Decision**: `SwipeTestHarness` wraps its child with `Directionality` + `MediaQuery` + `Material` (no `MaterialApp` needed). Default: LTR, 390×844 screen, English locale.

```dart
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
```

**Rationale**: `SwipeActionCell` requires `Directionality` (for RTL detection), `MediaQuery` (for text scaling in action labels), and `Material` (for ink effects in action buttons). It does NOT require a full `MaterialApp`. The minimal wrapper avoids navigation stack, theme cascade, and other `MaterialApp` overhead that can cause unexpected test failures.

**Alternatives considered**:
- Use `MaterialApp` — rejected: adds navigation, theme, and overlay layers that can interfere with gesture simulation timing; harder to reason about in tests.
- Use `WidgetsApp` — equivalent overhead reduction; `Material` is still needed for button rendering; chose explicit `Material` + `Directionality` for clarity.

---

## D7: `tapAction` Implementation

**Decision**: `tapAction` finds the `SwipeActionPanel` widget as a descendant of the cell finder, then finds tappable children in order (by horizontal position), and taps the one at `actionIndex`. If the cell is not in the revealed state, an immediate test failure is thrown with a descriptive message.

```dart
Future<void> tapAction(WidgetTester tester, Finder cellFinder, int actionIndex) async {
  final state = tester.state<SwipeActionCellState>(cellFinder);
  if (state.currentSwipeState != SwipeState.revealed) {
    fail('tapAction: cell is not in revealed state '
         '(actual: ${state.currentSwipeState}). '
         'Call swipeLeft/swipeRight and pumpAndSettle first.');
  }
  final panel = find.descendant(
    of: cellFinder, matching: find.byType(SwipeActionPanel));
  final actions = find.descendant(
    of: panel, matching: find.byType(GestureDetector));
  await tester.tap(actions.at(actionIndex));
  await tester.pumpAndSettle();
}
```

**Rationale**: `SwipeActionPanel` (exported from the main barrel) renders each `SwipeAction` as a `GestureDetector`. Ordering is deterministic (left-to-right / right-to-left follows the layout direction). Pre-checking the revealed state gives a better error message than letting the `at(actionIndex)` fail with a "no widget found" message.

**Alternatives considered**:
- `find.byKey` — requires consumers to assign keys to their actions; breaks zero-configuration.
- Find by action label text — requires knowing label text in the test; fragile if icons are used without labels.

---

## D8: `flutter_test` as a Runtime Dependency

**Decision**: Move `flutter_test: sdk: flutter` from `dev_dependencies` to `dependencies` in `pubspec.yaml` to enable `lib/testing.dart` to import and use `WidgetTester` and related types.

**Rationale**: Dart's `lib/` directory is for production code. Code in `lib/` cannot import from `dev_dependencies`. Moving `flutter_test` to `dependencies` is the standard Flutter pattern for packages that ship test utilities via `lib/testing.dart`. Since `flutter_test` is an SDK package (`sdk: flutter`), it: (a) adds no third-party package to the dependency graph, (b) is tree-shaken from production release builds by Flutter's build system, and (c) is always available regardless of platform.

This satisfies the SPIRIT of FR-014-022 (no third-party packages in the production tree) while enabling the separate entry point architecture.

**Alternatives considered**:
- Keep `flutter_test` in `dev_dependencies` and write `testing.dart` without it — rejected: `WidgetTester`, `Finder`, and `WidgetController` types cannot be referenced in `lib/` without the import.
- Separate `swipe_action_cell_test` pub package — rejected: the spec explicitly requires the same package via `testing.dart`; a separate package increases consumer friction.

---

## D9: `testing.dart` Re-exports

**Decision**: `lib/testing.dart` re-exports the following from the main package for single-import convenience:
- `SwipeState`, `SwipeProgress`, `SwipeDirection` — needed in assertion calls
- `SwipeController`, `SwipeGroupController` — needed when using `MockSwipeController` or `SwipeTestHarness`
- `SwipeActionCellState` — needed for direct state access via `tester.state<SwipeActionCellState>()`

It does NOT re-export the full `swipe_action_cell.dart` barrel to avoid namespace pollution.

**Rationale**: Consumers writing tests should import only `testing.dart` without also needing `swipe_action_cell.dart` for the types used in assertions. Selective re-exports keep the import footprint minimal.

**Alternatives considered**:
- Export everything from `swipe_action_cell.dart` — rejected: re-exporting 30+ types into a test-only import is confusing and risks identifier conflicts.
- No re-exports (consumer must import both) — rejected: defeats the "single import" goal in SC-014-002.

---

## D10: File Organization in `lib/src/testing/`

**Decision**: New `lib/src/testing/` directory with four files:

```text
lib/src/testing/
├── swipe_tester.dart           ← SwipeTester class (gesture helpers)
├── swipe_assertions.dart       ← SwipeAssertions extension on WidgetTester
├── mock_swipe_controller.dart  ← MockSwipeController class
└── swipe_test_harness.dart     ← SwipeTestHarness widget
```

**Rationale**: Follows the feature-first directory convention used by `gesture/`, `animation/`, `painting/`, `templates/`, etc. Four files match the four spec user stories, enabling task-level parallelism during implementation. Each file has a single clear responsibility.

**Alternatives considered**:
- Single `testing.dart` file — rejected: would exceed 300+ lines and mix unrelated concepts.
- Place files directly in `lib/` alongside `testing.dart` — rejected: violates the established `lib/src/` structure for implementation files.

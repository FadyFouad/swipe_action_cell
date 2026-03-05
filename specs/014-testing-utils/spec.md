# Feature Specification: Consumer Testing Utilities

**Feature Branch**: `014-testing-utils`
**Created**: 2026-03-01
**Status**: Draft
**Input**: User description: "Provide testing utilities for consumers of the swipe_action_cell package so they can easily test their own code that uses SwipeActionCell."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Gesture Simulation Helpers (Priority: P1)

As a package consumer, I want a set of swipe gesture helpers so that I can simulate left and right swipes, flings, mid-drag positions, and action button taps in my widget tests without managing timing, pixel math, or pump cycles manually.

**Why this priority**: Simulating gestures is the most fundamental and universal need. Without reliable gesture simulation, consumers cannot test any swipe interaction at all. All other testing utilities are secondary to solving this core pain point.

**Independent Test**: Write a widget test that wraps a `SwipeActionCell` with a delete callback. Call `swipeLeft` — verify the undo strip appears. Call `swipeRight` — verify no gesture fires. Call `flingLeft` — verify the delete action triggers. No other utilities needed.

**Acceptance Scenarios**:

1. **Given** a left-swipe cell, **When** `swipeLeft(tester, finder, ratio: 0.7)` is called, **Then** the cell is dragged to 70% of its width and the gesture settles.
2. **Given** a right-swipe cell, **When** `swipeRight(tester, finder)` is called with no `ratio` argument, **Then** the cell is dragged to the default 50% of its width.
3. **Given** a left-swipe cell, **When** `flingLeft(tester, finder, velocity: 1200)` is called, **Then** a fast left swipe at the given velocity is simulated and the action triggers.
4. **Given** a revealed left-swipe cell, **When** `tapAction(tester, finder, 0)` is called, **Then** the first action button in the reveal panel is tapped.
5. **Given** any cell, **When** `dragTo(tester, finder, Offset(-60, 0))` is called, **Then** the cell is dragged exactly 60 pixels to the left without settling, so mid-drag assertions can be made.
6. **Given** that `swipeLeft` is called multiple times with the same arguments, **Then** the resulting gesture behavior is identical each time (deterministic, no timing flakiness).

---

### User Story 2 - State Assertion Extensions (Priority: P1)

As a package consumer, I want assertion helpers on the test runner so that I can verify the cell's state (idle, dragging, revealed, etc.) and progress value with clear failure messages, without writing custom finder logic for every test.

**Why this priority**: Equal priority to US1 — simulating gestures without assertions makes tests incomplete. These two form the minimum viable testing toolkit. Neither delivers full value without the other.

**Independent Test**: Create a swipe cell test. After calling `swipeLeft(ratio: 0.9)`, call `expectRevealed(finder)` — verify it passes. Call `expectIdle(finder)` — verify it fails with a message showing the actual state. Call `expectProgress(finder, 0.0)` after snap-back — verify it passes.

**Acceptance Scenarios**:

1. **Given** a cell in the revealed state, **When** `expectRevealed(finder)` is called, **Then** the assertion passes.
2. **Given** a cell in the idle state, **When** `expectRevealed(finder)` is called, **Then** the assertion fails with a message showing "Expected: revealed, Actual: idle."
3. **Given** a cell with progress 0.73, **When** `expectProgress(finder, 0.73, tolerance: 0.02)` is called, **Then** the assertion passes.
4. **Given** a cell with progress 0.73, **When** `expectProgress(finder, 0.50)` is called, **Then** the assertion fails with a message showing both the expected and actual progress values.
5. **Given** a cell in the idle state with zero progress, **When** `expectIdle(finder)` is called, **Then** the assertion passes.
6. **Given** a cell in any non-idle state, **When** `expectSwipeState(finder, SwipeState.idle)` is called, **Then** the assertion fails with a message that names the expected and actual states.

---

### User Story 3 - Mock Swipe Controller (Priority: P2)

As a package consumer, I want a ready-made test double for `SwipeController` so that I can verify my component correctly calls `open`, `close`, `resetProgress`, or `undo` — and assert call counts — without setting up mockito or any other mocking framework.

**Why this priority**: Needed when testing components that inject a `SwipeController`. Provides significant value but only for consumers who use controlled mode. US1 and US2 are more broadly applicable.

**Independent Test**: Create a widget that takes a `SwipeController` and calls `controller.open()` on button press. Inject a `MockSwipeController`. Tap the button. Assert `mockController.openCallCount == 1`. Verify no external mock framework is needed.

**Acceptance Scenarios**:

1. **Given** a `MockSwipeController` injected into a widget, **When** the widget calls `controller.open()`, **Then** `mockController.openCallCount` is incremented to 1.
2. **Given** a `MockSwipeController`, **When** `close()`, `resetProgress()`, and `undo()` are each called once, **Then** their respective call counts each equal 1.
3. **Given** a `MockSwipeController` with a stubbed `state` value, **When** the widget reads `controller.state`, **Then** the stubbed value is returned.
4. **Given** a `MockSwipeController`, **When** `resetCalls()` is called, **Then** all call counts are reset to zero.
5. **Given** a widget test using only `flutter_test`, **When** `MockSwipeController` is used, **Then** no additional packages (mockito, mocktail, etc.) are required to be imported.

---

### User Story 4 - Test Setup Harness (Priority: P2)

As a package consumer, I want a widget that wraps a `SwipeActionCell` in all necessary test ancestors so that I can pump a cell widget in tests with a single wrapper widget, without manually composing `MaterialApp`, `Directionality`, and `MediaQuery` every time.

**Why this priority**: Reduces per-test boilerplate significantly, particularly for RTL and custom screen-size scenarios. Important for productivity but US1+US2 deliver the core value independently.

**Independent Test**: Pump a `SwipeTestHarness(child: SwipeActionCell.delete(...))` with no other ancestors. Verify it renders without exceptions. Then rebuild with `textDirection: TextDirection.rtl` and verify the swipe directions reverse correctly.

**Acceptance Scenarios**:

1. **Given** a `SwipeTestHarness` wrapping a `SwipeActionCell`, **When** pumped with no other ancestors, **Then** the cell renders without any "No MediaQuery ancestor found" or "No Material ancestor found" errors.
2. **Given** a `SwipeTestHarness` with `textDirection: TextDirection.rtl`, **When** `swipeLeft` is called, **Then** the cell responds as if a right-direction swipe was initiated (RTL layout semantics applied).
3. **Given** a `SwipeTestHarness` with `screenSize: Size(375, 812)`, **When** rendered, **Then** the widget tree behaves as if running on a 375×812 device.
4. **Given** a `SwipeTestHarness` with a `controller` parameter, **When** the wrapped cell is tested, **Then** the provided controller is wired to the cell.
5. **Given** a `SwipeTestHarness` with no configuration beyond `child`, **When** pumped, **Then** it defaults to LTR, English locale, and a standard phone screen size.

---

### Edge Cases

- **`swipeLeft` on a cell with no `leftSwipeConfig`**: The gesture is simulated (drag occurs), but no action fires; no exception thrown.
- **`tapAction` when cell is not revealed**: Assertion fails immediately with "Cell is not in revealed state; cannot tap action at index 0."
- **`tapAction` with an out-of-bounds `actionIndex`**: Fails with a clear message showing the index requested and the number of available actions.
- **`expectProgress` during active animation (non-settled)**: Asserts the progress at the instant of the call; consumer is responsible for calling this only at settled states unless testing mid-animation.
- **`dragTo` with zero offset**: No-op — gesture is simulated with zero movement, pump cycle runs; no exception.
- **`MockSwipeController.undo()` called when no pending undo**: Call is recorded (count incremented); no exception thrown.
- **`SwipeTestHarness` with `locale` set to a non-English locale**: Directionality and text direction follow the `textDirection` parameter; locale is passed through to the `MaterialApp`.
- **`flingLeft` velocity of 0 or negative**: Treated as a slow drag, not a fling; same behavior as `swipeLeft` with default ratio.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-014-001**: The system MUST provide a `swipeLeft(tester, finder, {ratio = 0.5})` helper that simulates a left drag on the found widget to the given fraction of its width, then settles all animations.
- **FR-014-002**: The system MUST provide a `swipeRight(tester, finder, {ratio = 0.5})` helper with the same behavior in the right direction.
- **FR-014-003**: The system MUST provide a `flingLeft(tester, finder, {velocity = 1000})` helper that simulates a fast left swipe at the given velocity and settles.
- **FR-014-004**: The system MUST provide a `flingRight(tester, finder, {velocity = 1000})` helper with the same behavior in the right direction.
- **FR-014-005**: The system MUST provide a `dragTo(tester, finder, offset)` helper that positions the cell at the given offset from its resting position without calling settle, to support mid-drag state inspection.
- **FR-014-006**: The system MUST provide a `tapAction(tester, cellFinder, actionIndex)` helper that taps the action button at the given index in the cell's revealed panel; the helper MUST fail with a descriptive message if the cell is not in the revealed state.
- **FR-014-007**: All gesture helpers MUST produce identical results when called with identical arguments on identical widget state (deterministic behavior).
- **FR-014-008**: The system MUST provide an `expectSwipeState(finder, SwipeState)` assertion that passes when the cell's current state matches the expected value, and fails with an "Expected: X, Actual: Y" message otherwise.
- **FR-014-009**: The system MUST provide an `expectProgress(finder, double, {tolerance = 0.01})` assertion that passes when the cell's current progress ratio is within the tolerance of the expected value.
- **FR-014-010**: The system MUST provide an `expectRevealed(finder)` assertion shorthand equivalent to `expectSwipeState(finder, SwipeState.revealed)`.
- **FR-014-011**: The system MUST provide an `expectIdle(finder)` assertion shorthand equivalent to `expectSwipeState(finder, SwipeState.idle)` with zero progress.
- **FR-014-012**: All assertion helpers MUST produce human-readable failure messages that show both the actual and expected values without requiring the consumer to inspect internal state manually.
- **FR-014-013**: The system MUST provide a `MockSwipeController` that records calls to `open()`, `close()`, `resetProgress()`, and `undo()`, exposing each as an integer call count.
- **FR-014-014**: `MockSwipeController` MUST allow consumers to pre-configure stub responses for state and progress queries before the test runs.
- **FR-014-015**: `MockSwipeController` MUST provide a `resetCalls()` method that sets all call counts back to zero.
- **FR-014-016**: `MockSwipeController` MUST require no packages beyond those available in a standard widget test environment.
- **FR-014-017**: The system MUST provide a `SwipeTestHarness` widget that wraps its child with the necessary test ancestors (theme, directionality, layout constraints) using sensible defaults.
- **FR-014-018**: `SwipeTestHarness` MUST accept a `textDirection` parameter controlling layout direction (LTR or RTL), defaulting to LTR.
- **FR-014-019**: `SwipeTestHarness` MUST accept a `screenSize` parameter that simulates a specific device screen size, defaulting to a standard phone size.
- **FR-014-020**: `SwipeTestHarness` MUST accept an optional `controller` parameter wired to the wrapped cell.
- **FR-014-021**: All testing utilities MUST be accessible exclusively via a dedicated testing import — they MUST NOT be included in the main package import.
- **FR-014-022**: The testing import MUST NOT introduce any package dependencies that would appear in a production app's dependency tree.

### Key Entities

- **SwipeTester**: A utility class exposing all gesture simulation methods as static or top-level functions. The single entry point for simulating swipe interactions in tests.
- **SwipeTestHarness**: A widget that provides a complete, pre-configured test scaffold for `SwipeActionCell`, eliminating the need to manually compose ancestors in each test.
- **MockSwipeController**: A test double for `SwipeController` that records method invocations and provides configurable stub return values without external mocking frameworks.
- **SwipeState** (existing): The state enum used in `expectSwipeState` assertions; already part of the core package, re-exported from the testing entry point for convenience.

---

## Assumptions & Dependencies

- **Dependencies**: All of F001–F013 are complete. The testing utilities build on the final public API of `SwipeActionCell` including `SwipeController`, `SwipeState`, and `SwipeProgress`.
- **Assumption**: The testing utilities are shipped as part of the same package via a separate entry point (`testing.dart`), not as a separate pub package.
- **Assumption**: `flutter_test` is already a dev dependency of any consumer project using Flutter; the utilities require only that (no additional packages).
- **Assumption**: `dragTo` does not call `pumpAndSettle` — its purpose is to inspect mid-drag state. The caller must manage pump cycles for such tests.
- **Assumption**: `flingLeft`/`flingRight` with velocity ≤ 0 behave equivalently to the corresponding `swipeLeft`/`swipeRight` with the default ratio.
- **Assumption**: `MockSwipeController` implements the full `SwipeController` interface; any call not explicitly stubbed returns a sensible zero/idle default.
- **Assumption**: Default `SwipeTestHarness` screen size is 390×844 (iPhone 14 logical pixels) — common base for mobile widget tests.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-014-001**: A consumer can write a complete widget test covering a left-swipe delete interaction (gesture + undo + callback verification) in 10 lines or fewer of test body code — verified by the feature's own usage examples.
- **SC-014-002**: All four utility components (`SwipeTester`, assertion extensions, `MockSwipeController`, `SwipeTestHarness`) are accessible from a single import line — verified by a test file that uses all four with one import.
- **SC-014-003**: The testing import adds zero packages to a production app's dependency tree — verified by confirming no new entries appear in `dependencies` in `pubspec.yaml` (only `dev_dependencies`).
- **SC-014-004**: Every gesture simulation method produces identical outcomes across 100 consecutive runs with the same parameters — verified by a parameterized stability test.
- **SC-014-005**: All assertion failures produce messages readable without inspecting source code — verified by intentionally triggering each assertion failure and reviewing its output text.
- **SC-014-006**: `MockSwipeController` correctly records all four tracked method calls — verified by a test that calls each method N times and asserts `callCount == N`.
- **SC-014-007**: `SwipeTestHarness` enables the same `SwipeActionCell` widget to be tested in both LTR and RTL layouts with only a single parameter change — verified by a test pair sharing identical cell setup but differing in `textDirection`.

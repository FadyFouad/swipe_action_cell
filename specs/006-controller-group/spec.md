# Feature Specification: Programmatic Control & Multi-Cell Coordination

**Feature Branch**: `006-controller-group`
**Created**: 2026-02-27
**Status**: Draft
**Input**: User description: "Add programmatic control and multi-cell coordination to the swipe_action_cell package."

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Programmatic Single-Cell Control (Priority: P1)

A developer needs to open, close, or reset a swipe cell from outside the widget — for
example, to close a revealed panel after a network deletion completes, or to open a cell
in response to a tutorial prompt. They create a `SwipeController`, pass it to
`SwipeActionCell`, and call methods on it like any other Flutter controller.

**Why this priority**: The most fundamental capability; every other story builds on it.
Without a working `SwipeController` with a full API, groups and providers have nothing
to coordinate.

**Independent Test**: Create a `SwipeController` and a `SwipeActionCell` with
`leftSwipeConfig` configured. Call `controller.openLeft()` without any gesture — verify
the cell animates open. Call `controller.close()` — verify it snaps back. Ship a working
counter reset via `resetProgress()`. This alone makes the feature useful.

**Acceptance Scenarios**:

1. **Given** a `SwipeActionCell` with `leftSwipeConfig` and an attached `SwipeController` in idle state, **When** `controller.openLeft()` is called, **Then** the cell animates to the open/revealed position and `controller.currentState` becomes `SwipeState.revealed`.
2. **Given** a cell in revealed state, **When** `controller.close()` is called, **Then** the cell animates back to idle and `controller.isOpen` returns `false`.
3. **Given** a `SwipeActionCell` with `rightSwipeConfig` and `initialValue: 0.0`, **When** `controller.setProgress(5.0)` is called, **Then** `controller.currentProgress` returns `5.0` and the progress indicator reflects the new value.
4. **Given** a cell with a progressive counter at `7.0`, **When** `controller.resetProgress()` is called, **Then** `controller.currentProgress` returns `initialValue` (e.g., `0.0`).
5. **Given** a cell already in revealed state, **When** `controller.openLeft()` is called again, **Then** no animation glitch occurs; the call is silently ignored in release mode and triggers a debug assertion.
6. **Given** a `SwipeController` with a listener attached, **When** the cell transitions state (idle → revealed), **Then** the listener fires and `controller.currentState` reflects the new state.

---

### User Story 2 — Observe State for Reactive UI (Priority: P2)

A developer wants to update other UI elements in response to a cell's swipe state — for
example, disabling a "delete all" button while any cell is open, or showing a "tap to
close" hint overlay. They listen to a `SwipeController` via `addListener` and read
`currentState`, `isOpen`, and `openDirection` to drive that logic.

**Why this priority**: Observation is independent of coordination — a single controller
on a single cell delivers this value, with no group machinery needed.

**Independent Test**: Attach a listener to a `SwipeController`. Perform a gesture that
opens the cell. Verify the listener fires and `isOpen == true`. Perform a close gesture.
Verify the listener fires and `isOpen == false`.

**Acceptance Scenarios**:

1. **Given** a listener added to a `SwipeController`, **When** any state transition occurs (including partial drags that snap back), **Then** the listener is called at least once and `currentState` matches the actual widget state.
2. **Given** a cell opened via right swipe, **When** the listener is queried, **Then** `controller.openDirection` returns `SwipeDirection.right` and `controller.isOpen` returns `true`.
3. **Given** a `SwipeController` with multiple listeners, **When** the state changes, **Then** all listeners are notified.

---

### User Story 3 — Accordion Behavior via `SwipeGroupController` (Priority: P3)

In a list of swipeable cells, a developer wants at most one cell open at a time. They
create a `SwipeGroupController`, register individual `SwipeController` instances to it,
and rely on the package to close any open cell when another one opens.

**Why this priority**: Requires a working `SwipeController` (US1) but delivers the
primary list-coordination use case. Most real-world apps need this pattern.

**Independent Test**: Create a `SwipeGroupController`, register two `SwipeController`
instances. Call `openLeft()` on controller A — verify B is closed. Then call `openLeft()`
on controller B — verify A closes automatically.

**Acceptance Scenarios**:

1. **Given** a `SwipeGroupController` with controllers A and B both registered, and A is open, **When** B opens (by gesture or programmatic call), **Then** controller A closes before B's opening animation begins.
2. **Given** a `SwipeGroupController`, **When** `closeAll()` is called, **Then** every registered open cell animates closed.
3. **Given** a `SwipeGroupController` with controllers A, B, C where A is open, **When** `closeAllExcept(A)` is called, **Then** B and C close and A remains open.
4. **Given** a controller is unregistered from the group while open, **When** another cell opens, **Then** the unregistered cell is not closed — no dangling listener, no crash.

---

### User Story 4 — Zero-Boilerplate Coordination via `SwipeControllerProvider` (Priority: P4)

A developer wraps a `ListView.builder` in `SwipeControllerProvider` and gets accordion
behavior for free — no manual controller creation, no group management. The provider
detects newly mounted cells, registers them automatically, and unregisters them on
dispose even during rapid scroll recycling.

**Why this priority**: Delivers the most ergonomic experience for the common case, but
depends on all three prior stories being solid.

**Independent Test**: Wrap a `ListView.builder` (50 items) in `SwipeControllerProvider`.
Open item 3 and item 10 in sequence — verify item 3 auto-closes when item 10 opens.
Scroll rapidly through the full list — verify no errors, no memory leaks.

**Acceptance Scenarios**:

1. **Given** a `ListView.builder` wrapped in `SwipeControllerProvider`, **When** any cell is opened by gesture, **Then** all other visible cells close automatically.
2. **Given** a `SwipeControllerProvider`-wrapped list and a cell that scrolls out of view and is recycled by the framework, **When** the cell re-enters view, **Then** it re-registers and accordion behavior is restored — no crash, no leak.
3. **Given** a `SwipeControllerProvider` in the tree, **When** a `SwipeActionCell` mounts without an explicit controller, **Then** the cell auto-creates an internal controller and registers it with the provider.
4. **Given** a `SwipeActionCell` with an explicit consumer-owned `SwipeController` inside a `SwipeControllerProvider`, **When** the cell mounts, **Then** the consumer controller is registered with the provider's group — the consumer retains full programmatic access.

---

### Edge Cases

- What happens when `openLeft()` is called on a cell with no `leftSwipeConfig`? → No-op; no crash; debug assertion fires.
- What happens when `setProgress()` receives a value outside `[minValue, maxValue]`? → Value is clamped to the valid range; no assertion; no crash.
- What happens when a `SwipeController` is disposed before the widget it is attached to? → Widget detects disposal on next rebuild and falls back to uncontrolled behavior; no dangling listener.
- What happens when a `SwipeController` is passed to a second `SwipeActionCell` while still attached to a first? → Debug assertion fires; the controller attaches to the new cell and detaches from the old one.
- What happens when `register()` is called with an already-registered controller? → No-op; no duplicate entries; no crash.
- What happens when `unregister()` is called with a controller not in the group? → No-op; no crash.
- What happens when a gesture is in progress (mid-drag) and `close()` is called? → In-progress gesture is cancelled and the cell animates closed; the drag pointer is released cleanly.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `SwipeController` MUST expose `openLeft()`, `openRight()`, and `close()` methods that trigger the corresponding cell animations identically to gesture-driven equivalents.
- **FR-002**: `SwipeController` MUST expose `resetProgress()` that sets the progressive counter back to `initialValue` as configured in `RightSwipeConfig`.
- **FR-003**: `SwipeController` MUST expose `setProgress(double value)` that directly sets the progressive counter, clamping the provided value to `[minValue, maxValue]`.
- **FR-004**: `SwipeController` MUST expose read-only observable properties: `currentState` (`SwipeState`), `currentProgress` (`double`), `isOpen` (`bool`), `openDirection` (`SwipeDirection?`).
- **FR-005**: `SwipeController` MUST implement `ChangeNotifier` and notify listeners on every state transition and on every `setProgress` call that changes the value.
- **FR-006**: `SwipeController` MUST enforce valid state machine transitions: invalid calls (e.g., `openLeft()` while already open) MUST be no-ops in release mode and trigger descriptive `assert` failures in debug mode, naming the current state and the requested operation.
- **FR-007**: `SwipeController` MUST be lifecycle-safe: it can be created before the widget, outlive the widget, and be re-attached to a new widget without memory leaks or crashes.
- **FR-008**: `openLeft()` MUST be a no-op when the cell has no `leftSwipeConfig`; `openRight()` MUST be a no-op when the cell has no `rightSwipeConfig`.
- **FR-009**: `SwipeGroupController` MUST support `register(SwipeController)` and `unregister(SwipeController)` to manage a dynamic set of controllers.
- **FR-010**: `SwipeGroupController` MUST implement accordion behavior: when any registered controller transitions to an open state (via gesture or programmatic call), all other registered controllers MUST be closed before the opening animation begins.
- **FR-011**: `SwipeGroupController` MUST expose `closeAll()` that closes every currently open registered controller.
- **FR-012**: `SwipeGroupController` MUST expose `closeAllExcept(SwipeController controller)` that closes all registered controllers except the specified one.
- **FR-013**: `SwipeControllerProvider` MUST be an `InheritedWidget` that creates and manages a shared `SwipeGroupController` for its subtree.
- **FR-014**: `SwipeActionCell` MUST auto-register its effective controller with the nearest `SwipeControllerProvider` ancestor on `initState` and unregister on `dispose`.
- **FR-015**: `SwipeControllerProvider` MUST handle rapid widget creation and disposal (as occurs in `ListView.builder` during scroll) without memory leaks, duplicate registrations, or dangling listeners.
- **FR-016**: An explicit consumer-owned `SwipeController` passed to `SwipeActionCell` MUST be registered with the ambient `SwipeControllerProvider` (if present) — the consumer retains programmatic access while the group handles coordination.

### Key Entities

- **SwipeController**: Single-cell programmatic interface. Holds observed state (`currentState`, `currentProgress`, `isOpen`, `openDirection`). Implements `ChangeNotifier`. Can be attached to at most one `SwipeActionCell` at a time.
- **SwipeGroupController**: Multi-cell coordinator. Holds a set of registered `SwipeController` instances. Enforces accordion invariant. Created by consumer or internally by `SwipeControllerProvider`.
- **SwipeControllerProvider**: Widget-tree integration layer. An `InheritedWidget` that owns a `SwipeGroupController` and exposes it for auto-registration by descendant `SwipeActionCell` widgets.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A developer can open, close, or reset any cell in a list with a single method call — no gesture simulation, no `setState`, no test driver required.
- **SC-002**: In a list of N cells (any N ≥ 2), opening any cell results in all others being visually closed within the same animation cycle — zero stale-open cells observable.
- **SC-003**: `SwipeControllerProvider` wrapping a `ListView.builder` of 1,000 items survives 100 rapid full-list scroll passes with zero memory leaks and zero errors reported by the Flutter framework.
- **SC-004**: Adopting `SwipeController` on an existing `SwipeActionCell` requires adding only the `controller` parameter — all existing gesture behavior, callbacks, and visual configuration continue to work identically.
- **SC-005**: Every invalid programmatic call (wrong state, unconfigured direction, out-of-range progress) produces a descriptive debug-mode assertion message naming the invalid input and the expected valid range or state.
- **SC-006**: The complete controller and provider API compiles with zero analyzer warnings and full dartdoc coverage on every public member.

---

## Assumptions

- `setProgress()` clamps silently (like `OverflowBehavior.clamp`) rather than asserting — out-of-range values are corrected without crashing.
- Accordion behavior fires synchronously: the closing animations of other cells begin before the opening animation of the triggered cell, so there is never a frame where two cells appear open simultaneously.
- Nested `SwipeControllerProvider` instances are independent groups — a cell registers with its nearest ancestor provider only.
- A `SwipeController` attached to a cell inside a `SwipeControllerProvider` is registered in that provider's group automatically; no additional consumer action is needed.
- `openLeft()` / `openRight()` run the same spring animation as a gesture-triggered open — they do not teleport the cell.
- The `SwipeController` stub introduced in F6 (`ChangeNotifier`, no API) is replaced by this full implementation; no migration is needed because the stub had no public methods or observable behavior.

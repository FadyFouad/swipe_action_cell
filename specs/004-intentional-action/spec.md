# Feature Specification: Left-Swipe Intentional Action

**Feature Branch**: `004-intentional-action`
**Created**: 2026-02-25
**Status**: Draft
**Input**: User description: "Add left-swipe intentional action behavior to the swipe_action_cell package."

## Clarifications

### Session 2026-02-25

- Q: After `postActionBehavior: stay`, what can the user do to leave that state? → A: User can swipe right to return the cell to idle (the background disappears); that is the only way out of the `stay` state within the widget.
- Q: When `postActionBehavior: animateOut` fires, does the widget also collapse its own height? → A: No — the widget slides out horizontally but does NOT collapse height. The developer removes the item from their list in response to `onActionTriggered`.
- Q: What is the default value for `postActionBehavior` when not specified? → A: `snapBack` — the safest non-destructive default; developers opt in to `animateOut` or `stay` explicitly.
- Q: Is `SwipeAction.label` required or optional? → A: Optional — `null` renders an icon-only button with no text.
- Q: What tap area triggers the "confirmation tap" when `requireConfirmation: true` and the cell is in confirmation state? → A: Tapping the exposed `leftBackground` area confirms; tapping the cell body cancels (consistent with US5 Scenario 3).

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Auto-Trigger: Single Action on Swipe (Priority: P1) 🎯 MVP

A developer configures a cell in auto-trigger mode. When the user swipes left past the
activation threshold and releases, a single action fires immediately. The cell returns to
its resting position. If the user releases below the threshold, the cell snaps back with
no action fired.

**Why this priority**: The simplest and most common "swipe to act" pattern (e.g., swipe to
mark as done). Delivers standalone value with just one callback and no panel UI.

**Independent Test**: Configure a cell with `mode: autoTrigger` and an `onActionTriggered`
callback. Verify the callback fires exactly once on above-threshold release and zero times
on below-threshold release.

**Acceptance Scenarios**:

1. **Given** a cell in auto-trigger mode, **When** the user swipes left past the activation
   threshold and releases, **Then** `onActionTriggered` fires once and the cell returns to
   its resting position.
2. **Given** a cell in auto-trigger mode, **When** the user swipes left below the threshold
   and releases, **Then** no callback fires and the cell snaps back.
3. **Given** a cell in auto-trigger mode, **When** the user flings left with sufficient
   velocity, **Then** `onActionTriggered` fires even if distance alone would not have
   triggered it.
4. **Given** an animation in progress, **When** the user starts a new left swipe, **Then**
   the ongoing animation is interrupted and the new drag begins from the current position.

---

### User Story 2 — Reveal Mode: Action Panel with Buttons (Priority: P2)

A developer configures a cell in reveal mode with 1–3 action buttons. The user swipes left
to reveal the action panel, then taps a button to execute that action. Tapping the cell body
or swiping right closes the panel without executing any action.

**Why this priority**: The most visually rich and widely recognisable swipe interaction
pattern (iOS Mail, iOS Messages). Enables multiple actions per cell.

**Independent Test**: Configure a cell with `mode: reveal` and two `SwipeAction` items.
Verify the panel appears on left swipe, the first button's `onTap` fires when tapped, and
the panel closes on cell-body tap.

**Acceptance Scenarios**:

1. **Given** a cell in reveal mode, **When** the user swipes left past the activation
   threshold and releases, **Then** the action panel springs open to its full width and
   `onPanelOpened` fires.
2. **Given** the action panel is open, **When** the user taps an action button, **Then** that
   button's `onTap` fires and the panel closes (with `onPanelClosed` firing).
3. **Given** the action panel is open, **When** the user taps the cell body, **Then** the
   panel closes with no action fired and `onPanelClosed` fires.
4. **Given** the action panel is open, **When** the user swipes right, **Then** the panel
   closes with no action fired and `onPanelClosed` fires.
5. **Given** the action panel is open, **When** the user swipes left again (further into the
   panel direction), **Then** the panel remains open and no new action fires.
6. **Given** a cell in reveal mode, **When** the user releases below the activation threshold,
   **Then** the panel does not open and the cell snaps back.

---

### User Story 3 — Post-Action Behavior (Auto-Trigger) (Priority: P3)

After an auto-trigger action fires, the cell's movement depends on the configured
`postActionBehavior`. Developers can choose between three outcomes: the cell returns to its
resting position (`snapBack`), the cell slides fully off screen (`animateOut`), or the cell
stays at the fully-swiped position (`stay`).

**Why this priority**: Different use cases need different post-action appearances. "Delete"
typically uses `animateOut`; "Mark as read" typically uses `snapBack`. Without this, only
snap-back is possible, which is insufficient for destructive actions.

**Independent Test**: Configure three cells with `postActionBehavior: snapBack`, `animateOut`,
and `stay` respectively. Verify each settles at the correct position after the action fires.

**Acceptance Scenarios**:

1. **Given** `postActionBehavior: snapBack`, **When** the action fires, **Then** the cell
   returns to its resting position.
2. **Given** `postActionBehavior: animateOut`, **When** the action fires, **Then** the cell
   slides fully off screen to the left. The widget does NOT collapse its own height; the
   developer is responsible for removing the item from their list in response to
   `onActionTriggered`.
3. **Given** `postActionBehavior: stay`, **When** the action fires, **Then** the cell remains
   at the fully-swiped position with the background fully visible; a subsequent right swipe
   by the user returns the cell to idle (the only exit from this state within the widget).

---

### User Story 4 — Destructive Action Confirm-Expand (Reveal Mode) (Priority: P4)

A developer marks one or more actions as destructive (`isDestructive: true`). On first tap,
a destructive action button expands to fill the entire panel width, making the intent clear.
A second tap on the now-full-width button executes the action. Tapping elsewhere after the
first tap collapses the button without executing.

**Why this priority**: Safety pattern for irreversible actions (delete, block, report).
Essential for production list UIs where accidental destructive actions cause user distress.

**Independent Test**: Configure a reveal cell with a single destructive action. Verify that
the first tap expands the button, and the second tap fires `onTap`. Verify that tapping the
cell body after the first tap cancels without firing `onTap`.

**Acceptance Scenarios**:

1. **Given** a reveal cell with a destructive action, **When** the user taps that action for
   the first time, **Then** the button expands to fill the full panel width and no `onTap`
   fires.
2. **Given** the destructive button is expanded, **When** the user taps it again, **Then**
   `onTap` fires and the panel closes.
3. **Given** the destructive button is expanded, **When** the user taps the cell body,
   **Then** the panel closes with no action fired.
4. **Given** a non-destructive action in the same panel, **When** tapped while a destructive
   button is expanded, **Then** the non-destructive action's `onTap` fires immediately.

---

### User Story 5 — Auto-Trigger Confirmation (Priority: P5)

When `requireConfirmation: true` in auto-trigger mode, the first swipe past threshold places
the cell into a confirmation state with the cell held at the fully-swiped position. A second
left swipe past threshold, or a tap on the exposed `leftBackground` area, confirms and fires
the action. Tapping the cell body or swiping right abandons the confirmation and snaps back
silently.

**Why this priority**: Protects against accidental triggers for consequential actions (send,
pay, submit). Lower priority because most use cases do not need it.

**Independent Test**: Configure an auto-trigger cell with `requireConfirmation: true`. Verify
that a single swipe does NOT fire `onActionTriggered`, and that a second confirming swipe
DOES fire it.

**Acceptance Scenarios**:

1. **Given** `requireConfirmation: true`, **When** the user swipes past threshold and
   releases, **Then** the cell holds at the fully-swiped position (confirmation state) and
   `onActionTriggered` does NOT fire.
2. **Given** the confirmation state is active, **When** the user swipes left again past
   threshold, **Then** `onActionTriggered` fires and `postActionBehavior` is applied.
3. **Given** the confirmation state is active, **When** the user taps the exposed
   `leftBackground` area, **Then** `onActionTriggered` fires and `postActionBehavior` is
   applied.
4. **Given** the confirmation state is active, **When** the user swipes right or taps the
   cell body, **Then** the cell snaps back and `onActionTriggered` does NOT fire.

---

### User Story 6 — Haptic Feedback (Priority: P6)

When `enableHaptic: true`, tactile feedback fires at key interaction milestones: when the
drag crosses the activation threshold and when an action actually executes.

**Why this priority**: Adds polish and physical coherence to swipe interactions. Low priority
because it has no functional impact and can be disabled.

**Independent Test**: Enable haptic with a mocked haptic channel. Verify a light haptic fires
at threshold crossing and a medium haptic fires on action execution.

**Acceptance Scenarios**:

1. **Given** `enableHaptic: true`, **When** the drag crosses the activation threshold,
   **Then** a light haptic fires once per drag gesture.
2. **Given** `enableHaptic: true`, **When** an auto-trigger action fires or a reveal-mode
   button is tapped, **Then** a medium haptic fires.
3. **Given** `enableHaptic: false`, **When** any swipe milestone occurs, **Then** no haptic
   fires.

---

### User Story 7 — Coexistence with Right-Swipe Progressive Action (Priority: P7)

A cell configured with both `rightSwipe: ProgressiveSwipeConfig` (F3) and `leftSwipe:
IntentionalSwipeConfig` behaves correctly in both directions with no cross-direction
interference.

**Why this priority**: Validates integration with F3. Without this, both features cannot be
used simultaneously, severely limiting real-world applicability.

**Independent Test**: Configure a cell with both `rightSwipe` and `leftSwipe`. Swipe right,
then swipe left. Verify each fires only its own callbacks with no state leakage.

**Acceptance Scenarios**:

1. **Given** both directions configured, **When** the user swipes right past threshold,
   **Then** only the progressive increment fires; no left-swipe callbacks fire.
2. **Given** both directions configured, **When** the user swipes left past threshold,
   **Then** only the intentional action fires; no right-swipe callbacks fire.
3. **Given** the reveal panel is open, **When** the user swipes right, **Then** the panel
   closes and right-swipe progressive behavior does NOT fire.

---

### Edge Cases

- What happens when `actions` is empty in reveal mode? The panel does not open; the cell
  behaves as if `leftSwipe` is `null`.
- What happens when more than 3 actions are provided? Only the first 3 are rendered; extras
  are silently ignored in production and flagged with an assertion in debug mode.
- What happens when all `flex` values are zero? Each action button receives equal width.
- What happens when `actionPanelWidth` is `null`? Width is auto-calculated from button
  content (icon + label + padding), capped at 60% of the cell width.
- What happens when `requireConfirmation` is set with `mode: reveal`? It has no effect;
  reveal mode uses per-action destructive confirm-expand for safety instead.
- What happens when `postActionBehavior: animateOut` is combined with `mode: reveal`? It
  has no effect; reveal mode always closes the panel after a button tap.
- What happens when the cell is disabled (`enabled: false`)? All swipe interactions are
  inert; touch events pass through to the child.
- What happens when `leftSwipe: null`? All left-swipe intentional behavior is disabled with
  zero overhead; existing F1/F2/F3 behavior is fully preserved.
- What happens to the list gap after `animateOut`? The widget does not collapse its height;
  the vertical gap remains until the developer removes the item from their data source (e.g.,
  in `onActionTriggered`). Developers using `AnimatedList` can animate the height collapse
  at the list level independently.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The widget MUST support two mutually exclusive left-swipe modes per instance:
  `autoTrigger` and `reveal`. The mode is set at construction time via `leftSwipe`.
- **FR-002**: In `autoTrigger` mode, a left swipe past the activation threshold followed by
  release MUST fire `onActionTriggered` exactly once.
- **FR-003**: In `autoTrigger` mode, a release below the activation threshold MUST snap the
  cell back to its resting position with no callback fired.
- **FR-004**: In `autoTrigger` mode, a fling with sufficient velocity MUST trigger the action
  regardless of distance traveled.
- **FR-005**: After an auto-trigger action fires, the cell MUST apply `postActionBehavior`:
  `snapBack` → resting position; `animateOut` → slides fully off screen to the left
  (height is NOT collapsed — the developer removes the item from their list in response to
  `onActionTriggered`); `stay` → holds at full-swipe position until the user performs a
  right swipe, which returns the cell to idle (the only exit from the `stay` state within
  the widget).
- **FR-006**: In `reveal` mode, a left swipe past the activation threshold and release MUST
  open the action panel to its target width and fire `onPanelOpened`.
- **FR-007**: In `reveal` mode, the action panel MUST accept 1–3 `SwipeAction` items; an
  empty list disables the feature; more than 3 renders only the first 3 (debug assertion).
- **FR-008**: In `reveal` mode, tapping an action button MUST fire that button's `onTap`
  and close the panel (firing `onPanelClosed`).
- **FR-009**: In `reveal` mode, tapping the cell body while the panel is open MUST close the
  panel (firing `onPanelClosed`) with no action fired.
- **FR-010**: In `reveal` mode, a right swipe while the panel is open MUST close the panel
  (firing `onPanelClosed`) without triggering right-swipe progressive behavior (F3).
- **FR-011**: Each `SwipeAction` MUST carry: icon, an optional label (`null` renders an
  icon-only button), background color, foreground color, tap handler, `isDestructive` flag,
  and `flex` weight for relative button sizing.
- **FR-012**: A destructive `SwipeAction` in reveal mode MUST require two taps to execute:
  the first expands the button to full panel width; the second fires `onTap`. Tapping
  elsewhere after expansion collapses without executing.
- **FR-013**: When `requireConfirmation: true` in `autoTrigger` mode, the first above-
  threshold release MUST hold the cell at the fully-swiped position (confirmation state)
  without firing `onActionTriggered`; a second left swipe past threshold OR a tap on the
  exposed `leftBackground` area MUST then fire it.
- **FR-014**: When confirmation state is active, a right swipe or cell-body tap MUST cancel
  the confirmation and snap back without firing the action.
- **FR-015**: When `enableHaptic: true`, a light haptic MUST fire once when the drag first
  crosses the activation threshold, and a medium haptic MUST fire when an action executes.
- **FR-016**: A cell with both `leftSwipe` and `rightSwipe` configured MUST honor each
  direction's behavior independently with no cross-direction state leakage.
- **FR-017**: `leftSwipe: null` MUST disable all left-swipe intentional behavior with zero
  overhead, preserving all existing F1/F2/F3 behavior unchanged.
- **FR-018**: All panel-open, panel-close, snap-back, and animate-out animations MUST use
  spring-based physics consistent with F1/F2.
- **FR-019**: When a swipe gesture begins during an ongoing animation, the animation MUST be
  interrupted and the drag MUST start from the current translated position.

### Key Entities

- **`IntentionalSwipeConfig`**: Configuration object for a cell's left-swipe behavior.
  Carries: mode, action list, post-action behavior (default: `snapBack`), confirmation flag,
  panel width, haptic flag, and all callbacks (`onActionTriggered`, `onPanelOpened`,
  `onPanelClosed`).
- **`SwipeAction`**: A single action button for reveal mode. Carries: icon, optional label
  (`null` = icon-only button), background color, foreground color, tap handler, destructive
  flag, and flex weight.
- **`LeftSwipeMode`**: Enumeration — `autoTrigger` or `reveal`.
- **`PostActionBehavior`**: Enumeration — `snapBack`, `animateOut`, or `stay`.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A swipe past threshold in auto-trigger mode fires the action within one
  animation frame of release — no perceptible lag.
- **SC-002**: The reveal panel opens and settles to its target width within 400 ms on
  mid-range devices.
- **SC-003**: Tapping an action button in reveal mode fires the callback and begins closing
  the panel within one animation frame of the tap.
- **SC-004**: All swipe interactions maintain 60 fps throughout drag, spring animation, and
  panel transitions on mid-range devices.
- **SC-005**: Right-swipe progressive action (F3) and left-swipe intentional action both
  work correctly on the same cell instance with no cross-interference, verified by automated
  widget tests.
- **SC-006**: A cell with `leftSwipe: null` has identical behavior and zero performance
  regression compared to a cell without the parameter — all existing tests continue to pass.
- **SC-007**: The destructive confirm-expand interaction requires no additional parameters
  beyond `isDestructive: true` on a `SwipeAction`.
- **SC-008**: A minimal `IntentionalSwipeConfig` with only required parameters compiles and
  runs correctly with sensible defaults for all optional parameters. In `autoTrigger` mode
  the default `postActionBehavior` is `snapBack`; in `reveal` mode the default action panel
  width is auto-calculated.

---

## Assumptions

- **Group coordination** (closing the panel when another cell opens) requires a future
  `SwipeController` (F7) and is **out of scope** for this feature. Single-cell behavior is
  fully specified here.
- **`postActionBehavior`** applies only to `autoTrigger` mode. Reveal mode always closes the
  panel after a button tap and does not animate the cell out of the list.
- **`requireConfirmation`** applies only to `autoTrigger` mode. Reveal mode uses per-action
  destructive confirm-expand (US4) for that safety role.
- **Confirmation state visual** for `requireConfirmation` reuses the developer-supplied
  `leftBackground` builder — no new built-in confirmation UI widget is introduced by this
  feature. The `leftBackground` area is tappable in confirmation state: a tap on it confirms
  and fires the action; a tap on the cell body cancels.
- **Auto-calculated `actionPanelWidth`** (when `null`) determines width from button content;
  the exact layout algorithm is an implementation concern.
- The feature targets the same SDK constraints as F1–F3: Dart ≥ 3.4.0, Flutter ≥ 3.22.0.
- No new external runtime dependencies are introduced.

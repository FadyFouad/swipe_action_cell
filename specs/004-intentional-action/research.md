# Research: Left-Swipe Intentional Action

**Feature**: 004-intentional-action
**Date**: 2026-02-26

---

## R1 — Integration Point: Animation Completion Hook

**Decision**: Hook into `_handleAnimationStatusChange` on `AnimationStatus.completed` when
`_state == SwipeState.animatingToOpen`, `_lockedDirection == SwipeDirection.left`, and
`widget.leftSwipe != null`. Extend the existing `if/else if` chain in that method.

**Rationale**: F003 established this pattern for right-swipe. It is already the canonical
extension point for "animation settled → do something based on direction + config." No new
architecture is needed.

**Alternatives considered**: A separate `AnimationStatusListener` callback per feature.
Rejected — adds listener lifecycle complexity with no benefit.

---

## R2 — State Machine: New `animatingOut` State

**Decision**: Add `SwipeState.animatingOut` to the existing `SwipeState` enum. This state
represents the cell sliding fully off-screen after a `postActionBehavior: animateOut` trigger.

**Rationale**: Constitution II forbids undefined intermediate states; any new state must be
formally added. The `animatingToClose` state cannot be reused because its completion handler
transitions to `idle` and resets `_lockedDirection`, which is incorrect for a terminal
slide-out. `animatingOut` has a distinct completion: no state transition occurs (the developer
removes the item from their list). The `stay` behavior reuses `revealed` (the cell is open
and the user can swipe right to close), so no new state is needed for it.

**Alternatives considered**: A `bool _isAnimatingOut` flag inside `animatingToClose`.
Rejected — muddies the state machine and makes the completion handler more complex.

---

## R3 — `animateOut` Animation: Reuse Existing Controller

**Decision**: Reuse the single `_controller` (the existing `AnimationController`) to drive
the slide-out animation. Target offset: `-(widgetWidth + extraPadding)`, e.g.
`-(widgetWidth * 1.5)`. Store `_widgetWidth` as a field updated each `build()` frame.

**Rationale**: The existing controller already drives the pixel offset of the translated
child. No second controller is needed. The `animatingOut` state is entered immediately after
the action fires, so the controller drives a spring from the current offset to a large
negative target. When `AnimationStatus.completed` fires in `animatingOut`, no additional
state transition occurs (cell is gone; developer removes item). Using a second controller
would require careful lifecycle management (add to `dispose()`, coordinate vsync) for a
one-time fire-and-forget use case.

**Alternatives considered**: A dedicated `AnimationController _animateOutController` created
on demand. Rejected — extra complexity; reusing `_controller` is simpler and sufficient.

---

## R4 — Reveal Panel Layout: Separate Stack Layer

**Decision**: The reveal panel is a separate widget layer in the Stack, rendered between
the existing `leftBackground` and the translated child. It is built by `_buildRevealPanel()`
and is `Positioned` to the right edge (`right: 0, top: 0, bottom: 0, width: panelWidth`).
It coexists with `leftBackground` — the background appears behind the panel.

**Rationale**: Keeping the panel separate from `leftBackground` means:
1. Developers can supply a `leftBackground` for the trailing area (e.g., a color wash) and
   the action buttons overlay it naturally.
2. No changes to the existing `SwipeBackgroundBuilder` typedef are required.
3. Button tap detection is self-contained in the panel widget.

**Panel construction**: A `Row` of `Expanded`-wrapped `GestureDetector` buttons, where each
button's `flex` parameter controls relative width. A destructive button uses an
`AnimatedContainer` to expand to `panelWidth` on first tap.

**`actionPanelWidth` auto-calculation**: When `null`, computed as
`(actions.length * 80.0).clamp(panelWidth_min, widgetWidth * 0.65)`. The result is stored
in a computed getter and used both for the `Positioned` width and for the spring
`completionSpring` target offset.

**Alternatives considered**: Using `leftBackground` builder exclusively for the action panel.
Rejected — requires developers to embed tap detection in a builder callback, coupling UI
layout with gesture logic.

---

## R5 — Panel Tap Routing in `revealed` State

**Decision**: When `_state == SwipeState.revealed` and `widget.leftSwipe?.mode == reveal`:

- Action button taps are handled by `GestureDetector` widgets inside `_buildRevealPanel()`.
  These widgets call the button's `onTap` and then call `_closePanelAndIdle()`.
- Cell body taps are handled by wrapping the translated `child` with a `GestureDetector`
  (only when `_state == SwipeState.revealed`) that calls `_closePanelAndIdle()` on tap.

**Rationale**: The top-level horizontal `GestureDetector` handles drag gestures. Tap
detection within the revealed panel and on the cell body must be independent of horizontal
drag. Wrapping the child in a tap detector (conditionally on state) is the minimal and
most targeted approach.

**Alternatives considered**: Using `_state` to reroute all taps in the top-level detector.
Rejected — the top-level detector uses `onHorizontalDragStart/Update/End`, not `onTap`, so
tap events already fall through to child widgets. The per-button approach is cleaner.

---

## R6 — Destructive Confirm-Expand: Per-State Index

**Decision**: Tracked via `int? _destructiveExpandedIndex` field in
`_SwipeActionCellState`. Initial value: `null` (none expanded). On first destructive button
tap: set to the button's index, call `setState`, rebuild the panel with an `AnimatedContainer`
expanding that button to `panelWidth`. On second tap: fire `onTap`, close panel, reset to
`null`. On body tap or panel close: reset to `null`.

**Rationale**: A single nullable integer is the minimal state needed. No separate controller
or `ValueNotifier` is required since panel renders always happen inside `setState`-triggered
rebuilds.

**Alternatives considered**: `bool` per `SwipeAction`. Rejected — only one can be expanded at
a time; an index is semantically clearer and enforces mutual exclusivity automatically.

---

## R7 — `requireConfirmation` State: Bool Flag

**Decision**: Tracked via `bool _awaitingConfirmation`. On first auto-trigger swipe
completion when `requireConfirmation: true`: set `_awaitingConfirmation = true`,
transition to `SwipeState.revealed` (hold at open position). On second trigger (left swipe
or `leftBackground` area tap): fire action, reset flag. On cancel (right swipe or body tap
from `revealed`): reset flag, snap back to idle.

**Rationale**: A single bool is sufficient. The `revealed` state already represents
"cell held open" — we reuse it for the confirmation holding position. The `leftBackground`
area receives a tap detector only in `revealed` state with `_awaitingConfirmation == true`.

---

## R8 — Haptic Feedback: Mirror F003 Pattern

**Decision**: In `_handleDragUpdate`, add a parallel check for
`widget.leftSwipe?.enableHaptic == true && _lockedDirection == SwipeDirection.left &&
progress.isActivated && !_hapticThresholdFired` → `HapticFeedback.lightImpact()`. Medium
haptic fires in `_applyIntentionalAction()` on action execution.

**Rationale**: Exact same pattern as F003's threshold haptic. Single `_hapticThresholdFired`
flag resets in `_handleDragStart`, shared between both directions (only one direction can be
active per gesture).

---

## R9 — `onSwipeCancelled` (Auto-Trigger) vs. `onPanelClosed` (Reveal)

**Decision**:
- **Auto-trigger below threshold**: `animatingToClose → idle` completion fires
  `leftSwipe!.onSwipeCancelled?.call()` when `_lockedDirection == left && mode == autoTrigger`
  and the snap-back was not a post-action snap-back (`_isPostActionSnapBack == false`).
- **Reveal panel close**: Any close path (body tap, right swipe, button tap) fires
  `leftSwipe!.onPanelClosed?.call()`.
- **Reveal panel open**: `animatingToOpen → revealed` fires `leftSwipe!.onPanelOpened?.call()`.

**Rationale**: Mirrors the F003 `onSwipeCancelled` pattern with a parallel flag
`_isPostActionSnapBack` (analogous to F003's `_isPostIncrementSnapBack`) to distinguish a
user-initiated cancel from a post-action snap-back.

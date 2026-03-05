# Feature Specification: Swipe Action Undo/Revert Support

**Feature Branch**: `011-swipe-undo`  
**Created**: 2026-03-01  
**Status**: Draft  
**Input**: User description: "Add undo/revert support to the swipe_action_cell package, allowing users to reverse swipe actions within a configurable time window. Context: Features 001-010 are complete. Actions are currently permanent on trigger. This feature adds a time-limited undo mechanism. Undo lifecycle: 1. Action completes (progressive increment or intentional trigger) 2. Undo window opens (configurable duration, default 5 seconds) 3. During window: revertable via SwipeController.undo() or built-in UI 4. After expiry: action committed permanently, onUndoExpired fires 5. New action during active undo: previous commits immediately, new window starts Undo for progressive actions (right swipe): - Revert restores previous value (newValue -> oldValue) - Value indicator animates backward Undo for intentional actions (left swipe): - animateOut post-action: widget animates back into view on undo - snapBack/stay: consumer provides revert logic via onUndo callback - Package handles animation + timing; consumer handles data reversal Built-in undo UI (optional): - SwipeUndoOverlay: bar on the cell showing action description + \"Undo\" button + countdown - Auto-dismisses on expiry - Configurable: position (top/bottom), colors, text, button style - Fully disableable — consumer can use callbacks only for custom UI Callbacks: - onUndoAvailable(UndoData) — UndoData: { oldValue, newValue, remainingDuration, revert() } - onUndoTriggered() - onUndoExpired() Programmatic access via SwipeController: - undo(): trigger revert - isUndoPending: bool - commitPendingUndo(): force-commit without waiting Constraints: - One pending undo per cell maximum - Works correctly with group controller (006) — closing others doesn't cancel undo - Timer cleaned up on dispose — no orphaned timers - Undo animation visually distinct from normal close (different spring, slight bounce) - enableUndo: bool (default false) — opt-in, zero overhead when disabled Parameters: - enableUndo, undoDuration, showBuiltInUndoUI, undoUIConfig"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Reverting a Progressive Action (Priority: P1)

As a user, when I accidentally swipe right to increment a value, I want to be able to undo that action within a few seconds so that the value and UI return to their previous state.

**Why this priority**: High value for data integrity and user confidence. Mistakes are common in high-frequency swiping environments.

**Independent Test**: Can be tested by triggering a progressive swipe, verifying the undo UI appears, clicking "Undo", and confirming the value and indicator revert to the original state.

**Acceptance Scenarios**:

1. **Given** a cell with `enableUndo` true and a progressive action, **When** the user swipes past the threshold, **Then** the value increments AND the undo window opens.
2. **Given** an active undo window for a progressive action, **When** the user triggers undo, **Then** the value reverts to the previous state AND the indicator animates backward.

---

### User Story 2 - Reverting an Intentional Action (Priority: P1)

As a user, when I swipe left to delete an item, I want a brief window to undo the deletion so that I don't lose data from an accidental gesture.

**Why this priority**: Deletion is a destructive action. Providing an undo mechanism is a critical UX standard for mobile lists.

**Independent Test**: Can be tested by triggering an intentional swipe (e.g., Delete), verifying the cell animates out/hides, clicking "Undo" in the overlay, and confirming the cell animates back into view and the item is restored.

**Acceptance Scenarios**:

1. **Given** an intentional action with `animateOut: true`, **When** the action triggers, **Then** the cell animates out AND the undo overlay appears.
2. **Given** an active undo window for a deleted item, **When** undo is triggered, **Then** the cell animates back into view AND the `onUndo` callback is executed to restore data.

---

### User Story 3 - Automatic Commitment on Expiry (Priority: P2)

As a user, I want my actions to become permanent automatically if I don't interact with the undo UI, so that I don't have to manually confirm every action.

**Why this priority**: Core lifecycle behavior. Ensures that "Undo" doesn't block finality or create "limbo" states indefinitely.

**Independent Test**: Trigger an action, wait for the `undoDuration` to elapse, and verify `onUndoExpired` fires and the undo UI disappears.

**Acceptance Scenarios**:

1. **Given** an active undo window, **When** the duration expires without interaction, **Then** the `onUndoExpired` callback fires AND the undo UI is dismissed.

---

### User Story 4 - Interrupted Undo Window (Priority: P3)

As a user, when I perform a second action on a cell while a previous action is still in the undo window, I want the first action to commit immediately so that the new action can take precedence.

**Why this priority**: Handles edge cases of rapid interaction and ensures only one undo state exists per cell.

**Independent Test**: Trigger Action A, wait 1 second, trigger Action B. Verify Action A is committed (expired) immediately and the undo window for Action B starts.

**Acceptance Scenarios**:

1. **Given** an active undo window for Action A, **When** the user starts a new swipe gesture that triggers Action B, **Then** Action A is committed immediately AND the undo window for Action B begins.

---

### Edge Cases

- **Dispose during Undo**: If the widget is disposed (e.g., list scrolled away or screen popped) while an undo is pending, the timer MUST be canceled and the action SHOULD be committed immediately to prevent data loss.
- **Group Controller Interplay**: Closing a cell via `SwipeControllerGroup` (e.g., when another cell opens) should NOT cancel an active undo window.
- **Rapid Toggle**: Rapidly swiping and undoing should not result in multiple timers or corrupted UI states.
- **undo() with No Pending Undo**: Calling `SwipeController.undo()` when `isUndoPending` is false MUST silently no-op and return `false`. No error is thrown. Callers are not required to guard with `isUndoPending` before calling.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-011-001**: System MUST provide a boolean `enableUndo` (default false) to opt-in to the undo mechanism.
- **FR-011-002**: System MUST maintain an internal "pending undo" state for a configurable `undoDuration` (default 5 seconds).
- **FR-011-003**: System MUST provide a built-in `SwipeUndoOverlay` widget that displays an action description, an "Undo" button, and a visual countdown rendered as an animated shrinking progress bar spanning the overlay width. The overlay MUST automatically integrate with the F8 accessibility layer: the "Undo" button MUST carry a semantic label (reachable via keyboard/switch access), and the progress bar animation MUST be suppressed when `reduceMotion` is active (expiry timer still runs; only the visual animation is omitted).
- **FR-011-004**: System MUST allow programmatic undo and commitment via `SwipeController.undo()` and `SwipeController.commitPendingUndo()`.
- **FR-011-005**: System MUST provide callbacks `onUndoAvailable`, `onUndoTriggered`, and `onUndoExpired` to allow custom UI and data handling.
- **FR-011-006**: For progressive actions, system MUST support backward animation of value indicators when undo is triggered.
- **FR-011-007**: For intentional actions with `animateOut`, system MUST support "animate back in" logic when undo is triggered. For `snapBack` and `stay` modes, the package MUST fire the `onUndo` callback only — no package-owned animation is produced, as the cell is already visible; the consumer owns all visual feedback for these modes.
- **FR-011-008**: System MUST ensure that at most one undo is pending per cell; a new action MUST commit the previous one.
- **FR-011-009**: System MUST use a visually distinct animation curve/spring for undo actions to differentiate them from normal cell closing.

### Key Entities

- **UndoData**: Represents the state of a pending undo.
    - `oldValue`: The value before the action. `null` for intentional (left-swipe) actions; only meaningful for progressive actions.
    - `newValue`: The value after the action. `null` for intentional (left-swipe) actions; only meaningful for progressive actions.
    - `remainingDuration`: Time left until automatic commitment.
    - `revert()`: A function to programmatically trigger the undo.
- **SwipeUndoOverlayConfig**: Configuration object for the built-in UI.
    - `position`: Top or Bottom of the cell.
    - `colors`: Background, text, button, and progress bar colors.
    - `textStyle`: Font styling for the description and button.
    - `progressBarHeight`: Height of the shrinking countdown progress bar.

## Clarifications

### Session 2026-03-01

- Q: What should `SwipeController.undo()` do when `isUndoPending` is false? → A: Silent no-op — returns `false` without error; callers are not required to guard with `isUndoPending` first.
- Q: For intentional `snapBack`/`stay` actions, what does the package animate during undo? → A: No package animation — fire `onUndo` callback only; consumer owns all visual feedback.
- Q: What do `UndoData.oldValue`/`newValue` represent for intentional (left-swipe) actions? → A: Both are `null`; these fields are only semantically meaningful for progressive actions.
- Q: Should `SwipeUndoOverlay` automatically integrate with the F8 accessibility layer? → A: Yes — "Undo" button carries a semantic label (keyboard/switch accessible), countdown animation suppressed under `reduceMotion` (timer still runs).
- Q: What form does the visual countdown in `SwipeUndoOverlay` take? → A: Animated shrinking progress bar spanning the overlay width; suppressed (not shown) when `reduceMotion` is active.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-011-001**: 100% of undo triggers result in state restoration and appropriate reverse animation within the specified window.
- **SC-011-002**: Memory profile shows zero orphaned timers or leaked state objects after 100 consecutive trigger/undo cycles.
- **SC-011-003**: The built-in undo UI responds to configuration changes (colors, duration, position) with 100% accuracy.
- **SC-011-004**: System commits pending actions within 100ms of a new gesture initiation on the same cell.

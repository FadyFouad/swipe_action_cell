# Data Model: Swipe Action Undo/Revert Support (F011)

**Branch**: `011-swipe-undo` | **Date**: 2026-03-01

---

## New Public Types

### `SwipeUndoConfig`

**File**: `lib/src/undo/swipe_undo_config.dart`
**Role**: Opt-in configuration for the undo mechanism. Passing `null` disables undo entirely (Constitution IX).

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `duration` | `Duration` | `Duration(seconds: 5)` | Length of the undo window. |
| `showBuiltInOverlay` | `bool` | `true` | Whether to render `SwipeUndoOverlay` automatically. |
| `overlayConfig` | `SwipeUndoOverlayConfig?` | `null` (use defaults) | Visual configuration for the built-in overlay. |
| `onUndoAvailable` | `void Function(UndoData)?` | `null` | Fired when an undo window opens. |
| `onUndoTriggered` | `VoidCallback?` | `null` | Fired when the user (or code) triggers undo. |
| `onUndoExpired` | `VoidCallback?` | `null` | Fired when the undo window expires without revert. |

**Constraints**:
- `const`-constructible, `@immutable`, has `copyWith`.
- `duration` must be positive (debug assert).

---

### `SwipeUndoOverlayConfig`

**File**: `lib/src/undo/swipe_undo_config.dart`
**Role**: Visual/layout configuration for the built-in `SwipeUndoOverlay` bar.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `position` | `SwipeUndoOverlayPosition` | `bottom` | Whether the bar appears at the top or bottom of the cell. |
| `backgroundColor` | `Color?` | `null` (theme surface variant) | Background color of the bar. |
| `textColor` | `Color?` | `null` (theme on-surface) | Color of the action description text. |
| `buttonColor` | `Color?` | `null` (theme primary) | Color of the "Undo" button label. |
| `progressBarColor` | `Color?` | `null` (theme primary with opacity) | Color of the shrinking countdown bar. |
| `progressBarHeight` | `double` | `3.0` | Height of the shrinking countdown progress bar in logical pixels. |
| `textStyle` | `TextStyle?` | `null` (inherit) | Style applied to the action description text. |
| `undoButtonLabel` | `String` | `'Undo'` | Label for the undo trigger button. |
| `actionLabel` | `String?` | `null` | Optional description shown next to the Undo button (e.g., "Deleted"). |

**Constraints**:
- `const`-constructible, `@immutable`, has `copyWith`.
- `progressBarHeight` must be ≥ 0 (debug assert).

---

### `SwipeUndoOverlayPosition`

**File**: `lib/src/undo/swipe_undo_config.dart`
**Role**: Enum controlling where the undo bar is anchored within the cell.

| Value | Description |
|-------|-------------|
| `top` | Bar appears at the top edge of the cell. |
| `bottom` | Bar appears at the bottom edge of the cell. |

---

### `UndoData`

**File**: `lib/src/undo/undo_data.dart`
**Role**: Snapshot of an undo window's state, passed to `onUndoAvailable`.

| Field | Type | Description |
|-------|------|-------------|
| `oldValue` | `double?` | Progressive value before the action. `null` for intentional (left-swipe) actions. |
| `newValue` | `double?` | Progressive value after the action. `null` for intentional (left-swipe) actions. |
| `remainingDuration` | `Duration` | Approximate time left before the window expires (snapshot at creation time). |
| `revert` | `VoidCallback` | Convenience shortcut — equivalent to calling `SwipeController.undo()` on the associated cell. No-op if the window has already closed. |

**Constraints**:
- `@immutable`.
- `oldValue` and `newValue` are both non-null or both null (invariant maintained internally).

---

## Modified Public Types

### `SwipeController` — New API Surface

**File**: `lib/src/controller/swipe_controller.dart`

New observable property:

| Member | Type | Description |
|--------|------|-------------|
| `isUndoPending` | `bool` | Whether an undo window is currently open for the attached cell. `false` when no cell attached. |

New commands:

| Method | Return | Description |
|--------|--------|-------------|
| `undo()` | `bool` | Triggers undo on the attached cell. Returns `true` if an undo was pending and triggered; `false` (silent no-op) if `isUndoPending` is false. |
| `commitPendingUndo()` | `void` | Force-commits the pending undo immediately (as if expired). No-op if `isUndoPending` is false. |

New package-internal bridge method:

| Method | Return | Description |
|--------|--------|-------------|
| `reportUndoPending(bool isPending)` | `void` | Called by `SwipeActionCellState` to push undo-pending state changes into the controller and notify listeners. |

---

### `SwipeCellHandle` — New Bridge Methods

**File**: `lib/src/controller/swipe_cell_handle.dart`

| Method | Description |
|--------|-------------|
| `executeUndo()` | Called by `SwipeController.undo()` — triggers `_triggerUndo()` on the state. |
| `executeCommitUndo()` | Called by `SwipeController.commitPendingUndo()` — triggers `_commitUndo()` on the state. |

---

### `SwipeActionCell` — New Parameter

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `undoConfig` | `SwipeUndoConfig?` | `null` | Undo configuration. `null` = feature disabled with zero overhead. |

---

## New Internal Types (not exported)

### `SwipeUndoOverlay` (widget)

**File**: `lib/src/undo/swipe_undo_overlay.dart`
**Role**: Internal `StatelessWidget` rendering the bar overlay.

| Field | Type | Description |
|-------|------|-------------|
| `config` | `SwipeUndoOverlayConfig` | Resolved display config. |
| `progressAnimation` | `Animation<double>` | Animation value 1.0 → 0.0 driving the progress bar width. |
| `onUndo` | `VoidCallback` | Called when user taps the Undo button. |
| `semanticUndoLabel` | `String` | Semantic label for the Undo button (accessibility). |

---

## State Added to `SwipeActionCellState`

These fields are internal implementation details, not public API:

| Field | Type | Description |
|-------|------|-------------|
| `_undoPending` | `bool` | Whether an undo window is currently active. |
| `_undoOldValue` | `double?` | Progressive value before the last action (null for intentional). |
| `_undoNewValue` | `double?` | Progressive value after the last action (null for intentional). |
| `_undoTimer` | `Timer?` | Cancellable expiry timer. Cancelled on trigger, new gesture, and dispose. |
| `_undoBarController` | `AnimationController?` | Drives the countdown progress bar; null when `undoConfig` is null. |

---

## State Transitions

```
Normal swipe lifecycle (unchanged):
  idle → dragging → animatingToOpen → revealed → animatingToClose → idle

Undo lifecycle (parallel to SwipeState):
  _undoPending = false (default)

  After action completes:
    _undoPending = true
    _undoTimer starts (duration = undoConfig.duration)
    _undoBarController.forward() starts (1.0 → 0.0)
    onUndoAvailable(UndoData) called

  Path A — User/code triggers undo:
    _undoPending = false
    _undoTimer.cancel()
    _undoBarController.stop()
    [Revert animation plays if animateOut; onUndo fired if snapBack/stay]
    onUndoTriggered() called

  Path B — Timer expires:
    _undoPending = false
    _undoBarController.stop() (already at ~0.0)
    onUndoExpired() called
    [Action committed — no revert]

  Path C — New action before expiry:
    _commitUndo() called first (path B without firing onUndoExpired? No — fires normally)
    Actually: _commitUndo() fires onUndoExpired, then new undo window opens

  On dispose:
    _undoTimer.cancel()
    _undoBarController.dispose()
    [_undoPending = false; no callbacks fired after dispose]
```

---

## Spring Configuration (Internal)

A new internal preset added to `SpringConfig`:

| Preset | Mass | Stiffness | Damping | Damping Ratio | Use |
|--------|------|-----------|---------|---------------|-----|
| `SpringConfig.undoReveal` | 1.0 | 300.0 | 18.0 | ~0.52 | Animate cell back into view after `animateOut` undo |

Damping ratio = damping / (2 × √(mass × stiffness)) = 18 / (2 × √300) ≈ 0.52 → underdamped (bouncy). Visually distinct from both `snapBack` (0.57, lightly underdamped) and `completion` (0.65, near-critical).

---

## Barrel Export Changes

New exports added to `lib/swipe_action_cell.dart`:

```dart
export 'src/undo/swipe_undo_config.dart';  // SwipeUndoConfig, SwipeUndoOverlayConfig, SwipeUndoOverlayPosition
export 'src/undo/undo_data.dart';           // UndoData
// swipe_undo_overlay.dart is NOT exported (internal widget)
```

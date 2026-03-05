# Data Model: Left-Swipe Intentional Action

**Feature**: 004-intentional-action
**Date**: 2026-02-26

---

## Entities

### LeftSwipeMode *(new — enum)*

Determines which left-swipe interaction model a cell uses.

| Value | Behavior |
|-------|----------|
| `autoTrigger` | A swipe past threshold fires a one-shot action callback immediately on animation completion |
| `reveal` | A swipe past threshold springs open an action panel with 1–3 tappable buttons |

**Invariants**:
- The two modes are mutually exclusive per widget instance; the mode is fixed at construction time.
- `autoTrigger` uses `postActionBehavior`, `requireConfirmation`, `onActionTriggered`, and `onSwipeCancelled`.
- `reveal` uses `actions`, `actionPanelWidth`, `onPanelOpened`, and `onPanelClosed`.

---

### PostActionBehavior *(new — enum)*

Controls what the cell does after an `autoTrigger` action fires.

| Value | Cell movement after action | Exit |
|-------|---------------------------|------|
| `snapBack` | Springs back to resting position (offset 0) | Automatic (default) |
| `animateOut` | Slides fully off screen to the left; height NOT collapsed | Developer removes item from list |
| `stay` | Remains at fully-open position; background fully visible | User swipes right (back to idle) |

**Default**: `snapBack`.

**Invariants**:
- `animateOut` is a terminal state within the widget; the cell does not return to idle. Height is not
  changed — the developer is responsible for removing the item from their data source.
- `stay` reuses the `SwipeState.revealed` state; the cell can be closed by a right swipe (same path
  as closing a reveal panel).
- `postActionBehavior` has no effect in `reveal` mode.

---

### SwipeAction *(new — immutable data class)*

A single action button definition for reveal mode.

| Field | Type | Required | Default | Constraints |
|-------|------|----------|---------|-------------|
| `icon` | `Widget` | Yes | — | Any widget (typically an `Icon`) |
| `label` | `String?` | No | `null` | `null` = icon-only button; no text rendered |
| `backgroundColor` | `Color` | Yes | — | Any valid `Color` |
| `foregroundColor` | `Color` | Yes | — | Applied to icon and label |
| `onTap` | `VoidCallback` | Yes | — | Called when the button is tapped (after expand, for destructive) |
| `isDestructive` | `bool` | No | `false` | `true` → two-tap confirm-expand before firing |
| `flex` | `int` | No | `1` | Relative width weight; all-zero treated as equal weight |

**Invariants**:
- `flex` must be ≥ 0. A value of 0 contributes zero width (effectively hidden). In practice,
  each action should have `flex >= 1`.
- `isDestructive` is independent of `onTap` — `onTap` still fires on the confirming second tap.
- `SwipeAction` is purely a data class (no state); it has `const` constructor, all-`final` fields,
  `==`, `hashCode`, and `copyWith`.

---

### IntentionalSwipeConfig *(new — immutable config object)*

Configuration for the left-swipe intentional action on a `SwipeActionCell`. Passed as
`leftSwipe: IntentionalSwipeConfig(...)`. When `null`, all left-swipe intentional behavior
is disabled (Constitution IX).

| Field | Type | Required | Default | Scope | Constraints |
|-------|------|----------|---------|-------|-------------|
| `mode` | `LeftSwipeMode` | Yes | — | both | `autoTrigger` or `reveal` |
| `actions` | `List<SwipeAction>` | reveal only | `const []` | reveal | 1–3 items; empty = feature disabled; >3 = first 3 used |
| `actionPanelWidth` | `double?` | No | `null` | reveal | `null` = auto-calculated; must be > 0 if provided |
| `postActionBehavior` | `PostActionBehavior` | No | `snapBack` | auto-trigger | Ignored in reveal mode |
| `requireConfirmation` | `bool` | No | `false` | auto-trigger | Ignored in reveal mode |
| `enableHaptic` | `bool` | No | `false` | both | Light haptic on threshold cross; medium on action execute |
| `onActionTriggered` | `VoidCallback?` | No | `null` | auto-trigger | Fires once per successful auto-trigger |
| `onSwipeCancelled` | `VoidCallback?` | No | `null` | auto-trigger | Fires on below-threshold release; not on post-action snap-back |
| `onPanelOpened` | `VoidCallback?` | No | `null` | reveal | Fires when panel springs to open position |
| `onPanelClosed` | `VoidCallback?` | No | `null` | reveal | Fires on any panel close (button tap, body tap, right swipe) |

**Invariants**:
- `actions` with 0 items in reveal mode disables the feature (cell behaves as `leftSwipe: null`).
- `actions` with > 3 items: first 3 rendered; debug assertion fired.
- `requireConfirmation` and `postActionBehavior` have no effect in `reveal` mode.
- `onSwipeCancelled` does NOT fire during the post-action snap-back after `autoTrigger` (parallel
  to F003's `_isPostIncrementSnapBack` guard).
- `const` constructor, all-`final` fields, `copyWith`, `==`, `hashCode` required.

---

### SwipeActionCell *(existing widget — additive update)*

One new parameter added. All existing parameters and defaults are unchanged.

| New Parameter | Type | Default | Meaning |
|---------------|------|---------|---------|
| `leftSwipe` | `IntentionalSwipeConfig?` | `null` | When non-null, enables left-swipe intentional behavior. `null` = disabled (Constitution IX). |

**New internal state fields** (in `_SwipeActionCellState`):

| Field | Type | Meaning |
|-------|------|---------|
| `_widgetWidth` | `double` | Stored from `LayoutBuilder`; used for `animateOut` target offset calculation |
| `_isPostActionSnapBack` | `bool` | True when `animatingToClose` is a post-action snap-back (not a user cancel); prevents false `onSwipeCancelled` fire |
| `_awaitingConfirmation` | `bool` | True when in confirmation holding state (`requireConfirmation: true` and first swipe complete) |
| `_leftHapticThresholdFired` | `bool` | True after left-swipe threshold haptic fires; reset in `_handleDragStart` |
| `_leftSwipeStartedFired` | `bool` | (Not in spec callbacks — no `onSwipeStarted` for intentional; omit) |
| `_destructiveExpandedIndex` | `int?` | Index of the currently-expanded destructive action button; `null` = none |

---

### SwipeState *(existing enum — additive update)*

One new state added.

| New Value | Meaning |
|-----------|---------|
| `animatingOut` | The cell is sliding off-screen to the left after `postActionBehavior: animateOut`. Terminal within the widget (no automatic transition to `idle`). |

---

## Updated State Machine

The state machine gains three new transition paths for left-swipe intentional action:

```
[existing unchanged paths]
idle ──drag start──▶ dragging
dragging ──release(below threshold, any direction)──▶ animatingToClose ──settled──▶ idle
animatingToClose ──drag start──▶ dragging  (interrupt)
animatingToOpen  ──drag start──▶ dragging  (interrupt)

[F003: right swipe progressive — unchanged]
dragging ──release(right, ≥threshold, rightSwipe configured)──▶ animatingToOpen
animatingToOpen ──settled(right+progressive)──▶ [increment] ──▶ animatingToClose ──settled──▶ idle

[NEW: left swipe auto-trigger, postActionBehavior: snapBack (default)]
dragging ──release(left, ≥threshold or fling, mode=autoTrigger)──▶ animatingToOpen
animatingToOpen ──settled(left+autoTrigger, requireConfirmation=false)──▶ [fire onActionTriggered]
  ──▶ animatingToClose ──settled──▶ idle

[NEW: left swipe auto-trigger, postActionBehavior: animateOut]
animatingToOpen ──settled(left+autoTrigger)──▶ [fire onActionTriggered]
  ──▶ animatingOut ──settled──▶ (terminal — developer removes from list)

[NEW: left swipe auto-trigger, postActionBehavior: stay]
animatingToOpen ──settled(left+autoTrigger)──▶ [fire onActionTriggered] ──▶ revealed
revealed ──right swipe──▶ dragging ──animatingToClose──▶ idle  (close from stay)

[NEW: left swipe auto-trigger with requireConfirmation]
animatingToOpen ──settled(left+autoTrigger, _awaitingConfirmation=false)──▶ revealed (hold)
  _awaitingConfirmation = true
revealed(confirm) ──left swipe past threshold──▶ animatingToOpen
  ──settled──▶ [fire onActionTriggered, _awaitingConfirmation=false] ──▶ (postActionBehavior)
revealed(confirm) ──leftBackground area tap──▶ [fire onActionTriggered, _awaitingConfirmation=false]
  ──▶ (postActionBehavior)
revealed(confirm) ──right swipe or body tap──▶ animatingToClose ──settled──▶ idle

[NEW: left swipe reveal mode]
dragging ──release(left, ≥threshold or fling, mode=reveal)──▶ animatingToOpen
animatingToOpen ──settled(left+reveal)──▶ revealed  [onPanelOpened fires]
revealed ──action button tap (non-destructive)──▶ [fire button.onTap, onPanelClosed] ──▶ animatingToClose ──settled──▶ idle
revealed ──destructive button, first tap──▶ [expand button; no onTap] (stays revealed)
revealed ──destructive button, second tap──▶ [fire button.onTap, onPanelClosed] ──▶ animatingToClose ──settled──▶ idle
revealed ──body tap──▶ [onPanelClosed] ──▶ animatingToClose ──settled──▶ idle
revealed ──right swipe──▶ dragging ──animatingToClose──▶ idle  [onPanelClosed fires on settle]

[existing — left swipe without leftSwipe config — unchanged]
dragging ──release(left, ≥threshold, no leftSwipe)──▶ animatingToOpen ──settled──▶ revealed
```

**Key invariants**:
- `SwipeState.revealed` is entered for: reveal-mode open, `stay` post-action, and
  `requireConfirmation` holding state. The `_awaitingConfirmation` and
  `_destructiveExpandedIndex` flags disambiguate behavior within `revealed`.
- `SwipeState.animatingOut` is entered only for `postActionBehavior: animateOut`. No
  automatic transition follows it; the developer is responsible for removing the item.
- `onSwipeCancelled` fires only when `animatingToClose` settles AND `!_isPostActionSnapBack`
  AND `mode == autoTrigger`.
- `onPanelClosed` fires whenever the reveal panel closes, regardless of trigger.

---

## Validation Rules

| Rule | Check location | Action |
|------|---------------|--------|
| `actions.length > 3` in reveal mode | `IntentionalSwipeConfig` constructor or `_buildRevealPanel` | Debug assert; truncate to first 3 in release |
| `actions.isEmpty` in reveal mode | `_handleAnimationStatusChange` / `_buildRevealPanel` | Skip to idle; treat as `leftSwipe: null` |
| `actionPanelWidth <= 0` when provided | `IntentionalSwipeConfig` constructor assert | Error in debug |
| `flex < 0` on a `SwipeAction` | `SwipeAction` constructor assert | Error in debug |
| `requireConfirmation` in reveal mode | Documentation / no runtime check | Silently ignored |
| `postActionBehavior` in reveal mode | Documentation / no runtime check | Silently ignored |

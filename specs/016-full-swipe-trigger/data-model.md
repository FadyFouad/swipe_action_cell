# Data Model: Full-Swipe Auto-Trigger (F016)

**Branch**: `016-full-swipe-trigger` | **Date**: 2026-03-02

---

## New Types

### `FullSwipeConfig`

**File**: `lib/src/actions/full_swipe/full_swipe_config.dart`

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `enabled` | `bool` | `false` | Master toggle. When false, zero overhead. |
| `threshold` | `double` | `0.75` | Fraction of widget width. Must be in (0.0, 1.0]. |
| `action` | `SwipeAction` | required | The action to fire. Must have non-null, non-empty `label`. |
| `postActionBehavior` | `PostActionBehavior` | `animateOut` | Cell behavior after action fires. |
| `expandAnimation` | `bool` | `true` | Whether expand-to-fill visual plays. |
| `enableHaptic` | `bool` | `true` | Whether full-swipe haptic events fire. |
| `fullSwipeProgressBehavior` | `FullSwipeProgressBehavior?` | `null` | Only applicable when on `RightSwipeConfig` + progressive mode. |

**Constructor assertions (debug-mode only)**:
1. `threshold > 0.0 && threshold <= 1.0` — threshold must be in range.
2. `action.label != null && action.label!.isNotEmpty` — label required for screen reader.
3. *(Runtime, checked in `_resolveEffectiveConfigs`)*: `threshold > activationThreshold` of same direction.
4. *(Runtime, checked in `_resolveEffectiveConfigs`)*: `threshold > max(zones[].threshold)` for same direction.
5. *(Runtime, checked in `_resolveEffectiveConfigs`)*: For reveal mode, `action` must be identity-equal to one of `LeftSwipeConfig.actions`.

**Immutability**: `@immutable`, `const` constructor, `copyWith`, `==`, `hashCode`.

---

### `FullSwipeProgressBehavior`

**File**: `lib/src/actions/full_swipe/full_swipe_config.dart`

```
enum FullSwipeProgressBehavior {
  setToMax,      // Jumps RightSwipeConfig progressive value to maxValue
  customAction,  // Fires FullSwipeConfig.action instead
}
```

Only read when `FullSwipeConfig` is on a `RightSwipeConfig` that is in progressive mode. Null (omitted) when `FullSwipeConfig` is on a `LeftSwipeConfig` or a non-progressive `RightSwipeConfig`.

---

## Modified Types

### `SwipeProgress` (modified)

**File**: `lib/src/core/swipe_progress.dart`

**Added field**:

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `fullSwipeRatio` | `double` | `0.0` | 0.0 = below full-swipe threshold; 1.0 = at/past threshold. Interpolated for smooth transitions. |

- Added to `copyWith`, `==`, `hashCode`, `toString`, `zero` constant.
- When `FullSwipeConfig` is null for the active direction, this is always `0.0` (no overhead).

---

### `LeftSwipeConfig` (modified)

**File**: `lib/src/config/left_swipe_config.dart`

**Added field**:

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `fullSwipeConfig` | `FullSwipeConfig?` | `null` | When null, full-swipe is disabled for left direction. |

Added to `copyWith`, `==`, `hashCode`, constructor.

---

### `RightSwipeConfig` (modified)

**File**: `lib/src/config/right_swipe_config.dart`

**Added field**:

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `fullSwipeConfig` | `FullSwipeConfig?` | `null` | When null, full-swipe is disabled for right direction. |

Added to `copyWith`, `==`, `hashCode`, constructor.

---

### `SwipeFeedbackEvent` (modified)

**File**: `lib/src/feedback/swipe_feedback_config.dart`

**Added values**:

| Value | When Fired | Default Pattern |
|-------|-----------|-----------------|
| `fullSwipeThresholdCrossed` | Each time drag crosses the full-swipe threshold (both entering and exiting) | `HapticPattern.heavy` |
| `fullSwipeActivation` | On release above the full-swipe threshold, before action executes | `HapticPattern.success` |

---

### `SwipeSemanticConfig` (modified)

**File**: `lib/src/accessibility/swipe_semantic_config.dart`

**Added fields**:

| Field | Type | Default | Notes |
|-------|------|---------|-------|
| `fullSwipeLeftLabel` | `SemanticLabel?` | `null` | Falls back to `"Swipe fully to [action.label]"` |
| `fullSwipeRightLabel` | `SemanticLabel?` | `null` | Falls back to `"Swipe fully to [action.label]"` |

Added to `copyWith`.

---

### `SwipeCellHandle` (modified)

**File**: `lib/src/controller/swipe_cell_handle.dart`

**Added method**:
```dart
void executeTriggerFullSwipe(SwipeDirection direction);
```

---

### `SwipeController` (modified)

**File**: `lib/src/controller/swipe_controller.dart`

**Added method**:
```dart
void triggerFullSwipe(SwipeDirection direction)
```
- Asserts handle is attached and direction has full-swipe configured.
- Delegates to `_handle!.executeTriggerFullSwipe(direction)`.

---

### `SwipeActionCell` widget (modified)

**File**: `lib/src/widget/swipe_action_cell.dart`

**New constructor parameter**:
```dart
final void Function(SwipeDirection direction, SwipeAction action)? onFullSwipeTriggered;
```

**New state fields** (all private, on `SwipeActionCellState`):
| Field | Type | Purpose |
|-------|------|---------|
| `_isFullSwipeArmed` | `bool` | True when drag ratio ≥ fullSwipeThreshold |
| `_fullSwipeTriggered` | `bool` | True during post-action animation (gesture lock) |
| `_fullSwipeBumpController` | `AnimationController?` | 150ms 1.0→1.15→1.0 bump animation |
| `_fullSwipeRatio` | `double` | Current interpolated ratio for visual layer |

**New internal methods**:
| Method | Purpose |
|--------|---------|
| `_resolvedFullSwipeConfig(SwipeDirection)` | Returns `FullSwipeConfig?` for the given direction |
| `_checkFullSwipeThreshold(double ratio, double widgetWidth)` | Called from `_handleDragUpdate`; updates `_isFullSwipeArmed`, fires haptic, starts bump |
| `_applyFullSwipeAction(SwipeDirection direction)` | Fires action, callback, haptic, post-action behavior |
| `_animateOutDirectional(SwipeDirection direction)` | Like `_animateOut()` but slides in the given direction |
| `_validateFullSwipeConfigs()` | Called from `_resolveEffectiveConfigs`; all assert checks |

**Modified `SwipeCellHandle.executeTriggerFullSwipe` implementation** on `SwipeActionCellState`.

---

## New Widgets

### `FullSwipeExpandOverlay`

**File**: `lib/src/actions/full_swipe/full_swipe_expand_overlay.dart`

| Parameter | Type | Notes |
|-----------|------|-------|
| `actions` | `List<SwipeAction>` | All reveal panel actions |
| `designatedAction` | `SwipeAction` | The full-swipe target action |
| `fullSwipeRatio` | `double` | 0.0 → 1.0 from `SwipeProgress.fullSwipeRatio` |
| `panelWidth` | `double` | Same as reveal panel width |
| `bumpAnimation` | `Animation<double>?` | Scale bump (1.0→1.15→1.0). Null = no bump |
| `direction` | `SwipeDirection` | Needed for alignment |

**Visual behavior**:
- When `fullSwipeRatio == 0.0`: renders identically to `SwipeActionPanel` (all actions visible, equal sizes).
- As `fullSwipeRatio → 1.0`:
  - Non-designated action buttons: `opacity = 1.0 - fullSwipeRatio`, also scale down slightly.
  - Designated action: expands to fill full panel width, icon scales up, icon translates to center of full cell.
  - Background color: lerps from the action's button color to fill the full cell area.
- The bump `bumpAnimation` adds a scale multiplier on top of the `fullSwipeRatio`-driven scale.

**Internal animation state**: The widget is a `StatelessWidget`; all animation values are driven by the parent.

---

## Internal FullSwipeState lifecycle

*(Internal to `SwipeActionCellState` — not part of public `SwipeState` enum)*

```
idle
 └─► armed (drag crosses threshold upward; haptic fires; bump plays)
      ├─► idle (drag crosses threshold downward; haptic fires; bump reverses)
      └─► triggered (gesture released above threshold; action fires; gesture locked)
           └─► idle (post-action animation completes; lock released)
```

---

## Files Modified Summary

| File | Change |
|------|--------|
| `lib/src/actions/full_swipe/full_swipe_config.dart` | **NEW** — `FullSwipeConfig`, `FullSwipeProgressBehavior` |
| `lib/src/actions/full_swipe/full_swipe_expand_overlay.dart` | **NEW** — `FullSwipeExpandOverlay` widget |
| `lib/src/core/swipe_progress.dart` | ADD `fullSwipeRatio` field |
| `lib/src/config/left_swipe_config.dart` | ADD `fullSwipeConfig` field |
| `lib/src/config/right_swipe_config.dart` | ADD `fullSwipeConfig` field |
| `lib/src/feedback/swipe_feedback_config.dart` | ADD 2 enum values to `SwipeFeedbackEvent` |
| `lib/src/accessibility/swipe_semantic_config.dart` | ADD 2 label fields |
| `lib/src/controller/swipe_cell_handle.dart` | ADD `executeTriggerFullSwipe` |
| `lib/src/controller/swipe_controller.dart` | ADD `triggerFullSwipe` |
| `lib/src/widget/swipe_action_cell.dart` | Main integration (gesture, visual, callbacks, keyboard) |
| `lib/src/templates/swipe_cell_templates.dart` | Update delete/archive with full-swipe defaults |
| `lib/src/testing/swipe_tester.dart` | ADD `fullSwipeLeft`, `fullSwipeRight` |
| `lib/swipe_action_cell.dart` | ADD export for `full_swipe_config.dart` |

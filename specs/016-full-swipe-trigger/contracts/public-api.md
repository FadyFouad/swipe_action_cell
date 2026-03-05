# Public API Contract: Full-Swipe Auto-Trigger (F016)

**Branch**: `016-full-swipe-trigger` | **Date**: 2026-03-02

This document defines the consumer-facing Dart API surface introduced or modified by F016.

---

## New Public Types

### `FullSwipeConfig`

```dart
/// Configuration for the full-swipe auto-trigger behavior on one swipe direction.
///
/// Pass as [LeftSwipeConfig.fullSwipeConfig] or [RightSwipeConfig.fullSwipeConfig]
/// to enable the full-swipe shortcut for that direction.
///
/// When null, the feature is completely disabled — zero overhead.
///
/// Example (left full-swipe to delete):
/// ```dart
/// leftSwipeConfig: LeftSwipeConfig(
///   mode: LeftSwipeMode.reveal,
///   actions: [deleteAction],
///   fullSwipeConfig: FullSwipeConfig(
///     enabled: true,
///     action: deleteAction, // must be identical to one of the reveal actions
///   ),
/// )
/// ```
@immutable
class FullSwipeConfig {
  const FullSwipeConfig({
    this.enabled = false,
    this.threshold = 0.75,
    required this.action,
    this.postActionBehavior = PostActionBehavior.animateOut,
    this.expandAnimation = true,
    this.enableHaptic = true,
    this.fullSwipeProgressBehavior,
  });

  /// Whether the full-swipe feature is active.
  final bool enabled;

  /// Fraction of widget width at which the full-swipe commits (0.0–1.0).
  ///
  /// Must be strictly greater than the direction's activation threshold
  /// and all zone thresholds. Default: 0.75.
  final double threshold;

  /// The action to fire when the full-swipe commits.
  ///
  /// In reveal mode, this MUST be one of the actions in the reveal panel.
  /// The action's [SwipeAction.label] must be non-null and non-empty (required
  /// for screen reader announcements).
  final SwipeAction action;

  /// What the cell does after the full-swipe action fires.
  ///
  /// [PostActionBehavior.animateOut] (default): slides the cell off-screen
  /// in the swipe direction, then collapses height to zero.
  final PostActionBehavior postActionBehavior;

  /// Whether the expand-to-fill visual animation plays past the threshold.
  ///
  /// When true (default), the designated action's background fills the cell
  /// and its icon scales to center. When false, no expand visual plays.
  final bool expandAnimation;

  /// Whether full-swipe haptic events ([fullSwipeThresholdCrossed],
  /// [fullSwipeActivation]) fire for this direction.
  final bool enableHaptic;

  /// Only for right-swipe in progressive mode: how full-swipe interacts
  /// with progressive value tracking.
  ///
  /// [FullSwipeProgressBehavior.setToMax]: jumps progress to maxValue.
  /// [FullSwipeProgressBehavior.customAction]: fires [action] instead.
  /// Null: same reveal-mode behavior as left-swipe.
  final FullSwipeProgressBehavior? fullSwipeProgressBehavior;

  FullSwipeConfig copyWith({...});

  @override bool operator ==(Object other);
  @override int get hashCode;
}
```

---

### `FullSwipeProgressBehavior`

```dart
/// Controls how a right-direction full-swipe interacts with progressive value
/// tracking when [RightSwipeConfig] is in progressive mode.
enum FullSwipeProgressBehavior {
  /// Jumps the progressive value directly to [RightSwipeConfig.maxValue].
  setToMax,

  /// Fires [FullSwipeConfig.action] instead of modifying progress.
  customAction,
}
```

---

## Modified Public Types

### `LeftSwipeConfig` — new field

```dart
/// Full-swipe auto-trigger configuration for the left direction.
///
/// When non-null and [FullSwipeConfig.enabled] is true, swiping left past
/// [FullSwipeConfig.threshold] triggers [FullSwipeConfig.action] on release.
///
/// In [LeftSwipeMode.reveal], [FullSwipeConfig.action] must be one of the
/// actions in [actions] (asserted in debug mode).
final FullSwipeConfig? fullSwipeConfig; // default: null
```

### `RightSwipeConfig` — new field

```dart
/// Full-swipe auto-trigger configuration for the right direction.
///
/// Works symmetrically with left-swipe full-swipe in reveal/intentional mode.
/// In progressive mode, also supports [FullSwipeProgressBehavior].
final FullSwipeConfig? fullSwipeConfig; // default: null
```

### `SwipeProgress` — new field

```dart
/// Interpolated full-swipe progress ratio for this frame.
///
/// `0.0` when below the full-swipe threshold (or no full-swipe configured).
/// `1.0` when at or past the full-swipe threshold.
/// Values between 0.0–1.0 during the approach or retreat from the threshold.
///
/// Use this in background builders to drive expand-to-fill visual transitions.
final double fullSwipeRatio; // default: 0.0
```

### `SwipeFeedbackEvent` — new values

```dart
/// Fired each time the drag crosses the full-swipe threshold (entering or exiting).
///
/// Default haptic pattern: [HapticPattern.heavy].
/// Gated by [FullSwipeConfig.enableHaptic].
fullSwipeThresholdCrossed,

/// Fired on release above the full-swipe threshold, before the action executes.
///
/// Default haptic pattern: [HapticPattern.success].
/// Gated by [FullSwipeConfig.enableHaptic].
fullSwipeActivation,
```

### `SwipeSemanticConfig` — new fields

```dart
/// Semantic label announced when the screen reader focuses a cell with left
/// full-swipe enabled.
///
/// Defaults to "Swipe fully to [action.label]" when null.
final SemanticLabel? fullSwipeLeftLabel;

/// Semantic label announced when the screen reader focuses a cell with right
/// full-swipe enabled.
///
/// Defaults to "Swipe fully to [action.label]" when null.
final SemanticLabel? fullSwipeRightLabel;
```

### `SwipeController` — new method

```dart
/// Programmatically triggers the full-swipe action for [direction].
///
/// Behaves identically to a gesture release above the full-swipe threshold:
/// fires the action, [SwipeActionCell.onFullSwipeTriggered], haptic, and
/// post-action animation.
///
/// No-op (debug assertion in debug mode) when:
/// - No cell is attached, OR
/// - [FullSwipeConfig.enabled] is false for [direction], OR
/// - [currentState] is not [SwipeState.idle].
void triggerFullSwipe(SwipeDirection direction);
```

### `SwipeActionCell` — new parameter

```dart
/// Called when a full-swipe auto-trigger action fires (gesture or programmatic).
///
/// [direction]: which direction the full-swipe occurred.
/// [action]: the [SwipeAction] that was triggered.
///
/// Note: [SwipeAction.onTap] also fires for the same action.
final void Function(SwipeDirection direction, SwipeAction action)? onFullSwipeTriggered;
```

---

## Barrel Export Changes

**`lib/swipe_action_cell.dart`** — add:
```dart
export 'src/actions/full_swipe/full_swipe_config.dart';
```

---

## Behavioral Contracts

### Threshold Ordering (Debug Assertions)

| Condition | Assert Message |
|-----------|---------------|
| `fullSwipeConfig.threshold <= activationThreshold` | "FullSwipeConfig.threshold (X) must be strictly greater than the activation threshold (Y) for [left\|right] swipe." |
| `fullSwipeConfig.threshold <= max(zones[].threshold)` | "FullSwipeConfig.threshold (X) must be strictly greater than all zone thresholds. Zone at index N has threshold Y." |
| Reveal mode + action not in panel | "FullSwipeConfig.action is not in LeftSwipeConfig.actions. In reveal mode, the full-swipe action must be one of the reveal panel actions for accessibility." |
| `action.label == null \|\| action.label!.isEmpty` | "FullSwipeConfig.action.label must be non-null and non-empty when enabled is true. Screen readers require a label to announce the full-swipe action." |

### Gesture Lock Contract

From the moment a full-swipe action fires until the post-action animation completes:
- `_handleDragStart` returns early without updating state.
- This prevents double-trigger regardless of sync/async action callback.

### SwipeGroupController Integration

Full-swipe trigger calls `_effectiveController.reportState(SwipeState.animatingOut, ...)`. The `SwipeGroupController` listens to this and closes other open cells, identical to normal swipe behavior.

### RTL Contract

`FullSwipeConfig` on `LeftSwipeConfig` always maps to the semantic "backward" (intentional) direction. When RTL, the physical direction is right (positive offset). `_isFullSwipeArmed` and `_fullSwipeRatio` are computed against `_controller.value.abs() / widgetWidth` regardless of sign — direction is determined by `_lockedDirection`, not the sign of the offset.

### Keyboard Contract

| Keystroke | Action |
|-----------|--------|
| `Shift + ArrowLeft` (LTR) | Triggers left full-swipe action if configured |
| `Shift + ArrowRight` (RTL) | Triggers left (semantic backward) full-swipe action if configured |
| `Shift + ArrowRight` (LTR) | Triggers right full-swipe action if configured |
| `Shift + ArrowLeft` (RTL) | Triggers right (semantic forward) full-swipe action if configured |

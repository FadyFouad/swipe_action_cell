# Data Model: Right-Swipe Progressive Action

**Feature**: 003-progressive-swipe
**Date**: 2026-02-25

---

## Entities

### OverflowBehavior *(new — enum)*

Determines what happens when a progressive swipe step would push the cumulative value
beyond `maxValue`.

| Value | Behavior when step would exceed `maxValue` | `onMaxReached` fires? |
|-------|-------------------------------------------|-----------------------|
| `clamp` | Value is clamped to `maxValue`; no further change | Yes |
| `wrap` | Value resets to `minValue` | Yes |
| `ignore` | Value increments without restriction | No |

**Invariants**:
- `clamp` and `wrap` always keep the value within `[minValue, maxValue]`.
- `ignore` may produce values outside `[minValue, maxValue]`.
- All three policies apply in both controlled and uncontrolled mode — the widget always
  applies the policy before firing any callbacks.

---

### ProgressIndicatorConfig *(new — immutable config object)*

Controls the visual appearance of the persistent progress bar rendered on the cell edge.
Only used when `ProgressiveSwipeConfig.showProgressIndicator` is `true`.

| Field | Type | Default | Constraints | Meaning |
|-------|------|---------|-------------|---------|
| `color` | `Color` | `Color(0xFF4CAF50)` (green) | Any valid `Color` | Fill color of the progress bar |
| `width` | `double` | `4.0` | > 0.0 | Bar width in logical pixels |
| `backgroundColor` | `Color?` | `null` | Any valid `Color` or null | Optional track/background color; `null` = transparent |
| `borderRadius` | `BorderRadius?` | `null` | Any valid `BorderRadius` or null | Optional rounding of bar corners |

**Invariants**:
- `width` must be > 0.0.
- The bar fills from the bottom of the cell edge upward, proportionally to `currentValue / maxValue`.
- `backgroundColor` is rendered at full height behind the fill bar when non-null.

**`copyWith`**: MUST be provided.
**`const` constructor**: MUST be provided.

---

### ProgressiveSwipeConfig *(new — immutable config object)*

The direction-specific configuration object for right-swipe progressive behavior.
Passed as `rightSwipe: ProgressiveSwipeConfig(...)` on `SwipeActionCell`. When `null`,
right-swipe progressive behavior is entirely disabled (Constitution IX).

| Field | Type | Default | Constraints | Meaning |
|-------|------|---------|-------------|---------|
| `value` | `double?` | `null` | Any finite double or null | Non-null activates controlled mode; null = uncontrolled |
| `initialValue` | `double` | `0.0` | Any finite double | Starting value in uncontrolled mode |
| `stepValue` | `double` | `1.0` | > 0.0 | Fixed increment per successful swipe (used when `dynamicStep` is null) |
| `maxValue` | `double` | `double.infinity` | > `minValue` | Upper bound for the cumulative value |
| `minValue` | `double` | `0.0` | < `maxValue` | Lower bound (used as reset target for `wrap`) |
| `overflowBehavior` | `OverflowBehavior` | `OverflowBehavior.clamp` | Any enum value | Policy applied when step would exceed `maxValue` |
| `dynamicStep` | `DynamicStepCallback?` | `null` | Returns > 0 for valid step | If set, overrides `stepValue`; receives current value, returns step size |
| `showProgressIndicator` | `bool` | `false` | true requires finite `maxValue` | Whether to render the persistent edge progress bar |
| `progressIndicatorConfig` | `ProgressIndicatorConfig?` | `null` | — | Appearance config for indicator; `null` = defaults |
| `enableHaptic` | `bool` | `false` | — | Whether haptic feedback fires at threshold crossing and increment |
| `onProgressChanged` | `ProgressChangeCallback?` | `null` | — | Fires when cumulative value changes: `(newValue, oldValue)` |
| `onMaxReached` | `VoidCallback?` | `null` | — | Fires when value reaches or would exceed `maxValue` (clamp/wrap only) |
| `onSwipeStarted` | `VoidCallback?` | `null` | — | Fires when right swipe direction is locked |
| `onSwipeCompleted` | `ValueChanged<double>?` | `null` | — | Fires after successful increment animation settles; receives new value |
| `onSwipeCancelled` | `VoidCallback?` | `null` | — | Fires when a below-threshold right swipe is released |

**Invariants**:
- `showProgressIndicator: true` requires `maxValue` to be finite; assert in debug mode.
- `dynamicStep` takes precedence over `stepValue` when both are set.
- `initialValue` is silently clamped to `[minValue, maxValue]` on first use in uncontrolled mode.
- A `dynamicStep` returning ≤ 0 is treated as a no-op for that swipe; value unchanged.
- All callbacks receive the already-constrained (post-overflow-policy) value.

**`copyWith`**: MUST be provided for all fields.
**`const` constructor**: MUST be provided.

---

### ProgressiveSwipeIndicator *(new — widget)*

A lightweight `StatelessWidget` wrapping a `CustomPaint` that renders a filled
vertical bar representing current progress as a proportion of `maxValue`.

| Parameter | Type | Meaning |
|-----------|------|---------|
| `fillRatio` | `double` | Current `currentValue / maxValue`, clamped to [0.0, 1.0] |
| `config` | `ProgressIndicatorConfig` | Appearance settings |

**Rendering**:
- Bar grows from the bottom edge of the cell upward.
- `fillHeight = totalHeight * fillRatio`.
- If `config.backgroundColor != null`, a full-height background rect is painted first.
- Fill rect is painted on top: `Rect.fromLTWH(0, totalHeight - fillHeight, config.width, fillHeight)`.
- `borderRadius` applies `canvas.drawRRect` instead of `drawRect`.

**Performance**: `CustomPainter.shouldRepaint` returns `true` only when `fillRatio` or
`config` changes. The `RepaintBoundary` wrapper around the indicator isolates its
repaint layer from the cell's gesture/animation layer.

---

### SwipeActionCell *(existing widget — additive update)*

`rightSwipe: ProgressiveSwipeConfig?` is added as a new optional parameter.

| New Parameter | Type | Default | Meaning |
|---------------|------|---------|---------|
| `rightSwipe` | `ProgressiveSwipeConfig?` | `null` | When non-null, enables progressive right-swipe behavior. `null` = feature disabled (Constitution IX). |

**State additions** (internal, in `_SwipeActionCellState`):

| Field | Type | Meaning |
|-------|------|---------|
| `_progressValueNotifier` | `ValueNotifier<double>?` | Non-null when `rightSwipe` is non-null; drives indicator and tracks internal value in uncontrolled mode |
| `_isPostIncrementSnapBack` | `bool` | True when `animatingToClose` follows a successful increment (not a cancel) |
| `_hapticThresholdFired` | `bool` | True after threshold haptic fires; reset each drag start |
| `_swipeStartedFired` | `bool` | True after `onSwipeStarted` fires; reset each drag start |

---

## Updated State Machine

The state machine (from F001) gains one new transition path for progressive right swipe:

```
[existing unchanged paths]
idle ──drag start──▶ dragging
dragging ──release(below threshold, any direction)──▶ animatingToClose ──settled──▶ idle
animatingToClose ──drag start──▶ dragging  (interrupt)
animatingToOpen  ──drag start──▶ dragging  (interrupt)
revealed ──drag start──▶ dragging  (left-swipe reveal, F4)

[new path — right swipe progressive]
dragging ──release(right, at/above threshold or fling)──▶ animatingToOpen
animatingToOpen ──settled(right+progressive)──▶ [apply increment] ──▶ animatingToClose ──settled──▶ idle

[unchanged — left swipe reveal, F4 — right swipe without progressive config]
dragging ──release(at/above threshold or fling)──▶ animatingToOpen ──settled──▶ revealed
```

**Key invariant**: `SwipeState.revealed` is never entered for a right swipe when
`widget.rightSwipe` is non-null. The `animatingToOpen` → increment → `animatingToClose`
path bypasses `revealed` entirely.

---

## Value Change Data Flow

```
User releases right swipe above threshold
  → _handleDragEnd: _updateState(animatingToOpen), _animateToOpen(...)
  → spring animation runs
  → AnimationStatus.completed fires in _handleAnimationStatusChange
      if (_state == animatingToOpen && _lockedDirection == right && rightSwipe != null):
        step = rightSwipe.dynamicStep?(currentValue) ?? rightSwipe.stepValue
        (nextValue, hitMax) = _computeNextValue(current, step, config)
        if nextValue != currentValue:
          _progressValueNotifier.value = nextValue  [uncontrolled only]
          config.onProgressChanged?.call(nextValue, currentValue)
        if hitMax:
          config.onMaxReached?.call()
        if enableHaptic:
          HapticFeedback.mediumImpact()
        config.onSwipeCompleted?.call(nextValue)
        _isPostIncrementSnapBack = true
        _updateState(animatingToClose)
        _snapBack(controller.value, 0.0)
```

---

## Validation Rules

| Rule | Check location | Action |
|------|---------------|--------|
| `stepValue` must be > 0 | `ProgressiveSwipeConfig` constructor assert | Error in debug, undefined in release |
| `minValue < maxValue` | `ProgressiveSwipeConfig` constructor assert | Error in debug |
| `showProgressIndicator` requires finite `maxValue` | `_buildProgressIndicator()` in widget state | Assert in debug; return `SizedBox.shrink()` in release |
| `initialValue` outside `[minValue, maxValue]` | `initState` when creating `_progressValueNotifier` | Silently clamped |
| `dynamicStep` returns ≤ 0 | `_computeNextValue` | Treated as no-op |

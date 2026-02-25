# Technical Research: Right-Swipe Progressive Action

**Feature**: 003-progressive-swipe
**Date**: 2026-02-25
**Flutter constraint**: >=3.22.0, Dart >=3.4.0

All technical decisions were informed by the existing F001/F002 implementation in
`lib/src/widget/swipe_action_cell.dart` and the user-provided implementation hints.
No external dependencies introduced — Flutter SDK only.

---

## Q1: Integration Point for Value Change Trigger

### Decision

Hook into `_handleAnimationStatusChange` in `_SwipeActionCellState`. When
`AnimationStatus.completed` fires while `_state == SwipeState.animatingToOpen`
AND `_lockedDirection == SwipeDirection.right` AND `widget.rightSwipe != null`,
apply the progressive increment and immediately begin the snap-back animation
instead of transitioning to `SwipeState.revealed`.

### Rationale

The existing state machine already fires `AnimationStatus.completed` precisely when
the spring animation settles. This is the cleanest and most accurate "animation complete"
signal available — it does not require polling, timers, or additional callbacks. The
`revealed` state is semantically reserved for left-swipe reveal panels (F4). Progressive
right swipe must never enter `revealed`; it increments and snaps back to `idle`.

**Modified state machine path for progressive right swipe**:
```
idle → dragging → animatingToOpen → [increment here] → animatingToClose → idle
```

**Unmodified paths (unaffected by this feature)**:
```
idle → dragging → animatingToClose → idle  (cancel / below threshold)
idle → dragging → animatingToOpen → revealed  (left swipe, F4)
```

A `_isPostIncrementSnapBack` flag tracks whether the `animatingToClose → idle`
transition is a cancel (fire `onSwipeCancelled`) or a post-increment return (do not
fire `onSwipeCancelled`; `onSwipeCompleted` was already fired during increment).

### Alternatives Considered

- **`onStateChanged` callback at `revealed`**: Cannot use because progressive right swipe
  must NOT enter `revealed`. Would require the consumer to snap back manually.
- **`onProgressChanged` per-frame**: Fires every frame; cannot reliably detect "swipe
  completed" without stateful tracking of ratio transitions.
- **Separate animation lifecycle**: Introducing a second `AnimationController` for the
  progressive snap-back would duplicate the spring physics already in F001.

---

## Q2: Progress State Management — ValueNotifier Pattern

### Decision

Use a `ValueNotifier<double> _progressValueNotifier` inside `_SwipeActionCellState`.

- **Uncontrolled mode** (`widget.rightSwipe?.value == null`): `_progressValueNotifier` is
  initialized from `config.initialValue` in `initState` and mutated on each increment.
- **Controlled mode** (`widget.rightSwipe?.value != null`): `_progressValueNotifier` is
  initialized from `config.value!` and mirrored in `didUpdateWidget` whenever the
  externally-provided value changes.

Both modes share the same `_progressValueNotifier`, so the progress indicator and any
`ValueListenableBuilder` consumers work identically regardless of mode.

### Rationale

A `ValueNotifier<double>` is the idiomatic Flutter pattern for single-value change
notification without `setState`. It integrates directly with `ValueListenableBuilder`
for the indicator widget and avoids triggering a full `build()` on every increment
(the indicator subtree rebuilds, the rest of the widget does not).

In controlled mode, mirroring the external value into `_progressValueNotifier` in
`didUpdateWidget` ensures the same notification path works. The widget does NOT
self-mutate the internal notifier on swipe completion in controlled mode — it fires
`onProgressChanged` and lets the developer provide a new `value` prop.

**Detecting the mode**: `widget.rightSwipe?.value != null` is evaluated in
`_computeCurrentValue()` and at every increment decision point. Mode can change
between rebuilds (developer toggling from controlled to uncontrolled) — handle in
`didUpdateWidget`.

### Alternatives Considered

- **`setState` on each increment**: Forces a full widget rebuild every frame the
  indicator changes. Acceptable for post-swipe updates (not per-frame), but
  ValueNotifier is cleaner and more composable.
- **Separate `ProgressiveValueController` class**: Adds indirection without benefit
  for a single `double` value. The ValueNotifier alone suffices.

---

## Q3: Overflow Policy Computation

### Decision

Extract a pure function `_computeNextValue` that takes the current value, the step
(from `dynamicStep` callback or `stepValue`), and the `ProgressiveSwipeConfig`, and
returns the constrained next value plus a flag indicating whether `maxValue` was hit.

```
step = config.dynamicStep != null ? config.dynamicStep!(current) : config.stepValue
candidate = current + step
if candidate <= 0: treat as no-op (negative dynamic step guard)
switch overflowBehavior:
  clamp:  nextValue = min(candidate, maxValue)
          hitMax = candidate >= maxValue
  wrap:   nextValue = candidate > maxValue ? minValue : candidate
          hitMax = candidate > maxValue
  ignore: nextValue = candidate
          hitMax = false
```

### Rationale

Extracting this logic as a pure function (not a method on `_SwipeActionCellState`)
makes it trivially unit-testable without a widget tree. It receives only data — no
`BuildContext`, no listeners — matching the spirit of the Red-Green-Refactor cycle
(Constitution VII). The clamp/wrap/ignore semantics mirror the spec exactly:
- Clamp: value stops at `maxValue`.
- Wrap: value jumps to `minValue` when `maxValue` would be exceeded.
- Ignore: no upper constraint.

The `hitMax` flag drives `onMaxReached()` callback dispatch without a separate
tracking variable.

### Edge cases resolved

| Input | Behavior |
|-------|----------|
| `dynamicStep` returns 0.0 | No value change; `onSwipeCompleted` fires with unchanged value |
| `dynamicStep` returns negative | Treated as no-op (guard: `step <= 0 → skip`) |
| `candidate == maxValue` exactly | `hitMax = true` for clamp; `hitMax = true` for wrap |
| `overflowBehavior: clamp`, value already at `maxValue` | step applied → clamped back to `maxValue` → `hitMax = true`, no `onProgressChanged` |

---

## Q4: Progress Indicator Widget — CustomPaint Bar

### Decision

Implement `ProgressiveSwipeIndicator` as a `StatelessWidget` wrapping a `CustomPaint`.
The painter draws a filled rectangle from the bottom of the cell edge up to a height
proportional to `fillRatio = (currentValue / maxValue).clamp(0.0, 1.0)`.

It is positioned in the widget's `Stack` as a `Positioned` overlay on the leading
(left) edge, with `top: 0`, `bottom: 0`, `left: 0`, `width: config.width`.

Driven by `ValueListenableBuilder<double>(valueListenable: _progressValueNotifier)` so
it only rebuilds the indicator subtree when the value changes, not the full cell tree.

### Rationale

`CustomPaint` is the lightest-weight Flutter painting primitive. For a simple filled
bar, it requires zero layout passes and no extra `RenderObject` allocations beyond the
`RenderCustomPaint` it wraps. The painter receives the fill ratio as a `double` and
calls `canvas.drawRect()` — O(1) per paint call.

Using `ValueListenableBuilder` instead of `setState` keeps indicator repaints isolated
to the `CustomPaint` subtree. The rest of the `SwipeActionCell` widget tree (child,
GestureDetector) does not rebuild when the indicator updates.

**Validation**: If `showProgressIndicator: true` and `maxValue.isInfinite`, the
indicator is not rendered and an assert fires in debug mode. Checked in `build()` via
`assert(!showProgressIndicator || !maxValue.isInfinite, '...')` — but since the
`ProgressiveSwipeConfig` cannot validate at const-construction time against a runtime
`isInfinite` check, the guard lives in `_buildProgressIndicator()` in the state.

### Alternatives Considered

- **`LinearProgressIndicator` (Material)**: Requires `flutter/material.dart` import,
  imports Material theme dependency, imposes Material-style animation. Unacceptable
  for a zero-external-dep package.
- **`AnimatedContainer` with height fraction**: Produces its own animation on value
  change, creating double-animation when used alongside the swipe spring. `CustomPaint`
  is immediately responsive with no internal animations.

---

## Q5: HapticFeedback Integration

### Decision

Use `HapticFeedback` from `package:flutter/services.dart` (Flutter SDK, zero deps):
- **Threshold crossing** (light): `HapticFeedback.lightImpact()` — called once per
  drag when `SwipeProgress.isActivated` first becomes `true` for a right swipe with
  progressive config active.
- **Successful increment** (medium): `HapticFeedback.mediumImpact()` — called inside
  `_applyProgressiveIncrement()` immediately before firing `onProgressChanged`.

Track `_hapticThresholdFired` (bool, reset in `_handleDragStart`) to prevent
re-firing the threshold haptic if the user oscillates back and forth across the
activation boundary during a single drag.

### Rationale

`HapticFeedback` calls are non-blocking fire-and-forget. They do not affect widget
state. The light/medium/heavy semantics map to platform feedback patterns:
- iOS: `UIImpactFeedbackGenerator` with `.light`/`.medium` style.
- Android: `VIEW_CONTEXT_CLICK` / `HAPTIC_FEEDBACK_ENABLED` equivalent.

Firing medium haptic inside `_applyProgressiveIncrement` ensures it only fires on
actual value change (after overflow policy applied), not on clamped no-ops.

---

## Q6: onSwipeStarted Callback Timing

### Decision

Fire `onSwipeStarted()` when `_lockedDirection` first transitions to `SwipeDirection.right`
inside `_handleDragUpdate`, not at `_handleDragStart`. This is the earliest point where
we know the gesture is definitely a right swipe.

A guard flag `_swipeStartedFired` (bool, reset in `_handleDragStart`) prevents the
callback from firing more than once per gesture even if re-evaluated.

### Rationale

At `_handleDragStart`, the direction is not yet known (`_lockedDirection = none`). The
spec says "fires immediately when a right swipe gesture begins" — the earliest meaningful
definition of "right swipe has begun" is direction lock. This is the same frame the dead
zone is crossed, which is perceptually immediate from the user's perspective.

---

## Summary Table

| Decision | Choice | Key Implementation Point |
|----------|--------|--------------------------|
| Value change trigger | `_handleAnimationStatusChange` on completed + right direction | `_SwipeActionCellState` |
| State management | `ValueNotifier<double> _progressValueNotifier` | Mirrored in controlled mode via `didUpdateWidget` |
| Overflow logic | Pure function `_computeNextValue` | Extracted for unit-testability |
| Progress indicator | `CustomPaint` in `Positioned` Stack overlay | `ValueListenableBuilder` for isolated rebuilds |
| Haptic | `HapticFeedback.lightImpact/mediumImpact` | Threshold: once per drag; increment: on value change |
| onSwipeStarted timing | Direction lock point in `_handleDragUpdate` | Guard flag prevents re-fire |
| Controlled mode mirror | `didUpdateWidget` updates `_progressValueNotifier` | No self-mutation on swipe completion |

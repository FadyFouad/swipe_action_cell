# Technical Research: Swipe Background Visual Layer

**Feature**: 002-swipe-background
**Date**: 2026-02-25
**Flutter constraint**: >=3.22.0, Dart >=3.4.0

Answers five targeted technical questions that directly inform the implementation of the visual
background layer added by this feature.

---

## Q1: Per-Frame Background Delivery — Builder in AnimatedBuilder vs ValueNotifier

### Decision

Call the background builder function directly inside the existing `AnimatedBuilder`'s builder
callback. Do **not** add a separate `ValueNotifier<SwipeProgress>` or a second
`AnimationController`.

### Rationale

Two delivery mechanisms were evaluated:

**Option A — AnimatedBuilder (chosen)**: The existing `AnimationController _controller` already
drives an `AnimatedBuilder` every frame. Calling `_buildBackground(context, progress)` inside the
same builder means:
- Zero additional listener registrations.
- Zero additional `State` objects.
- Background builder receives a freshly-computed `SwipeProgress` on every tick.
- `widget.child` is hoisted as the `child` parameter → stays out of the rebuild path.

**Option B — ValueNotifier<SwipeProgress> + ValueListenableBuilder**: Setting
`_progressNotifier.value` during a build callback schedules nested `setState` calls, which
Flutter disallows within a single frame's build pass. Safely avoiding this requires moving the
update to `_controller.addListener(...)` and caching `_widgetWidth` from `LayoutBuilder` into
a state field. This adds two extra state fields and one extra listener just to do what the
existing `AnimatedBuilder` already provides. Rejected for unnecessary complexity.

### Code Pattern

```dart
AnimatedBuilder(
  animation: _controller,
  builder: (context, hoistedChild) {
    final offset = _controller.value;
    final progress = _computeProgress(offset, widgetWidth);
    widget.onProgressChanged?.call(progress);

    final backgroundSlot = _buildBackground(context, progress);

    return Stack(children: [
      Positioned.fill(child: backgroundSlot),
      Transform.translate(offset: Offset(offset, 0), child: hoistedChild),
    ]);
  },
  child: widget.child,   // hoisted — never rebuilt per frame
)
```

---

## Q2: Clipping Strategy — ClipRect vs ClipRRect vs DecoratedBox

### Decision

Use `ClipRRect` when `borderRadius` is non-null; use `ClipRect` when `borderRadius` is null and
`clipBehavior != Clip.none`; skip clipping entirely when `clipBehavior == Clip.none`.

### Rationale

Three strategies were evaluated:

| Strategy | borderRadius support | clipBehavior control | Extra render objects |
|----------|---------------------|---------------------|----------------------|
| `ClipRect` | No | Yes | 1 (`RenderClipRect`) |
| `ClipRRect` | Yes | Yes | 1 (`RenderClipRRect`) |
| `DecoratedBox` + `ShapeDecoration` | Yes (via ShapeBorder) | No | 2 (box + clip) |

`ClipRRect(borderRadius: r, clipBehavior: c)` subsumes `ClipRect(clipBehavior: c)` when `r`
is non-null and non-zero. The two-branch approach (ClipRect / ClipRRect) maps directly to
Flutter stdlib patterns (`Container`, `Card`). It adds exactly one render object in the
common case. `DecoratedBox` was rejected because it does not directly clip its child —
it decorates the background. A `ClipPath` with a `RoundedRectangleBorder` shape was
rejected because it is slower (anti-aliasing path vs. fast-path RRect clip in Skia/Impeller).

### Code Pattern

```dart
Widget _wrapWithClip(Widget child) {
  if (widget.borderRadius != null) {
    return ClipRRect(
      borderRadius: widget.borderRadius!,
      clipBehavior: widget.clipBehavior,
      child: child,
    );
  }
  if (widget.clipBehavior != Clip.none) {
    return ClipRect(clipBehavior: widget.clipBehavior, child: child);
  }
  return child;
}
```

---

## Q3: Background Slot Lifecycle — Idle vs Drag vs Snap-Back

### Decision

Gate the background slot on `progress.direction != SwipeDirection.none` — no other sentinel
value or extra state field required. The existing F001 state machine naturally sets
`_lockedDirection = SwipeDirection.none` only when `animatingToClose` completes (not during
snap-back), so the background remains in the tree throughout snap-back and disappears when the
controller settles.

### Rationale

Tracing the F001 state machine:

```
dragging (direction locked) → drag-end below threshold
  → AnimatingToClose
  → SpringSimulation animates _controller.value: currentOffset → 0.0
  → Each tick: _lockedDirection still set; progress.direction = locked
  → AnimationStatus.completed fires when simulation isDone()
  → _handleAnimationStatusChange: _lockedDirection = SwipeDirection.none
  → _updateState(SwipeState.idle) → setState (schedules rebuild)
  → Next AnimatedBuilder tick: direction = none → background slot empty
```

This means:
- During snap-back: direction stays set, ratio decreases 0.x → 0.0, builder called each frame ✓
- At idle: direction = none → `_buildBackground` returns `SizedBox.shrink()` ✓
- No extra state field, no timer, no post-frame callback needed ✓

The one edge case: after `animationStatus.completed` sets `_lockedDirection = none`, the
`AnimatedBuilder` may fire one more time before `setState` propagates, showing the background
at `ratio ≈ 0.0`. This is visually imperceptible (opacity ≈ 0.0) and resolves correctly on
the subsequent rebuild.

### Code Pattern

```dart
Widget _buildBackground(BuildContext context, SwipeProgress progress) {
  if (progress.direction == SwipeDirection.none) {
    return const SizedBox.shrink();
  }
  final builder = progress.direction == SwipeDirection.right
      ? widget.rightBackground
      : widget.leftBackground;
  if (builder == null) return const SizedBox.shrink();
  return builder(context, progress);
}
```

---

## Q4: SwipeActionBackground Animation Driver — Internal AnimationController for Bump

### Decision

Use a second `AnimationController` (`_bumpController`) owned by
`_SwipeActionBackgroundState`. Drive it via `didUpdateWidget` by detecting the
`isActivated` transition (`false → true`). Use a `TweenSequence` to produce an overshoot-and-
return scale curve over ~300ms.

### Rationale

`SwipeActionBackground` is a `StatefulWidget` that receives `SwipeProgress progress` as a
constructor parameter. When the parent's `AnimatedBuilder` calls
`SwipeActionBackground(progress: p, ...)` each frame, Flutter reconciles the existing element
(same widget type, same tree position) and calls `didUpdateWidget(old)` with the new props,
preserving `_bumpController`'s state.

Alternative — embed the bump in `SwipeActionCell`'s own controller: rejected because
`SwipeActionCell` should not know about `SwipeActionBackground`'s visual implementation.
Alternative — use `AnimationController` on `SwipeActionCell` and forward it: rejected because
it breaks the `const SwipeActionBackground(...)` call site and couples the two widgets.

### Bump animation design

```
Time:  0ms ─── 150ms ─── 300ms
Scale: 0.0 ──▶  +0.3  ──▶  0.0   (relative to base ratio)

Final displayed scale = ratio * (1.0 + bumpValue)
```

- `bumpValue` starts at 0.0, peaks at 0.3 at 150ms, returns to 0.0 at 300ms.
- Applied as a multiplier on top of `ratio`, so the bump is proportional to how far the icon
  is already scaled — a soft pulse rather than an absolute overshoot.

### Code Pattern

```dart
@override
void didUpdateWidget(SwipeActionBackground old) {
  super.didUpdateWidget(old);
  if (widget.progress.isActivated && !old.progress.isActivated) {
    _bumpController.forward(from: 0.0);
  }
}
```

---

## Q5: Background Color Intensification — HSL Lightness vs Color.lerp

### Decision

Use `HSLColor.fromColor(backgroundColor).withLightness(...)` to produce the intensified color.
Reduce lightness by up to 15 percentage points as `ratio` increases from 0.0 to 1.0.

### Rationale

Two approaches were evaluated:

**Option A — `Color.lerp(base, darkerVersion, ratio)` (chosen direction, with HSL computation)**:
Produces a perceptually smooth darkening. `HSLColor` manipulation directly controls the
lightness axis independently of hue and saturation — the color gets darker without shifting hue
or desaturating, maintaining color identity.

**Option B — `Color.lerp(base, Colors.black, ratio * 0.15)`**: Lerps toward black, which both
darkens AND desaturates the color. This produces a muddy result for bright or saturated
background colors. Rejected.

**Option C — HSL saturation increase (intensify by saturating)**: Saturating can look good on
muted colors but over-saturates already-vivid colors and has no effect on greyscale inputs.
Not universally applicable. Rejected.

### Code Pattern

```dart
Color _intensifiedColor(double ratio) {
  final hsl = HSLColor.fromColor(widget.backgroundColor);
  final darkenAmount = 0.15 * ratio;
  return hsl
      .withLightness((hsl.lightness - darkenAmount).clamp(0.0, 1.0))
      .toColor();
}
```

At `ratio = 0.0`: no change. At `ratio = 1.0`: lightness reduced by 0.15 (15pp). Monotonically
darker as the user drags further, providing clear visual feedback of approach to the threshold.

---

## Summary Table

| Question | Decision | Key API |
|----------|----------|---------|
| Q1: Per-frame delivery | Builder inside existing `AnimatedBuilder` | `AnimatedBuilder.builder` |
| Q2: Clipping | `ClipRRect` (radius set) / `ClipRect` (radius null) / none | `ClipRRect`, `ClipRect` |
| Q3: Background lifecycle | Gate on `direction != none`; F001 state machine provides correct lifecycle | `SwipeDirection.none` sentinel |
| Q4: Bump animation | `_bumpController` in `_SwipeActionBackgroundState`; detect via `didUpdateWidget` | `AnimationController`, `TweenSequence` |
| Q5: Color intensification | HSL lightness reduction (−15pp at ratio=1.0) | `HSLColor.fromColor`, `.withLightness` |

# Flutter Technical Research: Gesture & Animation for Swipe Interaction Widget

**Feature**: 001-gesture-animation
**Date**: 2026-02-25
**Flutter constraint**: >=3.22.0, Dart >=3.4.0

This document answers seven targeted technical questions that directly inform the implementation
of `SwipeActionCell`'s gesture and animation layer. Each section is self-contained and includes
a Decision, Rationale, and Code Pattern.

---

## Q1: Horizontal Drag + Scroll Coexistence

### Decision

Use a raw `GestureDetector` with `onHorizontalDragStart/Update/End` inside a vertical
`ListView`. Do NOT set `behavior: HitTestBehavior.opaque` unconditionally. Instead, use
`behavior: HitTestBehavior.translucent` (the default) and allow the gesture arena to resolve
the conflict naturally. For this widget, the decisive additional mechanism is to defer claiming
the gesture in the horizontal recognizer until the horizontal displacement clearly exceeds the
dead zone — which is exactly what Flutter's `HorizontalDragGestureRecognizer` does by default
via its `kTouchSlop` acceptance threshold.

### Rationale

**How the gesture arena works**: When a pointer-down event fires, every recognizer that
intersects the hit-test region enters the same gesture arena for that pointer. In a
`GestureDetector(onHorizontalDragStart: ...) → ListView` stack, two recognizers compete:

- The `HorizontalDragGestureRecognizer` from the `GestureDetector`.
- The `VerticalDragGestureRecognizer` (or `ScrollDragController`) owned by the `ScrollPosition`
  inside the `ListView`.

Each recognizer watches pointer-move events. The horizontal recognizer calls `resolve(win)` when
cumulative horizontal displacement exceeds `kTouchSlop` (typically 18 logical pixels on most
devices, derived from `MediaQueryData.gestureSettings.touchSlop` in Flutter 3.22+). The vertical
recognizer does the same for vertical displacement. Whichever exceeds its slop threshold first
wins the arena; the other recognizer is rejected and stops receiving events.

**Flutter 3.22+ behavioral change — `touchSlop` from platform**: Starting around Flutter 3.10
and solidified in 3.22, `GestureBinding` reads the platform-reported `touchSlop` value via
`ui.GestureSettings` and passes it down to recognizers through `GestureRecognizerExtraData`. On
Android, this defaults to the platform's ViewConfiguration touch slop. On iOS it matches
`kTouchSlop` from Flutter constants. This means you should no longer hard-code `kTouchSlop` (18)
yourself; the recognizer handles it. There are no breaking changes to arena behavior in 3.22 for
the standard horizontal/vertical conflict scenario.

**Known gotchas**:

1. **Diagonal gestures**: If the first 20px of motion are nearly 45 degrees, neither recognizer
   wins immediately and both remain in the arena. The arena is resolved lazily, meaning the
   first recognizer whose slop is exceeded along its axis wins. For this widget, this is
   acceptable because the direction-lock logic (Q5) handles the in-cell portion.

2. **`HitTestBehavior.opaque` pitfall**: Setting this on the `GestureDetector` causes the
   horizontal recognizer to immediately claim the pointer, preventing the `ListView` from even
   entering the arena. This breaks vertical scrolling entirely. Use the default `translucent`
   so both recognizers can participate.

3. **Nested horizontal scrolling**: If the `SwipeActionCell` is inside a `PageView` or
   horizontal `ListView`, the same horizontal/horizontal arena conflict applies. That case
   requires a `RawGestureDetector` with a `GestureArenaTeam` or `ScrollNotification`-based
   logic — outside the current scope.

4. **`PointerSignal` (scroll wheel/trackpad)**: `GestureDetector` does not interfere with
   `PointerScrollEvent` dispatch. Horizontal trackpad swipes go through the `Scrollable`'s
   `PointerSignalHandler`, not through the drag recognizer.

### Code Pattern

```dart
GestureDetector(
  // HitTestBehavior.translucent (default) — lets ListView also receive hit tests.
  behavior: HitTestBehavior.translucent,
  onHorizontalDragStart: _handleDragStart,
  onHorizontalDragUpdate: _handleDragUpdate,
  onHorizontalDragEnd: _handleDragEnd,
  child: widget.child,
)
```

If the widget needs to yield to the scroll view on ambiguous diagonal gestures, pair this with a
`NotificationListener<ScrollStartNotification>` wrapping the list to detect when the ancestor
scroll claims priority, and reset the internal drag state at that point. Alternatively, use a
custom `OneSequenceGestureRecognizer` that calls `stopTrackingPointer` on the first vertical
motion exceeding slop, but the default arena behavior handles this correctly in the vast majority
of cases.

---

## Q2: SpringSimulation with AnimationController from Arbitrary Position

### Decision

Use `AnimationController` with `lowerBound: double.negativeInfinity` and
`upperBound: double.infinity` (an unbounded controller). Seed its value directly to the current
drag offset before calling `animateWith(SpringSimulation(...))`. Pass the current drag offset as
`start` and zero (or the target position) as `end` in the `SpringSimulation` constructor, with
the current velocity from `DragEndDetails.primaryVelocity` as the initial velocity.

### Rationale

`AnimationController.animateWith(Simulation simulation)` drives the controller by asking the
simulation for `x(t)` and `dx/dt(t)` at each tick. The simulation is completely responsible for
the trajectory — the controller's `lowerBound`/`upperBound` only matter for clamping in the
bounded case. When you use `double.negativeInfinity` / `double.infinity`, the controller emits
raw simulation values without clamping, which is exactly what you need for pixel-space offsets
that range from `-maxTranslation` to `+maxTranslation`.

**Do NOT use a normalized 0–1 range** for this use case. Normalizing and then scaling back into
pixel space is error-prone: it requires you to convert the drag velocity into normalized units,
convert the spring's output back to pixels, and the spring's natural length units change meaning.
Work in pixel space directly.

**`SpringSimulation` constructor signature**:

```dart
SpringSimulation(
  SpringDescription spring,  // mass, stiffness, damping
  double start,              // initial position (current drag offset in pixels)
  double end,                // target position (0.0 for snap-back, maxTranslation for open)
  double velocity,           // initial velocity in pixels/second (from DragEndDetails)
)
```

The `SpringDescription` is created with:

```dart
const SpringDescription(
  mass: 1.0,
  stiffness: 500.0,   // higher = snappier
  damping: 28.0,      // critical ≈ 2*sqrt(mass*stiffness) = 2*sqrt(500) ≈ 44.7
                      // 28 gives a slight underdamp (subtle bounce), 44+ = overdamped
)
```

For a snap-back (return to origin), `end = 0.0`. For a completion (reveal), `end = maxTranslation`
(positive for right swipe, negative for left swipe).

**Seeding the controller value**: Before calling `animateWith`, set `controller.value` to the
current pixel offset. With an unbounded controller this is done via direct assignment, which is
legal even mid-animation after calling `stop()`.

**`isDone` detection**: `SpringSimulation.isDone(double time)` returns true when the spring
settles. The `AnimationController` monitors this via the simulation's `isDone` and emits a
`completed` status. Listen to `controller.addStatusListener` to detect settlement.

### Code Pattern

```dart
// In State<SwipeActionCell>:
late final AnimationController _controller;

@override
void initState() {
  super.initState();
  _controller = AnimationController(
    vsync: this,
    // Unbounded: value tracks pixel offset directly.
    lowerBound: double.negativeInfinity,
    upperBound: double.infinity,
    // value defaults to 0.0 which matches idle position.
    value: 0.0,
  );
}

void _snapBack({required double fromOffset, required double velocity}) {
  final spring = SpringDescription(
    mass: 1.0,
    stiffness: _config.snapBackStiffness,
    damping: _config.snapBackDamping,
  );
  final simulation = SpringSimulation(spring, fromOffset, 0.0, velocity);
  _controller
    ..value = fromOffset   // seed position before animating
    ..animateWith(simulation);
}

void _animateToOpen({required double fromOffset, required double toOffset, required double velocity}) {
  final spring = SpringDescription(
    mass: 1.0,
    stiffness: _config.completionStiffness,
    damping: _config.completionDamping,
  );
  final simulation = SpringSimulation(spring, fromOffset, toOffset, velocity);
  _controller
    ..value = fromOffset
    ..animateWith(simulation);
}

// In build():
@override
Widget build(BuildContext context) {
  return AnimatedBuilder(
    animation: _controller,
    builder: (context, child) {
      return Transform.translate(
        offset: Offset(_controller.value, 0.0),
        child: child,
      );
    },
    child: _gestureWrapper,
  );
}
```

**Critical note on unbounded controller + value assignment**: When `lowerBound` and `upperBound`
are both finite and `value` is set to a pixel offset that exceeds them, Flutter will clamp the
value and print an assertion error in debug mode. Always use unbounded bounds when your value
represents raw pixels.

---

## Q3: Interrupting an Animation Mid-Flight and Resuming Drag

### Decision

Call `controller.stop()` — do NOT call `reset()`. Then read `controller.value` for the current
position and continue setting `.value` directly (via the drag update handler) from that point.
No additional seeding or re-initialization is needed.

### Rationale

`AnimationController.stop()` does three things:
1. Cancels the active `Ticker` tick (ending the simulation loop).
2. Leaves `controller.value` at whatever the simulation last produced.
3. Sets `status` to `AnimationStatus.forward` or `dismissed` depending on direction — but this
   is not meaningful after `stop()` for the simulation case; the relevant observable is the
   `value`.

`AnimationController.reset()` would set the value back to `lowerBound` (0.0 for a bounded
controller, or `double.negativeInfinity` for an unbounded one — but since `value` defaults to
0.0, it effectively zeroes out). This would produce a visual jump. Never call `reset()` during
an interruption.

**The correct state-machine flow for mid-flight interruption**:

```
animatingToClose / animatingToOpen
  → user onHorizontalDragStart fires
  → controller.stop()           // freeze at current pixel
  → _currentOffset = controller.value  // read frozen pixel
  → setState(() => _state = SwipeState.dragging)
  → drag update: controller.value = _currentOffset + delta.dx
```

Because `AnimationController.value` is a settable property (even when not animating), directly
assigning to it during drag update triggers `AnimatedBuilder` to rebuild with the new value —
providing the live drag-following behavior.

**Gotcha — multiple status listeners**: If you attach a status listener that transitions state
when the animation completes (`AnimationStatus.completed`), stopping mid-flight does NOT trigger
`completed`. Ensure your drag-start handler updates `_state` regardless of whether the
`statusListener` will fire.

### Code Pattern

```dart
void _handleDragStart(DragStartDetails details) {
  // Interrupt any in-flight animation without resetting position.
  _controller.stop(); // leaves .value at the current simulated position

  setState(() {
    _currentOffset = _controller.value; // snapshot the frozen position
    _swipeState = SwipeState.dragging;
    _direction = SwipeDirection.none;   // will be locked on first meaningful delta
  });
}

void _handleDragUpdate(DragUpdateDetails details) {
  final dx = details.delta.dx;
  // Lock direction on first meaningful movement (see Q5).
  if (_direction == SwipeDirection.none) {
    _tryLockDirection(dx);
    return; // eat the first locking delta; no translation yet
  }
  final newOffset = (_currentOffset + dx).clamp(
    -_config.maxTranslationLeft,
    _config.maxTranslationRight,
  );
  // Apply resistance near bounds (see Q4 before clamping).
  _currentOffset = newOffset;
  _controller.value = _currentOffset; // drives AnimatedBuilder directly
}
```

---

## Q4: Rubber-Band / Drag Resistance Formula

### Decision

Use the standard logarithmic resistance formula derived from iOS `UIScrollView` behavior. It
maps raw overflow displacement through a damping curve that approaches but never reaches the
bound. The practical implementation for this widget applies resistance only to the portion of
the drag that exceeds `maxTranslation`, then adds it back on top of `maxTranslation`.

### Rationale

iOS rubber-banding uses the formula:

```
resistedOffset = (1 - (1 / ((rawOverflow * factor / maxTranslation) + 1))) * maxTranslation
```

Where `rawOverflow` is the amount of drag past the bound, `maxTranslation` is the bound, and
`factor` is a constant (iOS uses 0.55 internally, often described as "55% visible per unit of
effort"). This produces a curve that:

- Starts linear near the bound (factor ≈ 1 for small overflows).
- Asymptotically approaches `maxTranslation` as overflow grows.
- Never actually reaches or exceeds `maxTranslation` mathematically.

For configurable resistance, expose `resistanceFactor` in `SwipeAnimationConfig`:
- `0.0` — no resistance (linear drag all the way to and past the bound, clamped).
- `1.0` — maximum resistance (iOS-like feel).
- `0.55` — recommended default, matches iOS feel.

A `resistanceFactor` of `0.0` should bypass the formula entirely and clamp to `maxTranslation`
directly, giving hard-wall behavior.

### Code Pattern

```dart
/// Applies rubber-band resistance to [rawOffset] when it exceeds [maxTranslation].
///
/// Returns the visually-damped offset. The result never exceeds [maxTranslation]
/// regardless of [rawOffset], assuming [factor] > 0.
///
/// - [rawOffset]: The total drag displacement in pixels (positive = right, negative = left).
///   Pass the absolute signed value; the sign is restored by the caller.
/// - [maxTranslation]: The soft bound in pixels (always positive).
/// - [factor]: Resistance factor 0.0–1.0. 0.0 = hard clamp. 0.55 = iOS-like.
double applyResistance(
  double rawOffset,
  double maxTranslation,
  double factor,
) {
  assert(maxTranslation > 0, 'maxTranslation must be positive');
  assert(factor >= 0.0 && factor <= 1.0, 'factor must be in [0.0, 1.0]');

  final sign = rawOffset.sign;
  final abs = rawOffset.abs();

  if (abs <= maxTranslation) {
    // Within bounds — no resistance needed.
    return rawOffset;
  }

  if (factor == 0.0) {
    // Hard clamp: no rubber-band, just stop at the bound.
    return sign * maxTranslation;
  }

  final overflow = abs - maxTranslation;
  // iOS-derived logarithmic formula:
  // resistedOverflow = (1 - 1 / (overflow * factor / maxTranslation + 1)) * maxTranslation
  final resistedOverflow =
      (1.0 - 1.0 / ((overflow * factor / maxTranslation) + 1.0)) * maxTranslation;

  return sign * (maxTranslation + resistedOverflow);
}
```

**Usage in drag update**:

```dart
void _handleDragUpdate(DragUpdateDetails details) {
  if (_direction == SwipeDirection.none) return;

  _rawOffset += details.delta.dx;
  final maxT = _direction == SwipeDirection.right
      ? _config.maxTranslationRight
      : _config.maxTranslationLeft;

  // Apply resistance: work in signed offset space.
  final dampedOffset = applyResistance(
    _rawOffset,
    maxT,
    _config.resistanceFactor,
  );

  _controller.value = dampedOffset;
}
```

**Why not a simple linear multiplier?** A linear factor (`offset * 0.3` past the bound) still
allows the widget to exceed `maxTranslation` given enough drag distance. The logarithmic formula
mathematically guarantees the cell never visually passes the bound, matching native platform
behavior.

---

## Q5: Direction Lock Pattern

### Decision

Track direction manually using `DragUpdateDetails.delta.dx` in the first N pixels of a drag
(N = dead zone, e.g. 12px). There is no built-in Flutter mechanism for direction locking within
a `GestureDetector`. Lock on the first update where cumulative horizontal displacement exceeds
the dead zone, then ignore subsequent vertical drift for the remainder of the gesture.

### Rationale

Flutter provides no "lock axis" concept inside `GestureDetector` callback sequences. The
horizontal drag recognizer has already won the arena at this point (it called `resolve(win)` when
horizontal slop was exceeded), but that does not prevent the update stream from containing
`DragUpdateDetails.delta` with non-zero `dy` values — the user's finger physically drifts.

The standard industry pattern (used by `flutter_slidable` and `Dismissible`) is:

1. On `onHorizontalDragStart`: reset accumulated delta to zero. Set `_directionLocked = false`.
2. On `onHorizontalDragUpdate`: if `!_directionLocked`, accumulate `delta.dx`.
   - If `|accumulated| >= deadZone`: determine direction (`dx > 0` = right, `dx < 0` = left).
     Set `_directionLocked = true` and record `_lockedDirection`.
   - If `_directionLocked`: apply `delta.dx` to offset only (ignore `delta.dy` entirely).
3. On `onHorizontalDragEnd`: consume `primaryVelocity` and reset.

**Why 10–20px for the lock window**: The spec mandates 10–20 logical pixels. The Flutter
`kTouchSlop` constant is 18.0px. Using 12px (from the spec's default dead zone) means the
direction lock often fires in the same update that the arena was won — a natural coincidence that
avoids a perceived double threshold.

**No `delta.dy` suppression needed**: Because the `HorizontalDragGestureRecognizer` has already
won the arena, `DragUpdateDetails.globalPosition` may include diagonal movement but the cell only
applies `delta.dx` to the transform offset. Vertical components are naturally discarded by only
using `delta.dx`.

### Code Pattern

```dart
// State fields:
SwipeDirection _lockedDirection = SwipeDirection.none;
double _accumulatedDx = 0.0;
static const double _deadZone = 12.0; // logical pixels

void _handleDragStart(DragStartDetails details) {
  _controller.stop();
  _accumulatedDx = 0.0;
  _lockedDirection = SwipeDirection.none;
  setState(() => _swipeState = SwipeState.dragging);
}

void _handleDragUpdate(DragUpdateDetails details) {
  final dx = details.delta.dx;

  if (_lockedDirection == SwipeDirection.none) {
    _accumulatedDx += dx;
    if (_accumulatedDx.abs() < _deadZone) {
      // Still inside dead zone — do not move the cell.
      return;
    }
    // Dead zone exceeded: lock direction for the rest of this gesture.
    _lockedDirection =
        _accumulatedDx > 0 ? SwipeDirection.right : SwipeDirection.left;

    // Check if this direction is enabled; if not, bail out.
    if (!_isDirectionEnabled(_lockedDirection)) {
      _lockedDirection = SwipeDirection.none;
      return;
    }
  }

  // Direction is locked — use only the horizontal component.
  final newOffset = applyResistance(
    _controller.value + dx,
    _maxTranslationFor(_lockedDirection),
    _config.resistanceFactor,
  );
  _controller.value = newOffset;
}
```

**Accumulate vs. threshold on first update**: Some implementations check only the first
`DragUpdateDetails` delta. That is unreliable because the first update delta can be very small
(sub-pixel precision). Accumulating until the threshold is reliably crossed handles fast vs. slow
drag starts consistently.

---

## Q6: VelocityTracker / DragEndDetails Velocity

### Decision

Use `DragEndDetails.primaryVelocity` for the fling-vs-snap decision. It returns the velocity in
logical pixels per second along the primary axis (horizontal, in this case), and is always
non-null for a horizontal drag recognizer. If it is exactly `0.0` (user lifted without moving),
fall back to the distance-only threshold comparison.

### Rationale

`DragEndDetails` exposes two velocity fields:

| Field | Type | Description |
|---|---|---|
| `velocity` | `Velocity` | 2D velocity vector (has `.pixelsPerSecond` of type `Offset`). |
| `primaryVelocity` | `double?` | Signed scalar along the primary axis. Non-null for mono-directional recognizers. |

For a `HorizontalDragGestureRecognizer` (which is what `GestureDetector.onHorizontalDragEnd`
uses), `primaryVelocity` is always the horizontal component (positive = right, negative = left).
It is equivalent to `velocity.pixelsPerSecond.dx` but is the idiomatic field to use because it
communicates intent explicitly.

**When `primaryVelocity` is `0.0`**: This happens when:
- The finger was stationary for >100ms before lift-off (the `VelocityTracker` only uses the last
  ~100ms of pointer events and discards older samples).
- The drag was extremely slow and the computed pixel-per-second figure rounds to zero.
- The gesture duration was so short that fewer than the minimum required pointer events were
  captured.

In all these cases, `primaryVelocity == 0.0` is valid and means "no meaningful fling velocity
detected." The spec explicitly handles this: "if velocity data is unavailable, fall back to
distance-only threshold comparison."

**`VelocityTracker` internals (informational)**: Flutter's `VelocityTracker` (in
`gestures/velocity_tracker.dart`) uses a least-squares polynomial regression over the last 150ms
of pointer events. The `HorizontalDragGestureRecognizer` feeds pointer events into this tracker
automatically — you do not need to instantiate one yourself.

**Do NOT use `details.velocity.pixelsPerSecond.dy`** for a horizontal gesture decision. It may
be non-zero due to drift, and using it could misidentify the fling direction.

### Code Pattern

```dart
void _handleDragEnd(DragEndDetails details) {
  final velocity = details.primaryVelocity ?? 0.0;
  final currentOffset = _controller.value;
  final maxT = _maxTranslationFor(_lockedDirection);
  final ratio = currentOffset.abs() / maxT;

  final bool isActivationFling =
      velocity.abs() >= _config.velocityThreshold;       // e.g. 700 px/s

  final bool isActivationDistance =
      ratio >= _config.activationThreshold;              // e.g. 0.40

  // Fling direction must agree with locked direction.
  final bool flingInSwipeDirection = _lockedDirection == SwipeDirection.right
      ? velocity > 0
      : velocity < 0;

  final bool shouldComplete =
      (isActivationFling && flingInSwipeDirection) || isActivationDistance;

  if (shouldComplete) {
    setState(() => _swipeState = SwipeState.animatingToOpen);
    _animateToOpen(
      fromOffset: currentOffset,
      toOffset: _lockedDirection == SwipeDirection.right ? maxT : -maxT,
      velocity: velocity,
    );
  } else {
    setState(() => _swipeState = SwipeState.animatingToClose);
    _snapBack(fromOffset: currentOffset, velocity: velocity);
  }
}
```

**Velocity sign convention**: `primaryVelocity` is positive for rightward movement, negative for
leftward. The `SpringSimulation` velocity parameter uses the same sign convention — pass
`primaryVelocity` directly as the initial velocity for a physically consistent handoff from drag
to spring.

---

## Q7: `flutter_test` Widget Test for Gestures

### Decision

Use `TestGesture` (obtained via `tester.startGesture(...)`) for any test that requires velocity
control, multi-step sequences, or mid-animation interruption. Use `tester.drag()` only for simple
single-axis fixed-offset tests. Never use `tester.fling()` when you need precise velocity control
because its velocity is approximate and implementation-defined.

### Rationale

`flutter_test` provides three gesture simulation mechanisms:

| API | Best For | Velocity Control | Multi-step |
|---|---|---|---|
| `tester.drag(finder, offset)` | Simple offset, no velocity | None | No |
| `tester.fling(finder, offset, speed)` | Quick fling, coarse velocity | Coarse | No |
| `TestGesture` (via `tester.startGesture`) | All precision tests | Exact | Yes |

**`tester.drag`**: Sends a `pointer-down` then a series of `pointer-move` events covering the
total `offset`, then `pointer-up` — all within a single `pump()`. The inter-frame timing means
no meaningful velocity is reported (`primaryVelocity` will be 0 or near-zero) because all moves
arrive in the same event batch. Use only for testing position-threshold behavior (not flings).

**`tester.fling`**: Wraps `tester.drag` but introduces timing between move events to produce a
measurable velocity. The `speed` parameter is in logical pixels per second and controls how fast
the simulated pointer moves. This is useful for basic fling tests but the actual reported
`primaryVelocity` in the handler may differ from `speed` because of the `VelocityTracker`'s
regression algorithm — treat it as approximate.

**`TestGesture`** (recommended for this widget):

```dart
final gesture = await tester.startGesture(
  tester.getCenter(find.byType(SwipeActionCell)),
);
```

Returns a `TestGesture` that you can `moveBy(offset)` in discrete steps, controlling inter-step
timing with `await tester.pump(Duration(...))`. This mirrors real user input fidelity.

For velocity-critical tests, use `tester.pump(Duration(milliseconds: 16))` between `moveBy`
calls (approximately one frame at 60fps) to give the `VelocityTracker` enough temporal samples
to compute an accurate velocity. Send at least 3–5 move events before `up()` to avoid zero-
velocity edge cases.

### Code Pattern

```dart
// Minimal horizontal drag test (position threshold only):
testWidgets('snap-back when drag is below threshold', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: SwipeActionCell(child: const Text('item'))),
  ));

  // Simple drag: no velocity, just offset.
  await tester.drag(
    find.byType(SwipeActionCell),
    const Offset(60, 0), // 60px rightward
  );
  await tester.pumpAndSettle();

  // Verify cell has returned to origin (snap-back path).
  expect(
    tester.getRect(find.byType(SwipeActionCell)).left,
    moreOrLessEquals(0.0, epsilon: 1.0),
  );
});

// Fling test with precise velocity using TestGesture:
testWidgets('fling completes animation when velocity exceeds threshold', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: SwipeActionCell(child: const Text('item'))),
  ));

  final center = tester.getCenter(find.byType(SwipeActionCell));
  final gesture = await tester.startGesture(center);

  // 5 move events × 10px × 16ms apart ≈ 625 px/s horizontal velocity.
  // Adjust step size / count to hit the 700 px/s threshold reliably.
  const stepPx = 14.0; // 14px × 5 = 70px total, 14/0.016 = 875 px/s
  for (int i = 0; i < 5; i++) {
    await gesture.moveBy(const Offset(stepPx, 0));
    await tester.pump(const Duration(milliseconds: 16));
  }
  await gesture.up();
  await tester.pumpAndSettle();

  // Verify cell reached revealed state.
  final cellFinder = find.byType(SwipeActionCell);
  // The Transform.translate offset should be at maxTranslation.
  // Inspect via RenderObject or a ValueNotifier exposed by the widget.
});

// Multi-step drag with mid-animation interruption:
testWidgets('mid-animation drag interruption has no positional jump', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(body: SwipeActionCell(child: const Text('item'))),
  ));

  final center = tester.getCenter(find.byType(SwipeActionCell));

  // 1. Drag partway, release (triggers snap-back animation).
  final gesture1 = await tester.startGesture(center);
  await gesture1.moveBy(const Offset(50, 0));
  await tester.pump(const Duration(milliseconds: 16));
  await gesture1.up();
  await tester.pump(const Duration(milliseconds: 50)); // let animation start

  // 2. Read current visual offset mid-animation.
  // (Requires an accessible ValueNotifier or renderObject transform inspection.)
  final offsetBefore = _readTranslateOffset(tester);

  // 3. Start new drag — should snap to current position, no jump.
  final gesture2 = await tester.startGesture(center);
  await tester.pump();

  final offsetAfterInterrupt = _readTranslateOffset(tester);
  expect(
    offsetAfterInterrupt,
    moreOrLessEquals(offsetBefore, epsilon: 2.0),
    reason: 'No positional jump allowed on mid-animation interrupt',
  );

  await gesture2.up();
  await tester.pumpAndSettle();
});
```

**`tester.pumpAndSettle` vs. `tester.pump(duration)`**: Use `pumpAndSettle()` to run a spring
animation to completion (it pumps until no more frames are pending). Use discrete `pump(duration)`
calls when you need to inspect the widget at a specific point mid-animation.

**Accessing the translation offset in tests**: `Transform.translate` does not expose its offset
through a public interface. Preferred test patterns:
1. Expose a `ValueNotifier<double> swipeOffset` from `SwipeActionCell` (test-visible field).
2. Use `tester.widget<Transform>(find.byType(Transform))` and cast its `transform` matrix.
3. Provide a test utility callback (`onOffsetChanged`) during test setup.

Option 1 is idiomatic for testable Flutter widgets and aligns with the `lib/testing.dart` entry
point the package already defines.

---

## Summary Table

| Question | Recommended Approach | Key Class/API |
|---|---|---|
| Q1: Drag + scroll | Default `GestureDetector` with `translucent` hit behavior; rely on arena | `HorizontalDragGestureRecognizer`, gesture arena |
| Q2: Spring from arbitrary position | Unbounded `AnimationController` + `SpringSimulation` in pixel space | `SpringSimulation`, `AnimationController.animateWith` |
| Q3: Interrupt mid-flight | `controller.stop()` only; read `.value`; assign directly during drag | `AnimationController.stop()`, `.value` |
| Q4: Rubber-band resistance | iOS logarithmic formula; asymptotically approaches bound | Custom `applyResistance()` function |
| Q5: Direction lock | Manual accumulation over dead-zone threshold; apply only `delta.dx` | `DragUpdateDetails.delta` |
| Q6: Release velocity | `DragEndDetails.primaryVelocity`; fallback to distance on zero | `DragEndDetails.primaryVelocity` |
| Q7: Widget test gestures | `TestGesture` via `tester.startGesture()`; pump between moves for velocity | `TestGesture`, `tester.pumpAndSettle()` |

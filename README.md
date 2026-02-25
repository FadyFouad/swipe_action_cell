# swipe_action_cell

> 🚧 **Under Development** — not yet published to pub.dev

A highly configurable Flutter swipe interaction widget with asymmetric left/right semantics:

- **Right swipe (forward):** Progressive/incremental action (e.g., increment a counter, increase progress)
- **Left swipe (backward):** Intentional committed action (e.g., delete, archive, reveal action buttons)

Spring-based physics, an explicit state machine, and zero external runtime dependencies.

## Feature Roadmap

### Phase 1 — Core

- [x] F1: Horizontal drag detection & direction discrimination
- [x] F2: Spring-based animation & snap-back/completion
- [x] F5: Background builders & progress-linked transitions
- [x] F3: Right swipe — incremental value tracking (progressive)
- [ ] F4: Left swipe — auto-trigger & reveal modes (intentional)

### Phase 2 — Production Ready

- [ ] F6: Consolidated configuration API
- [ ] F9: Gesture arena & scroll conflict resolution
- [ ] F7: `SwipeController` & group coordination
- [ ] F8: Accessibility (semantics, keyboard nav, motion sensitivity)

### Phase 3 — Advanced

- [ ] F10: Performance optimisations & large-list support
- [ ] F11: Haptic patterns & audio hooks
- [ ] F12: Undo lifecycle & revert support
- [ ] F13: Custom painter & decoration hooks

### Phase 4 — Polish

- [ ] F14: Prebuilt zero-config templates
- [ ] F15: RTL & localisation support
- [ ] F16: Theme integration
- [ ] F17: Migration guide & stable API

## Installation

```yaml
# Not yet published — add via path dependency for local development:
dependencies:
  swipe_action_cell:
    path: ../swipe_action_cell
```

## Quick Start

```dart
import 'package:swipe_action_cell/swipe_action_cell.dart';
```

### Basic swipeable cell

```dart
SwipeActionCell(
  child: ListTile(title: Text('Swipeable item')),
)
```

### With visual backgrounds

`SwipeActionBackground` provides a progress-reactive icon/label panel. The background
color darkens and the icon scales up as the user approaches the activation threshold,
with a brief bump animation at the moment the threshold is crossed.

```dart
SwipeActionCell(
  leftBackground: (progress) => SwipeActionBackground(
    icon: const Icon(Icons.delete),
    backgroundColor: const Color(0xFFE53935),
    foregroundColor: const Color(0xFFFFFFFF),
    label: 'Delete',
    progress: progress,
  ),
  rightBackground: (progress) => SwipeActionBackground(
    icon: const Icon(Icons.add),
    backgroundColor: const Color(0xFF43A047),
    foregroundColor: const Color(0xFFFFFFFF),
    progress: progress,
  ),
  child: ListTile(title: Text('Swipeable item')),
)
```

### Right-swipe progressive action (uncontrolled)

Each right swipe past the activation threshold increments an internal counter. The cell
snaps back to idle immediately — it never enters a "revealed" state.

```dart
SwipeActionCell(
  rightSwipe: ProgressiveSwipeConfig(
    stepValue: 1.0,
    maxValue: 10.0,
    overflowBehavior: OverflowBehavior.clamp,
    onProgressChanged: (newValue, oldValue) {
      print('Counter: $newValue (was $oldValue)');
    },
    onSwipeCompleted: (value) => print('Swipe done, total: $value'),
    onSwipeCancelled: () => print('Swipe cancelled'),
  ),
  child: ListTile(title: Text('Swipe right to increment')),
)
```

### Right-swipe progressive action (controlled)

Pass a non-null `value` to take ownership of the displayed value. The widget will call
`onProgressChanged` but will **not** self-update — you drive state externally.

```dart
class _MyState extends State<MyWidget> {
  double _count = 0.0;

  @override
  Widget build(BuildContext context) {
    return SwipeActionCell(
      rightSwipe: ProgressiveSwipeConfig(
        value: _count,          // non-null → controlled mode
        maxValue: 10.0,
        onProgressChanged: (newValue, _) {
          setState(() => _count = newValue);
        },
      ),
      child: ListTile(title: Text('Count: ${_count.toInt()}')),
    );
  }
}
```

### Overflow behaviors

```dart
// Clamp (default): stops at maxValue, further swipes are no-ops
ProgressiveSwipeConfig(
  maxValue: 5.0,
  overflowBehavior: OverflowBehavior.clamp,
  onMaxReached: () => print('Reached maximum!'),
)

// Wrap: resets to minValue when maxValue would be exceeded
ProgressiveSwipeConfig(
  maxValue: 5.0,
  overflowBehavior: OverflowBehavior.wrap,
  onMaxReached: () => print('Wrapped around'),
)

// Ignore: no upper bound enforced
ProgressiveSwipeConfig(
  overflowBehavior: OverflowBehavior.ignore,
)
```

### Dynamic step

Supply a callback to vary the increment per swipe based on the current value.

```dart
ProgressiveSwipeConfig(
  maxValue: 100.0,
  dynamicStep: (current) => current < 50 ? 5.0 : 10.0,
  onProgressChanged: (newValue, _) => print('Value: $newValue'),
)
```

### Progress indicator

Render a persistent colored bar on the leading edge of the cell. Requires a finite
`maxValue`.

```dart
ProgressiveSwipeConfig(
  stepValue: 1.0,
  maxValue: 10.0,
  showProgressIndicator: true,
  progressIndicatorConfig: const ProgressIndicatorConfig(
    color: Color(0xFF4CAF50),
    width: 6.0,
    backgroundColor: Color(0xFFE0E0E0),
  ),
)
```

### Haptic feedback

```dart
ProgressiveSwipeConfig(
  stepValue: 1.0,
  maxValue: 10.0,
  enableHaptic: true,   // light on threshold cross, medium on increment
)
```

### Gesture & animation tuning

```dart
SwipeActionCell(
  gestureConfig: const SwipeGestureConfig(
    deadZone: 12.0,            // px before direction locks
    velocityThreshold: 700.0,  // px/s fling threshold
    enabledDirections: {SwipeDirection.right},
  ),
  animationConfig: const SwipeAnimationConfig(
    activationThreshold: 0.4,  // 40% of max translation
    resistanceFactor: 0.55,
  ),
  child: ListTile(title: Text('Right-only swipe')),
)
```

## API Reference

### `SwipeActionCell`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `child` | `Widget` | required | The widget inside the cell |
| `gestureConfig` | `SwipeGestureConfig` | defaults | Dead zone, directions, fling velocity |
| `animationConfig` | `SwipeAnimationConfig` | defaults | Spring physics, thresholds |
| `leftBackground` | `SwipeBackgroundBuilder?` | `null` | Background for left swipe |
| `rightBackground` | `SwipeBackgroundBuilder?` | `null` | Background for right swipe |
| `rightSwipe` | `ProgressiveSwipeConfig?` | `null` | Progressive right-swipe config; `null` disables feature |
| `onStateChanged` | `ValueChanged<SwipeState>?` | `null` | State machine transition callback |
| `onProgressChanged` | `ValueChanged<SwipeProgress>?` | `null` | Per-frame drag progress |
| `enabled` | `bool` | `true` | Enable/disable all swipe interactions |
| `clipBehavior` | `Clip` | `Clip.hardEdge` | Clipping mode for child/background stack |
| `borderRadius` | `BorderRadius?` | `null` | Corner radius for clip |

### `ProgressiveSwipeConfig`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `value` | `double?` | `null` | Non-null = controlled mode; `null` = uncontrolled |
| `initialValue` | `double` | `0.0` | Starting value (uncontrolled only; clamped to range) |
| `stepValue` | `double` | `1.0` | Fixed increment per swipe (requires `> 0`) |
| `maxValue` | `double` | `double.infinity` | Upper bound |
| `minValue` | `double` | `0.0` | Lower bound and wrap-reset target |
| `overflowBehavior` | `OverflowBehavior` | `.clamp` | What happens when step would exceed `maxValue` |
| `dynamicStep` | `DynamicStepCallback?` | `null` | Overrides `stepValue`; receives current value |
| `showProgressIndicator` | `bool` | `false` | Render edge progress bar (requires finite `maxValue`) |
| `progressIndicatorConfig` | `ProgressIndicatorConfig?` | `null` | Indicator appearance |
| `enableHaptic` | `bool` | `false` | Haptic on threshold cross + increment |
| `onProgressChanged` | `ProgressChangeCallback?` | `null` | `(newValue, oldValue)` on each increment |
| `onMaxReached` | `VoidCallback?` | `null` | Fires for `clamp` and `wrap` overflow |
| `onSwipeStarted` | `VoidCallback?` | `null` | Direction locked as right swipe |
| `onSwipeCompleted` | `ValueChanged<double>?` | `null` | Animation settled after increment |
| `onSwipeCancelled` | `VoidCallback?` | `null` | Below-threshold release |

### `OverflowBehavior`

| Value | Behavior | `onMaxReached` fires? |
|-------|----------|----------------------|
| `clamp` | Value stops at `maxValue` | Yes |
| `wrap` | Value resets to `minValue` | Yes |
| `ignore` | Value grows without limit | No |

### `ProgressIndicatorConfig`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `color` | `Color` | green `0xFF4CAF50` | Fill color |
| `width` | `double` | `4.0` | Bar width in logical pixels (must be `> 0`) |
| `backgroundColor` | `Color?` | `null` | Track color behind fill; `null` = transparent |
| `borderRadius` | `BorderRadius?` | `null` | Rounded corners |

### `SwipeGestureConfig`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `deadZone` | `double` | `12.0` | Min horizontal px before direction locks |
| `enabledDirections` | `Set<SwipeDirection>` | both | Which directions are active |
| `velocityThreshold` | `double` | `700.0` | px/s to trigger completion via fling |

### `SwipeAnimationConfig`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `activationThreshold` | `double` | `0.4` | Progress ratio triggering completion on release |
| `snapBackSpring` | `SpringConfig` | preset | Physics for snap-back animation |
| `completionSpring` | `SpringConfig` | preset | Physics for open/completion animation |
| `resistanceFactor` | `double` | `0.55` | Drag resistance near max extent |
| `maxTranslationLeft` | `double?` | `null` | Max drag extent left (logical pixels) |
| `maxTranslationRight` | `double?` | `null` | Max drag extent right (logical pixels) |

## State Machine

```
idle ──drag──▶ dragging ──release above threshold──▶ animatingToOpen
                        ──release below threshold──▶ animatingToClose ──▶ idle

animatingToOpen ──[left / no rightSwipe]──▶ revealed ──drag──▶ dragging
animatingToOpen ──[right + rightSwipe]────▶ [increment] ──▶ animatingToClose ──▶ idle
```

Right swipe with `rightSwipe` configured **never enters `revealed`** — it increments
the value and snaps back to `idle` immediately.

## License

MIT

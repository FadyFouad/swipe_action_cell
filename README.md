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
- [x] F4: Left swipe — auto-trigger & reveal modes (intentional)

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

---

## Left Swipe — Intentional Action

Left swipes express deliberate, committed intent (delete, archive, reveal options). Two
mutually exclusive modes are available via `LeftSwipeMode`.

### Auto-trigger: fire a callback on swipe

The simplest left-swipe pattern. Swipe past the threshold and release → action fires once.

```dart
SwipeActionCell(
  leftSwipe: IntentionalSwipeConfig(
    mode: LeftSwipeMode.autoTrigger,
    onActionTriggered: () => print('Action fired!'),
  ),
  child: ListTile(title: Text('Swipe me left')),
)
```

### Auto-trigger with animate-out (e.g., delete)

```dart
SwipeActionCell(
  leftBackground: (context, progress) => ColoredBox(
    color: Colors.red,
    child: Align(
      alignment: Alignment.centerRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Icon(Icons.delete, color: Colors.white),
      ),
    ),
  ),
  leftSwipe: IntentionalSwipeConfig(
    mode: LeftSwipeMode.autoTrigger,
    postActionBehavior: PostActionBehavior.animateOut,
    enableHaptic: true,
    onActionTriggered: () => deleteItem(item),
  ),
  child: ListTile(title: Text(item.title)),
)
```

> **Note**: The widget does NOT collapse its height after `animateOut`. Call `setState` in
> `onActionTriggered` to remove the item from your list, then use `AnimatedList` for a
> height-collapse animation.

### Reveal mode: action panel with buttons

```dart
SwipeActionCell(
  leftSwipe: IntentionalSwipeConfig(
    mode: LeftSwipeMode.reveal,
    actions: [
      SwipeAction(
        icon: const Icon(Icons.archive),
        label: 'Archive',
        backgroundColor: const Color(0xFF43A047),
        foregroundColor: Colors.white,
        onTap: () => archiveItem(item),
      ),
      SwipeAction(
        icon: const Icon(Icons.delete),
        label: 'Delete',
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        onTap: () => deleteItem(item),
        isDestructive: true,   // requires two taps to confirm
      ),
    ],
    onPanelOpened: () => print('Panel opened'),
    onPanelClosed: () => print('Panel closed'),
  ),
  child: ListTile(title: Text(item.title)),
)
```

### Confirmation mode (require a second gesture)

```dart
SwipeActionCell(
  leftSwipe: IntentionalSwipeConfig(
    mode: LeftSwipeMode.autoTrigger,
    requireConfirmation: true,   // first swipe holds open; second fires
    onActionTriggered: () => deleteItem(item),
  ),
  child: ListTile(title: Text('Swipe twice to delete')),
)
```

### Post-action behaviors

| Value | Cell movement | Default? |
|-------|--------------|---------|
| `PostActionBehavior.snapBack` | Springs back to resting position | ✅ Yes |
| `PostActionBehavior.animateOut` | Slides off-screen to the left | No |
| `PostActionBehavior.stay` | Holds at open position; right-swipe to close | No |

---

## Right Swipe — Progressive Action

Right swipes express incremental, repeatable intent (increment a counter, increase progress).
The cell never enters a "revealed" state — it snaps back immediately after each swipe.

### Uncontrolled (internal state)

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

### Controlled (external state)

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

```dart
ProgressiveSwipeConfig(
  maxValue: 100.0,
  dynamicStep: (current) => current < 50 ? 5.0 : 10.0,
  onProgressChanged: (newValue, _) => print('Value: $newValue'),
)
```

### Progress indicator

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

---

## Both Directions Simultaneously

Right-swipe progressive and left-swipe intentional are fully independent:

```dart
SwipeActionCell(
  rightSwipe: ProgressiveSwipeConfig(
    onSwipeCompleted: (value) => print('Incremented to $value'),
  ),
  leftSwipe: IntentionalSwipeConfig(
    mode: LeftSwipeMode.autoTrigger,
    postActionBehavior: PostActionBehavior.animateOut,
    onActionTriggered: () => deleteItem(item),
  ),
  child: ListTile(title: Text('Bidirectional')),
)
```

---

## Visual Backgrounds

`SwipeActionBackground` provides a progress-reactive icon/label panel. The background
color darkens and the icon scales up as the user approaches the activation threshold,
with a brief bump animation at the threshold crossing.

```dart
SwipeActionCell(
  leftBackground: (context, progress) => SwipeActionBackground(
    icon: const Icon(Icons.delete),
    backgroundColor: const Color(0xFFE53935),
    foregroundColor: Colors.white,
    label: 'Delete',
    progress: progress,
  ),
  rightBackground: (context, progress) => SwipeActionBackground(
    icon: const Icon(Icons.add),
    backgroundColor: const Color(0xFF43A047),
    foregroundColor: Colors.white,
    progress: progress,
  ),
  child: ListTile(title: Text('Swipeable item')),
)
```

---

## Gesture & Animation Tuning

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

---

## API Reference

### `SwipeActionCell`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `child` | `Widget` | required | The widget inside the cell |
| `gestureConfig` | `SwipeGestureConfig` | defaults | Dead zone, directions, fling velocity |
| `animationConfig` | `SwipeAnimationConfig` | defaults | Spring physics, thresholds |
| `leftBackground` | `SwipeBackgroundBuilder?` | `null` | Background builder for left swipe |
| `rightBackground` | `SwipeBackgroundBuilder?` | `null` | Background builder for right swipe |
| `rightSwipe` | `ProgressiveSwipeConfig?` | `null` | Progressive right-swipe config; `null` disables |
| `leftSwipe` | `IntentionalSwipeConfig?` | `null` | Intentional left-swipe config; `null` disables |
| `onStateChanged` | `ValueChanged<SwipeState>?` | `null` | State machine transition callback |
| `onProgressChanged` | `ValueChanged<SwipeProgress>?` | `null` | Per-frame drag progress |
| `enabled` | `bool` | `true` | Enable/disable all swipe interactions |
| `clipBehavior` | `Clip` | `Clip.hardEdge` | Clipping mode for child/background stack |
| `borderRadius` | `BorderRadius?` | `null` | Corner radius for clip |

### `IntentionalSwipeConfig`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `mode` | `LeftSwipeMode` | required | `autoTrigger` or `reveal` |
| `actions` | `List<SwipeAction>` | `[]` | Buttons for reveal panel (1–3 items) |
| `actionPanelWidth` | `double?` | `null` | Panel width override; auto-calculated when `null` |
| `postActionBehavior` | `PostActionBehavior` | `.snapBack` | Cell position after auto-trigger fires |
| `requireConfirmation` | `bool` | `false` | Whether a second gesture confirms the action |
| `enableHaptic` | `bool` | `false` | Haptic on threshold cross + action execute |
| `onActionTriggered` | `VoidCallback?` | `null` | Fires when auto-trigger action executes |
| `onSwipeCancelled` | `VoidCallback?` | `null` | Below-threshold release (auto-trigger only) |
| `onPanelOpened` | `VoidCallback?` | `null` | Reveal panel animation settled open |
| `onPanelClosed` | `VoidCallback?` | `null` | Reveal panel closed (any trigger) |

### `SwipeAction`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `icon` | `Widget` | required | Icon displayed in the action button |
| `label` | `String?` | `null` | Optional text label below the icon |
| `backgroundColor` | `Color` | required | Button background color |
| `foregroundColor` | `Color` | required | Icon and label color |
| `onTap` | `VoidCallback` | required | Callback when the button is tapped |
| `isDestructive` | `bool` | `false` | Whether the action requires a two-tap confirm |
| `flex` | `int` | `1` | Relative width share in the panel |

### `ProgressiveSwipeConfig`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `value` | `double?` | `null` | Non-null = controlled mode; `null` = uncontrolled |
| `initialValue` | `double` | `0.0` | Starting value (uncontrolled only) |
| `stepValue` | `double` | `1.0` | Fixed increment per swipe (must be `> 0`) |
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

### `ProgressIndicatorConfig`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `color` | `Color` | `Color(0xFF4CAF50)` | Fill color |
| `width` | `double` | `4.0` | Bar width in logical pixels (must be `> 0`) |
| `backgroundColor` | `Color?` | `null` | Track color; `null` = transparent |
| `borderRadius` | `BorderRadius?` | `null` | Rounded corners |

---

## State Machine

```
                    ┌─────────────────────────────────────────────────────┐
                    │                                                     │
idle ──drag──▶ dragging ──release above threshold──▶ animatingToOpen      │
                        ──release below threshold──▶ animatingToClose ──▶ idle

animatingToOpen ──[left / autoTrigger]──▶ revealed ──right-drag──▶ animatingToClose ──▶ idle
                                                   ──body tap──▶ animatingToClose ──▶ idle
animatingToOpen ──[left / reveal]───────▶ revealed ──action tap──▶ animatingToClose ──▶ idle
animatingToOpen ──[right + rightSwipe]──▶ [increment] ──▶ animatingToClose ──▶ idle
animatingToOpen ──[left / animateOut]───▶ animatingOut  (slides off-screen)
```

Right swipe with `rightSwipe` configured **never enters `revealed`** — it increments
the value and snaps back to `idle` immediately.

Left swipe with `postActionBehavior: PostActionBehavior.animateOut` transitions through
`animatingOut` — remove the item from your data source in `onActionTriggered`.

---

## License

MIT

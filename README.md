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

- [x] F6: Consolidated configuration API & app-wide theme
- [x] F9: Gesture arena & scroll conflict resolution
- [x] F7: `SwipeController` & group coordination
- [x] F8: Accessibility (semantics, keyboard nav, motion sensitivity)

### Phase 3 — Advanced

- [ ] F10: Performance optimisations & large-list support
- [ ] F11: Haptic patterns & audio hooks
- [ ] F12: Undo lifecycle & revert support
- [ ] F13: Custom painter & decoration hooks

### Phase 4 — Polish

- [ ] F14: Prebuilt zero-config templates
- [ ] F15: Theme integration
- [ ] F16: Migration guide & stable API

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
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.autoTrigger,
    onActionTriggered: () => print('Action fired!'),
  ),
  child: ListTile(title: Text('Swipe me left')),
)
```

### Auto-trigger with animate-out (e.g., delete)

```dart
SwipeActionCell(
  visualConfig: SwipeVisualConfig(
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
  ),
  leftSwipeConfig: LeftSwipeConfig(
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
  leftSwipeConfig: LeftSwipeConfig(
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
  leftSwipeConfig: LeftSwipeConfig(
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
  rightSwipeConfig: RightSwipeConfig(
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
      rightSwipeConfig: RightSwipeConfig(
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
RightSwipeConfig(
  maxValue: 5.0,
  overflowBehavior: OverflowBehavior.clamp,
  onMaxReached: () => print('Reached maximum!'),
)

// Wrap: resets to minValue when maxValue would be exceeded
RightSwipeConfig(
  maxValue: 5.0,
  overflowBehavior: OverflowBehavior.wrap,
  onMaxReached: () => print('Wrapped around'),
)

// Ignore: no upper bound enforced
RightSwipeConfig(
  overflowBehavior: OverflowBehavior.ignore,
)
```

### Dynamic step

```dart
RightSwipeConfig(
  maxValue: 100.0,
  dynamicStep: (current) => current < 50 ? 5.0 : 10.0,
  onProgressChanged: (newValue, _) => print('Value: $newValue'),
)
```

### Progress indicator

```dart
RightSwipeConfig(
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
  rightSwipeConfig: RightSwipeConfig(
    onSwipeCompleted: (value) => print('Incremented to $value'),
  ),
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.autoTrigger,
    postActionBehavior: PostActionBehavior.animateOut,
    onActionTriggered: () => deleteItem(item),
  ),
  child: ListTile(title: Text('Bidirectional')),
)
```

---

## Visual Backgrounds

Visual configuration (backgrounds, clipping, border radius) is grouped into `SwipeVisualConfig`.

`SwipeActionBackground` provides a progress-reactive icon/label panel. The background
color darkens and the icon scales up as the user approaches the activation threshold,
with a brief bump animation at the threshold crossing.

```dart
SwipeActionCell(
  visualConfig: SwipeVisualConfig(
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
    borderRadius: BorderRadius.circular(12),
  ),
  child: ListTile(title: Text('Swipeable item')),
)
```

---

## Gesture & Animation Tuning

### Manual configuration

```dart
SwipeActionCell(
  gestureConfig: const SwipeGestureConfig(
    deadZone: 12.0,                   // px before direction locks
    velocityThreshold: 700.0,         // px/s fling threshold
    horizontalThresholdRatio: 1.5,    // H:V ratio to claim as horizontal
    closeOnScroll: true,              // close reveal panel on parent scroll
    respectEdgeGestures: true,        // yield to platform back-nav edge gesture
    enabledDirections: {SwipeDirection.right},
  ),
  animationConfig: const SwipeAnimationConfig(
    activationThreshold: 0.4,  // 40% of max translation
    resistanceFactor: 0.55,
  ),
  child: ListTile(title: Text('Right-only swipe')),
)
```

### Preset constructors

Four named presets are available for quick feel tuning:

```dart
// Tight: requires deliberate, longer swipes — avoids accidental triggers
SwipeActionCell(
  gestureConfig: SwipeGestureConfig.tight(),
  animationConfig: SwipeAnimationConfig.snappy(),
  // ...
)

// Loose + smooth: responds to short, light swipes with a relaxed settle
SwipeActionCell(
  gestureConfig: SwipeGestureConfig.loose(),
  animationConfig: SwipeAnimationConfig.smooth(),
  // ...
)
```

| Preset | `deadZone` | `velocityThreshold` | `horizontalThresholdRatio` |
|--------|-----------|---------------------|---------------------------|
| `SwipeGestureConfig.tight()` | 24.0 px | 1000.0 px/s | 2.5 |
| `SwipeGestureConfig.loose()` | 4.0 px | 300.0 px/s | 1.5 |

| Preset | `completionSpring.stiffness` | `activationThreshold` |
|--------|-----------------------------|-----------------------|
| `SwipeAnimationConfig.snappy()` | 700.0 | 0.3 |
| `SwipeAnimationConfig.smooth()` | 180.0 | 0.5 |

---

## App-Wide Defaults via `SwipeActionCellTheme`

Install `SwipeActionCellTheme` once at the app root and every `SwipeActionCell` in the
tree inherits the configured defaults. Per-cell config fully overrides the theme for
that parameter (no field-level merging).

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [
      SwipeActionCellTheme(
        gestureConfig: SwipeGestureConfig.loose(),
        animationConfig: SwipeAnimationConfig.smooth(),
        visualConfig: SwipeVisualConfig(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ],
  ),
  home: MyHomePage(),
)
```

### Per-cell override

```dart
// This cell uses tight gestures; all other theme settings still apply.
SwipeActionCell(
  gestureConfig: SwipeGestureConfig.tight(),
  child: ListTile(title: Text('Override gesture only')),
)
```

### Merging with `copyWith`

```dart
SwipeActionCell(
  gestureConfig: SwipeActionCellTheme.maybeOf(context)
      ?.gestureConfig
      ?.copyWith(deadZone: 8.0),
  child: ListTile(title: Text('Merge with theme')),
)
```

---

## Programmatic Control

Use `SwipeController` to open, close, or manipulate a cell from code — without a user gesture.

```dart
class _MyState extends State<MyWidget> {
  final _controller = SwipeController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwipeActionCell(
          controller: _controller,
          leftSwipeConfig: LeftSwipeConfig(
            mode: LeftSwipeMode.reveal,
            actions: [
              SwipeAction(
                icon: const Icon(Icons.delete),
                label: 'Delete',
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                onTap: () => deleteItem(),
              ),
            ],
          ),
          child: ListTile(title: Text('Controlled cell')),
        ),
        ElevatedButton(
          onPressed: () => _controller.openLeft(),
          child: const Text('Open panel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.isOpen) _controller.close();
          },
          child: const Text('Close panel'),
        ),
      ],
    );
  }
}
```

### Listening to state changes

```dart
_controller.addListener(() {
  print('State: ${_controller.currentState}');
  print('Open: ${_controller.isOpen}');
  print('Progress: ${_controller.currentProgress}');
});
```

### Programmatic progress control

```dart
// Reset the progressive counter to its initial value.
_controller.resetProgress();

// Jump to a specific value (clamped to min/max).
_controller.setProgress(5.0);
```

---

## Accordion / Group Behaviour

Ensure only one cell is open at a time across a list. All cells in the group close
automatically when any one of them opens.

### Automatic (recommended for `ListView`)

Wrap the list in `SwipeControllerProvider` — cells register and deregister themselves
as they scroll in and out of view.

```dart
SwipeControllerProvider(
  child: ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) => SwipeActionCell(
      leftSwipeConfig: LeftSwipeConfig(
        mode: LeftSwipeMode.reveal,
        actions: [
          SwipeAction(
            icon: const Icon(Icons.archive),
            label: 'Archive',
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            onTap: () => archiveItem(items[index]),
          ),
        ],
      ),
      child: ListTile(title: Text(items[index].title)),
    ),
  ),
)
```

### Manual (explicit controller management)

```dart
class _MyState extends State<MyWidget> {
  final _group = SwipeGroupController();
  late final List<SwipeController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (_) => SwipeController());
    for (final c in _controllers) {
      _group.register(c);
    }
  }

  @override
  void dispose() {
    _group.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }
}
```

### Close all programmatically

```dart
// Close every open cell in the group.
_group.closeAll();

// Close all except a specific controller.
_group.closeAllExcept(_controllers[0]);
```

---

## Accessibility & Screen Readers

`SwipeActionCell` is fully accessible out of the box. When enabled, screen readers
see custom actions in their action menu, and the cell responds to arrow keys.

### Default behaviour (no config required)

- Screen readers announce direction-adaptive action labels automatically (e.g.,
  "Swipe right to progress" / "Swipe left for actions" in LTR;  reversed in RTL).
- Arrow keys trigger the corresponding action (→ for forward, ← for backward in LTR).
- **Escape** closes any open reveal panel and returns focus to the cell.
- When the system `reduceMotion` / `disableAnimations` flag is set, all spring
  animations are replaced with instant jumps.

### Custom labels

```dart
SwipeActionCell(
  semanticConfig: SwipeSemanticConfig(
    cellLabel: SemanticLabel.string('Task item'),
    rightSwipeLabel: SemanticLabel.string('Mark as done'),
    leftSwipeLabel: SemanticLabel.string('Delete task'),
    panelOpenLabel: SemanticLabel.string('Actions menu open'),
  ),
  rightSwipeConfig: RightSwipeConfig(
    onSwipeCompleted: (value) => markDone(item),
  ),
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.reveal,
    actions: [...],
  ),
  child: ListTile(title: Text(item.title)),
)
```

### Locale-aware labels via builder

```dart
SwipeActionCell(
  semanticConfig: SwipeSemanticConfig(
    rightSwipeLabel: SemanticLabel.builder(
      (context) => AppLocalizations.of(context)!.markDone,
    ),
    leftSwipeLabel: SemanticLabel.builder(
      (context) => AppLocalizations.of(context)!.deleteItem,
    ),
    progressAnnouncementBuilder: (current, max) =>
        '${current.toInt()} of ${max.toInt()} completed',
  ),
  child: ListTile(title: Text(item.title)),
)
```

---

## RTL & Bidirectional Support

`SwipeActionCell` automatically mirrors its swipe semantics when placed in an RTL
`Directionality` context. No extra configuration is needed for basic RTL support.

### Semantic direction aliases (recommended for RTL-aware apps)

Use `forwardSwipeConfig` / `backwardSwipeConfig` instead of `rightSwipeConfig` /
`leftSwipeConfig`. These aliases adapt to the ambient text direction:

- In **LTR**: `forwardSwipeConfig` → right swipe; `backwardSwipeConfig` → left swipe.
- In **RTL**: `forwardSwipeConfig` → left swipe; `backwardSwipeConfig` → right swipe.

```dart
SwipeActionCell(
  // Works correctly in both LTR and RTL without any additional changes.
  forwardSwipeConfig: RightSwipeConfig(
    onSwipeCompleted: (value) => incrementCounter(value),
  ),
  backwardSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.autoTrigger,
    onActionTriggered: () => deleteItem(item),
  ),
  child: ListTile(title: Text(item.title)),
)
```

### Force a specific direction

Override the ambient `Directionality` for a single cell:

```dart
SwipeActionCell(
  forceDirection: ForceDirection.ltr,   // or ForceDirection.rtl
  rightSwipeConfig: RightSwipeConfig(...),
  child: ListTile(title: Text('Always LTR')),
)
```

---

## API Reference

### `SwipeActionCell`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `child` | `Widget` | required | The widget inside the cell |
| `rightSwipeConfig` | `RightSwipeConfig?` | `null` | Progressive right-swipe config; `null` disables |
| `leftSwipeConfig` | `LeftSwipeConfig?` | `null` | Intentional left-swipe config; `null` disables |
| `forwardSwipeConfig` | `RightSwipeConfig?` | `null` | Direction-agnostic alias for right-swipe config (LTR) / left-swipe config (RTL); takes precedence over `rightSwipeConfig` |
| `backwardSwipeConfig` | `LeftSwipeConfig?` | `null` | Direction-agnostic alias for left-swipe config (LTR) / right-swipe config (RTL); takes precedence over `leftSwipeConfig` |
| `forceDirection` | `ForceDirection` | `.auto` | Override ambient `Directionality`; `.auto` reads from context |
| `semanticConfig` | `SwipeSemanticConfig?` | `null` | Custom accessibility labels and screen reader announcements |
| `gestureConfig` | `SwipeGestureConfig?` | theme → defaults | Dead zone, directions, fling velocity |
| `animationConfig` | `SwipeAnimationConfig?` | theme → defaults | Spring physics, thresholds |
| `visualConfig` | `SwipeVisualConfig?` | theme → none | Backgrounds, clip behavior, border radius |
| `controller` | `SwipeController?` | `null` | External controller for programmatic open/close/progress |
| `onStateChanged` | `ValueChanged<SwipeState>?` | `null` | State machine transition callback |
| `onProgressChanged` | `ValueChanged<SwipeProgress>?` | `null` | Per-frame drag progress |
| `enabled` | `bool` | `true` | Enable/disable all swipe interactions |

### `RightSwipeConfig`

Renamed from `ProgressiveSwipeConfig` in F6. All fields and semantics are preserved.

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

### `LeftSwipeConfig`

Renamed from `IntentionalSwipeConfig` in F6. All fields and semantics are preserved.

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

### `SwipeVisualConfig`

Consolidates `leftBackground`, `rightBackground`, `clipBehavior`, and `borderRadius` from the old flat API.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `leftBackground` | `SwipeBackgroundBuilder?` | `null` | Background builder for left swipe |
| `rightBackground` | `SwipeBackgroundBuilder?` | `null` | Background builder for right swipe |
| `clipBehavior` | `Clip` | `Clip.hardEdge` | Clipping mode for child/background stack |
| `borderRadius` | `BorderRadius?` | `null` | Corner radius for clip |

### `SwipeActionCellTheme`

A `ThemeExtension<SwipeActionCellTheme>` installed in `ThemeData.extensions`. All fields are optional — a `null` field means "no theme default; fall back to package defaults".

| Field | Type | Description |
|-------|------|-------------|
| `rightSwipeConfig` | `RightSwipeConfig?` | Default right-swipe config for all cells |
| `leftSwipeConfig` | `LeftSwipeConfig?` | Default left-swipe config for all cells |
| `gestureConfig` | `SwipeGestureConfig?` | Default gesture config for all cells |
| `animationConfig` | `SwipeAnimationConfig?` | Default animation config for all cells |
| `visualConfig` | `SwipeVisualConfig?` | Default visual config for all cells |

Use `SwipeActionCellTheme.maybeOf(context)` to read the nearest theme instance.

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
| `horizontalThresholdRatio` | `double` | `1.5` | Min H:V displacement ratio to claim as horizontal; must be `>= 1.0` |
| `closeOnScroll` | `bool` | `true` | Close open reveal panel when the user begins scrolling a parent `Scrollable` |
| `respectEdgeGestures` | `bool` | `true` | Yield to the 20 px platform back-navigation edge zone |

Named presets: `SwipeGestureConfig.tight()`, `SwipeGestureConfig.loose()`

### `SwipeAnimationConfig`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `activationThreshold` | `double` | `0.4` | Progress ratio (0.0–1.0) triggering completion on release |
| `snapBackSpring` | `SpringConfig` | preset | Physics for snap-back animation |
| `completionSpring` | `SpringConfig` | preset | Physics for open/completion animation |
| `resistanceFactor` | `double` | `0.55` | Drag resistance near max extent |
| `maxTranslationLeft` | `double?` | `null` | Max drag extent left (logical pixels) |
| `maxTranslationRight` | `double?` | `null` | Max drag extent right (logical pixels) |

Named presets: `SwipeAnimationConfig.snappy()`, `SwipeAnimationConfig.smooth()`

### `ProgressIndicatorConfig`

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `color` | `Color` | `Color(0xFF4CAF50)` | Fill color |
| `width` | `double` | `4.0` | Bar width in logical pixels (must be `> 0`) |
| `backgroundColor` | `Color?` | `null` | Track color; `null` = transparent |
| `borderRadius` | `BorderRadius?` | `null` | Rounded corners |

### `SwipeController`

Controls a single attached `SwipeActionCell` programmatically. Implements `ChangeNotifier`.

**Observable properties:**

| Property | Type | Description |
|----------|------|-------------|
| `currentState` | `SwipeState` | The cell's current state machine state |
| `currentProgress` | `double` | Cumulative progressive value (`rightSwipeConfig` only) |
| `isOpen` | `bool` | `true` when `currentState == SwipeState.revealed` |
| `openDirection` | `SwipeDirection?` | Direction the cell is open in; `null` when closed |

**Commands:**

| Method | Description |
|--------|-------------|
| `openLeft()` | Trigger a left-swipe open (asserts from `idle` state) |
| `openRight()` | Trigger a right-swipe increment (asserts from `idle` state) |
| `close()` | Snap the cell closed (valid from `revealed` or `animatingToOpen`) |
| `resetProgress()` | Reset the progressive value to `initialValue` |
| `setProgress(double value)` | Set the progressive value, clamped to `[minValue, maxValue]` |
| `dispose()` | Release resources; call in `State.dispose` |

### `SwipeGroupController`

Coordinates multiple `SwipeController` instances for accordion behaviour.

| Method | Description |
|--------|-------------|
| `register(SwipeController)` | Add a controller to the group |
| `unregister(SwipeController)` | Remove a controller from the group |
| `closeAll()` | Close every open registered cell |
| `closeAllExcept(SwipeController)` | Close all open cells except the given controller |
| `dispose()` | Remove all listeners and release resources |

### `SwipeControllerProvider`

An `InheritedWidget` that automatically registers and deregisters `SwipeActionCell`
descendants with a shared `SwipeGroupController`.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `child` | `Widget` | required | The subtree containing `SwipeActionCell` widgets |
| `groupController` | `SwipeGroupController?` | `null` | External group controller; when `null`, an internal one is created and managed automatically |

Use `SwipeControllerProvider.maybeGroupOf(context)` to read the nearest group controller.

### `SwipeSemanticConfig`

Configures accessibility labels and screen reader announcements for a single `SwipeActionCell`.
All fields are optional — omitted fields fall back to direction-adaptive built-in defaults.

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `cellLabel` | `SemanticLabel?` | `null` | Label announced when the screen reader focuses the cell |
| `rightSwipeLabel` | `SemanticLabel?` | adaptive | Label for the forward-swipe custom action in the screen reader menu |
| `leftSwipeLabel` | `SemanticLabel?` | adaptive | Label for the backward-swipe custom action in the screen reader menu |
| `panelOpenLabel` | `SemanticLabel?` | `"Action panel open"` | Announcement spoken when the reveal panel opens |
| `progressAnnouncementBuilder` | `String Function(double current, double max)?` | auto | Override the automatic "Progress incremented to N of M" announcement |

### `SemanticLabel`

A const-constructable wrapper for an accessibility label that is either a static string
or a context-aware builder.

| Constructor | Description |
|-------------|-------------|
| `SemanticLabel.string(String value)` | Static label string |
| `SemanticLabel.builder(String Function(BuildContext) builder)` | Locale-aware label resolved at build time |

### `ForceDirection`

Controls how `SwipeActionCell` resolves its effective text direction.

| Value | Description |
|-------|-------------|
| `ForceDirection.auto` | Reads `Directionality.of(context)` (default) |
| `ForceDirection.ltr` | Forces left-to-right regardless of ambient directionality |
| `ForceDirection.rtl` | Forces right-to-left regardless of ambient directionality |

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
animatingToOpen ──[right + rightSwipeConfig]──▶ [increment] ──▶ animatingToClose ──▶ idle
animatingToOpen ──[left / animateOut]───▶ animatingOut  (slides off-screen)
```

Right swipe with `rightSwipeConfig` configured **never enters `revealed`** — it increments
the value and snaps back to `idle` immediately.

Left swipe with `postActionBehavior: PostActionBehavior.animateOut` transitions through
`animatingOut` — remove the item from your data source in `onActionTriggered`.

---

## Migration from Pre-F6 API

| Old parameter | New parameter |
|--------------|--------------|
| `rightSwipe: ProgressiveSwipeConfig(...)` | `rightSwipeConfig: RightSwipeConfig(...)` |
| `leftSwipe: IntentionalSwipeConfig(...)` | `leftSwipeConfig: LeftSwipeConfig(...)` |
| `leftBackground: builder` | `visualConfig: SwipeVisualConfig(leftBackground: builder)` |
| `rightBackground: builder` | `visualConfig: SwipeVisualConfig(rightBackground: builder)` |
| `clipBehavior: clip` | `visualConfig: SwipeVisualConfig(clipBehavior: clip)` |
| `borderRadius: radius` | `visualConfig: SwipeVisualConfig(borderRadius: radius)` |

---

## License

MIT

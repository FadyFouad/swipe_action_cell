# swipe_action_cell

[![pub.dev](https://img.shields.io/pub/v/swipe_action_cell.svg)](https://pub.dev/packages/swipe_action_cell)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android%20%7C%20Web%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-lightgrey.svg)](https://pub.dev/packages/swipe_action_cell)

> A Flutter list-cell widget with **asymmetric swipe semantics** — right swipe increments a value progressively, left swipe commits a destructive or reveal action.

![Reveal actions](https://raw.githubusercontent.com/FadyFouad/swipe_action_cell/main/doc/assets/demo-swipe-reveal.gif)
![Multi-action panel](https://raw.githubusercontent.com/FadyFouad/swipe_action_cell/main/doc/assets/demo-multi-action.gif)
![Full-swipe expansion](https://raw.githubusercontent.com/FadyFouad/swipe_action_cell/main/doc/assets/demo-full-swipe.gif)

## Features

- **Asymmetric swipe model** — right swipe is progressive (increment/counter), left swipe is intentional (delete/archive/reveal)
- **Spring-based physics** — natural feel with configurable spring stiffness and damping, not fixed-duration animations
- **Built-in undo** — 5-second undo window before a destructive action fires, cancelable programmatically
- **Reveal mode** — left swipe slides open a panel of 1–3 tappable action buttons

  ![Swipe reveal](https://raw.githubusercontent.com/FadyFouad/swipe_action_cell/main/doc/assets/demo-swipe-reveal.gif)

- **Multi-action panel** — reveal up to 3 actions simultaneously; swipe further to expand the primary action to fill the cell

  ![Multi-action panel](https://raw.githubusercontent.com/FadyFouad/swipe_action_cell/main/doc/assets/demo-multi-action.gif)

- **Full-swipe auto-trigger** — drag all the way across to instantly commit the primary action without tapping; the designated action expands to fill the panel as you approach the threshold

  ![Full-swipe expansion](https://raw.githubusercontent.com/FadyFouad/swipe_action_cell/main/doc/assets/demo-full-swipe.gif)

- **Multi-zone swipes** — up to 4 distinct threshold zones per direction, each with its own visual and callback
- **Zero-config templates** — six prebuilt factory constructors (`.delete`, `.archive`, `.favorite`, `.checkbox`, `.counter`, `.standard`) work out of the box
- **Accessibility and RTL** — semantic labels, keyboard navigation, and direction-adaptive swipe semantics for right-to-left layouts
- **Consumer testing utilities** — `SwipeTester`, `SwipeAssertions`, `MockSwipeController`, and `SwipeTestHarness` for deterministic widget tests

## Quick Start

```dart
import 'package:swipe_action_cell/swipe_action_cell.dart';

SwipeActionCell.delete(
  child: const ListTile(title: Text('Left swipe to delete')),
  onDeleted: () => print('Deleted!'),
)
```

## Installation

```yaml
dependencies:
  swipe_action_cell: ^1.1.1
```

Or run:

```bash
flutter pub add swipe_action_cell
```

## Platform Support

| Platform | Support | Min Flutter |
|---|---|---|
| iOS | ✅ | 3.22.0 |
| Android | ✅ | 3.22.0 |
| Web | ✅ | 3.22.0 |
| macOS | ✅ | 3.22.0 |
| Windows | ✅ | 3.22.0 |
| Linux | ✅ | 3.22.0 |

## Configuration Reference

| Parameter | Type | Default | Description |
|---|---|---|---|
| `child` | `Widget` | required | The list item widget displayed in the cell |
| `leftSwipeConfig` | `LeftSwipeConfig?` | `null` | Left-swipe behavior (auto-trigger or reveal mode). `null` disables left swipe |
| `rightSwipeConfig` | `RightSwipeConfig?` | `null` | Right-swipe progressive behavior. `null` disables right swipe |
| `controller` | `SwipeController?` | `null` | External controller for programmatic open/close/undo |
| `visualConfig` | `SwipeVisualConfig?` | `null` | Background builders, clip behavior, border radius |
| `gestureConfig` | `SwipeGestureConfig?` | `null` | Activation threshold, direction lock angle |
| `animationConfig` | `SwipeAnimationConfig?` | `null` | Spring stiffness, damping, mass |
| `feedbackConfig` | `SwipeFeedbackConfig?` | `null` | Haptic and audio patterns at swipe milestones |
| `undoConfig` | `SwipeUndoConfig?` | `null` | Undo window duration and callbacks |
| `paintingConfig` | `SwipePaintingConfig?` | `null` | Custom painter and decoration hooks |
| `enabled` | `bool` | `true` | Disables all gesture recognition when `false` |
| `semanticConfig` | `SwipeSemanticConfig?` | `null` | Accessibility labels and announcements |

### LeftSwipeConfig

| Parameter | Type | Default | Description |
|---|---|---|---|
| `mode` | `LeftSwipeMode` | required | `.autoTrigger` fires callback; `.reveal` opens action panel |
| `actions` | `List<SwipeAction>` | `[]` | Action buttons shown in reveal mode (1–3 items) |
| `actionPanelWidth` | `double?` | `null` | Panel width in logical pixels; auto-calculated when `null` |
| `postActionBehavior` | `PostActionBehavior` | `.snapBack` | What happens after auto-trigger fires |
| `enableHaptic` | `bool` | `false` | Haptic feedback at activation threshold |

### FullSwipeConfig

Attach to either `LeftSwipeConfig.fullSwipeConfig` or `RightSwipeConfig.fullSwipeConfig` to enable the full-swipe auto-trigger and expand animation.

| Parameter | Type | Default | Description |
|---|---|---|---|
| `enabled` | `bool` | required | Activates full-swipe behavior for this direction |
| `threshold` | `double` | `0.75` | Fraction of widget width at which the full-swipe fires (must exceed `activationThreshold`) |
| `action` | `SwipeAction` | required | The action triggered on full swipe; should match one of the reveal `actions` |
| `expandAnimation` | `bool` | `false` | Animates the designated action expanding to fill the panel as the threshold approaches |
| `enableHaptic` | `bool` | `false` | Haptic pulse when the full-swipe threshold is crossed |
| `fullSwipeProgressBehavior` | `FullSwipeProgressBehavior` | `.customAction` | Right-swipe only: `.setToMax` or `.customAction` |

**Example — multi-action reveal with full-swipe expansion:**

```dart
SwipeActionCell(
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.reveal,
    actions: [
      SwipeAction(
        icon: const Icon(Icons.flag),
        label: 'Flag',
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        onTap: () {},
      ),
      SwipeAction(
        icon: const Icon(Icons.delete),
        label: 'Delete',
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        onTap: () {},
      ),
    ],
    fullSwipeConfig: FullSwipeConfig(
      enabled: true,
      threshold: 0.8,
      expandAnimation: true,   // actions start equal; Delete expands on further drag
      action: SwipeAction(
        icon: const Icon(Icons.delete),
        label: 'Delete',
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        onTap: () => _delete(),
      ),
    ),
  ),
  child: const ListTile(title: Text('Swipe left')),
)
```

### RightSwipeConfig

| Parameter | Type | Default | Description |
|---|---|---|---|
| `stepValue` | `double` | `1.0` | Amount added on each successful right swipe |
| `maxValue` | `double` | `infinity` | Upper bound for the cumulative value |
| `overflowBehavior` | `OverflowBehavior` | `.clamp` | What happens when `maxValue` is reached |
| `showProgressIndicator` | `bool` | `false` | Renders a persistent progress bar |
| `onSwipeCompleted` | `ValueChanged<double>?` | `null` | Called after each successful swipe with the new value |
| `enableHaptic` | `bool` | `false` | Haptic feedback at activation threshold |

## swipe_action_cell vs flutter_slidable

| Feature | swipe_action_cell | flutter_slidable |
|---|---|---|
| Swipe model | Asymmetric — right = progressive, left = intentional | Symmetric — both sides show action panels |
| Built-in undo | ✅ 5-second undo window before destructive callback | ❌ Must implement manually with `DismissiblePane` |
| Animation physics | Spring-based (`SpringSimulation`) — natural feel | Fixed-duration `Tween` — linear/curve based |
| Right-swipe behavior | Progressive counter/value increment with real-time tracking | Reveal action panel (same as left swipe) |
| Prebuilt templates | ✅ Six zero-config constructors | ❌ Manual configuration required |
| Consumer testing | ✅ `SwipeTester`, `SwipeAssertions`, `MockSwipeController` | ❌ No dedicated testing utilities |
| Multi-zone swipes | ✅ Up to 4 zones per direction | ❌ Single threshold only |
| Reveal motion | Fixed-position panel reveal | Animated panel with `DrawerMotion`, `ScrollMotion`, etc. |
| Custom extent ratio per action | ❌ Shared panel width | ✅ Per-action `extentRatio` |

## Documentation & Links

- [API reference on pub.dev](https://pub.dev/documentation/swipe_action_cell/latest/)
- [Example app source](https://github.com/FadyFouad/swipe_action_cell/tree/main/example)

[//]: # (- [Migration guide from flutter_slidable]&#40;MIGRATION.md&#41;)
- [Changelog](CHANGELOG.md)

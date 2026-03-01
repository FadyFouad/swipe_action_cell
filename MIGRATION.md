# Migrating from flutter_slidable to swipe_action_cell

## Overview

`swipe_action_cell` uses an **asymmetric swipe model** — right swipe is a progressive incremental action (counter, toggle, value tracking) while left swipe is an intentional committed action (delete, archive, or reveal a panel). This differs fundamentally from `flutter_slidable`, where both directions reveal symmetric action panels.

The key practical differences are: a built-in undo window for destructive left-swipe actions (no `Dismissible` workaround needed), spring-based physics instead of fixed-duration tweens, and a `SwipeGroupController` that replaces `SlidableAutoCloseBehavior` with a simpler registration API.

## Installation

**Before** (`flutter_slidable`):

```yaml
dependencies:
  flutter_slidable: ^3.0.0
```

**After** (`swipe_action_cell`):

```yaml
dependencies:
  swipe_action_cell: ^1.0.0
```

## API Mapping

| flutter_slidable (v3.x) | swipe_action_cell (v1.0.0) | Notes |
|---|---|---|
| `Slidable(child: ...)` | `SwipeActionCell(child: ...)` | Same composition pattern |
| `ActionPane(endActionPane:...)` | `leftSwipeConfig: LeftSwipeConfig(...)` | End = left in LTR |
| `ActionPane(startActionPane:...)` | `rightSwipeConfig: RightSwipeConfig(...)` | Start = right in LTR |
| `SlidableAction(onPressed: ..., icon: ..., label: ...)` | `SwipeAction(icon: Widget, label: String, onTap: ...)` | `icon` is a `Widget`, not `IconData` |
| `SlidableController` | `SwipeController` | Same programmatic API shape |
| `SlidableAutoCloseBehavior` | `SwipeGroupController` | Register controllers explicitly |
| `DismissiblePane(onDismissed: ...)` | `LeftSwipeConfig(mode: LeftSwipeMode.autoTrigger)` + `SwipeUndoConfig(onUndoExpired: ...)` | Adds 5-second undo window |

## Behavioral Differences

- **Asymmetric semantics**: In `flutter_slidable`, both sides show action panels. In `swipe_action_cell`, the right swipe is a repeatable progressive action (counter/increment), not a panel. Left swipe is the intentional committed action.
- **Built-in undo**: `swipe_action_cell` provides a 5-second undo strip via `SwipeUndoConfig` for destructive left swipes. With `flutter_slidable` + `DismissiblePane`, you implement undo yourself.
- **Spring physics**: Animations use `SpringSimulation` (configurable stiffness/damping) rather than fixed-duration `Tween` animations. The cell snaps back with a natural bounce.
- **Group controller**: `SwipeGroupController` requires explicit `register(controller)` calls. `SlidableAutoCloseBehavior` works as a widget wrapper — no registration needed. Use `SwipeControllerProvider` in a `ListView` to get automatic registration.
- **Consumer testing utilities**: `swipe_action_cell` ships `SwipeTester`, `SwipeAssertions`, `MockSwipeController`, and `SwipeTestHarness` in a separate `package:swipe_action_cell/testing.dart` import. `flutter_slidable` has no equivalent.

## Code Examples

### Example 1: Basic Reveal Action

**Before** (`flutter_slidable`):

```dart
import 'package:flutter_slidable/flutter_slidable.dart';

Slidable(
  endActionPane: ActionPane(
    motion: const ScrollMotion(),
    children: [
      SlidableAction(
        onPressed: (_) => archive(item),
        icon: Icons.archive,
        label: 'Archive',
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
      ),
    ],
  ),
  child: ListTile(title: Text(item.title)),
)
```

**After** (`swipe_action_cell`):

```dart
import 'package:swipe_action_cell/swipe_action_cell.dart';

SwipeActionCell(
  // endActionPane (left swipe in LTR) → leftSwipeConfig
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.reveal,
    actions: [
      SwipeAction(
        // icon is a Widget, not IconData
        icon: const Icon(Icons.archive),
        label: 'Archive',
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        onTap: () => archive(item),
      ),
    ],
  ),
  child: ListTile(title: Text(item.title)),
)
```

### Example 2: Delete with Undo

**Before** (`flutter_slidable` + `DismissiblePane`):

```dart
import 'package:flutter_slidable/flutter_slidable.dart';

Slidable(
  endActionPane: ActionPane(
    motion: const DrawerMotion(),
    dismissible: DismissiblePane(
      onDismissed: () => deleteItem(item),
    ),
    children: [
      SlidableAction(
        onPressed: (_) {},
        icon: Icons.delete,
        label: 'Delete',
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
    ],
  ),
  child: ListTile(title: Text(item.title)),
)
```

**After** (`swipe_action_cell` with built-in undo):

```dart
import 'package:swipe_action_cell/swipe_action_cell.dart';

// Use the factory constructor for zero-config delete with undo:
SwipeActionCell.delete(
  onDeleted: () => deleteItem(item),  // fires after 5-second undo window
  child: ListTile(title: Text(item.title)),
)

// Or manually configure for full control:
SwipeActionCell(
  leftSwipeConfig: const LeftSwipeConfig(
    mode: LeftSwipeMode.autoTrigger,
    postActionBehavior: PostActionBehavior.animateOut,
    enableHaptic: true,
  ),
  undoConfig: SwipeUndoConfig(
    windowDuration: const Duration(seconds: 5),
    onUndoExpired: () => deleteItem(item),  // fires after window
  ),
  child: ListTile(title: Text(item.title)),
)
```

## Features not in swipe_action_cell

The following `flutter_slidable` features have no direct equivalent:

- **Motion animations** (`ScrollMotion`, `DrawerMotion`, `BehindMotionAnimation`) — `swipe_action_cell` uses a fixed-position reveal panel without panel-sliding animations during the drag.
- **Per-action `extentRatio`** — all actions share the reveal panel width in `swipe_action_cell`; width is auto-calculated from action count or set via `LeftSwipeConfig.actionPanelWidth`.
- **`SlidableAction.autoClose`** — closing is managed externally via `SwipeGroupController` or by calling `controller.close()`.
- **Right-side reveal panel with action buttons** — in `swipe_action_cell`, right swipe is always a progressive action (counter/toggle), not a reveal panel.

## Features not in flutter_slidable

The following features are unique to `swipe_action_cell`:

- **Progressive right swipe** — real-time value tracking, step increments, multi-threshold zones, and `onSwipeCompleted` callbacks for counter/progress patterns.
- **Built-in undo window** — `SwipeUndoConfig` provides a configurable countdown strip; destructive callbacks fire only after the window expires or is explicitly committed.
- **Spring-based physics** — natural deceleration and snap-back via `SpringSimulation`; configurable stiffness, damping, and mass via `SwipeAnimationConfig`.
- **Prebuilt zero-config templates** — `SwipeActionCell.delete`, `.archive`, `.favorite`, `.checkbox`, `.counter`, `.standard` require only a callback and a child widget.
- **Consumer testing utilities** — `SwipeTester`, `SwipeAssertions`, `MockSwipeController`, and `SwipeTestHarness` are available in a separate `package:swipe_action_cell/testing.dart` import for deterministic widget tests.
- **Multi-zone swipes** — up to 4 named threshold zones per direction, each with its own background, semantic label, step value, and haptic pattern.

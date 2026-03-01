# Quickstart: Left-Swipe Intentional Action (F004)

**Branch**: `004-intentional-action` | **Package**: `swipe_action_cell`

---

## Installation

This feature is part of the `swipe_action_cell` package. No additional dependencies are required.

```yaml
# pubspec.yaml
dependencies:
  flutter:
    sdk: flutter
```

## Import

```dart
import 'package:swipe_action_cell/swipe_action_cell.dart';
```

---

## Minimal Examples

### Auto-Trigger: Fire a callback on left swipe

The simplest left-swipe pattern. Swipe left past the threshold → action fires immediately.

```dart
SwipeActionCell(
  leftSwipe: IntentionalSwipeConfig(
    mode: LeftSwipeMode.autoTrigger,
    onActionTriggered: () => print('Action fired!'),
  ),
  child: ListTile(title: Text('Swipe me left')),
)
```

### Auto-Trigger with Animate-Out (e.g., delete)

```dart
SwipeActionCell(
  leftBackground: (context, progress) => ColoredBox(
    color: Colors.red,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ],
    ),
  ),
  leftSwipe: IntentionalSwipeConfig(
    mode: LeftSwipeMode.autoTrigger,
    postActionBehavior: PostActionBehavior.animateOut,
    enableHaptic: true,
    onActionTriggered: () => myModel.deleteItem(item),
  ),
  child: ListTile(title: Text(item.title)),
)
```

> **Note**: The widget does NOT collapse its height after `animateOut`. Call `setState` in
> `onActionTriggered` to remove the item from your list, then use `AnimatedList` if you want
> a height-collapse animation.

### Reveal Mode: Action Panel with Buttons

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
        isDestructive: true,
      ),
    ],
    onPanelOpened: () => print('Panel opened'),
    onPanelClosed: () => print('Panel closed'),
  ),
  child: ListTile(title: Text(item.title)),
)
```

---

## Key Concepts

### Two Mutually Exclusive Modes

| Mode | Trigger | Outcome |
|------|---------|---------|
| `autoTrigger` | Swipe past threshold + release | Fires `onActionTriggered` once |
| `reveal` | Swipe past threshold + release | Opens action panel at target width |

### Post-Action Behavior (auto-trigger only)

| Value | Cell movement | Default? |
|-------|--------------|---------|
| `snapBack` | Springs back to resting position | ✅ Yes |
| `animateOut` | Slides off-screen to the left | No |
| `stay` | Holds at open position; user right-swipes to close | No |

### Destructive Actions (reveal mode)

Mark an action as `isDestructive: true` to require a two-tap confirm:
1. **First tap**: Button expands to fill the full panel width.
2. **Second tap**: `onTap` fires and the panel closes.
3. **Tap elsewhere** after expansion: Collapses without firing.

### Confirmation Mode (auto-trigger only)

Set `requireConfirmation: true` to require a second gesture before the action fires:
1. **First swipe** past threshold: Cell holds at open position.
2. **Second left swipe** or **tap on leftBackground area**: Action fires.
3. **Right swipe** or **tap on cell body**: Cancels back to idle.

### Both Directions Simultaneously

Right-swipe progressive (F3) and left-swipe intentional (F4) are fully independent:

```dart
SwipeActionCell(
  rightSwipe: ProgressiveSwipeConfig(
    onSwipeCompleted: (value, previous) => print('Incremented to $value'),
  ),
  leftSwipe: IntentionalSwipeConfig(
    mode: LeftSwipeMode.autoTrigger,
    onActionTriggered: () => print('Left action fired'),
  ),
  child: ListTile(title: Text('Bidirectional')),
)
```

### Disabling Left-Swipe

Pass `leftSwipe: null` (or omit it) to disable all left-swipe intentional behavior with
zero overhead. The `leftBackground` builder still applies for visual feedback if provided.

---

## API Summary

| Type | Role |
|------|------|
| `IntentionalSwipeConfig` | Configuration object passed to `SwipeActionCell.leftSwipe` |
| `LeftSwipeMode` | Enum: `autoTrigger` or `reveal` |
| `PostActionBehavior` | Enum: `snapBack`, `animateOut`, or `stay` |
| `SwipeAction` | Immutable data class defining a single action button |
| `SwipeActionPanel` | Internal widget rendering the reveal panel; exported for custom layouts |
| `SwipeState.animatingOut` | New state: cell sliding off-screen after `animateOut` |

---

## See Also

- `spec.md` — Full feature specification and user scenarios
- `data-model.md` — Entity definitions and updated state machine
- `contracts/intentional-api.md` — Complete Dart API signatures
- `research.md` — Technical decisions and rationale

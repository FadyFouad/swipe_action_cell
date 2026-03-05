# Quickstart: Swipe Action Undo/Revert Support (F011)

**Branch**: `011-swipe-undo` | **Package**: `swipe_action_cell`

---

## Overview

F011 adds a time-limited undo mechanism to `SwipeActionCell`. After a swipe action fires, a
configurable window stays open during which the user can revert the action. After the window
expires, the action is committed permanently.

**Opt-in**: Pass `undoConfig: SwipeUndoConfig(...)` to enable. Omitting it (or passing `null`)
leaves zero overhead — no timer allocated, no overlay rendered.

---

## Minimal Example — Built-In Overlay with Callbacks

```dart
SwipeActionCell(
  undoConfig: SwipeUndoConfig(
    duration: const Duration(seconds: 5),
    onUndoExpired: () {
      // Action committed permanently — execute side effect here
      _deleteItem(item);
    },
    onUndoTriggered: () {
      // Undo was triggered — data is already reverted by the package
      // for animateOut; for snapBack/stay, revert your data here
    },
  ),
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.autoTrigger,
    postActionBehavior: PostActionBehavior.animateOut,
  ),
  visualConfig: SwipeVisualConfig(
    leftBackground: (ctx, p) => ColoredBox(
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
  child: ListTile(title: Text(item.title)),
)
```

> **Pattern for `animateOut`**: Move the permanent side effect (API call, state update) into
> `onUndoExpired`. If the user undoes, `onUndoExpired` never fires and the widget animates back.
> `onActionTriggered` is no longer the place to commit — it fires before the undo window opens.

---

## Customise the Built-In Overlay

```dart
undoConfig: SwipeUndoConfig(
  duration: const Duration(seconds: 8),
  overlayConfig: const SwipeUndoOverlayConfig(
    position: SwipeUndoOverlayPosition.top,
    actionLabel: 'Deleted',
    undoButtonLabel: 'Undo',
    backgroundColor: Color(0xFF212121),
    textColor: Colors.white,
    buttonColor: Color(0xFFFFCC02),
    progressBarColor: Color(0xFFFFCC02),
    progressBarHeight: 4.0,
  ),
  onUndoExpired: () => _deleteItem(item),
),
```

---

## Disable the Built-In Overlay — Use Callbacks Only

```dart
undoConfig: SwipeUndoConfig(
  showBuiltInOverlay: false,   // no automatic UI
  onUndoAvailable: (data) {
    // Show your own SnackBar, Toast, or custom widget
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Item deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: data.revert,  // triggers undo
        ),
        duration: data.remainingDuration,
      ),
    );
  },
  onUndoExpired: () => _deleteItem(item),
),
```

---

## Programmatic Undo via `SwipeController`

```dart
final _controller = SwipeController();

@override
void dispose() {
  _controller.dispose();
  super.dispose();
}

// In build:
SwipeActionCell(
  controller: _controller,
  undoConfig: SwipeUndoConfig(
    showBuiltInOverlay: false,
    onUndoExpired: () => _deleteItem(item),
  ),
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.autoTrigger,
    postActionBehavior: PostActionBehavior.animateOut,
  ),
  child: ListTile(title: Text(item.title)),
)

// Elsewhere (e.g., an app bar "Undo" button):
ElevatedButton(
  onPressed: _controller.isUndoPending ? _controller.undo : null,
  child: const Text('Undo'),
)
```

---

## Progressive Action Undo (Right Swipe)

```dart
SwipeActionCell(
  undoConfig: SwipeUndoConfig(
    onUndoAvailable: (data) {
      // data.oldValue and data.newValue are non-null for progressive actions
      debugPrint('Can undo: ${data.oldValue} → ${data.newValue}');
    },
    onUndoExpired: () {
      // Value increment is permanently committed
    },
    onUndoTriggered: () {
      // Value reverted to oldValue; indicator animates backward
    },
  ),
  rightSwipeConfig: RightSwipeConfig(
    stepValue: 1.0,
    onSwipeCompleted: (value, previous) => debugPrint('Value: $value'),
  ),
  child: ListTile(title: Text('Swipe right to increment')),
)
```

---

## Undo with `snapBack` or `stay` Mode

For `snapBack` and `stay` modes, the cell body is already visible after the action fires.
The package fires `onUndoTriggered` only — no animation is played. Your `onUndoTriggered`
callback is responsible for reverting any data change.

```dart
SwipeActionCell(
  undoConfig: SwipeUndoConfig(
    onUndoTriggered: () {
      // Cell is already visible — revert your data
      setState(() => item.isArchived = false);
    },
    onUndoExpired: () {
      // Commit permanently
      _archiveItem(item);
    },
  ),
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.autoTrigger,
    postActionBehavior: PostActionBehavior.snapBack,
    onActionTriggered: () {
      // Called immediately — do NOT commit here with undo enabled
      setState(() => item.isArchived = true);  // optimistic UI
    },
  ),
  child: ListTile(title: Text(item.isArchived ? 'Archived' : item.title)),
)
```

---

## Force-Commit Without Waiting

```dart
// Skip the undo window and commit immediately:
controller.commitPendingUndo();
```

Useful when navigating away from a screen — ensure pending actions are committed before disposal.

---

## Disabling Undo

```dart
// Undo disabled (default — null):
SwipeActionCell(
  // undoConfig not set → zero overhead
  leftSwipeConfig: LeftSwipeConfig(...),
  child: ListTile(...),
)
```

---

## API Summary

| Type | Role |
|------|------|
| `SwipeUndoConfig` | Opt-in undo configuration (null = disabled) |
| `SwipeUndoOverlayConfig` | Visual config for the built-in overlay bar |
| `SwipeUndoOverlayPosition` | `top` or `bottom` anchor for the overlay |
| `UndoData` | Snapshot of undo state passed to `onUndoAvailable` |
| `SwipeController.isUndoPending` | Observable: whether an undo window is open |
| `SwipeController.undo()` | Programmatically trigger undo (returns `false` if nothing pending) |
| `SwipeController.commitPendingUndo()` | Force-commit without waiting for expiry |

---

## See Also

- `spec.md` — Feature specification and user scenarios
- `data-model.md` — Full entity and field reference
- `contracts/public-api.md` — Complete Dart API signatures
- `research.md` — Technical decisions and rationale

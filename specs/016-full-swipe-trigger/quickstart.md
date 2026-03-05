# Quickstart & Test Scenarios: Full-Swipe Auto-Trigger (F016)

**Branch**: `016-full-swipe-trigger` | **Date**: 2026-03-02

---

## Usage Examples

### Scenario 1 — Left full-swipe to delete (reveal mode)

```dart
final deleteAction = SwipeAction(
  icon: const Icon(Icons.delete),
  label: 'Delete',
  backgroundColor: Colors.red,
  foregroundColor: Colors.white,
  onTap: () => deleteItem(item),
  isDestructive: true,
);

SwipeActionCell(
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.reveal,
    actions: [deleteAction],
    fullSwipeConfig: FullSwipeConfig(
      enabled: true,
      action: deleteAction, // must be same instance or equal
      postActionBehavior: PostActionBehavior.animateOut,
    ),
  ),
  onFullSwipeTriggered: (direction, action) {
    print('Full swipe triggered: ${action.label}');
  },
  child: ListTile(title: Text(item.title)),
)
```

**Test checkpoints**:
- [ ] Drag left 80% → action fires, `onFullSwipeTriggered` called
- [ ] Drag left 80% then pull back to 60% → no action fires; reveal panel stays
- [ ] Drag left 50% → normal reveal (panel stays open)
- [ ] Drag left 20% → snap back, no action

---

### Scenario 2 — Using the delete template (zero-config full-swipe)

```dart
SwipeActionCell.delete(
  onDeleted: () => removeItem(item),
  child: ListTile(title: Text(item.title)),
)
```

**Test checkpoints**:
- [ ] Template includes `FullSwipeConfig` by default
- [ ] Full swipe left past 75% triggers delete callback
- [ ] `animateOut` animation runs (slides left, then height collapses in parent AnimatedList)

---

### Scenario 3 — Left auto-trigger + full-swipe (two commitment levels)

```dart
final archiveAction = SwipeAction(
  icon: const Icon(Icons.archive),
  label: 'Archive',
  backgroundColor: Colors.orange,
  foregroundColor: Colors.white,
  onTap: () => archiveItem(item),
);

final deleteAction = SwipeAction(
  icon: const Icon(Icons.delete),
  label: 'Delete',
  backgroundColor: Colors.red,
  foregroundColor: Colors.white,
  onTap: () => deleteItem(item),
);

SwipeActionCell(
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.autoTrigger,
    onActionTriggered: archiveAction.onTap, // threshold 0.4 → archive
    fullSwipeConfig: FullSwipeConfig(
      enabled: true,
      threshold: 0.75,
      action: deleteAction, // threshold 0.75 → delete
    ),
  ),
  child: ListTile(title: Text(item.title)),
)
```

**Test checkpoints**:
- [ ] Drag to 50%, release → archive fires (normal auto-trigger)
- [ ] Drag to 80%, release → delete fires (full-swipe), archive does NOT fire
- [ ] Dragging between 40%–75% shows expand-in-progress visual but no expansion

---

### Scenario 4 — Right full-swipe progressive max-out

```dart
SwipeActionCell(
  rightSwipeConfig: RightSwipeConfig(
    stepValue: 1.0,
    maxValue: 10.0,
    onSwipeCompleted: (v) => setState(() => _count = v.toInt()),
    fullSwipeConfig: FullSwipeConfig(
      enabled: true,
      threshold: 0.75,
      action: SwipeAction(
        icon: const Icon(Icons.flash_on),
        label: 'Max out',
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
        onTap: () => setState(() => _count = 10),
      ),
      fullSwipeProgressBehavior: FullSwipeProgressBehavior.setToMax,
    ),
  ),
  child: ListTile(title: Text('Count: $_count')),
)
```

**Test checkpoints**:
- [ ] Drag right 40% → increments by 1
- [ ] Drag right 80% → jumps to maxValue (10), `onMaxReached` fires

---

### Scenario 5 — Programmatic trigger via SwipeController

```dart
final controller = SwipeController();

// In widget:
SwipeActionCell(
  controller: controller,
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.reveal,
    actions: [deleteAction],
    fullSwipeConfig: FullSwipeConfig(
      enabled: true,
      action: deleteAction,
    ),
  ),
  child: ListTile(title: Text(item.title)),
)

// Elsewhere (tutorial, test):
controller.triggerFullSwipe(SwipeDirection.left);
```

**Test checkpoints**:
- [ ] `triggerFullSwipe(SwipeDirection.left)` fires action and `onFullSwipeTriggered`
- [ ] `triggerFullSwipe(SwipeDirection.right)` when right full-swipe not configured → no-op
- [ ] New gesture blocked during post-action animation

---

### Scenario 6 — Haptic customization

```dart
SwipeActionCell(
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.reveal,
    actions: [deleteAction],
    fullSwipeConfig: FullSwipeConfig(
      enabled: true,
      action: deleteAction,
      enableHaptic: true,
    ),
  ),
  feedbackConfig: SwipeFeedbackConfig(
    hapticOverrides: {
      SwipeFeedbackEvent.fullSwipeThresholdCrossed: HapticPattern.medium,
      SwipeFeedbackEvent.fullSwipeActivation: HapticPattern.heavy,
    },
  ),
  child: const ListTile(title: Text('Custom haptic')),
)
```

**Test checkpoints**:
- [ ] Crossing threshold fires `fullSwipeThresholdCrossed` with custom pattern
- [ ] Release above threshold fires `fullSwipeActivation` with heavy impact
- [ ] `enableHaptic: false` suppresses both events

---

### Scenario 7 — RTL layout

```dart
Directionality(
  textDirection: TextDirection.rtl,
  child: SwipeActionCell(
    leftSwipeConfig: LeftSwipeConfig(
      mode: LeftSwipeMode.reveal,
      actions: [deleteAction],
      fullSwipeConfig: FullSwipeConfig(
        enabled: true,
        action: deleteAction,
      ),
    ),
    child: const ListTile(title: Text('RTL cell')),
  ),
)
```

**Test checkpoints**:
- [ ] In RTL, dragging right triggers the semantic "left" (backward) full-swipe
- [ ] Keyboard `Shift+ArrowRight` in RTL triggers full-swipe action
- [ ] Screen reader announces "Swipe fully to Delete" regardless of text direction

---

### Scenario 8 — Disabled state (zero overhead)

```dart
SwipeActionCell(
  leftSwipeConfig: const LeftSwipeConfig(
    mode: LeftSwipeMode.reveal,
    actions: [someAction],
    // fullSwipeConfig is null — not provided
  ),
  child: const ListTile(title: Text('No full swipe')),
)
```

**Test checkpoints**:
- [ ] Widget tree contains no `FullSwipeExpandOverlay` nodes
- [ ] `SwipeProgress.fullSwipeRatio` is always 0.0
- [ ] No `_fullSwipeBumpController` allocated
- [ ] All existing tests (383) pass with no regressions

---

## SwipeTester Helpers

```dart
// Drag left past full-swipe threshold and release
await SwipeTester.fullSwipeLeft(tester, find.byType(SwipeActionCell));

// Drag right past full-swipe threshold and release
await SwipeTester.fullSwipeRight(tester, find.byType(SwipeActionCell));

// Drag to specific ratio and hold (no pumpAndSettle — for mid-drag inspection)
await SwipeTester.dragTo(
  tester,
  find.byType(SwipeActionCell),
  Offset(-tester.getRect(find.byType(SwipeActionCell)).width * 0.8, 0),
);
```

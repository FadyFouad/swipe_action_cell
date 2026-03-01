# Quickstart: Scroll Conflict Resolution & Gesture Arena (F007)

**Branch**: `007-scroll-conflict` | **Date**: 2026-02-27

---

## Example 1 — Zero Config (Recommended for Most Apps)

No changes required. Drop `SwipeActionCell` into any `ListView` and both
swipe and scroll work correctly out of the box.

```dart
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => SwipeActionCell(
    rightSwipeConfig: RightSwipeConfig(
      stepValue: 1.0,
      onSwipeCompleted: (value) => print('Count: $value'),
    ),
    leftSwipeConfig: LeftSwipeConfig(
      mode: LeftSwipeMode.reveal,
      actions: [
        SwipeAction(
          icon: const Icon(Icons.delete),
          label: 'Delete',
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          onTap: () => deleteItem(items[index]),
          isDestructive: true,
        ),
      ],
    ),
    child: ListTile(title: Text(items[index].title)),
  ),
)
```

> Swipe ↔ and scroll ↕ both work. Diagonal gestures resolve to the dominant
> direction. Open panels close automatically when you scroll.

---

## Example 2 — Custom Threshold Ratio

For apps with precision requirements (e.g., music players, drawing tools) where
accidental horizontal activation must be minimized:

```dart
SwipeActionCell(
  gestureConfig: const SwipeGestureConfig(
    horizontalThresholdRatio: 2.5, // Require 2.5× more horizontal than vertical
  ),
  rightSwipeConfig: RightSwipeConfig(stepValue: 1.0),
  child: ListTile(title: Text('Precise swipe only')),
)
```

Or use the `tight()` preset (which now also sets a stricter threshold):

```dart
SwipeActionCell(
  gestureConfig: SwipeGestureConfig.tight(),
  rightSwipeConfig: RightSwipeConfig(stepValue: 1.0),
  child: ListTile(title: Text('Tight gesture feel')),
)
```

---

## Example 3 — Disable Auto-Close on Scroll

For scenarios where panels should persist while the user browses
(e.g., a batch-selection workflow):

```dart
SwipeActionCell(
  gestureConfig: const SwipeGestureConfig(closeOnScroll: false),
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.reveal,
    actions: [
      SwipeAction(
        icon: const Icon(Icons.check_circle),
        label: 'Select',
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        onTap: () => toggleSelect(item),
      ),
    ],
  ),
  child: ListTile(title: Text(item.title)),
)
```

---

## Example 4 — Nested PageView + ListView

No extra configuration needed. The default `horizontalThresholdRatio: 1.5`
correctly prioritizes cell swipes over page turns for deliberate cell gestures,
while fast full-width swipes still turn pages.

```dart
PageView.builder(
  itemCount: pages.length,
  itemBuilder: (context, pageIndex) => ListView.builder(
    itemCount: pages[pageIndex].items.length,
    itemBuilder: (context, itemIndex) => SwipeActionCell(
      leftSwipeConfig: LeftSwipeConfig(
        mode: LeftSwipeMode.autoTrigger,
        onActionTriggered: () => deleteItem(pages[pageIndex].items[itemIndex]),
      ),
      child: ListTile(title: Text(pages[pageIndex].items[itemIndex].title)),
    ),
  ),
)
```

---

## Example 5 — Disable Edge Gesture Deference (Uncommon)

Only relevant if your app intentionally intercepts the iOS back-navigation
swipe (e.g., a custom navigation system that replaces UINavigationController):

```dart
SwipeActionCell(
  gestureConfig: const SwipeGestureConfig(respectEdgeGestures: false),
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.reveal,
    actions: [/* ... */],
  ),
  child: ListTile(title: Text('Custom nav app')),
)
```

> **Warning**: Setting `respectEdgeGestures: false` will intercept the iOS
> system back-navigation gesture when the cell is at the left edge of the screen.
> This can cause App Store review rejections if the back gesture becomes unreachable.

---

## Migration from F001 (No Breaking Changes)

F007 adds new fields to `SwipeGestureConfig` — all with defaults that match
the previous implicit behavior. No existing code requires changes:

```dart
// Before F007 (still works; uses new defaults automatically):
SwipeActionCell(
  gestureConfig: const SwipeGestureConfig(deadZone: 8.0),
  rightSwipeConfig: RightSwipeConfig(stepValue: 1.0),
  child: ListTile(title: Text('Item')),
)

// After F007 (same behavior, new fields available):
SwipeActionCell(
  gestureConfig: const SwipeGestureConfig(
    deadZone: 8.0,
    // horizontalThresholdRatio: 1.5,  // default — added automatically
    // closeOnScroll: true,             // default — added automatically
    // respectEdgeGestures: true,       // default — added automatically
  ),
  rightSwipeConfig: RightSwipeConfig(stepValue: 1.0),
  child: ListTile(title: Text('Item')),
)
```

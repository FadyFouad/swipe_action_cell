# Data Model: Scroll Conflict Resolution & Gesture Arena (F007)

**Branch**: `007-scroll-conflict` | **Date**: 2026-02-27

---

## Entities

### 1. `SwipeGestureConfig` (extended)

**Location**: `lib/src/gesture/swipe_gesture_config.dart`
**Change**: Add 3 new fields

| Field | Type | Default | Validation |
|-------|------|---------|------------|
| `deadZone` | `double` | `12.0` | — (existing) |
| `enabledDirections` | `Set<SwipeDirection>` | `{left, right}` | — (existing) |
| `velocityThreshold` | `double` | `700.0` | — (existing) |
| `horizontalThresholdRatio` | `double` | `1.5` | `assert >= 1.0` |
| `closeOnScroll` | `bool` | `true` | — |
| `respectEdgeGestures` | `bool` | `true` | — |

**Invariants**:
- `horizontalThresholdRatio >= 1.0` (assert in constructor; debug-mode only)
- All fields `final`, constructor `const`-compatible
- `copyWith` updated to include all three new fields
- `==` and `hashCode` updated to include all three new fields

---

### 2. `_SwipeHorizontalRecognizer` (new, package-internal)

**Location**: `lib/src/scroll/swipe_gesture_recognizer.dart`
**Visibility**: Package-internal (not exported from barrel)
**Extends**: `HorizontalDragGestureRecognizer` from `flutter/gestures.dart`

| Field | Type | Description |
|-------|------|-------------|
| `thresholdRatio` | `double` | Minimum H:V ratio; updated each build via initializer |
| `respectEdgeGestures` | `bool` | Whether to skip gestures from the left edge zone |
| `edgeWidth` | `double` | Width of the edge zone in logical pixels (constant: 20.0) |
| `_cumulativeH` | `double` | Accumulated horizontal delta since pointer down (mutable, reset per gesture) |
| `_cumulativeV` | `double` | Accumulated vertical delta since pointer down (mutable, reset per gesture) |
| `_directionDecided` | `bool` | True once the H/V ratio decision has been made |

**Lifecycle**:
```
addAllowedPointer(PointerDownEvent)
  → if (respectEdgeGestures && dx < edgeWidth): return  // never enters arena
  → reset _cumulativeH, _cumulativeV, _directionDecided
  → super.addAllowedPointer(event)               // enters arena

handleEvent(PointerEvent)
  → if _directionDecided: super.handleEvent()    // already decided, pass through
  → if PointerMoveEvent: accumulate dx, dy
    → if |cumulativeH| + |cumulativeV| > kTouchSlop:
        → if |cumulativeH| >= |cumulativeV| * thresholdRatio:
            _directionDecided = true
            super.handleEvent(event)              // accept path
        → else:
            resolve(GestureDisposition.rejected)  // yield to scroll
  → else: super.handleEvent(event)               // small movement, pass through
```

---

### 3. `SwipeActionCellState` (additions)

**Location**: `lib/src/widget/swipe_action_cell.dart`
**Change**: Replace `GestureDetector` with `RawGestureDetector` + `NotificationListener`

| Addition | Description |
|----------|-------------|
| `_buildGestureRecognizers(double width)` | Returns the `Map<Type, GestureRecognizerFactory>` for `RawGestureDetector` |
| `_handleScrollStart(ScrollStartNotification)` | Calls `executeClose()` when `closeOnScroll` and `notification.dragDetails != null` |

**Modified `build` layout** (outermost to innermost):
```
NotificationListener<ScrollStartNotification>
  └── LayoutBuilder
        └── RawGestureDetector (replaces GestureDetector)
              └── _wrapWithClip
                    └── AnimatedBuilder → Stack (unchanged)
```

**No new state fields.** All new behavior is expressed through the recognizer and the notification listener callback.

---

### 4. File Structure

```text
lib/
├── swipe_action_cell.dart          ← no new exports (recognizer is internal)
└── src/
    ├── gesture/
    │   └── swipe_gesture_config.dart   ← ADD 3 fields, update copyWith/==/hashCode
    ├── scroll/
    │   └── swipe_gesture_recognizer.dart  ← NEW (package-internal)
    └── widget/
        └── swipe_action_cell.dart      ← replace GestureDetector, add NotificationListener

test/
└── scroll/
    └── swipe_scroll_conflict_test.dart ← NEW (all F007 tests)
```

---

### 5. Gesture State Transitions (unchanged)

No new states are added. The existing state machine handles all F007 scenarios:

| Trigger | From State | To State |
|---------|-----------|----------|
| Recognizer yields to scroll | `dragging` | `idle` (drag end with no-op) |
| Diagonal horizontal → accepted | `idle` | `dragging` |
| ScrollStartNotification + `closeOnScroll` | `revealed` | `animatingToClose` |
| Momentum scroll touches screen | `idle` | `idle` (recognizer never enters arena) |

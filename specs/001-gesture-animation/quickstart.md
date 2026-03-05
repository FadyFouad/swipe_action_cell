# Quickstart: Foundational Gesture & Spring Animation

**Feature**: 001-gesture-animation
**Date**: 2026-02-25

This guide shows how to use `SwipeActionCell` once this feature is implemented. Use it to
validate the implementation against expected consumer behavior.

---

## Prerequisites

```yaml
# pubspec.yaml
dependencies:
  swipe_action_cell: ^0.1.0   # or path: ../swipe_action_cell during dev
```

```dart
import 'package:swipe_action_cell/swipe_action_cell.dart';
```

---

## Basic Usage — Zero Configuration

Wrap any widget in `SwipeActionCell`. Both directions are enabled by default.

```dart
SwipeActionCell(
  child: ListTile(
    title: Text('Swipe me'),
    tileColor: Colors.white,
  ),
)
```

The wrapped item now:
- Follows the user's finger horizontally when dragged.
- Snaps back smoothly if released before 40% of its width.
- Springs to the fully-extended position if released at or beyond 40%.
- Flings to completion on fast swipes (≥ 700 px/s) regardless of distance.

---

## Observing State Changes

```dart
SwipeActionCell(
  child: MyListItem(),
  onStateChanged: (SwipeState state) {
    debugPrint('Swipe state: $state');
    if (state == SwipeState.revealed) {
      // Widget is fully extended — an action could fire here in future features.
    }
  },
  onProgressChanged: (SwipeProgress progress) {
    // Called every frame during drag.
    // Use progress.ratio (0.0–1.0) to drive background visual effects.
    // Use progress.isActivated to know if the current drag will commit.
    debugPrint(
      'ratio: ${progress.ratio.toStringAsFixed(2)}, '
      'activated: ${progress.isActivated}',
    );
  },
)
```

---

## Custom Gesture Configuration

```dart
SwipeActionCell(
  child: MyListItem(),
  gestureConfig: const SwipeGestureConfig(
    deadZone: 20.0,            // Larger dead zone — harder to accidentally trigger
    enabledDirections: {SwipeDirection.left},  // Left swipe only
    velocityThreshold: 500.0,  // Easier to trigger completion via fling
  ),
)
```

---

## Custom Animation Physics

```dart
SwipeActionCell(
  child: MyListItem(),
  animationConfig: const SwipeAnimationConfig(
    activationThreshold: 0.3,  // 30% drag = confirmed swipe
    snapBackSpring: SpringConfig(
      mass: 1.0,
      stiffness: 300.0,
      damping: 20.0,  // Slightly more bounce on snap-back
    ),
    completionSpring: SpringConfig(
      mass: 1.0,
      stiffness: 800.0,
      damping: 40.0,  // Very snappy completion
    ),
    resistanceFactor: 0.3,    // Less rubber-band, closer to hard stop
    maxTranslationRight: 80.0, // Limit right swipe to 80 logical pixels
    maxTranslationLeft: 120.0, // Allow more space for left swipe
  ),
)
```

---

## Inside a ListView

`SwipeActionCell` coexists with `ListView` automatically — no special configuration needed.
Vertical scrolling is not disrupted.

```dart
ListView.builder(
  itemCount: 20,
  itemBuilder: (context, index) {
    return SwipeActionCell(
      key: ValueKey(index),  // Always provide a key in list contexts
      child: ListTile(
        title: Text('Item $index'),
      ),
    );
  },
)
```

---

## Disabled State

```dart
SwipeActionCell(
  enabled: false,  // No gesture interception — child renders normally
  child: MyListItem(),
)
```

---

## Validation Checklist

After implementation, verify these scenarios manually or in widget tests:

- [ ] Cell stays still when tapped (dead zone prevents trigger)
- [ ] Cell follows finger during drag (no lag visible at 60fps)
- [ ] Cell snaps back cleanly after a short drag released at 25% of max translation
- [ ] Cell springs to full extension after drag released at 60% of max translation
- [ ] Fast fling at 15% displacement still completes (velocity threshold test)
- [ ] Grab during snap-back: no positional jump, resumes from current position
- [ ] Grab during completion animation: same seamless handoff
- [ ] Vertical scrolling works normally inside a ListView
- [ ] Left-only config: right swipe produces no motion
- [ ] Both directions disabled: child receives all touch events
- [ ] `onStateChanged` fires on every state transition
- [ ] `onProgressChanged` fires on every drag frame with correct ratio and direction

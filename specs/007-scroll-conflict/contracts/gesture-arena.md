# Contract: Scroll Conflict Resolution & Gesture Arena (F007)

**Branch**: `007-scroll-conflict` | **Date**: 2026-02-27
**Spec**: [spec.md](../spec.md) | **Data Model**: [data-model.md](../data-model.md)

All signatures are normative — implementation MUST match exactly.
Internal helpers not listed here.

---

## `lib/src/gesture/swipe_gesture_config.dart` (modified)

Three new fields added; all other members unchanged.

```dart
@immutable
class SwipeGestureConfig {
  /// Creates a gesture configuration.
  const SwipeGestureConfig({
    this.deadZone = 12.0,
    this.enabledDirections = const {SwipeDirection.left, SwipeDirection.right},
    this.velocityThreshold = 700.0,
    this.horizontalThresholdRatio = 1.5,  // NEW
    this.closeOnScroll = true,            // NEW
    this.respectEdgeGestures = true,      // NEW
  }) : assert(
         horizontalThresholdRatio >= 1.0,
         'horizontalThresholdRatio must be >= 1.0, got $horizontalThresholdRatio. '
         'A value below 1.0 would classify vertical gestures as horizontal swipes.',
       );

  // ... existing fields ...

  /// Minimum ratio of horizontal-to-vertical displacement required before
  /// a gesture is classified as a horizontal swipe.
  ///
  /// A value of `1.5` (default) means the horizontal displacement must be at
  /// least 1.5× the vertical displacement for the gesture to be treated as a
  /// swipe. Higher values require a more deliberate horizontal motion.
  ///
  /// Must be ≥ 1.0. A value below 1.0 would misclassify vertical gestures.
  final double horizontalThresholdRatio;

  /// Whether to close any open action panel when the user begins scrolling
  /// a parent [Scrollable].
  ///
  /// When `true` (default), an open reveal panel snaps closed as soon as the
  /// user initiates a vertical scroll. When `false`, open panels remain
  /// visible during scroll. Only user-initiated scrolls trigger auto-close —
  /// programmatic scrolls (e.g., [ScrollController.animateTo]) do not.
  final bool closeOnScroll;

  /// Whether to yield to the platform's back-navigation edge gesture.
  ///
  /// When `true` (default), drag gestures that begin within 20 logical pixels
  /// of the left screen edge are not claimed by the swipe cell, allowing the
  /// iOS or Android back-navigation gesture to proceed normally. When `false`,
  /// all horizontal drags are processed by the cell regardless of start position.
  final bool respectEdgeGestures;

  /// Returns a copy of this config with the specified fields replaced.
  SwipeGestureConfig copyWith({
    double? deadZone,
    Set<SwipeDirection>? enabledDirections,
    double? velocityThreshold,
    double? horizontalThresholdRatio,   // NEW
    bool? closeOnScroll,               // NEW
    bool? respectEdgeGestures,         // NEW
  });

  // == and hashCode MUST include all six fields.
}
```

---

## `lib/src/scroll/swipe_gesture_recognizer.dart` (new, NOT exported)

```dart
import 'package:flutter/gestures.dart';

/// Package-internal horizontal-drag recognizer that applies an H/V ratio
/// threshold before claiming the gesture arena.
///
/// Extends [HorizontalDragGestureRecognizer] and overrides gesture-arena
/// participation to:
///
/// 1. Reject gestures that start within the platform edge zone when
///    [respectEdgeGestures] is `true`.
/// 2. Reject gestures whose accumulated vertical displacement exceeds
///    `1 / horizontalThresholdRatio` of the horizontal displacement, deferring
///    to any parent [VerticalDragGestureRecognizer] (e.g., a [ListView] scroll).
///
/// Not for consumer use — this file is not exported from the package barrel.
class SwipeHorizontalRecognizer extends HorizontalDragGestureRecognizer {
  /// Creates a [SwipeHorizontalRecognizer].
  SwipeHorizontalRecognizer({super.debugOwner, super.supportedDevices});

  /// Minimum H:V ratio for a gesture to be classified as a horizontal swipe.
  ///
  /// Updated by [SwipeActionCellState] on each rebuild via the
  /// [GestureRecognizerFactoryWithHandlers] initializer.
  double thresholdRatio = 1.5;

  /// Whether to skip gestures that originate within the platform edge zone.
  ///
  /// Updated by [SwipeActionCellState] on each rebuild.
  bool respectEdgeGestures = true;

  // Package-internal constant: iOS/Android back-navigation edge zone width.
  static const double _kEdgeZoneWidth = 20.0;

  double _cumulativeH = 0.0;
  double _cumulativeV = 0.0;
  bool _directionDecided = false;

  @override
  void addAllowedPointer(PointerDownEvent event) {
    // Yield immediately to the platform if this is an edge gesture.
    if (respectEdgeGestures && event.position.dx < _kEdgeZoneWidth) return;
    _cumulativeH = 0.0;
    _cumulativeV = 0.0;
    _directionDecided = false;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (_directionDecided) {
      super.handleEvent(event);
      return;
    }
    if (event is PointerMoveEvent) {
      _cumulativeH += event.delta.dx;
      _cumulativeV += event.delta.dy;
      final absH = _cumulativeH.abs();
      final absV = _cumulativeV.abs();
      if (absH + absV > kTouchSlop) {
        if (absH >= absV * thresholdRatio) {
          _directionDecided = true;
          super.handleEvent(event);
        } else {
          // Vertical dominant — yield to the scroll recognizer.
          resolve(GestureDisposition.rejected);
          return;
        }
      } else {
        super.handleEvent(event);
      }
    } else {
      super.handleEvent(event);
    }
  }
}
```

---

## `lib/src/widget/swipe_action_cell.dart` (additions to existing)

**`SwipeActionCellState` build changes** — replace inner `GestureDetector` with
`NotificationListener` + `RawGestureDetector`:

```dart
/// Builds the gesture recognizer map for [RawGestureDetector].
Map<Type, GestureRecognizerFactory> _buildGestureRecognizers(double width) {
  return {
    SwipeHorizontalRecognizer:
        GestureRecognizerFactoryWithHandlers<SwipeHorizontalRecognizer>(
      () => SwipeHorizontalRecognizer(debugOwner: this),
      (instance) {
        instance
          ..thresholdRatio = effectiveGestureConfig.horizontalThresholdRatio
          ..respectEdgeGestures = effectiveGestureConfig.respectEdgeGestures
          ..onStart = _handleDragStart
          ..onUpdate = (d) => _handleDragUpdate(d, width)
          ..onEnd = (d) => _handleDragEnd(d, width);
      },
    ),
  };
}

/// Handles a [ScrollStartNotification] from a parent [Scrollable].
///
/// Closes any open panel when [SwipeGestureConfig.closeOnScroll] is `true`
/// and the scroll was user-initiated (indicated by non-null [dragDetails]).
bool _handleScrollStart(ScrollStartNotification notification) {
  if (effectiveGestureConfig.closeOnScroll &&
      notification.dragDetails != null &&
      _state == SwipeState.revealed) {
    executeClose();
  }
  return false; // always bubble — do not absorb the notification
}
```

**Modified `build` structure** (only the relevant portion):

```dart
@override
Widget build(BuildContext context) {
  if (!widget.enabled) return widget.child;
  return NotificationListener<ScrollStartNotification>(  // NEW outer wrapper
    onNotification: _handleScrollStart,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        _widgetWidth = width;
        return RawGestureDetector(                       // REPLACES GestureDetector
          behavior: HitTestBehavior.translucent,
          gestures: _buildGestureRecognizers(width),
          child: _wrapWithClip(
            AnimatedBuilder(/* ... unchanged ... */),
          ),
        );
      },
    ),
  );
}
```

---

## Test Files

| File | Coverage |
|------|----------|
| `test/scroll/swipe_scroll_conflict_test.dart` | All F007 scenarios: vertical scroll in ListView works, horizontal swipe works, diagonal resolves to dominant direction, `closeOnScroll` auto-close, fast fling does not trigger swipe, `PageView > ListView > SwipeActionCell` nesting, edge gesture priority, `horizontalThresholdRatio` assertion |
| `test/gesture/swipe_gesture_config_test.dart` | Extended: new fields in `==`, `hashCode`, `copyWith`; `horizontalThresholdRatio < 1.0` assertion |

> `swipe_gesture_recognizer.dart` is package-internal and tested indirectly through widget tests.
> No dedicated unit test file for the recognizer class itself.

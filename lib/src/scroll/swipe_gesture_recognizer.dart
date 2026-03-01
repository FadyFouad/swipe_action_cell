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

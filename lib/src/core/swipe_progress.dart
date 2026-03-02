import 'package:flutter/foundation.dart';
import 'swipe_direction.dart';

/// Contains progress information about the current swipe gesture.
///
/// Provided to background builders and visual feedback components so they can
/// react to drag state without coupling to internal widget implementation.
@immutable
class SwipeProgress {
  /// Creates a [SwipeProgress] with the given values.
  const SwipeProgress({
    required this.direction,
    required this.ratio,
    required this.isActivated,
    required this.rawOffset,
    this.fullSwipeRatio = 0.0,
  });

  /// The direction of the current swipe.
  final SwipeDirection direction;

  /// Progress ratio from `0.0` (at origin) to `1.0` (full swipe extent).
  final double ratio;

  /// Whether the swipe has passed the activation threshold.
  ///
  /// When `true`, releasing the gesture will trigger the associated action.
  final bool isActivated;

  /// Raw pixel displacement from the origin position.
  final double rawOffset;

  /// Progress ratio from 0.0 to 1.0 specifically for the full-swipe threshold.
  final double fullSwipeRatio;

  /// A constant representing no swipe in progress.
  static const SwipeProgress zero = SwipeProgress(
    direction: SwipeDirection.none,
    ratio: 0.0,
    isActivated: false,
    rawOffset: 0.0,
    fullSwipeRatio: 0.0,
  );

  /// Returns a copy of this progress with the given fields replaced.
  SwipeProgress copyWith({
    SwipeDirection? direction,
    double? ratio,
    bool? isActivated,
    double? rawOffset,
    double? fullSwipeRatio,
  }) {
    return SwipeProgress(
      direction: direction ?? this.direction,
      ratio: ratio ?? this.ratio,
      isActivated: isActivated ?? this.isActivated,
      rawOffset: rawOffset ?? this.rawOffset,
      fullSwipeRatio: fullSwipeRatio ?? this.fullSwipeRatio,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SwipeProgress &&
        other.direction == direction &&
        other.ratio == ratio &&
        other.isActivated == isActivated &&
        other.rawOffset == rawOffset &&
        other.fullSwipeRatio == fullSwipeRatio;
  }

  @override
  int get hashCode => Object.hash(direction, ratio, isActivated, rawOffset, fullSwipeRatio);

  @override
  String toString() {
    return 'SwipeProgress(direction: $direction, ratio: $ratio, isActivated: $isActivated, rawOffset: $rawOffset)';
  }
}

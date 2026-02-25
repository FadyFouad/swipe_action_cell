import 'swipe_direction.dart';

/// Contains progress information about the current swipe gesture.
///
/// Provided to background builders and visual feedback components so they can
/// react to drag state without coupling to internal widget implementation.
class SwipeProgress {
  /// Creates a [SwipeProgress] with the given values.
  const SwipeProgress({
    required this.direction,
    required this.ratio,
    required this.isActivated,
    required this.rawOffset,
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

  /// A constant representing no swipe in progress.
  static const SwipeProgress zero = SwipeProgress(
    direction: SwipeDirection.none,
    ratio: 0.0,
    isActivated: false,
    rawOffset: 0.0,
  );
}

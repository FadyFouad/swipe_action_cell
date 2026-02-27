import 'package:flutter/foundation.dart';
import '../core/swipe_direction.dart';

/// Configuration for horizontal drag gesture recognition.
@immutable
class SwipeGestureConfig {
  /// Creates a gesture configuration.
  const SwipeGestureConfig({
    this.deadZone = 12.0,
    this.enabledDirections = const {SwipeDirection.left, SwipeDirection.right},
    this.velocityThreshold = 700.0,
    this.horizontalThresholdRatio = 1.5,
    this.closeOnScroll = true,
    this.respectEdgeGestures = true,
  }) : assert(
          horizontalThresholdRatio >= 1.0,
          'horizontalThresholdRatio must be >= 1.0, got $horizontalThresholdRatio. '
          'A value below 1.0 would classify vertical gestures as horizontal swipes.',
        );

  /// A configuration with a large dead zone for a precise, intentional feel.
  factory SwipeGestureConfig.tight() => const SwipeGestureConfig(
        deadZone: 24.0,
        velocityThreshold: 1000.0,
        horizontalThresholdRatio: 2.5,
      );

  /// A configuration with a small dead zone for a highly sensitive, loose feel.
  factory SwipeGestureConfig.loose() => const SwipeGestureConfig(
        deadZone: 4.0,
        velocityThreshold: 300.0,
      );

  /// Minimum horizontal displacement before a swipe is recognized.
  final double deadZone;

  /// The set of swipe directions this cell responds to.
  final Set<SwipeDirection> enabledDirections;

  /// Minimum release velocity to trigger completion via fling.
  final double velocityThreshold;

  /// Minimum ratio of horizontal-to-vertical displacement required before
  /// a gesture is classified as a horizontal swipe.
  ///
  /// A value of `1.5` (default) means the horizontal displacement must be at
  /// least 1.5× the vertical displacement for the gesture to be treated as a
  /// swipe. Higher values require a more deliberate horizontal motion.
  ///
  /// Must be >= 1.0. A value below 1.0 would misclassify vertical gestures.
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
    double? horizontalThresholdRatio,
    bool? closeOnScroll,
    bool? respectEdgeGestures,
  }) {
    return SwipeGestureConfig(
      deadZone: deadZone ?? this.deadZone,
      enabledDirections: enabledDirections ?? this.enabledDirections,
      velocityThreshold: velocityThreshold ?? this.velocityThreshold,
      horizontalThresholdRatio:
          horizontalThresholdRatio ?? this.horizontalThresholdRatio,
      closeOnScroll: closeOnScroll ?? this.closeOnScroll,
      respectEdgeGestures: respectEdgeGestures ?? this.respectEdgeGestures,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SwipeGestureConfig &&
        other.deadZone == deadZone &&
        setEquals(other.enabledDirections, enabledDirections) &&
        other.velocityThreshold == velocityThreshold &&
        other.horizontalThresholdRatio == horizontalThresholdRatio &&
        other.closeOnScroll == closeOnScroll &&
        other.respectEdgeGestures == respectEdgeGestures;
  }

  @override
  int get hashCode => Object.hash(
        deadZone,
        Object.hashAll(enabledDirections),
        velocityThreshold,
        horizontalThresholdRatio,
        closeOnScroll,
        respectEdgeGestures,
      );
}

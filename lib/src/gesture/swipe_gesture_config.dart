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
  });

  /// A configuration with a large dead zone for a precise, intentional feel.
  factory SwipeGestureConfig.tight() => const SwipeGestureConfig(
        deadZone: 24.0,
        velocityThreshold: 1000.0,
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

  /// Returns a copy of this config with the specified fields replaced.
  SwipeGestureConfig copyWith({
    double? deadZone,
    Set<SwipeDirection>? enabledDirections,
    double? velocityThreshold,
  }) {
    return SwipeGestureConfig(
      deadZone: deadZone ?? this.deadZone,
      enabledDirections: enabledDirections ?? this.enabledDirections,
      velocityThreshold: velocityThreshold ?? this.velocityThreshold,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SwipeGestureConfig &&
        other.deadZone == deadZone &&
        setEquals(other.enabledDirections, enabledDirections) &&
        other.velocityThreshold == velocityThreshold;
  }

  @override
  int get hashCode => Object.hash(
        deadZone,
        Object.hashAll(enabledDirections),
        velocityThreshold,
      );
}

import 'package:flutter/foundation.dart';
import 'spring_config.dart';

/// Configuration for swipe animation physics and thresholds.
@immutable
class SwipeAnimationConfig {
  /// Creates an animation configuration.
  const SwipeAnimationConfig({
    this.activationThreshold = 0.4,
    this.snapBackSpring = SpringConfig.snapBack,
    this.completionSpring = SpringConfig.completion,
    this.resistanceFactor = 0.55,
    this.maxTranslationLeft,
    this.maxTranslationRight,
  });

  /// The progress ratio at which a drag release triggers completion.
  final double activationThreshold;

  /// Spring physics used when the cell snaps back to the origin.
  final SpringConfig snapBackSpring;

  /// Spring physics used when the cell animates to the revealed position.
  final SpringConfig completionSpring;

  /// Controls drag resistance near the maximum translation bound.
  final double resistanceFactor;

  /// Maximum drag extent in the left direction (logical pixels).
  final double? maxTranslationLeft;

  /// Maximum drag extent in the right direction (logical pixels).
  final double? maxTranslationRight;

  /// Returns a copy of this config with the specified fields replaced.
  SwipeAnimationConfig copyWith({
    double? activationThreshold,
    SpringConfig? snapBackSpring,
    SpringConfig? completionSpring,
    double? resistanceFactor,
    double? maxTranslationLeft,
    double? maxTranslationRight,
  }) {
    return SwipeAnimationConfig(
      activationThreshold: activationThreshold ?? this.activationThreshold,
      snapBackSpring: snapBackSpring ?? this.snapBackSpring,
      completionSpring: completionSpring ?? this.completionSpring,
      resistanceFactor: resistanceFactor ?? this.resistanceFactor,
      maxTranslationLeft: maxTranslationLeft ?? this.maxTranslationLeft,
      maxTranslationRight: maxTranslationRight ?? this.maxTranslationRight,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SwipeAnimationConfig &&
        other.activationThreshold == activationThreshold &&
        other.snapBackSpring == snapBackSpring &&
        other.completionSpring == completionSpring &&
        other.resistanceFactor == resistanceFactor &&
        other.maxTranslationLeft == maxTranslationLeft &&
        other.maxTranslationRight == maxTranslationRight;
  }

  @override
  int get hashCode => Object.hash(
        activationThreshold,
        snapBackSpring,
        completionSpring,
        resistanceFactor,
        maxTranslationLeft,
        maxTranslationRight,
      );
}

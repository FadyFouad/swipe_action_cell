import 'package:flutter/material.dart';

import '../animation/swipe_animation_config.dart';
import '../feedback/swipe_feedback_config.dart';
import '../gesture/swipe_gesture_config.dart';
import 'left_swipe_config.dart';
import 'right_swipe_config.dart';
import 'swipe_visual_config.dart';

/// App-level defaults for all [SwipeActionCell] widgets in the widget tree.
@immutable
class SwipeActionCellTheme extends ThemeExtension<SwipeActionCellTheme> {
  /// Creates a [SwipeActionCellTheme].
  const SwipeActionCellTheme({
    this.rightSwipeConfig,
    this.leftSwipeConfig,
    this.gestureConfig,
    this.animationConfig,
    this.visualConfig,
    this.feedbackConfig,
  });

  /// Default right-swipe configuration applied to all cells in the tree.
  final RightSwipeConfig? rightSwipeConfig;

  /// Default left-swipe configuration applied to all cells in the tree.
  final LeftSwipeConfig? leftSwipeConfig;

  /// Default gesture recognition configuration applied to all cells in the tree.
  final SwipeGestureConfig? gestureConfig;

  /// Default animation physics configuration applied to all cells in the tree.
  final SwipeAnimationConfig? animationConfig;

  /// Default visual presentation configuration applied to all cells in the tree.
  final SwipeVisualConfig? visualConfig;

  /// Default feedback configuration applied to all cells in the tree.
  final SwipeFeedbackConfig? feedbackConfig;

  /// Returns the nearest [SwipeActionCellTheme] from [context], or `null` if
  /// none is installed in the app theme.
  static SwipeActionCellTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<SwipeActionCellTheme>();

  /// Returns a copy with the specified fields replaced.
  @override
  SwipeActionCellTheme copyWith({
    RightSwipeConfig? rightSwipeConfig,
    LeftSwipeConfig? leftSwipeConfig,
    SwipeGestureConfig? gestureConfig,
    SwipeAnimationConfig? animationConfig,
    SwipeVisualConfig? visualConfig,
    SwipeFeedbackConfig? feedbackConfig,
  }) {
    return SwipeActionCellTheme(
      rightSwipeConfig: rightSwipeConfig ?? this.rightSwipeConfig,
      leftSwipeConfig: leftSwipeConfig ?? this.leftSwipeConfig,
      gestureConfig: gestureConfig ?? this.gestureConfig,
      animationConfig: animationConfig ?? this.animationConfig,
      visualConfig: visualConfig ?? this.visualConfig,
      feedbackConfig: feedbackConfig ?? this.feedbackConfig,
    );
  }

  /// Hard-cutover lerp: returns [other] when [t] >= 1.0, [this] otherwise.
  @override
  SwipeActionCellTheme lerp(
    ThemeExtension<SwipeActionCellTheme>? other,
    double t,
  ) {
    if (other is! SwipeActionCellTheme) return this;
    return t >= 1.0 ? other : this;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwipeActionCellTheme &&
          runtimeType == other.runtimeType &&
          rightSwipeConfig == other.rightSwipeConfig &&
          leftSwipeConfig == other.leftSwipeConfig &&
          gestureConfig == other.gestureConfig &&
          animationConfig == other.animationConfig &&
          visualConfig == other.visualConfig &&
          feedbackConfig == other.feedbackConfig;

  @override
  int get hashCode => Object.hash(
        rightSwipeConfig,
        leftSwipeConfig,
        gestureConfig,
        animationConfig,
        visualConfig,
        feedbackConfig,
      );
}

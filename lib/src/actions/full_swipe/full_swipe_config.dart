import 'package:flutter/foundation.dart';
import '../../actions/intentional/post_action_behavior.dart';
import '../../actions/intentional/swipe_action.dart';

/// Dictates how full-swipe behaves when in progressive mode.
enum FullSwipeProgressBehavior {
  /// Jumps the progressive value to [RightSwipeConfig.maxValue] on trigger.
  setToMax,

  /// Fires the specific [FullSwipeConfig.action] instead of jumping value.
  customAction,
}

/// Configuration for the full-swipe auto-trigger feature.
@immutable
class FullSwipeConfig {
  /// Whether full-swipe is enabled for this direction.
  final bool enabled;

  /// The drag ratio (0.0 to 1.0) at which the full-swipe action is armed.
  ///
  /// Defaults to 0.75 (75% of widget width).
  final double threshold;

  /// The action to fire when the user releases the drag while armed.
  final SwipeAction action;

  /// What happens to the cell after the action fires.
  ///
  /// Defaults to [PostActionBehavior.animateOut].
  final PostActionBehavior postActionBehavior;

  /// Whether the "expand-to-fill" visual animation plays while armed.
  final bool expandAnimation;

  /// Whether full-swipe specific haptic feedback is enabled.
  final bool enableHaptic;

  /// How to handle progressive mode triggers (Right-swipe only).
  ///
  /// If null, defaults to [FullSwipeProgressBehavior.customAction].
  final FullSwipeProgressBehavior? fullSwipeProgressBehavior;

  /// Creates a [FullSwipeConfig].
  const FullSwipeConfig({
    this.enabled = false,
    this.threshold = 0.75,
    required this.action,
    this.postActionBehavior = PostActionBehavior.animateOut,
    this.expandAnimation = true,
    this.enableHaptic = true,
    this.fullSwipeProgressBehavior,
  })  : assert(threshold > 0.0 && threshold <= 1.0);

  /// Creates a copy of this config with the given fields replaced.
  FullSwipeConfig copyWith({
    bool? enabled,
    double? threshold,
    SwipeAction? action,
    PostActionBehavior? postActionBehavior,
    bool? expandAnimation,
    bool? enableHaptic,
    FullSwipeProgressBehavior? fullSwipeProgressBehavior,
  }) {
    return FullSwipeConfig(
      enabled: enabled ?? this.enabled,
      threshold: threshold ?? this.threshold,
      action: action ?? this.action,
      postActionBehavior: postActionBehavior ?? this.postActionBehavior,
      expandAnimation: expandAnimation ?? this.expandAnimation,
      enableHaptic: enableHaptic ?? this.enableHaptic,
      fullSwipeProgressBehavior:
          fullSwipeProgressBehavior ?? this.fullSwipeProgressBehavior,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FullSwipeConfig &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          threshold == other.threshold &&
          action == other.action &&
          postActionBehavior == other.postActionBehavior &&
          expandAnimation == other.expandAnimation &&
          enableHaptic == other.enableHaptic &&
          fullSwipeProgressBehavior == other.fullSwipeProgressBehavior;

  @override
  int get hashCode =>
      enabled.hashCode ^
      threshold.hashCode ^
      action.hashCode ^
      postActionBehavior.hashCode ^
      expandAnimation.hashCode ^
      enableHaptic.hashCode ^
      fullSwipeProgressBehavior.hashCode;
}

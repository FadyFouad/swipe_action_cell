import 'package:flutter/foundation.dart';
import '../actions/intentional/left_swipe_mode.dart';
import '../actions/intentional/post_action_behavior.dart';
import '../actions/intentional/swipe_action.dart';


/// Configuration for left-swipe intentional (one-shot) action behavior.
@immutable
class LeftSwipeConfig {
  /// Creates a configuration for left-swipe intentional actions.
  const LeftSwipeConfig({
    this.mode = LeftSwipeMode.autoTrigger,
    this.actions = const [],
    this.actionPanelWidth = 240.0,
    this.postActionBehavior = PostActionBehavior.snapBack,
    this.requireConfirmation = false,
    this.enableHaptic = false,
    this.onActionTriggered,
    this.onSwipeCancelled,
    this.onPanelOpened,
    this.onPanelClosed,
  })  : assert(actionPanelWidth > 0,
            'LeftSwipeConfig: actionPanelWidth must be > 0, got $actionPanelWidth'),
        assert(mode != LeftSwipeMode.reveal || actions.length > 0,
            'LeftSwipeConfig in reveal mode requires at least one action, but actions is empty.');

  /// The interaction model for the left swipe.
  final LeftSwipeMode mode;

  /// The list of actions to show in reveal mode.
  final List<SwipeAction> actions;

  /// The fixed width of the action panel in reveal mode.
  final double actionPanelWidth;

  /// How the cell behaves after an action is triggered.
  final PostActionBehavior postActionBehavior;

  /// Whether a second swipe or background tap is required to confirm.
  final bool requireConfirmation;

  /// Whether to trigger haptic feedback at key interaction milestones.
  final bool enableHaptic;

  /// Callback when a one-shot action is triggered (autoTrigger mode).
  final VoidCallback? onActionTriggered;

  /// Callback when the swipe is cancelled before activation.
  final VoidCallback? onSwipeCancelled;

  /// Callback when the reveal panel is opened.
  final VoidCallback? onPanelOpened;

  /// Callback when the reveal panel is closed.
  final VoidCallback? onPanelClosed;

  /// Creates a copy of this configuration with the given fields replaced.
  LeftSwipeConfig copyWith({
    LeftSwipeMode? mode,
    List<SwipeAction>? actions,
    double? actionPanelWidth,
    PostActionBehavior? postActionBehavior,
    bool? requireConfirmation,
    bool? enableHaptic,
    VoidCallback? onActionTriggered,
    VoidCallback? onSwipeCancelled,
    VoidCallback? onPanelOpened,
    VoidCallback? onPanelClosed,
  }) {
    return LeftSwipeConfig(
      mode: mode ?? this.mode,
      actions: actions ?? this.actions,
      actionPanelWidth: actionPanelWidth ?? this.actionPanelWidth,
      postActionBehavior: postActionBehavior ?? this.postActionBehavior,
      requireConfirmation: requireConfirmation ?? this.requireConfirmation,
      enableHaptic: enableHaptic ?? this.enableHaptic,
      onActionTriggered: onActionTriggered ?? this.onActionTriggered,
      onSwipeCancelled: onSwipeCancelled ?? this.onSwipeCancelled,
      onPanelOpened: onPanelOpened ?? this.onPanelOpened,
      onPanelClosed: onPanelClosed ?? this.onPanelClosed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeftSwipeConfig &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          listEquals(actions, other.actions) &&
          actionPanelWidth == other.actionPanelWidth &&
          postActionBehavior == other.postActionBehavior &&
          requireConfirmation == other.requireConfirmation &&
          enableHaptic == other.enableHaptic &&
          onActionTriggered == other.onActionTriggered &&
          onSwipeCancelled == other.onSwipeCancelled &&
          onPanelOpened == other.onPanelOpened &&
          onPanelClosed == other.onPanelClosed;

  @override
  int get hashCode =>
      mode.hashCode ^
      actions.hashCode ^
      actionPanelWidth.hashCode ^
      postActionBehavior.hashCode ^
      requireConfirmation.hashCode ^
      enableHaptic.hashCode ^
      onActionTriggered.hashCode ^
      onSwipeCancelled.hashCode ^
      onPanelOpened.hashCode ^
      onPanelClosed.hashCode;
}

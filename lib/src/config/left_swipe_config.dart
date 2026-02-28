import 'package:flutter/foundation.dart';

import '../actions/intentional/left_swipe_mode.dart';
import '../actions/intentional/post_action_behavior.dart';
import '../actions/intentional/swipe_action.dart';
import '../core/swipe_zone.dart';

/// Configuration for left-swipe intentional (one-shot) action behavior.
///
/// Pass as [SwipeActionCell.leftSwipeConfig] to enable left-swipe intentional
/// semantics. When `null`, left-swipe intentional behavior is disabled entirely.
///
/// Renamed from `IntentionalSwipeConfig` in F005. A new debug assertion has been
/// added for reveal mode with an empty [actions] list.
@immutable
class LeftSwipeConfig {
  /// Creates a [LeftSwipeConfig].
  const LeftSwipeConfig({
    required this.mode,
    this.actions = const [],
    this.actionPanelWidth,
    this.postActionBehavior = PostActionBehavior.snapBack,
    this.requireConfirmation = false,
    this.enableHaptic = false,
    this.onActionTriggered,
    this.onSwipeCancelled,
    this.onPanelOpened,
    this.onPanelClosed,
    this.zones,
    this.zoneTransitionStyle = ZoneTransitionStyle.instant,
  })  : assert(
          actionPanelWidth == null || actionPanelWidth > 0,
          'actionPanelWidth must be > 0 when provided, got $actionPanelWidth',
        ),
        assert(
          mode != LeftSwipeMode.reveal || actions.length > 0,
          'LeftSwipeConfig in reveal mode requires at least one action, '
          'but actions is empty.',
        ),
        assert(
          zones == null || zones.length <= 4,
          'zones must have at most 4 entries for the left swipe direction.',
        );

  /// The interaction mode: [LeftSwipeMode.autoTrigger] or [LeftSwipeMode.reveal].
  final LeftSwipeMode mode;

  /// When non-null and non-empty, overrides single-threshold behavior.
  final List<SwipeZone>? zones;

  /// Visual transition between zone backgrounds.
  final ZoneTransitionStyle zoneTransitionStyle;

  /// The action buttons displayed in the panel. Used only in [LeftSwipeMode.reveal].
  ///
  /// Must contain 1–3 [SwipeAction] items when mode is [LeftSwipeMode.reveal].
  /// More than 3 items: only the first 3 are rendered.
  final List<SwipeAction> actions;

  /// The width of the action panel in logical pixels. Used only in
  /// [LeftSwipeMode.reveal]. When `null`, auto-calculated from action count.
  final double? actionPanelWidth;

  /// What the cell does after an auto-trigger action fires.
  /// Used only in [LeftSwipeMode.autoTrigger].
  final PostActionBehavior postActionBehavior;

  /// Whether a second gesture (or background-area tap) is required to confirm
  /// the action. Used only in [LeftSwipeMode.autoTrigger].
  final bool requireConfirmation;

  /// Whether haptic feedback fires at swipe milestones.
  final bool enableHaptic;

  /// Called when an auto-trigger action fires successfully.
  final VoidCallback? onActionTriggered;

  /// Called when a left swipe is released below the activation threshold.
  final VoidCallback? onSwipeCancelled;

  /// Called when the reveal panel opens and the animation settles.
  final VoidCallback? onPanelOpened;

  /// Called when the reveal panel closes (any trigger).
  final VoidCallback? onPanelClosed;

  /// Returns a copy with the specified fields replaced.
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
    List<SwipeZone>? zones,
    ZoneTransitionStyle? zoneTransitionStyle,
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
      zones: zones ?? this.zones,
      zoneTransitionStyle: zoneTransitionStyle ?? this.zoneTransitionStyle,
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
          onPanelClosed == other.onPanelClosed &&
          listEquals(zones, other.zones) &&
          zoneTransitionStyle == other.zoneTransitionStyle;

  @override
  int get hashCode => Object.hashAll([
        mode,
        actions,
        actionPanelWidth,
        postActionBehavior,
        requireConfirmation,
        enableHaptic,
        onActionTriggered,
        onSwipeCancelled,
        onPanelOpened,
        onPanelClosed,
        zones,
        zoneTransitionStyle,
      ]);
}

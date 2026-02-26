import 'package:flutter/foundation.dart';

import 'left_swipe_mode.dart';
import 'post_action_behavior.dart';
import 'swipe_action.dart';

/// Configuration for left-swipe intentional (one-shot) action behavior.
///
/// Pass as [SwipeActionCell.leftSwipe] to enable left-swipe intentional
/// semantics. When `null`, left-swipe intentional behavior is disabled entirely.
///
/// Two mutually exclusive modes are supported, set via [mode]:
/// - **[LeftSwipeMode.autoTrigger]**: Swipe fires a one-shot callback.
///   Post-action cell position controlled by [postActionBehavior].
/// - **[LeftSwipeMode.reveal]**: Swipe opens an action panel with 1–3 buttons.
///   Panel stays open until a button is tapped, the cell body is tapped, or
///   the user swipes right to close.
///
/// Example — auto-trigger (delete on swipe):
/// ```dart
/// SwipeActionCell(
///   leftSwipe: IntentionalSwipeConfig(
///     mode: LeftSwipeMode.autoTrigger,
///     postActionBehavior: PostActionBehavior.animateOut,
///     onActionTriggered: () => deleteItem(item),
///   ),
///   child: ListTile(title: Text(item.title)),
/// )
/// ```
///
/// Example — reveal panel:
/// ```dart
/// SwipeActionCell(
///   leftSwipe: IntentionalSwipeConfig(
///     mode: LeftSwipeMode.reveal,
///     actions: [
///       SwipeAction(
///         icon: const Icon(Icons.archive),
///         label: 'Archive',
///         backgroundColor: const Color(0xFF43A047),
///         foregroundColor: Colors.white,
///         onTap: () => archiveItem(item),
///       ),
///     ],
///   ),
///   child: ListTile(title: Text(item.title)),
/// )
/// ```
@immutable
class IntentionalSwipeConfig {
  /// Creates an [IntentionalSwipeConfig].
  ///
  /// [mode] is required. All other parameters are optional with sensible defaults.
  const IntentionalSwipeConfig({
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
  }) : assert(
          actionPanelWidth == null || actionPanelWidth > 0,
          'actionPanelWidth must be > 0 when provided',
        );

  /// The interaction mode. [LeftSwipeMode.autoTrigger] or [LeftSwipeMode.reveal].
  final LeftSwipeMode mode;

  /// The action buttons displayed in the panel. Used only in [LeftSwipeMode.reveal].
  ///
  /// Must contain 1–3 [SwipeAction] items. An empty list disables the feature.
  /// More than 3 items: only the first 3 are rendered (debug assertion fired).
  final List<SwipeAction> actions;

  /// The width of the action panel in logical pixels. Used only in [LeftSwipeMode.reveal].
  ///
  /// When `null`, width is auto-calculated from action count and content.
  /// Must be > 0 when provided.
  final double? actionPanelWidth;

  /// What the cell does after an auto-trigger action fires.
  /// Used only in [LeftSwipeMode.autoTrigger]. Default: [PostActionBehavior.snapBack].
  ///
  /// Has no effect in [LeftSwipeMode.reveal].
  final PostActionBehavior postActionBehavior;

  /// Whether a second swipe (or background-area tap) is required to confirm the action.
  /// Used only in [LeftSwipeMode.autoTrigger]. Default: `false`.
  ///
  /// When `true`, the first swipe past threshold holds the cell at the fully-open
  /// position. A second left swipe past threshold, or a tap on the exposed
  /// [SwipeActionCell.leftBackground] area, fires [onActionTriggered]. A right
  /// swipe or cell-body tap cancels.
  ///
  /// Has no effect in [LeftSwipeMode.reveal].
  final bool requireConfirmation;

  /// Whether haptic feedback fires at swipe milestones.
  ///
  /// When `true`:
  /// - Light haptic fires once when the drag crosses the activation threshold.
  /// - Medium haptic fires when an action executes (button tap or auto-trigger fire).
  ///
  /// Default: `false`.
  final bool enableHaptic;

  /// Called when an auto-trigger action fires successfully.
  ///
  /// Fires after the animation settles at the open position (or after the
  /// confirmation is accepted, if [requireConfirmation] is `true`).
  /// Used only in [LeftSwipeMode.autoTrigger].
  final VoidCallback? onActionTriggered;

  /// Called when a left swipe is released below the activation threshold.
  ///
  /// Does NOT fire during the post-action snap-back following a successful trigger.
  /// Used only in [LeftSwipeMode.autoTrigger].
  final VoidCallback? onSwipeCancelled;

  /// Called when the reveal panel opens and the animation settles.
  /// Used only in [LeftSwipeMode.reveal].
  final VoidCallback? onPanelOpened;

  /// Called when the reveal panel closes, regardless of trigger (button tap,
  /// cell body tap, or right swipe). Used only in [LeftSwipeMode.reveal].
  final VoidCallback? onPanelClosed;

  /// Returns a copy with the specified fields replaced.
  IntentionalSwipeConfig copyWith({
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
    return IntentionalSwipeConfig(
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
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is IntentionalSwipeConfig &&
        other.mode == mode &&
        listEquals(other.actions, actions) &&
        other.actionPanelWidth == actionPanelWidth &&
        other.postActionBehavior == postActionBehavior &&
        other.requireConfirmation == requireConfirmation &&
        other.enableHaptic == enableHaptic &&
        other.onActionTriggered == onActionTriggered &&
        other.onSwipeCancelled == onSwipeCancelled &&
        other.onPanelOpened == onPanelOpened &&
        other.onPanelClosed == onPanelClosed;
  }

  @override
  int get hashCode => Object.hash(
        mode,
        Object.hashAll(actions),
        actionPanelWidth,
        postActionBehavior,
        requireConfirmation,
        enableHaptic,
        onActionTriggered,
        onSwipeCancelled,
        onPanelOpened,
        onPanelClosed,
      );
}

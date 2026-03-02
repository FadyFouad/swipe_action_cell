import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors, ColoredBox;
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../accessibility/swipe_semantic_config.dart';
import '../actions/full_swipe/full_swipe_config.dart';
import '../actions/full_swipe/full_swipe_expand_overlay.dart';
import '../actions/intentional/left_swipe_mode.dart';
import '../actions/intentional/post_action_behavior.dart';
import '../actions/intentional/swipe_action.dart';
import '../actions/intentional/swipe_action_panel.dart';
import '../actions/progressive/progressive_swipe_indicator.dart';
import '../actions/progressive/progressive_value_logic.dart';
import '../animation/spring_config.dart';
import '../animation/swipe_animation_config.dart';
import '../config/left_swipe_config.dart';
import '../config/right_swipe_config.dart';
import '../config/swipe_action_cell_theme.dart';
import '../config/swipe_visual_config.dart';
import '../controller/swipe_cell_handle.dart';
import '../controller/swipe_controller.dart';
import '../controller/swipe_controller_provider.dart';
import '../controller/swipe_group_controller.dart';
import '../core/swipe_direction.dart';
import '../core/swipe_direction_resolver.dart';
import '../core/swipe_progress.dart';
import '../core/swipe_state.dart';
import '../core/swipe_zone.dart';
import '../feedback/feedback_dispatcher.dart';
import '../feedback/swipe_feedback_config.dart';
import '../gesture/swipe_gesture_config.dart';
import '../painting/swipe_morph_icon.dart';
import '../painting/swipe_painting_config.dart';
import '../painting/swipe_particle_painter.dart';
import '../scroll/swipe_gesture_recognizer.dart';
import '../templates/swipe_cell_templates.dart';
import '../templates/template_style.dart';
import '../undo/swipe_undo_config.dart';
import '../undo/swipe_undo_overlay.dart';
import '../undo/undo_data.dart';
import '../zones/zone_background.dart';
import '../zones/zone_resolver.dart';

/// A widget that wraps any child and provides spring-based horizontal swipe
/// interaction with asymmetric left/right semantics.
///
/// Right swipe is the **progressive** direction: incremental value tracking,
/// counter increments, or any repeatable action. Left swipe is the
/// **intentional** direction: auto-trigger (delete/archive) or reveal (action panel).
///
/// ```dart
/// SwipeActionCell(
///   rightSwipeConfig: RightSwipeConfig(
///     onSwipeCompleted: (value) => print('Count: $value'),
///   ),
///   leftSwipeConfig: LeftSwipeConfig(
///     mode: LeftSwipeMode.reveal,
///     actions: [
///       SwipeAction(
///         icon: const Icon(Icons.delete),
///         label: 'Delete',
///         backgroundColor: Colors.red,
///         foregroundColor: Colors.white,
///         onTap: () => deleteItem(),
///       ),
///     ],
///   ),
///   child: const ListTile(title: Text('Swipe me')),
/// )
/// ```
///
/// For the simplest use case, prefer the factory constructors:
/// [SwipeActionCell.delete], [SwipeActionCell.archive], [SwipeActionCell.favorite],
/// [SwipeActionCell.checkbox], [SwipeActionCell.counter], [SwipeActionCell.standard].
class SwipeActionCell extends StatefulWidget {
  /// Creates a [SwipeActionCell].
  ///
  /// Only [child] is required. All config parameters default to `null`,
  /// which either falls through to a [SwipeActionCellTheme] in the widget
  /// tree or to the package's built-in defaults.
  ///
  /// Passing `null` for [rightSwipeConfig] or [leftSwipeConfig] completely
  /// disables that swipe direction — no gesture recognition, no visual
  /// feedback, no callbacks fired.
  const SwipeActionCell({
    super.key,
    required this.child,
    this.rightSwipeConfig,
    this.leftSwipeConfig,
    this.forwardSwipeConfig,
    this.backwardSwipeConfig,
    this.forceDirection = ForceDirection.auto,
    this.semanticConfig,
    this.gestureConfig,
    this.animationConfig,
    this.visualConfig,
    this.controller,
    this.enabled = true,
    this.onStateChanged,
    this.onProgressChanged,
    this.feedbackConfig,
    this.undoConfig,
    this.paintingConfig,
    this.onFullSwipeTriggered,
  });

  /// The widget displayed inside the swipe cell.
  final Widget child;

  /// Configuration for right-swipe progressive (incremental) action behavior.
  ///
  /// When `null` and no [SwipeActionCellTheme] provides a value, right-swipe
  /// progressive behavior is disabled entirely — zero overhead.
  final RightSwipeConfig? rightSwipeConfig;

  /// Configuration for left-swipe intentional (one-shot or reveal) behavior.
  ///
  /// When `null` and no [SwipeActionCellTheme] provides a value, left-swipe
  /// intentional behavior is disabled entirely — zero overhead.
  final LeftSwipeConfig? leftSwipeConfig;

  /// Semantic alias for right-swipe config (LTR) / left-swipe config (RTL).
  ///
  /// Use this when you want the same configuration to work correctly as the
  /// "forward" (progressive) action in both LTR and RTL layouts. Takes
  /// precedence over [rightSwipeConfig].
  ///
  /// When null, falls back to [rightSwipeConfig].
  final RightSwipeConfig? forwardSwipeConfig;

  /// Semantic alias for left-swipe config (LTR) / right-swipe config (RTL).
  ///
  /// Use this when you want the same configuration to work correctly as the
  /// "backward" (intentional) action in both LTR and RTL layouts. Takes
  /// precedence over [leftSwipeConfig].
  ///
  /// When null, falls back to [leftSwipeConfig].
  final LeftSwipeConfig? backwardSwipeConfig;

  /// Manual override for direction resolution.
  ///
  /// Defaults to [ForceDirection.auto], which reads [Directionality.of(context)].
  /// Set to [ForceDirection.ltr] or [ForceDirection.rtl] to force a specific
  /// layout direction regardless of the ambient [Directionality].
  final ForceDirection forceDirection;

  /// Accessibility labels and announcement configuration.
  ///
  /// When null, all labels use direction-adaptive defaults. When provided,
  /// any null field within this config also falls back to direction-adaptive
  /// defaults.
  final SwipeSemanticConfig? semanticConfig;

  /// Configuration for gesture recognition behavior.
  ///
  /// When `null`, uses [SwipeActionCellTheme.gestureConfig] if present,
  /// otherwise falls back to [SwipeGestureConfig] defaults.
  final SwipeGestureConfig? gestureConfig;

  /// Configuration for animation physics.
  ///
  /// When `null`, uses [SwipeActionCellTheme.animationConfig] if present,
  /// otherwise falls back to [SwipeAnimationConfig] defaults.
  final SwipeAnimationConfig? animationConfig;

  /// Configuration for visual presentation (backgrounds, clip, border radius).
  ///
  /// When `null`, uses [SwipeActionCellTheme.visualConfig] if present,
  /// otherwise no backgrounds, hard-edge clip, no border radius.
  final SwipeVisualConfig? visualConfig;

  /// External controller for programmatic swipe operations.
  ///
  /// Accepted and stored but has no effect in this release. Reserved for F007.
  final SwipeController? controller;

  /// Whether swipe interactions are active.
  ///
  /// When `false`, all gesture recognition is bypassed and touch events pass
  /// through to the child unchanged.
  final bool enabled;

  /// Called whenever the swipe state machine transitions to a new state.
  final ValueChanged<SwipeState>? onStateChanged;

  /// Called on every frame during a drag with the current swipe progress.
  final ValueChanged<SwipeProgress>? onProgressChanged;

  /// Per-cell feedback configuration.
  final SwipeFeedbackConfig? feedbackConfig;

  /// Configuration for undo/revert support.
  final SwipeUndoConfig? undoConfig;

  /// Configuration for custom painting and decoration hooks.
  final SwipePaintingConfig? paintingConfig;

  /// Called when a full-swipe action is triggered.
  final void Function(SwipeDirection direction, SwipeAction action)?
      onFullSwipeTriggered;

  @override

  /// Creates a [SwipeActionCell] configured for a delete action.
  factory SwipeActionCell.delete({
    required Widget child,
    required VoidCallback onDeleted,
    Color? backgroundColor,
    Widget? icon,
    String? semanticLabel,
    TemplateStyle style = TemplateStyle.auto,
    SwipeController? controller,
  }) {
    final resolved = resolveStyle(style);
    final assets = deleteAssets(resolved, icon, backgroundColor);
    return SwipeActionCell(
      controller: controller,
      leftSwipeConfig: LeftSwipeConfig(
        mode: LeftSwipeMode.autoTrigger,
        postActionBehavior: PostActionBehavior.animateOut,
        enableHaptic: true,
        fullSwipeConfig: FullSwipeConfig(
          enabled: true,
          threshold: 0.75,
          action: SwipeAction(
            icon: icon ?? assets.primaryIcon,
            label: semanticLabel ?? 'Delete item',
            onTap: onDeleted,
            backgroundColor: backgroundColor ?? assets.backgroundColor,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      undoConfig: SwipeUndoConfig(
        onUndoExpired: onDeleted,
      ),
      visualConfig: buildVisualConfig(
        resolvedStyle: resolved,
        leftBackground: (context, progress) => ColoredBox(
          color: assets.backgroundColor,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: assets.primaryIcon,
            ),
          ),
        ),
      ),
      semanticConfig: SwipeSemanticConfig(
        leftSwipeLabel: SemanticLabel.string(semanticLabel ?? 'Delete item'),
      ),
      child: child,
    );
  }

  /// Creates a [SwipeActionCell] configured for an archive action.
  factory SwipeActionCell.archive({
    required Widget child,
    required VoidCallback onArchived,
    Color? backgroundColor,
    Widget? icon,
    String? semanticLabel,
    TemplateStyle style = TemplateStyle.auto,
    SwipeController? controller,
  }) {
    final resolved = resolveStyle(style);
    final assets = archiveAssets(resolved, icon, backgroundColor);
    return SwipeActionCell(
      controller: controller,
      leftSwipeConfig: LeftSwipeConfig(
        mode: LeftSwipeMode.autoTrigger,
        postActionBehavior: PostActionBehavior.animateOut,
        onActionTriggered: onArchived,
        enableHaptic: true,
        fullSwipeConfig: FullSwipeConfig(
          enabled: true,
          threshold: 0.75,
          action: SwipeAction(
            icon: icon ?? assets.primaryIcon,
            label: semanticLabel ?? 'Archive item',
            onTap: onArchived,
            backgroundColor: backgroundColor ?? assets.backgroundColor,
            foregroundColor: Colors.white,
          ),
        ),
      ),
      visualConfig: buildVisualConfig(
        resolvedStyle: resolved,
        leftBackground: (context, progress) => ColoredBox(
          color: assets.backgroundColor,
          child: Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: assets.primaryIcon,
            ),
          ),
        ),
      ),
      semanticConfig: SwipeSemanticConfig(
        leftSwipeLabel: SemanticLabel.string(semanticLabel ?? 'Archive item'),
      ),
      child: child,
    );
  }

  /// Creates a [SwipeActionCell] configured for a favorite toggle action.
  factory SwipeActionCell.favorite({
    required Widget child,
    required bool isFavorited,
    required ValueChanged<bool> onToggle,
    Color? backgroundColor,
    Widget? outlineIcon,
    Widget? filledIcon,
    String? semanticLabel,
    TemplateStyle style = TemplateStyle.auto,
    SwipeController? controller,
  }) {
    final resolved = resolveStyle(style);
    final assets =
        favoriteAssets(resolved, outlineIcon, filledIcon, backgroundColor);
    return SwipeActionCell(
      controller: controller,
      rightSwipeConfig: RightSwipeConfig(
        onSwipeCompleted: (_) => onToggle(!isFavorited),
        enableHaptic: true,
      ),
      visualConfig: buildVisualConfig(
        resolvedStyle: resolved,
        rightBackground: (context, progress) => ColoredBox(
          color: assets.backgroundColor,
          child: Center(
            child: SwipeMorphIcon(
              startIcon: assets.outlineIcon,
              endIcon: assets.filledIcon,
              progress: progress.ratio,
            ),
          ),
        ),
      ),
      semanticConfig: SwipeSemanticConfig(
        rightSwipeLabel: SemanticLabel.string(
          semanticLabel ??
              (isFavorited ? 'Remove from favorites' : 'Add to favorites'),
        ),
      ),
      child: child,
    );
  }

  /// Creates a [SwipeActionCell] configured for a checkbox toggle action.
  factory SwipeActionCell.checkbox({
    required Widget child,
    required bool isChecked,
    required ValueChanged<bool> onChanged,
    Color? backgroundColor,
    Widget? uncheckedIcon,
    Widget? checkedIcon,
    String? semanticLabel,
    TemplateStyle style = TemplateStyle.auto,
    SwipeController? controller,
  }) {
    final resolved = resolveStyle(style);
    final assets =
        checkboxAssets(resolved, uncheckedIcon, checkedIcon, backgroundColor);
    return SwipeActionCell(
      controller: controller,
      rightSwipeConfig: RightSwipeConfig(
        onSwipeCompleted: (_) => onChanged(!isChecked),
        enableHaptic: true,
      ),
      visualConfig: buildVisualConfig(
        resolvedStyle: resolved,
        rightBackground: (context, progress) => ColoredBox(
          color: assets.backgroundColor,
          child: Center(
            child: SwipeMorphIcon(
              startIcon: assets.uncheckedIcon,
              endIcon: assets.checkedIcon,
              progress: progress.ratio,
            ),
          ),
        ),
      ),
      semanticConfig: SwipeSemanticConfig(
        rightSwipeLabel: SemanticLabel.string(
          semanticLabel ??
              (isChecked ? 'Mark as incomplete' : 'Mark as complete'),
        ),
      ),
      child: child,
    );
  }

  /// Creates a [SwipeActionCell] configured for a counter increment action.
  factory SwipeActionCell.counter({
    required Widget child,
    required int count,
    required ValueChanged<int> onCountChanged,
    int? max,
    Color? backgroundColor,
    Widget? icon,
    String? semanticLabel,
    TemplateStyle style = TemplateStyle.auto,
    SwipeController? controller,
  }) {
    final resolved = resolveStyle(style);
    final assets = counterAssets(resolved, icon, backgroundColor);
    final atMax = max != null && max > 0 && count >= max;
    return SwipeActionCell(
      controller: controller,
      rightSwipeConfig: atMax
          ? null
          : RightSwipeConfig(
              onSwipeCompleted: (_) => onCountChanged(count + 1),
              enableHaptic: true,
            ),
      visualConfig: buildVisualConfig(
        resolvedStyle: resolved,
        rightBackground: atMax
            ? null
            : (context, progress) => ColoredBox(
                  color: assets.backgroundColor,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        assets.primaryIcon,
                        const SizedBox(width: 8),
                        Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
      semanticConfig: SwipeSemanticConfig(
        rightSwipeLabel: SemanticLabel.string(semanticLabel ?? 'Increment'),
      ),
      child: child,
    );
  }

  /// Creates a [SwipeActionCell] configured with a standard reveal action panel
  /// and a favorite toggle shortcut.
  factory SwipeActionCell.standard({
    required Widget child,
    ValueChanged<bool>? onFavorited,
    bool isFavorited = false,
    List<SwipeAction>? actions,
    TemplateStyle style = TemplateStyle.auto,
    SwipeController? controller,
  }) {
    final resolved = resolveStyle(style);
    final favAssets = favoriteAssets(resolved, null, null, null);
    final hasRight = onFavorited != null;
    final hasLeft = actions != null && actions.isNotEmpty;
    return SwipeActionCell(
      controller: controller,
      rightSwipeConfig: hasRight
          ? RightSwipeConfig(
              onSwipeCompleted: (_) => onFavorited(!isFavorited),
              enableHaptic: true,
            )
          : null,
      leftSwipeConfig: hasLeft
          ? LeftSwipeConfig(
              mode: LeftSwipeMode.reveal,
              actions: actions,
              enableHaptic: true,
            )
          : null,
      visualConfig: buildVisualConfig(
        resolvedStyle: resolved,
        rightBackground: hasRight
            ? (context, progress) => ColoredBox(
                  color: favAssets.backgroundColor,
                  child: Center(
                    child: SwipeMorphIcon(
                      startIcon: favAssets.outlineIcon,
                      endIcon: favAssets.filledIcon,
                      progress: progress.ratio,
                    ),
                  ),
                )
            : null,
      ),
      child: child,
    );
  }

  /// Creates a [SwipeActionCell] delete template with forced Material styling.
  static SwipeActionCell deleteMaterial({
    required Widget child,
    required VoidCallback onDeleted,
    Color? backgroundColor,
    Widget? icon,
    String? semanticLabel,
    SwipeController? controller,
  }) =>
      SwipeActionCell.delete(
        onDeleted: onDeleted,
        backgroundColor: backgroundColor,
        icon: icon,
        semanticLabel: semanticLabel,
        style: TemplateStyle.material,
        controller: controller,
        child: child,
      );

  /// Creates a [SwipeActionCell] delete template with forced Cupertino styling.
  static SwipeActionCell deleteCupertino({
    required Widget child,
    required VoidCallback onDeleted,
    Color? backgroundColor,
    Widget? icon,
    String? semanticLabel,
    SwipeController? controller,
  }) =>
      SwipeActionCell.delete(
        onDeleted: onDeleted,
        backgroundColor: backgroundColor,
        icon: icon,
        semanticLabel: semanticLabel,
        style: TemplateStyle.cupertino,
        controller: controller,
        child: child,
      );

  /// Creates a [SwipeActionCell] archive template with forced Material styling.
  static SwipeActionCell archiveMaterial({
    required Widget child,
    required VoidCallback onArchived,
    Color? backgroundColor,
    Widget? icon,
    String? semanticLabel,
    SwipeController? controller,
  }) =>
      SwipeActionCell.archive(
        onArchived: onArchived,
        backgroundColor: backgroundColor,
        icon: icon,
        semanticLabel: semanticLabel,
        style: TemplateStyle.material,
        controller: controller,
        child: child,
      );

  /// Creates a [SwipeActionCell] archive template with forced Cupertino styling.
  static SwipeActionCell archiveCupertino({
    required Widget child,
    required VoidCallback onArchived,
    Color? backgroundColor,
    Widget? icon,
    String? semanticLabel,
    SwipeController? controller,
  }) =>
      SwipeActionCell.archive(
        onArchived: onArchived,
        backgroundColor: backgroundColor,
        icon: icon,
        semanticLabel: semanticLabel,
        style: TemplateStyle.cupertino,
        controller: controller,
        child: child,
      );

  /// Creates a [SwipeActionCell] favorite template with forced Material styling.
  static SwipeActionCell favoriteMaterial({
    required Widget child,
    required bool isFavorited,
    required ValueChanged<bool> onToggle,
    Color? backgroundColor,
    Widget? outlineIcon,
    Widget? filledIcon,
    String? semanticLabel,
    SwipeController? controller,
  }) =>
      SwipeActionCell.favorite(
        isFavorited: isFavorited,
        onToggle: onToggle,
        backgroundColor: backgroundColor,
        outlineIcon: outlineIcon,
        filledIcon: filledIcon,
        semanticLabel: semanticLabel,
        style: TemplateStyle.material,
        controller: controller,
        child: child,
      );

  /// Creates a [SwipeActionCell] favorite template with forced Cupertino styling.
  static SwipeActionCell favoriteCupertino({
    required Widget child,
    required bool isFavorited,
    required ValueChanged<bool> onToggle,
    Color? backgroundColor,
    Widget? outlineIcon,
    Widget? filledIcon,
    String? semanticLabel,
    SwipeController? controller,
  }) =>
      SwipeActionCell.favorite(
        isFavorited: isFavorited,
        onToggle: onToggle,
        backgroundColor: backgroundColor,
        outlineIcon: outlineIcon,
        filledIcon: filledIcon,
        semanticLabel: semanticLabel,
        style: TemplateStyle.cupertino,
        controller: controller,
        child: child,
      );

  /// Creates a [SwipeActionCell] checkbox template with forced Material styling.
  static SwipeActionCell checkboxMaterial({
    required Widget child,
    required bool isChecked,
    required ValueChanged<bool> onChanged,
    Color? backgroundColor,
    Widget? uncheckedIcon,
    Widget? checkedIcon,
    String? semanticLabel,
    SwipeController? controller,
  }) =>
      SwipeActionCell.checkbox(
        isChecked: isChecked,
        onChanged: onChanged,
        backgroundColor: backgroundColor,
        uncheckedIcon: uncheckedIcon,
        checkedIcon: checkedIcon,
        semanticLabel: semanticLabel,
        style: TemplateStyle.material,
        controller: controller,
        child: child,
      );

  /// Creates a [SwipeActionCell] checkbox template with forced Cupertino styling.
  static SwipeActionCell checkboxCupertino({
    required Widget child,
    required bool isChecked,
    required ValueChanged<bool> onChanged,
    Color? backgroundColor,
    Widget? uncheckedIcon,
    Widget? checkedIcon,
    String? semanticLabel,
    SwipeController? controller,
  }) =>
      SwipeActionCell.checkbox(
        isChecked: isChecked,
        onChanged: onChanged,
        backgroundColor: backgroundColor,
        uncheckedIcon: uncheckedIcon,
        checkedIcon: checkedIcon,
        semanticLabel: semanticLabel,
        style: TemplateStyle.cupertino,
        controller: controller,
        child: child,
      );

  /// Creates a [SwipeActionCell] counter template with forced Material styling.
  static SwipeActionCell counterMaterial({
    required Widget child,
    required int count,
    required ValueChanged<int> onCountChanged,
    int? max,
    Color? backgroundColor,
    Widget? icon,
    String? semanticLabel,
    SwipeController? controller,
  }) =>
      SwipeActionCell.counter(
        count: count,
        onCountChanged: onCountChanged,
        max: max,
        backgroundColor: backgroundColor,
        icon: icon,
        semanticLabel: semanticLabel,
        style: TemplateStyle.material,
        controller: controller,
        child: child,
      );

  /// Creates a [SwipeActionCell] counter template with forced Cupertino styling.
  static SwipeActionCell counterCupertino({
    required Widget child,
    required int count,
    required ValueChanged<int> onCountChanged,
    int? max,
    Color? backgroundColor,
    Widget? icon,
    String? semanticLabel,
    SwipeController? controller,
  }) =>
      SwipeActionCell.counter(
        count: count,
        onCountChanged: onCountChanged,
        max: max,
        backgroundColor: backgroundColor,
        icon: icon,
        semanticLabel: semanticLabel,
        style: TemplateStyle.cupertino,
        controller: controller,
        child: child,
      );

  /// Creates a [SwipeActionCell] standard template with forced Material styling.
  static SwipeActionCell standardMaterial({
    required Widget child,
    ValueChanged<bool>? onFavorited,
    bool isFavorited = false,
    List<SwipeAction>? actions,
    SwipeController? controller,
  }) =>
      SwipeActionCell.standard(
        onFavorited: onFavorited,
        isFavorited: isFavorited,
        actions: actions,
        style: TemplateStyle.material,
        controller: controller,
        child: child,
      );

  /// Creates a [SwipeActionCell] standard template with forced Cupertino styling.
  static SwipeActionCell standardCupertino({
    required Widget child,
    ValueChanged<bool>? onFavorited,
    bool isFavorited = false,
    List<SwipeAction>? actions,
    SwipeController? controller,
  }) =>
      SwipeActionCell.standard(
        onFavorited: onFavorited,
        isFavorited: isFavorited,
        actions: actions,
        style: TemplateStyle.cupertino,
        controller: controller,
        child: child,
      );

  @override
  State<SwipeActionCell> createState() => SwipeActionCellState();
}

/// Mutable state for [SwipeActionCell].
///
/// Exposed for testing via `tester.state<SwipeActionCellState>(...)`.
class SwipeActionCellState extends State<SwipeActionCell>
    with TickerProviderStateMixin
    implements SwipeCellHandle {
  // F016 full-swipe fields.
  bool _isFullSwipeArmed = false;
  bool _fullSwipeTriggered = false;
  double _fullSwipeRatio = 0.0;

  late final AnimationController _controller;
  SwipeState _state = SwipeState.idle;

  /// The current state of this cell's interaction state machine.
  ///
  /// Exposed for widget test inspection.
  SwipeState get currentSwipeState => _state;

  /// The current animation controller value (0.0 = closed, 1.0 = fully open).
  double get currentSwipeRatio => _controller.value;

  SwipeDirection _lockedDirection = SwipeDirection.none;
  double _accumulatedDx = 0.0;

  // F13 particle fields.
  AnimationController? _particleController;
  List<Particle>? _particles;

  // F11 undo fields.
  bool _undoPending = false;
  double? _undoOldValue;
  double? _undoNewValue;
  PostActionBehavior? _lastPostActionBehavior;
  Timer? _undoTimer;
  AnimationController? _undoBarController;

  // F3 progressive fields.
  ValueNotifier<double>? _progressValueNotifier;
  bool _isPostIncrementSnapBack = false;
  bool _swipeStartedFired = false;
  bool _hapticThresholdFired = false;
  int _lastHapticZoneIndex = -1;
  int _currentZoneIndex = -1;
  SwipeZone? _activeZoneAtRelease;

  // F7 controller fields.
  /// Internal controller created when [SwipeActionCell.controller] is null.
  SwipeController? _internalController;

  /// The effective controller: consumer-provided or the internal one.
  SwipeController get _effectiveController =>
      widget.controller ?? _internalController!;

  /// The group this cell is currently registered with (cached to enable cleanup).
  SwipeGroupController? _registeredGroup;

  /// Cached widget width from [LayoutBuilder]; used for animateOut target.
  double _widgetWidth = 400.0;
  Offset _burstOrigin = Offset.zero;

  /// True during a post-action snap-back so [onSwipeCancelled] is not fired.
  bool _isPostActionSnapBack = false;

  /// True after the first swipe completes when [requireConfirmation] is true.
  bool _awaitingConfirmation = false;

  // F007: scroll-position listener for close-on-scroll.
  FeedbackDispatcher? _feedbackDispatcher;
  ScrollPosition? _scrollPosition;

  // F8: accessibility fields.
  late final FocusNode _cellFocusNode;

  // ── F8: RTL-aware computed properties ──────────────────────────────────────
  /// Whether the effective direction is right-to-left.
  bool get _isRtl =>
      SwipeDirectionResolver.isRtl(context, widget.forceDirection);

  /// The resolved forward (progressive) config, considering semantic aliases.
  RightSwipeConfig? get _resolvedForwardConfig =>
      widget.forwardSwipeConfig ?? effectiveRightSwipeConfig;

  /// The resolved backward (intentional) config, considering semantic aliases.
  LeftSwipeConfig? get _resolvedBackwardConfig =>
      widget.backwardSwipeConfig ?? effectiveLeftSwipeConfig;

  /// Whether the current locked direction corresponds to the forward action.
  bool get _dragIsForward =>
      _lockedDirection == SwipeDirectionResolver.forwardPhysical(_isRtl);

  /// Whether the current locked direction corresponds to the backward action.
  bool get _dragIsBackward =>
      _lockedDirection == SwipeDirectionResolver.backwardPhysical(_isRtl);

  /// The resolved gesture config after applying the theme/local/default cascade.
  late SwipeGestureConfig effectiveGestureConfig;

  /// The resolved animation config after applying the theme/local/default cascade.
  late SwipeAnimationConfig effectiveAnimationConfig;

  /// The resolved right-swipe config, or `null` if right-swipe is disabled.
  RightSwipeConfig? effectiveRightSwipeConfig;

  /// The resolved left-swipe config, or `null` if left-swipe is disabled.
  LeftSwipeConfig? effectiveLeftSwipeConfig;

  /// The resolved visual config after applying the theme/local/default cascade.
  late SwipeVisualConfig effectiveVisualConfig;

  List<SwipeZone>? _effectiveForwardZones() =>
      _resolvedForwardConfig?.zones?.isNotEmpty == true
          ? _resolvedForwardConfig!.zones
          : null;

  bool _hasActiveZones() =>
      (_dragIsForward ? _effectiveForwardZones() : _effectiveBackwardZones()) !=
      null;

  List<SwipeZone>? _effectiveBackwardZones() =>
      _resolvedBackwardConfig?.zones?.isNotEmpty == true
          ? _resolvedBackwardConfig!.zones
          : null;

  // ── F11: Undo Logic ───────────────────────────────────────────────────────
  void _startParticleBurst() {
    final config = widget.paintingConfig!.particleConfig!;
    if (config.count <= 0) return;
    final colors = config.colors.isEmpty
        ? const [Color(0xFFFFC107), Color(0xFFFF9800), Color(0xFFF44336)]
        : config.colors;
    final spreadRad = (config.spreadAngle <= 0 ? 360.0 : config.spreadAngle) *
        (math.pi / 180.0);
    final startAngle = -spreadRad / 2;
    _particles = List.generate(config.count, (i) {
      final angle = startAngle +
          (spreadRad / config.count) * i +
          (math.Random().nextDouble() - 0.5) * (spreadRad / config.count);
      return Particle(
        angle: angle,
        maxDistance: 20.0 + math.Random().nextDouble() * 40.0,
        color: colors[i % colors.length],
      );
    });
    _particleController!
      ..duration = config.duration
      ..forward(from: 0.0).then((_) {
        if (mounted) {
          setState(() => _particles = null);
        }
      });
    setState(() {});
  }

  void _startUndoWindow() {
    final config = widget.undoConfig;
    if (config == null) return;
    _particleController?.dispose();
    _undoTimer?.cancel();
    _undoBarController?.stop();
    _undoBarController?.value = 1.0;
    _undoPending = true;
    _effectiveController.reportUndoPending(true);
    final data = UndoData(
      oldValue: _undoOldValue,
      newValue: _undoNewValue,
      remainingDuration: config.duration,
      revert: _triggerUndo,
    );
    config.onUndoAvailable?.call(data);
    if (MediaQuery.of(context).disableAnimations != true) {
      _undoBarController?.reverse();
    }
    _undoTimer = Timer(config.duration, _commitUndo);
    setState(() {});
  }

  void _triggerUndo() {
    if (!_undoPending || !mounted) return;
    _particleController?.dispose();
    _undoTimer?.cancel();
    _undoBarController?.stop();
    _undoPending = false;
    _effectiveController.reportUndoPending(false);
    if (_lastPostActionBehavior == PostActionBehavior.animateOut) {
      _updateState(SwipeState.animatingToClose);
      final simulation = SpringSimulation(
        SpringDescription(
          mass: SpringConfig.undoReveal.mass,
          stiffness: SpringConfig.undoReveal.stiffness,
          damping: SpringConfig.undoReveal.damping,
        ),
        _controller.value,
        0.0,
        0.0,
      );
      _controller.animateWith(simulation);
    } else if (_undoOldValue != null) {
      _progressValueNotifier!.value = _undoOldValue!;
      _effectiveController.reportProgress(_undoOldValue!);
    }
    widget.undoConfig?.onUndoTriggered?.call();
    setState(() {});
  }

  void _commitUndo() {
    if (!_undoPending || !mounted) return;
    _particleController?.dispose();
    _undoTimer?.cancel();
    _undoBarController?.stop();
    _undoPending = false;
    _effectiveController.reportUndoPending(false);
    widget.undoConfig?.onUndoExpired?.call();
    setState(() {});
  }

  @override
  void executeUndo() => _triggerUndo();

  @override
  void executeCommitUndo() => _commitUndo();

  void _fireZoneHaptic(SwipeZoneHaptic? pattern) {
    if (pattern == null) return;
    switch (pattern) {
      case SwipeZoneHaptic.light:
        HapticFeedback.lightImpact();
        break;
      case SwipeZoneHaptic.medium:
        HapticFeedback.mediumImpact();
        break;
      case SwipeZoneHaptic.heavy:
        HapticFeedback.heavyImpact();
        break;
    }
  }

  /// A [ValueListenable] that emits the current swipe offset on every frame.
  ValueListenable<double> get swipeOffsetListenable => _controller;

  /// The current accumulated progressive value, or `null` when right-swipe
  /// is disabled.
  ValueNotifier<double>? get progressValueNotifier => _progressValueNotifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveEffectiveConfigs();
    _initFeedbackDispatcher();
    if (_progressValueNotifier == null && _resolvedForwardConfig != null) {
      _initProgressiveNotifier();
    }
    // F7: attach handle and sync group registration.
    if (!_effectiveController.hasHandle) {
      _effectiveController.attach(this);
    }
    _syncGroupRegistration();
    // F007: attach to the nearest ancestor ScrollPosition.
    _attachScrollListener();
    _validateFullSwipeConfigs();
  }

  void _resolveEffectiveConfigs() {
    final theme = SwipeActionCellTheme.maybeOf(context);
    effectiveGestureConfig = widget.gestureConfig ??
        theme?.gestureConfig ??
        const SwipeGestureConfig();
    effectiveAnimationConfig = widget.animationConfig ??
        theme?.animationConfig ??
        const SwipeAnimationConfig();
    effectiveRightSwipeConfig =
        widget.rightSwipeConfig ?? theme?.rightSwipeConfig;
    effectiveLeftSwipeConfig = widget.leftSwipeConfig ?? theme?.leftSwipeConfig;
    effectiveVisualConfig =
        widget.visualConfig ?? theme?.visualConfig ?? const SwipeVisualConfig();
    if (kDebugMode) {
      assert(
        !(widget.feedbackConfig != null &&
            (_resolvedForwardConfig?.enableHaptic == true ||
                _resolvedBackwardConfig?.enableHaptic == true)),
        'SwipeActionCell: Use SwipeFeedbackConfig instead of direction-level enableHaptic flags. '
        'Legacy enableHaptic must be false when feedbackConfig is provided.',
      );
    }
    if (kDebugMode) {
      if (effectiveLeftSwipeConfig?.zones?.isNotEmpty == true) {
        assertZonesValid(effectiveLeftSwipeConfig!.zones!);
      }
      if (effectiveRightSwipeConfig?.zones?.isNotEmpty == true) {
        assertZonesValid(effectiveRightSwipeConfig!.zones!, progressive: true);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // F11: initialize undo bar controller.
    if (widget.paintingConfig?.particleConfig != null) {
      _particleController = AnimationController(vsync: this);
    }
    if (widget.undoConfig != null) {
      _undoBarController = AnimationController(
        vsync: this,
        value: 1.0,
        duration: widget.undoConfig!.duration,
      );
    }
    _controller = AnimationController(
      vsync: this,
      lowerBound: double.negativeInfinity,
      upperBound: double.infinity,
      value: 0.0,
    );
    _controller.addStatusListener(_handleAnimationStatusChange);
    // F7: create internal controller when consumer provides none.
    if (widget.controller == null) {
      _internalController = SwipeController();
    }
    // F8: focus node for keyboard navigation.
    _cellFocusNode = FocusNode();
  }

  void _initProgressiveNotifier() {
    final config = _resolvedForwardConfig;
    if (config != null) {
      _progressValueNotifier = ValueNotifier(config.initialValue);
    }
  }

  @override
  void didUpdateWidget(SwipeActionCell oldWidget) {
    _resolveEffectiveConfigs();
    super.didUpdateWidget(oldWidget);
    final forwardConfig = _resolvedForwardConfig;
    if (forwardConfig != null) {
      if (_progressValueNotifier == null) {
        _initProgressiveNotifier();
      } else if (forwardConfig.value != null) {
        _progressValueNotifier!.value = forwardConfig.value!;
      }
    }
    // F7: handle controller swap.
    if (widget.controller != oldWidget.controller) {
      final oldController = oldWidget.controller ?? _internalController!;
      _registeredGroup?.unregister(oldController);
      oldController.detach(this);
      // F11: handle undoConfig change.
      if (widget.undoConfig != oldWidget.undoConfig) {
        if (widget.undoConfig == null) {
          _particleController?.dispose();
          _undoTimer?.cancel();
          _undoBarController?.dispose();
          _undoBarController = null;
        } else if (_undoBarController == null) {
          _undoBarController = AnimationController(
            vsync: this,
            value: 1.0,
            duration: widget.undoConfig!.duration,
          );
        } else {
          _undoBarController!.duration = widget.undoConfig!.duration;
        }
      }
      if (widget.controller == null && _internalController == null) {
        _internalController = SwipeController();
      } else if (widget.controller != null) {
        _internalController?.dispose();
        _internalController = null;
      }
      _effectiveController.attach(this);
      _registeredGroup?.register(_effectiveController);
    }
  }

  @override
  void dispose() {
    // F007: detach from scroll position.
    _detachScrollListener();
    // F7: unregister from group and detach from controller before disposal.
    _registeredGroup?.unregister(_effectiveController);
    _effectiveController.detach(this);
    _internalController?.dispose();
    _feedbackDispatcher?.cancelPendingTimers();
    _controller.removeStatusListener(_handleAnimationStatusChange);
    _controller.dispose();
    _progressValueNotifier?.dispose();
    // F8: dispose focus node.
    _cellFocusNode.dispose();
    _particleController?.dispose();
    _undoTimer?.cancel();
    _undoBarController?.dispose();
    super.dispose();
  }

  // ── SwipeCellHandle — F7 bridge methods ────────────────────────────────────
  @override
  void executeOpenLeft() {
    if (_resolvedBackwardConfig == null) return;
    _lockedDirection = SwipeDirectionResolver.backwardPhysical(_isRtl);
    _updateState(SwipeState.animatingToOpen);
    _animateToOpen(
      _controller.value,
      -_leftMaxTranslation(_widgetWidth),
      0.0,
    );
  }

  @override
  void executeOpenRight() {
    if (_resolvedForwardConfig == null) return;
    final maxT =
        effectiveAnimationConfig.maxTranslationRight ?? _widgetWidth * 0.6;
    _lockedDirection = SwipeDirectionResolver.forwardPhysical(_isRtl);
    _updateState(SwipeState.animatingToOpen);
    _animateToOpen(_controller.value, maxT, 0.0);
  }

  @override
  void executeClose() {
    _updateState(SwipeState.animatingToClose);
    _snapBack(_controller.value, 0.0);
  }

  @override
  void executeResetProgress() {
    final config = _resolvedForwardConfig;
    if (config == null || _progressValueNotifier == null) return;
    _progressValueNotifier!.value = config.initialValue;
    _effectiveController.reportProgress(config.initialValue);
  }

  @override
  void executeSetProgress(double value) {
    final config = _resolvedForwardConfig;
    if (config == null || _progressValueNotifier == null) return;
    final clamped = value.clamp(config.minValue, config.maxValue);
    if (clamped == _progressValueNotifier!.value) return;
    _progressValueNotifier!.value = clamped;
    _effectiveController.reportProgress(clamped);
  }

  /// Syncs this cell's registration with the nearest [SwipeControllerProvider].
  ///
  /// Has an empty body in US1 — filled in by T013 (US4).
  void _initFeedbackDispatcher() {
    _feedbackDispatcher = FeedbackDispatcher.resolve(
      cellConfig: widget.feedbackConfig,
      themeConfig: SwipeActionCellTheme.maybeOf(context)?.feedbackConfig,
      legacyForwardHaptic: _resolvedForwardConfig?.enableHaptic ?? false,
      legacyBackwardHaptic: _resolvedBackwardConfig?.enableHaptic ?? false,
    );
  }

  void _syncGroupRegistration() {
    // T013 will fill this in.
    final newGroup = SwipeControllerProvider.maybeGroupOf(context);
    if (newGroup == _registeredGroup) return;
    _registeredGroup?.unregister(_effectiveController);
    _registeredGroup = newGroup;
    _registeredGroup?.register(_effectiveController);
  }

  void _handleAnimationStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (_state == SwipeState.animatingOut) {
        if (_fullSwipeTriggered) _fullSwipeTriggered = false;
        return;
      } else if (_state == SwipeState.animatingToClose) {
        final wasProgressiveForward =
            _dragIsForward && _resolvedForwardConfig != null;
        final wasIntentionalBackward = _dragIsBackward &&
            _resolvedBackwardConfig?.mode == LeftSwipeMode.autoTrigger;
        final wasPanelClose = _dragIsBackward &&
            _resolvedBackwardConfig?.mode == LeftSwipeMode.reveal;
        if (_fullSwipeTriggered) _fullSwipeTriggered = false;
        _lockedDirection = SwipeDirection.none;
        _awaitingConfirmation = false;
        _updateState(SwipeState.idle);
        if (wasProgressiveForward && !_isPostIncrementSnapBack) {
          _resolvedForwardConfig!.onSwipeCancelled?.call();
        }
        if (wasIntentionalBackward && !_isPostActionSnapBack) {
          _resolvedBackwardConfig!.onSwipeCancelled?.call();
        }
        if (wasPanelClose) {
          _resolvedBackwardConfig!.onPanelClosed?.call();
          _feedbackDispatcher?.fire(SwipeFeedbackEvent.panelClosed,
              isForward: false);
        }
        _isPostIncrementSnapBack = false;
        _isPostActionSnapBack = false;
        _isFullSwipeArmed = false;
        _fullSwipeRatio = 0.0;
      } else if (_state == SwipeState.animatingToOpen) {
        if (_dragIsForward && _resolvedForwardConfig != null) {
          _applyProgressiveIncrement();
          _isPostIncrementSnapBack = true;
          _updateState(SwipeState.animatingToClose);
          _snapBack(_controller.value, 0.0);
        } else if (_dragIsBackward && _resolvedBackwardConfig != null) {
          _handleIntentionalActionSettled();
        } else {
          _updateState(SwipeState.revealed);
          if (widget.undoConfig != null &&
              _resolvedBackwardConfig?.mode == LeftSwipeMode.autoTrigger) {
            _startUndoWindow();
          }
        }
      }
    }
  }

  void _handleIntentionalActionSettled() {
    final config = _resolvedBackwardConfig!;
    if (config.mode == LeftSwipeMode.reveal) {
      _updateState(SwipeState.revealed);
      config.onPanelOpened?.call();
      _feedbackDispatcher?.fire(SwipeFeedbackEvent.panelOpened,
          isForward: false);
      _announcePanelOpen();
    } else {
      if (config.requireConfirmation && !_awaitingConfirmation) {
        _awaitingConfirmation = true;
        _updateState(SwipeState.revealed);
      } else {
        _applyIntentionalAction();
      }
    }
  }

  void _applyIntentionalAction() {
    final config = _resolvedBackwardConfig!;
    _awaitingConfirmation = false;
    // F009: Use zone action if present
    if (_activeZoneAtRelease != null && _dragIsBackward) {
      _fireZoneHaptic(_activeZoneAtRelease!.hapticPattern ??
          (config.enableHaptic ? SwipeZoneHaptic.medium : null));
      _activeZoneAtRelease!.onActivated?.call();
      _activeZoneAtRelease = null;
      _feedbackDispatcher?.cancelPendingTimers();
    } else {
      if (config.enableHaptic) {
        HapticFeedback.mediumImpact();
      }
      config.onActionTriggered?.call();
      // F13: trigger particle burst on intentional action
      if (widget.paintingConfig?.particleConfig != null) {
        _startParticleBurst();
      }
    }
    _applyPostActionBehavior();
  }

  void _applyPostActionBehavior() {
    final config = _resolvedBackwardConfig!;
    _lastPostActionBehavior = config.postActionBehavior;
    _undoOldValue = null;
    _undoNewValue = null;
    switch (config.postActionBehavior) {
      case PostActionBehavior.snapBack:
        _isPostActionSnapBack = true;
        _updateState(SwipeState.animatingToClose);
        _snapBack(_controller.value, 0.0);
      case PostActionBehavior.animateOut:
        _updateState(SwipeState.animatingOut);
        _animateOut();
        if (widget.undoConfig != null) {
          _startUndoWindow();
        }
      case PostActionBehavior.stay:
        _updateState(SwipeState.revealed);
    }
  }

  void _animateOut() {
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = -(_widgetWidth * 1.5);
      return;
    }
    final spring = effectiveAnimationConfig.completionSpring;
    final simulation = SpringSimulation(
      SpringDescription(
        mass: spring.mass,
        stiffness: spring.stiffness,
        damping: spring.damping,
      ),
      _controller.value,
      -(_widgetWidth * 1.5),
      0.0,
    );
    _controller.animateWith(simulation);
  }

  double _effectiveMaxTranslation(
      double widgetWidth, SwipeDirection direction) {
    double maxT = direction == SwipeDirection.right
        ? (effectiveAnimationConfig.maxTranslationRight ?? widgetWidth * 0.6)
        : _leftMaxTranslation(widgetWidth);

    final fsCfg = _resolvedFullSwipeConfig(direction);
    if (fsCfg != null && fsCfg.enabled) {
      maxT = math.max(maxT, widgetWidth * fsCfg.threshold);
    }
    return maxT;
  }

  double _leftMaxTranslation(double widgetWidth) {
    final config = _resolvedBackwardConfig;
    if (config?.mode == LeftSwipeMode.reveal && config!.actions.isNotEmpty) {
      return config.actionPanelWidth ??
          80.0 * config.actions.length.clamp(1, 3);
    }
    return effectiveAnimationConfig.maxTranslationLeft ?? widgetWidth * 0.35;
  }

  void _applyProgressiveIncrement() {
    final config = _resolvedForwardConfig!;
    final current = _progressValueNotifier!.value;
    _undoOldValue = current;
    // F009: Use zone step value if present
    final step = (_activeZoneAtRelease != null && _dragIsForward)
        ? _activeZoneAtRelease!.stepValue
        : null;
    final result = computeNextProgressiveValue(
      current: current,
      config: config,
      stepOverride: step,
    );
    if (result.nextValue != current) {
      _progressValueNotifier!.value = result.nextValue;
      config.onProgressChanged?.call(result.nextValue, current);
    }
    if (result.hitMax) {
      config.onMaxReached?.call();
    }
    if (_activeZoneAtRelease != null && _dragIsForward) {
      _fireZoneHaptic(_activeZoneAtRelease!.hapticPattern ??
          (config.enableHaptic ? SwipeZoneHaptic.medium : null));
      _activeZoneAtRelease = null;
      _feedbackDispatcher?.cancelPendingTimers();
    } else {
      if (config.enableHaptic) {
        HapticFeedback.mediumImpact();
      }
    }
    config.onSwipeCompleted?.call(result.nextValue);
    _undoNewValue = result.nextValue;
    if (widget.undoConfig != null) {
      _startUndoWindow();
    }
    // F8: announce progress after increment.
    _announceProgress(result.nextValue, config.maxValue);
  }

  void _updateState(SwipeState newState) {
    if (_state == newState) return;
    setState(() {
      _state = newState;
    });
    widget.onStateChanged?.call(newState);
    // F7: push state to the controller so observers and group accordion can react.
    _effectiveController.reportState(
      newState,
      _progressValueNotifier?.value ?? 0.0,
      newState == SwipeState.revealed ? _lockedDirection : null,
    );
  }

  double _applyResistance(
      double rawOffset, double maxTranslation, double factor) {
    if (maxTranslation <= 0) return 0.0;
    final sign = rawOffset.sign;
    final abs = rawOffset.abs();
    if (abs <= maxTranslation) return rawOffset;
    if (factor <= 0.0) return sign * maxTranslation;
    final overflow = abs - maxTranslation;
    final resistedOverflow =
        (1.0 - 1.0 / (overflow * factor / maxTranslation + 1.0)) *
            maxTranslation;
    return sign * (maxTranslation + resistedOverflow);
  }

  void _handleDragStart(DragStartDetails details) {
    if (_fullSwipeTriggered) return;
    if (_undoPending) {
      _commitUndo();
    }
    if (_state == SwipeState.animatingOut) return;
    _controller.stop();
    _accumulatedDx = 0.0;
    if (_state == SwipeState.revealed && _controller.value < 0) {
      _lockedDirection = SwipeDirection.left;
    } else {
      _lockedDirection = SwipeDirection.none;
    }
    _updateState(SwipeState.dragging);
    _isPostIncrementSnapBack = false;
    _isPostActionSnapBack = false;
    _isFullSwipeArmed = false;
    _fullSwipeRatio = 0.0;
    _swipeStartedFired = false;
    _hapticThresholdFired = false;
    _lastHapticZoneIndex = -1;
    _currentZoneIndex = -1;
    _activeZoneAtRelease = null;
    _feedbackDispatcher?.cancelPendingTimers();
  }

  void _handleDragUpdate(DragUpdateDetails details, double widgetWidth) {
    if (_state == SwipeState.animatingOut) return;
    final dx = details.delta.dx;
    if (_lockedDirection == SwipeDirection.none) {
      _accumulatedDx += dx;
      if (_accumulatedDx.abs() < effectiveGestureConfig.deadZone &&
          _controller.value == 0.0) {
        return;
      }
      if (_controller.value != 0.0 ||
          _accumulatedDx.abs() >= effectiveGestureConfig.deadZone) {
        final rawNewOffset = _controller.value + _accumulatedDx;
        if (rawNewOffset > 0.05) {
          _lockedDirection = SwipeDirection.right;
        } else if (rawNewOffset < -0.05) {
          _lockedDirection = SwipeDirection.left;
        }
        if (_dragIsForward &&
            _resolvedForwardConfig != null &&
            !_swipeStartedFired) {
          _resolvedForwardConfig!.onSwipeStarted?.call();
          _swipeStartedFired = true;
        }
      } else {
        return;
      }
    }
    if (!effectiveGestureConfig.enabledDirections.contains(_lockedDirection)) {
      return;
    }
    final maxT = _effectiveMaxTranslation(widgetWidth, _lockedDirection);
    if (maxT <= 0) return;
    final rawNewOffset = _controller.value + dx;
    // F003: Clamping logic for progressive-style reveal.
    final resistance = (_lockedDirection == SwipeDirection.left &&
            _resolvedBackwardConfig?.mode == LeftSwipeMode.reveal)
        ? 0.0
        : effectiveAnimationConfig.resistanceFactor;
    _controller.value = _applyResistance(rawNewOffset, maxT, resistance);
    _checkFullSwipeThreshold(_controller.value.abs(), widgetWidth);
  }

  void _handleDragEnd(DragEndDetails details, double widgetWidth) {
    if (_state == SwipeState.animatingOut) return;
    if (_lockedDirection == SwipeDirection.none) {
      _updateState(SwipeState.idle);
      return;
    }
    if (!effectiveGestureConfig.enabledDirections.contains(_lockedDirection)) {
      _updateState(SwipeState.idle);
      return;
    }

    final maxT = _effectiveMaxTranslation(widgetWidth, _lockedDirection);
    if (maxT <= 0) {
      _snapBack(0.0, 0.0);
      return;
    }
    final fsCfg = _resolvedFullSwipeConfig(_lockedDirection);
    if (fsCfg != null && fsCfg.enabled && _isFullSwipeArmed) {
      _applyFullSwipeAction(_lockedDirection, fsCfg);
      return;
    }
    final velocity = details.primaryVelocity ?? 0.0;
    if (_lockedDirection == SwipeDirection.left &&
        (velocity > 0 || _controller.value >= 0)) {
      _updateState(SwipeState.animatingToClose);
      _snapBack(_controller.value, velocity > 0 ? velocity : 0.0);
      return;
    }
    final ratio = _controller.value.abs() / maxT;
    final forwardZones = _effectiveForwardZones();
    final backwardZones = _effectiveBackwardZones();
    final activeForwardZone = (forwardZones != null && _dragIsForward)
        ? resolveActiveZone(forwardZones, ratio)
        : null;
    final activeBackwardZone = (backwardZones != null && _dragIsBackward)
        ? resolveActiveZone(backwardZones, ratio)
        : null;
    _activeZoneAtRelease = activeForwardZone ?? activeBackwardZone;
    final isFling =
        velocity.abs() >= effectiveGestureConfig.velocityThreshold &&
            (_lockedDirection == SwipeDirection.right
                ? velocity > 0
                : velocity < 0);
    final bool shouldComplete;
    if (_activeZoneAtRelease != null) {
      shouldComplete = true;
    } else if ((_dragIsForward && forwardZones != null) ||
        (_dragIsBackward && backwardZones != null)) {
      shouldComplete = isFling;
    } else {
      shouldComplete =
          isFling || ratio >= effectiveAnimationConfig.activationThreshold;
    }
    if (shouldComplete) {
      _updateState(SwipeState.animatingToOpen);
      _animateToOpen(_controller.value,
          _lockedDirection == SwipeDirection.right ? maxT : -maxT, velocity);
    } else {
      _updateState(SwipeState.animatingToClose);
      _snapBack(_controller.value, velocity);
      _feedbackDispatcher?.fire(SwipeFeedbackEvent.swipeCancelled,
          isForward: _dragIsForward);
    }
  }

  /// Attaches to the nearest ancestor [ScrollPosition] to close on scroll.
  void _attachScrollListener() {
    final newPosition = Scrollable.maybeOf(context)?.position;
    if (newPosition == _scrollPosition) return;
    _detachScrollListener();
    _scrollPosition = newPosition;
    _scrollPosition?.addListener(_onScrollPositionChanged);
  }

  /// Detaches from the currently tracked [ScrollPosition].
  void _detachScrollListener() {
    _scrollPosition?.removeListener(_onScrollPositionChanged);
    _scrollPosition = null;
  }

  /// Called on every scroll position change from the ancestor [Scrollable].
  void _onScrollPositionChanged() {
    if (!effectiveGestureConfig.closeOnScroll) return;
    if (_state != SwipeState.revealed) return;
    // isScrollingNotifier is true during user-initiated drags only.
    // Programmatic scrolls (jumpTo, animateTo) do not set this flag.
    if (_scrollPosition?.isScrollingNotifier.value == true) {
      executeClose();
    }
  }

  /// Builds the gesture recognizer map for [RawGestureDetector].
  Map<Type, GestureRecognizerFactory> _buildGestureRecognizers(double width) {
    return {
      SwipeHorizontalRecognizer:
          GestureRecognizerFactoryWithHandlers<SwipeHorizontalRecognizer>(
        () => SwipeHorizontalRecognizer(debugOwner: this),
        (instance) {
          instance.thresholdRatio =
              effectiveGestureConfig.horizontalThresholdRatio;
          instance.respectEdgeGestures =
              effectiveGestureConfig.respectEdgeGestures;
          instance.onStart = _handleDragStart;
          instance.onUpdate = (d) => _handleDragUpdate(d, width);
          instance.onEnd = (d) => _handleDragEnd(d, width);
        },
      ),
    };
  }

  void _snapBack(double fromOffset, double velocity) {
    // F8: reduced motion — instant snap.
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = 0.0;
      _handleAnimationStatusChange(AnimationStatus.completed);
      return;
    }
    final spring = effectiveAnimationConfig.snapBackSpring;
    final simulation = SpringSimulation(
      SpringDescription(
          mass: spring.mass,
          stiffness: spring.stiffness,
          damping: spring.damping),
      fromOffset,
      0.0,
      velocity,
    );
    _controller.animateWith(simulation);
  }

  void _animateToOpen(double fromOffset, double toOffset, double velocity) {
    // F8: reduced motion — instant jump.
    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = toOffset;
      _handleAnimationStatusChange(AnimationStatus.completed);
      return;
    }
    final spring = effectiveAnimationConfig.completionSpring;
    final simulation = SpringSimulation(
      SpringDescription(
          mass: spring.mass,
          stiffness: spring.stiffness,
          damping: spring.damping),
      fromOffset,
      toOffset,
      velocity,
    );
    _controller.animateWith(simulation);
  }

  CustomPainter _safePainterCall(
      SwipePainterCallback callback, SwipeProgress progress, SwipeState state) {
    if (kDebugMode) {
      return callback(progress, state);
    }
    try {
      return callback(progress, state);
    } catch (e, st) {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: st));
      return _NoOpPainter();
    }
  }

  Widget _buildDecoratedChild(Widget child, SwipeProgress progress) {
    final config = widget.paintingConfig;
    if (config?.restingDecoration == null &&
        config?.activatedDecoration == null) {
      return child;
    }
    final t = progress.ratio.clamp(0.0, 1.0);
    final decoration = (config!.activatedDecoration != null)
        ? (Decoration.lerp(
                config.restingDecoration, config.activatedDecoration, t) ??
            config.restingDecoration)
        : config.restingDecoration;
    if (decoration == null) return child;
    return DecoratedBox(
      decoration: decoration,
      child: child,
    );
  }

  Widget _maybeWrapWithBodyTapInterceptor(Widget child) {
    // Body-tap interception for the reveal mode is handled by the Positioned
    // widget added to the Stack below the decoratedChild in the build method.
    // Wrapping the child here is insufficient because the child widget is
    // translated off-screen when the panel is open, leaving no on-screen hit
    // area. The Positioned approach covers the full visible cell body instead.
    return child;
  }

  void _handleBodyTapInRevealedState() {
    _awaitingConfirmation = false;
    _updateState(SwipeState.animatingToClose);
    _snapBack(_controller.value, 0.0);
  }

  Widget _buildBackground(BuildContext context, SwipeProgress progress) {
    if (!effectiveGestureConfig.enabledDirections
        .contains(progress.direction)) {
      return const SizedBox.shrink();
    }
    // F8: RTL-aware background selection — forward drag shows rightBackground,
    // backward drag shows leftBackground, regardless of physical direction.
    final isForward =
        progress.direction == SwipeDirectionResolver.forwardPhysical(_isRtl);
    // F009: Route to ZoneAwareBackground if zones are configured.
    final zones =
        isForward ? _effectiveForwardZones() : _effectiveBackwardZones();
    if (zones != null && zones.isNotEmpty) {
      final transitionStyle = isForward
          ? _resolvedForwardConfig?.zoneTransitionStyle
          : _resolvedBackwardConfig?.zoneTransitionStyle;
      return ZoneAwareBackground(
        zones: zones,
        progress: progress,
        transitionStyle: transitionStyle ?? ZoneTransitionStyle.instant,
      );
    }
    final builder = isForward
        ? effectiveVisualConfig.rightBackground
        : effectiveVisualConfig.leftBackground;
    if (builder == null) {
      return const SizedBox.shrink();
    }
    return builder(context, progress);
  }

  Widget _buildProgressIndicator() {
    final config = _resolvedForwardConfig!;
    final indicatorConfig = config.progressIndicatorConfig;
    return Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      width: indicatorConfig?.width,
      child: RepaintBoundary(
        child: ValueListenableBuilder<double>(
          valueListenable: _progressValueNotifier!,
          builder: (context, value, _) {
            final fillRatio = config.maxValue.isFinite
                ? (value / config.maxValue).clamp(0.0, 1.0)
                : 0.0;
            if (indicatorConfig == null) {
              return const SizedBox.shrink();
            }
            return ProgressiveSwipeIndicator(
                fillRatio: fillRatio, config: indicatorConfig);
          },
        ),
      ),
    );
  }

  Widget _buildRevealPanel(double widgetWidth) {
    final config = _resolvedBackwardConfig!;
    final panelWidth =
        config.actionPanelWidth ?? 80.0 * config.actions.length.clamp(1, 3);
    final actions = config.actions.take(3).toList();
    final currentWidth = _controller.value.abs().clamp(0.0, panelWidth);
    return Positioned(
      top: 0,
      bottom: 0,
      right: 0,
      width: currentWidth,
      child: SwipeActionPanel(
        actions: actions,
        panelWidth: panelWidth,
        enableHaptic: config.enableHaptic,
        onFeedbackRequest: _feedbackDispatcher != null
            ? () => _feedbackDispatcher!
                .fire(SwipeFeedbackEvent.actionTriggered, isForward: false)
            : null,
        onClose: () {
          _updateState(SwipeState.animatingToClose);
          _snapBack(_controller.value, 0.0);
        },
      ),
    );
  }

  Widget _wrapWithClip(Widget child) {
    final visual = effectiveVisualConfig;
    if (visual.borderRadius != null) {
      return ClipRRect(
          borderRadius: visual.borderRadius!,
          clipBehavior: visual.clipBehavior,
          child: child);
    }
    if (visual.clipBehavior != Clip.none) {
      return ClipRect(clipBehavior: visual.clipBehavior, child: child);
    }
    return child;
  }

  // ── F8: Accessibility helpers ──────────────────────────────────────────────
  /// Default label for the forward (progressive) action.
  String _defaultForwardLabel(bool isRtl) =>
      isRtl ? 'Swipe left to progress' : 'Swipe right to progress';

  /// Default label for the backward (intentional) action.

  String _fullForwardLabel(bool isRtl, SwipeAction action) => isRtl
      ? 'Full swipe left to ${action.label}'
      : 'Full swipe right to ${action.label}';

  String _fullBackwardLabel(bool isRtl, SwipeAction action) => isRtl
      ? 'Full swipe right to ${action.label}'
      : 'Full swipe left to ${action.label}';

  String _defaultBackwardLabel(bool isRtl) =>
      isRtl ? 'Swipe right for actions' : 'Swipe left for actions';

  /// Resolves a [SemanticLabel] with a fallback default.
  String _resolveLabel(
      SemanticLabel? label, String fallback, BuildContext ctx) {
    if (label == null) return fallback;
    final resolved = label.resolve(ctx);
    return resolved.isEmpty ? fallback : resolved;
  }

  /// Builds custom semantics actions for screen reader users.
  Map<CustomSemanticsAction, VoidCallback> _buildSemanticActions(
      BuildContext context) {
    final isRtl = _isRtl;
    final forwardConfig = _resolvedForwardConfig;
    final backwardConfig = _resolvedBackwardConfig;
    final semanticCfg = widget.semanticConfig;
    final actions = <CustomSemanticsAction, VoidCallback>{};
    if (forwardConfig != null) {
      final label = _resolveLabel(
          semanticCfg?.rightSwipeLabel, _defaultForwardLabel(isRtl), context);
      actions[CustomSemanticsAction(label: label)] =
          _triggerForwardFromSemantics;

      final fsCfg = forwardConfig.fullSwipeConfig;
      if (fsCfg != null && fsCfg.enabled) {
        actions[CustomSemanticsAction(
                label: _fullForwardLabel(isRtl, fsCfg.action))] =
            _triggerFullForwardFromSemantics;
      }
    }
    if (backwardConfig != null) {
      final label = _resolveLabel(
          semanticCfg?.leftSwipeLabel, _defaultBackwardLabel(isRtl), context);
      actions[CustomSemanticsAction(label: label)] =
          _triggerBackwardFromSemantics;

      final fsCfg = backwardConfig.fullSwipeConfig;
      if (fsCfg != null && fsCfg.enabled) {
        actions[CustomSemanticsAction(
                label: _fullBackwardLabel(isRtl, fsCfg.action))] =
            _triggerFullBackwardFromSemantics;
      }
    }
    return actions;
  }

  /// Triggers the forward (progressive) action from screen reader or keyboard.
  void _triggerForwardFromSemantics() {
    if (_isAnimating || _resolvedForwardConfig == null) return;
    final physicalDir = SwipeDirectionResolver.forwardPhysical(_isRtl);
    _lockedDirection = physicalDir;
    _updateState(SwipeState.animatingToOpen);
    final maxT =
        effectiveAnimationConfig.maxTranslationRight ?? _widgetWidth * 0.6;
    // Physical direction determines sign: right → positive, left → negative.
    final target = physicalDir == SwipeDirection.right ? maxT : -maxT;
    _animateToOpen(_controller.value, target, 0.0);
  }

  /// Triggers the backward (intentional) action from screen reader or keyboard.

  void _triggerFullForwardFromSemantics() {
    final cfg = _resolvedForwardConfig?.fullSwipeConfig;
    if (_isAnimating || cfg == null || !cfg.enabled) return;
    _lockedDirection = SwipeDirectionResolver.forwardPhysical(_isRtl);
    _applyFullSwipeAction(_lockedDirection, cfg);
  }

  void _triggerFullBackwardFromSemantics() {
    final cfg = _resolvedBackwardConfig?.fullSwipeConfig;
    if (_isAnimating || cfg == null || !cfg.enabled) return;
    _lockedDirection = SwipeDirectionResolver.backwardPhysical(_isRtl);
    _applyFullSwipeAction(_lockedDirection, cfg);
  }

  void _triggerBackwardFromSemantics() {
    if (_isAnimating || _resolvedBackwardConfig == null) return;
    _lockedDirection = SwipeDirectionResolver.backwardPhysical(_isRtl);
    _updateState(SwipeState.animatingToOpen);
    _animateToOpen(_controller.value, -_leftMaxTranslation(_widgetWidth), 0.0);
  }

  /// Whether an animation is currently in progress.
  bool get _isAnimating =>
      _state == SwipeState.animatingToOpen ||
      _state == SwipeState.animatingToClose ||
      _state == SwipeState.animatingOut;

  /// Announces progress change via [SemanticsService].
  void _announceProgress(double current, double max) {
    if (!mounted) return;
    final msg = widget.semanticConfig?.progressAnnouncementBuilder
            ?.call(current, max) ??
        'Progress incremented to ${current.toStringAsFixed(0)} of ${max.toStringAsFixed(0)}';
    // ignore: deprecated_member_use
    // ignore: deprecated_member_use
    SemanticsService.announce(msg, Directionality.of(context));
  }

  /// Announces panel open via [SemanticsService].
  void _announcePanelOpen() {
    if (!mounted) return;
    final raw = widget.semanticConfig?.panelOpenLabel?.resolve(context);
    final msg = (raw != null && raw.isNotEmpty) ? raw : 'Action panel open';
    // ignore: deprecated_member_use
    // ignore: deprecated_member_use
    SemanticsService.announce(msg, Directionality.of(context));
  }

  /// Handles keyboard events for arrow-key navigation and Escape.
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final isRtl = _isRtl;
    final forwardKey =
        isRtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight;
    final backwardKey =
        isRtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft;
    if (event.logicalKey == forwardKey) {
      if (_isAnimating) return KeyEventResult.handled;
      final fsCfg = _resolvedForwardConfig?.fullSwipeConfig;
      if (HardwareKeyboard.instance.isShiftPressed &&
          fsCfg != null &&
          fsCfg.enabled) {
        _triggerFullForwardFromSemantics();
      } else if (_resolvedForwardConfig != null) {
        _triggerForwardFromSemantics();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == backwardKey) {
      if (_isAnimating) return KeyEventResult.handled;
      final fsCfg = _resolvedBackwardConfig?.fullSwipeConfig;
      if (HardwareKeyboard.instance.isShiftPressed &&
          fsCfg != null &&
          fsCfg.enabled) {
        _triggerFullBackwardFromSemantics();
      } else if (_resolvedBackwardConfig != null) {
        _triggerBackwardFromSemantics();
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      if (_state == SwipeState.revealed) {
        executeClose();
        _cellFocusNode.requestFocus();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    // F8: resolve semantic actions for screen reader.
    final semanticActions = _buildSemanticActions(context);
    final cellLabel = widget.semanticConfig?.cellLabel?.resolve(context);
    return Focus(
      focusNode: _cellFocusNode,
      onKeyEvent: _handleKeyEvent,
      child: Semantics(
        label: (cellLabel != null && cellLabel.isNotEmpty) ? cellLabel : null,
        customSemanticsActions:
            semanticActions.isEmpty ? null : semanticActions,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            _widgetWidth = width;
            final height = constraints.maxHeight;
            _burstOrigin = Offset(width / 2, height / 2);
            return RawGestureDetector(
              behavior: HitTestBehavior.translucent,
              gestures: _buildGestureRecognizers(width),
              child: _wrapWithClip(
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final offset = _controller.value;
                    final maxT = _lockedDirection == SwipeDirection.right
                        ? (effectiveAnimationConfig.maxTranslationRight ??
                            width * 0.6)
                        : _leftMaxTranslation(width);
                    final ratio =
                        maxT > 0 ? (offset.abs() / maxT).clamp(0.0, 1.0) : 0.0;
                    final progress = SwipeProgress(
                      direction: _lockedDirection,
                      ratio: ratio,
                      isActivated:
                          ratio >= effectiveAnimationConfig.activationThreshold,
                      rawOffset: offset,
                      fullSwipeRatio: _fullSwipeRatio,
                    );
                    // F009: Zone detection for haptic and semantics
                    if (_state == SwipeState.dragging) {
                      final zones = _dragIsForward
                          ? _effectiveForwardZones()
                          : _effectiveBackwardZones();
                      if (zones != null && zones.isNotEmpty) {
                        final newZoneIndex =
                            resolveActiveZoneIndex(zones, ratio);
                        // Haptic: Forward-only crossing
                        if (newZoneIndex > _lastHapticZoneIndex &&
                            newZoneIndex >= 0) {
                          _feedbackDispatcher?.fire(
                            SwipeFeedbackEvent.zoneBoundaryCrossed,
                            isForward: _dragIsForward,
                            pattern: HapticPattern.fromZoneHaptic(
                              zones[newZoneIndex].hapticPattern,
                            ),
                          );
                        }
                        _lastHapticZoneIndex = newZoneIndex;
                        // Semantics: Any change in active zone
                        if (newZoneIndex != _currentZoneIndex) {
                          _currentZoneIndex = newZoneIndex;
                          if (newZoneIndex >= 0) {
                            // ignore: deprecated_member_use
                            SemanticsService.announce(
                              zones[newZoneIndex].semanticLabel,
                              Directionality.of(context),
                            );
                          }
                        }
                      }
                    }
                    if (progress.isActivated &&
                        !_hapticThresholdFired &&
                        !_hasActiveZones()) {
                      _feedbackDispatcher?.fire(
                        SwipeFeedbackEvent.thresholdCrossed,
                        isForward: _dragIsForward,
                      );
                      _hapticThresholdFired = true;
                    }
                    widget.onProgressChanged?.call(progress);
                    final undoOverlay = (widget.undoConfig != null &&
                            widget.undoConfig!.showBuiltInOverlay &&
                            _undoPending &&
                            _undoBarController != null)
                        ? Positioned(
                            left: 0,
                            right: 0,
                            top: widget.undoConfig!.overlayConfig?.position ==
                                    SwipeUndoOverlayPosition.top
                                ? 0
                                : null,
                            bottom:
                                (widget.undoConfig!.overlayConfig?.position ??
                                            SwipeUndoOverlayPosition.bottom) ==
                                        SwipeUndoOverlayPosition.bottom
                                    ? 0
                                    : null,
                            child: SwipeUndoOverlay(
                              config: widget.undoConfig!.overlayConfig ??
                                  const SwipeUndoOverlayConfig(),
                              progressAnimation: _undoBarController!,
                              onUndo: _triggerUndo,
                              semanticUndoLabel: widget.undoConfig!
                                      .overlayConfig?.undoButtonLabel ??
                                  'Undo',
                            ),
                          )
                        : null;
                    final translatedChild = Transform.translate(
                      offset: Offset(offset, 0),
                      child: _maybeWrapWithBodyTapInterceptor(child!),
                    );
                    final confirmOverlay = _awaitingConfirmation
                        ? Positioned.fill(
                            child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: _applyIntentionalAction))
                        : null;
                    return Stack(
                      children: [
                        if (widget.paintingConfig?.backgroundPainter != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: _safePainterCall(
                                      widget.paintingConfig!.backgroundPainter!,
                                      progress,
                                      _state),
                                ),
                              ),
                            ),
                          ),
                        if (effectiveVisualConfig.leftBackground != null ||
                            effectiveVisualConfig.rightBackground != null)
                          Positioned.fill(
                              child: _buildBackground(context, progress)),
                        if (_resolvedBackwardConfig?.mode ==
                                LeftSwipeMode.reveal &&
                            _resolvedBackwardConfig!.actions.isNotEmpty &&
                            offset < -0.5 &&
                            (_state == SwipeState.revealed ||
                                ((_state == SwipeState.dragging ||
                                        _state == SwipeState.animatingToOpen) &&
                                    _dragIsBackward)))
                          _buildRevealPanel(width),
                        if (confirmOverlay != null) confirmOverlay,

                        if (_fullSwipeRatio > 0 &&
                            _resolvedFullSwipeConfig(_lockedDirection)
                                    ?.expandAnimation ==
                                true)
                          FullSwipeExpandOverlay(
                            action: _resolvedFullSwipeConfig(_lockedDirection)!
                                .action,
                            direction: _lockedDirection,
                            ratio: _fullSwipeRatio,
                            panelWidth: _effectiveMaxTranslation(
                                width, _lockedDirection),
                          ),
                        _buildDecoratedChild(translatedChild, progress),
                        // Reveal-mode body-tap interceptor: covers the visible
                        // cell area (excluding the exposed panel) so that
                        // tapping anywhere on the cell body closes the panel.
                        // Positioned avoids the infinite-height crash that
                        // SizedBox.expand causes inside ListView.
                        if (_state == SwipeState.revealed &&
                            _resolvedBackwardConfig?.mode ==
                                LeftSwipeMode.reveal)
                          Positioned(
                            top: 0,
                            bottom: 0,
                            left: offset > 0 ? offset : 0.0,
                            right: offset < 0 ? -offset : 0.0,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: _handleBodyTapInRevealedState,
                            ),
                          ),
                        if (undoOverlay != null) undoOverlay,
                        if (_particles != null && _particleController != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: AnimatedBuilder(
                                animation: _particleController!,
                                builder: (context, _) => CustomPaint(
                                  painter: SwipeParticlePainter(
                                    particles: _particles!,
                                    animationValue: _particleController!.value,
                                    origin: _burstOrigin,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (widget.paintingConfig?.foregroundPainter != null)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: RepaintBoundary(
                                child: CustomPaint(
                                  painter: _safePainterCall(
                                      widget.paintingConfig!.foregroundPainter!,
                                      progress,
                                      _state),
                                ),
                              ),
                            ),
                          ),
                        if (_resolvedForwardConfig != null &&
                            _resolvedForwardConfig!.showProgressIndicator)
                          _buildProgressIndicator(),
                      ],
                    );
                  },
                  child: widget.child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  FullSwipeConfig? _resolvedFullSwipeConfig(SwipeDirection direction) {
    if (direction == SwipeDirection.left) {
      return _resolvedBackwardConfig?.fullSwipeConfig;
    } else if (direction == SwipeDirection.right) {
      return _resolvedForwardConfig?.fullSwipeConfig;
    }
    return null;
  }

  void _validateFullSwipeConfigs() {
    void check(FullSwipeConfig? cfg, double activationThreshold,
        List<SwipeZone>? zones, String dir) {
      if (cfg == null || !cfg.enabled) return;
      assert(cfg.threshold > activationThreshold,
          'SwipeActionCell:  full-swipe threshold must be greater than activationThreshold.');
      if (zones != null && zones.isNotEmpty) {
        final maxZoneT = zones.map((z) => z.threshold).reduce(math.max);
        assert(cfg.threshold > maxZoneT,
            'SwipeActionCell:  full-swipe threshold must be greater than the maximum zone threshold ().');
      }
      assert(cfg.action.label != null && cfg.action.label!.isNotEmpty,
          'SwipeActionCell: Full-swipe action for  must have a non-empty label for accessibility.');
    }

    check(
      _resolvedBackwardConfig?.fullSwipeConfig,
      effectiveAnimationConfig.activationThreshold,
      _resolvedBackwardConfig?.zones,
      'Backward',
    );
    check(
      _resolvedForwardConfig?.fullSwipeConfig,
      effectiveAnimationConfig.activationThreshold,
      _resolvedForwardConfig?.zones,
      'Forward',
    );
  }

  void _checkFullSwipeThreshold(double absOffset, double widgetWidth) {
    final cfg = _resolvedFullSwipeConfig(_lockedDirection);
    if (cfg == null || !cfg.enabled) {
      if (_isFullSwipeArmed) {
        _isFullSwipeArmed = false;
        _fullSwipeRatio = 0.0;
      }
      return;
    }
    final rawRatio = absOffset / widgetWidth;
    final activationThreshold = effectiveAnimationConfig.activationThreshold;

    // Smoothly interpolate fullSwipeRatio between activation and full-swipe thresholds.
    _fullSwipeRatio = ((rawRatio - activationThreshold) /
            (cfg.threshold - activationThreshold))
        .clamp(0.0, 1.0);

    final nowArmed = rawRatio >= cfg.threshold;
    if (nowArmed != _isFullSwipeArmed) {
      setState(() {
        _isFullSwipeArmed = nowArmed;
      });
      if (cfg.enableHaptic) {
        _feedbackDispatcher?.fire(
          SwipeFeedbackEvent.fullSwipeThresholdCrossed,
          isForward: _dragIsForward,
        );
      }
    }
  }

  void _applyFullSwipeAction(SwipeDirection direction, FullSwipeConfig cfg) {
    _fullSwipeTriggered = true;
    _isFullSwipeArmed = false;
    _fullSwipeRatio = 0.0;

    if (cfg.enableHaptic) {
      _feedbackDispatcher?.fire(
        SwipeFeedbackEvent.fullSwipeActivation,
        isForward: _dragIsForward,
      );
    }

    if (_dragIsForward &&
        cfg.fullSwipeProgressBehavior == FullSwipeProgressBehavior.setToMax) {
      final fwdCfg = _resolvedForwardConfig!;
      final oldValue = _progressValueNotifier!.value;
      _progressValueNotifier!.value = fwdCfg.maxValue;
      fwdCfg.onMaxReached?.call();
      fwdCfg.onProgressChanged?.call(fwdCfg.maxValue, oldValue);
    } else {
      cfg.action.onTap();
    }

    widget.onFullSwipeTriggered?.call(direction, cfg.action);
    _lastPostActionBehavior = cfg.postActionBehavior;

    switch (cfg.postActionBehavior) {
      case PostActionBehavior.snapBack:
        _isPostActionSnapBack = true;
        _updateState(SwipeState.animatingToClose);
        _snapBack(_controller.value, 0.0);
      case PostActionBehavior.animateOut:
        _updateState(SwipeState.animatingOut);
        _animateOutDirectional(direction);
        if (widget.undoConfig != null) {
          _startUndoWindow();
        }
      case PostActionBehavior.stay:
        _fullSwipeTriggered = false;
        _updateState(SwipeState.revealed);
    }
  }

  void _animateOutDirectional(SwipeDirection direction) {
    final target = direction == SwipeDirection.right
        ? _widgetWidth * 1.5
        : -(_widgetWidth * 1.5);

    if (MediaQuery.of(context).disableAnimations) {
      _controller.value = target;
      _handleAnimationStatusChange(AnimationStatus.completed);
      return;
    }

    final spring = effectiveAnimationConfig.completionSpring;
    _controller.animateWith(SpringSimulation(
      SpringDescription(
          mass: spring.mass,
          stiffness: spring.stiffness,
          damping: spring.damping),
      _controller.value,
      target,
      0.0,
    ));
  }
}

class _NoOpPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}

  @override
  bool shouldRepaint(_NoOpPainter old) => false;
}

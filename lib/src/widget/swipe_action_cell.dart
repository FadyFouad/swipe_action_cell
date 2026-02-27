import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../accessibility/swipe_semantic_config.dart';
import '../actions/intentional/left_swipe_mode.dart';
import '../actions/intentional/post_action_behavior.dart';
import '../actions/intentional/swipe_action_panel.dart';
import '../actions/progressive/progressive_swipe_indicator.dart';
import '../actions/progressive/progressive_value_logic.dart';
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
import '../gesture/swipe_gesture_config.dart';
import '../scroll/swipe_gesture_recognizer.dart';

/// A widget that wraps any child and provides spring-based horizontal swipe
/// interaction with asymmetric left/right semantics.
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

  @override
  State<SwipeActionCell> createState() => SwipeActionCellState();
}

/// Mutable state for [SwipeActionCell].
///
/// Exposed for testing via `tester.state<SwipeActionCellState>(...)`.
class SwipeActionCellState extends State<SwipeActionCell>
    with TickerProviderStateMixin
    implements SwipeCellHandle {
  late final AnimationController _controller;
  SwipeState _state = SwipeState.idle;
  SwipeDirection _lockedDirection = SwipeDirection.none;
  double _accumulatedDx = 0.0;

  // F3 progressive fields.
  ValueNotifier<double>? _progressValueNotifier;
  bool _isPostIncrementSnapBack = false;
  bool _swipeStartedFired = false;
  bool _hapticThresholdFired = false;

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

  /// True during a post-action snap-back so [onSwipeCancelled] is not fired.
  bool _isPostActionSnapBack = false;

  /// True after the first swipe completes when [requireConfirmation] is true.
  bool _awaitingConfirmation = false;

  // F007: scroll-position listener for close-on-scroll.
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

  /// A [ValueListenable] that emits the current swipe offset on every frame.
  ValueListenable<double> get swipeOffsetListenable => _controller;

  /// The current accumulated progressive value, or `null` when right-swipe
  /// is disabled.
  ValueNotifier<double>? get progressValueNotifier => _progressValueNotifier;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveEffectiveConfigs();
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
  }

  @override
  void initState() {
    super.initState();
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
    _controller.removeStatusListener(_handleAnimationStatusChange);
    _controller.dispose();
    _progressValueNotifier?.dispose();
    // F8: dispose focus node.
    _cellFocusNode.dispose();
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
        return;
      } else if (_state == SwipeState.animatingToClose) {
        final wasProgressiveForward =
            _dragIsForward && _resolvedForwardConfig != null;
        final wasIntentionalBackward = _dragIsBackward &&
            _resolvedBackwardConfig?.mode == LeftSwipeMode.autoTrigger;
        final wasPanelClose = _dragIsBackward &&
            _resolvedBackwardConfig?.mode == LeftSwipeMode.reveal;
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
        }
        _isPostIncrementSnapBack = false;
        _isPostActionSnapBack = false;
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
        }
      }
    }
  }

  void _handleIntentionalActionSettled() {
    final config = _resolvedBackwardConfig!;
    if (config.mode == LeftSwipeMode.reveal) {
      _updateState(SwipeState.revealed);
      config.onPanelOpened?.call();
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
    if (config.enableHaptic) HapticFeedback.mediumImpact();
    config.onActionTriggered?.call();
    _applyPostActionBehavior();
  }

  void _applyPostActionBehavior() {
    final config = _resolvedBackwardConfig!;
    switch (config.postActionBehavior) {
      case PostActionBehavior.snapBack:
        _isPostActionSnapBack = true;
        _updateState(SwipeState.animatingToClose);
        _snapBack(_controller.value, 0.0);
      case PostActionBehavior.animateOut:
        _updateState(SwipeState.animatingOut);
        _animateOut();
      case PostActionBehavior.stay:
        _updateState(SwipeState.revealed);
    }
  }

  void _animateOut() {
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

  double _leftMaxTranslation(double widgetWidth) {
    final config = _resolvedBackwardConfig;
    if (config?.mode == LeftSwipeMode.reveal && config!.actions.isNotEmpty) {
      return config.actionPanelWidth ??
          80.0 * config.actions.length.clamp(1, 3);
    }
    return effectiveAnimationConfig.maxTranslationLeft ?? widgetWidth * 0.6;
  }

  void _applyProgressiveIncrement() {
    final config = _resolvedForwardConfig!;
    final current = _progressValueNotifier!.value;
    final result =
        computeNextProgressiveValue(current: current, config: config);

    if (result.nextValue != current) {
      _progressValueNotifier!.value = result.nextValue;
      config.onProgressChanged?.call(result.nextValue, current);
    }
    if (result.hitMax) {
      config.onMaxReached?.call();
    }
    if (config.enableHaptic) HapticFeedback.mediumImpact();
    config.onSwipeCompleted?.call(result.nextValue);
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
    _swipeStartedFired = false;
    _hapticThresholdFired = false;
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
    final maxT = _lockedDirection == SwipeDirection.right
        ? (effectiveAnimationConfig.maxTranslationRight ?? widgetWidth * 0.6)
        : _leftMaxTranslation(widgetWidth);
    if (maxT <= 0) return;
    final rawNewOffset = _controller.value + dx;
    _controller.value = _applyResistance(
        rawNewOffset, maxT, effectiveAnimationConfig.resistanceFactor);
  }

  void _handleDragEnd(DragEndDetails details, double widgetWidth) {
    if (_state == SwipeState.animatingOut) return;
    if (_lockedDirection == SwipeDirection.none) {
      _updateState(SwipeState.idle);
      return;
    }
    final maxT = _lockedDirection == SwipeDirection.right
        ? (effectiveAnimationConfig.maxTranslationRight ?? widgetWidth * 0.6)
        : _leftMaxTranslation(widgetWidth);
    if (maxT <= 0) {
      _snapBack(0.0, 0.0);
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
    final isFling =
        velocity.abs() >= effectiveGestureConfig.velocityThreshold &&
            (_lockedDirection == SwipeDirection.right
                ? velocity > 0
                : velocity < 0);
    final shouldComplete =
        isFling || ratio >= effectiveAnimationConfig.activationThreshold;
    if (shouldComplete) {
      _updateState(SwipeState.animatingToOpen);
      _animateToOpen(_controller.value,
          _lockedDirection == SwipeDirection.right ? maxT : -maxT, velocity);
    } else {
      _updateState(SwipeState.animatingToClose);
      _snapBack(_controller.value, velocity);
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

  Widget _maybeWrapWithBodyTapInterceptor(Widget child) {
    if (_state != SwipeState.revealed || _resolvedBackwardConfig == null) {
      return child;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleBodyTapInRevealedState,
      child: child,
    );
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
    final isForward = progress.direction ==
        SwipeDirectionResolver.forwardPhysical(_isRtl);
    final builder = isForward
        ? effectiveVisualConfig.rightBackground
        : effectiveVisualConfig.leftBackground;
    if (builder == null) return const SizedBox.shrink();
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
            if (indicatorConfig == null) return const SizedBox.shrink();
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
    return Positioned(
      top: 0,
      bottom: 0,
      right: 0,
      width: panelWidth,
      child: SwipeActionPanel(
        actions: actions,
        panelWidth: panelWidth,
        enableHaptic: config.enableHaptic,
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
    }
    if (backwardConfig != null) {
      final label = _resolveLabel(
          semanticCfg?.leftSwipeLabel, _defaultBackwardLabel(isRtl), context);
      actions[CustomSemanticsAction(label: label)] =
          _triggerBackwardFromSemantics;
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
  void _triggerBackwardFromSemantics() {
    if (_isAnimating || _resolvedBackwardConfig == null) return;
    _lockedDirection = SwipeDirectionResolver.backwardPhysical(_isRtl);
    _updateState(SwipeState.animatingToOpen);
    _animateToOpen(
        _controller.value, -_leftMaxTranslation(_widgetWidth), 0.0);
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
    SemanticsService.announce(msg, Directionality.of(context));
  }

  /// Announces panel open via [SemanticsService].
  void _announcePanelOpen() {
    if (!mounted) return;
    final raw =
        widget.semanticConfig?.panelOpenLabel?.resolve(context);
    final msg =
        (raw != null && raw.isNotEmpty) ? raw : 'Action panel open';
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
      if (_resolvedForwardConfig != null) _triggerForwardFromSemantics();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == backwardKey) {
      if (_isAnimating) return KeyEventResult.handled;
      if (_resolvedBackwardConfig != null) _triggerBackwardFromSemantics();
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
        label:
            (cellLabel != null && cellLabel.isNotEmpty) ? cellLabel : null,
        customSemanticsActions:
            semanticActions.isEmpty ? null : semanticActions,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            _widgetWidth = width;
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
                    final ratio = maxT > 0
                        ? (offset.abs() / maxT).clamp(0.0, 1.0)
                        : 0.0;
                    final progress = SwipeProgress(
                      direction: _lockedDirection,
                      ratio: ratio,
                      isActivated: ratio >=
                          effectiveAnimationConfig.activationThreshold,
                      rawOffset: offset,
                    );
                    if (_dragIsForward &&
                        _resolvedForwardConfig?.enableHaptic == true &&
                        progress.isActivated &&
                        !_hapticThresholdFired) {
                      HapticFeedback.lightImpact();
                      _hapticThresholdFired = true;
                    }
                    if (_dragIsBackward &&
                        _resolvedBackwardConfig?.enableHaptic == true &&
                        progress.isActivated &&
                        !_hapticThresholdFired) {
                      HapticFeedback.lightImpact();
                      _hapticThresholdFired = true;
                    }
                    widget.onProgressChanged?.call(progress);
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
                        if (effectiveVisualConfig.leftBackground != null ||
                            effectiveVisualConfig.rightBackground != null)
                          Positioned.fill(
                              child: _buildBackground(context, progress)),
                        if (confirmOverlay != null) confirmOverlay,
                        translatedChild,
                        if (_resolvedBackwardConfig?.mode ==
                                LeftSwipeMode.reveal &&
                            _state == SwipeState.revealed &&
                            _resolvedBackwardConfig!.actions.isNotEmpty)
                          _buildRevealPanel(width),
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
}

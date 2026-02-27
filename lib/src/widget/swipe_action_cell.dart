import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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
import '../controller/swipe_controller.dart';
import '../core/swipe_direction.dart';
import '../core/swipe_progress.dart';
import '../core/swipe_state.dart';
import '../gesture/swipe_gesture_config.dart';

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
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  SwipeState _state = SwipeState.idle;
  SwipeDirection _lockedDirection = SwipeDirection.none;
  double _accumulatedDx = 0.0;

  // F3 progressive fields.
  ValueNotifier<double>? _progressValueNotifier;
  bool _isPostIncrementSnapBack = false;
  bool _swipeStartedFired = false;
  bool _hapticThresholdFired = false;

  /// Cached widget width from [LayoutBuilder]; used for animateOut target.
  double _widgetWidth = 400.0;

  /// True during a post-action snap-back so [onSwipeCancelled] is not fired.
  bool _isPostActionSnapBack = false;

  /// True after the first swipe completes when [requireConfirmation] is true.
  bool _awaitingConfirmation = false;

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
    if (_progressValueNotifier == null && effectiveRightSwipeConfig != null) {
      _initProgressiveNotifier();
    }
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
  }

  void _initProgressiveNotifier() {
    final config = effectiveRightSwipeConfig;
    if (config != null) {
      _progressValueNotifier = ValueNotifier(config.initialValue);
    }
  }

  @override
  void didUpdateWidget(SwipeActionCell oldWidget) {
    _resolveEffectiveConfigs();

    super.didUpdateWidget(oldWidget);
    if (widget.rightSwipeConfig != null) {
      if (_progressValueNotifier == null) {
        _initProgressiveNotifier();
      } else if (widget.rightSwipeConfig!.value != null) {
        _progressValueNotifier!.value = widget.rightSwipeConfig!.value!;
      }
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleAnimationStatusChange);
    _controller.dispose();
    _progressValueNotifier?.dispose();
    super.dispose();
  }

  void _handleAnimationStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (_state == SwipeState.animatingOut) {
        return;
      } else if (_state == SwipeState.animatingToClose) {
        final wasProgressiveRight = _lockedDirection == SwipeDirection.right &&
            effectiveRightSwipeConfig != null;
        final wasIntentionalLeft = _lockedDirection == SwipeDirection.left &&
            effectiveLeftSwipeConfig?.mode == LeftSwipeMode.autoTrigger;
        final wasPanelClose = _lockedDirection == SwipeDirection.left &&
            effectiveLeftSwipeConfig?.mode == LeftSwipeMode.reveal;
        _lockedDirection = SwipeDirection.none;
        _awaitingConfirmation = false;
        _updateState(SwipeState.idle);
        if (wasProgressiveRight && !_isPostIncrementSnapBack) {
          effectiveRightSwipeConfig!.onSwipeCancelled?.call();
        }
        if (wasIntentionalLeft && !_isPostActionSnapBack) {
          effectiveLeftSwipeConfig!.onSwipeCancelled?.call();
        }
        if (wasPanelClose) {
          effectiveLeftSwipeConfig!.onPanelClosed?.call();
        }
        _isPostIncrementSnapBack = false;
        _isPostActionSnapBack = false;
      } else if (_state == SwipeState.animatingToOpen) {
        if (_lockedDirection == SwipeDirection.right &&
            effectiveRightSwipeConfig != null) {
          _applyProgressiveIncrement();
          _isPostIncrementSnapBack = true;
          _updateState(SwipeState.animatingToClose);
          _snapBack(_controller.value, 0.0);
        } else if (_lockedDirection == SwipeDirection.left &&
            effectiveLeftSwipeConfig != null) {
          _handleIntentionalActionSettled();
        } else {
          _updateState(SwipeState.revealed);
        }
      }
    }
  }

  void _handleIntentionalActionSettled() {
    final config = effectiveLeftSwipeConfig!;
    if (config.mode == LeftSwipeMode.reveal) {
      _updateState(SwipeState.revealed);
      config.onPanelOpened?.call();
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
    final config = effectiveLeftSwipeConfig!;
    _awaitingConfirmation = false;
    if (config.enableHaptic) HapticFeedback.mediumImpact();
    config.onActionTriggered?.call();
    _applyPostActionBehavior();
  }

  void _applyPostActionBehavior() {
    final config = effectiveLeftSwipeConfig!;
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
    final config = effectiveLeftSwipeConfig;
    if (config?.mode == LeftSwipeMode.reveal && config!.actions.isNotEmpty) {
      return config.actionPanelWidth ??
          80.0 * config.actions.length.clamp(1, 3);
    }
    return effectiveAnimationConfig.maxTranslationLeft ?? widgetWidth * 0.6;
  }

  void _applyProgressiveIncrement() {
    final config = effectiveRightSwipeConfig!;
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
  }

  void _updateState(SwipeState newState) {
    if (_state == newState) return;
    setState(() {
      _state = newState;
    });
    widget.onStateChanged?.call(newState);
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
        if (_lockedDirection == SwipeDirection.right &&
            effectiveRightSwipeConfig != null &&
            !_swipeStartedFired) {
          effectiveRightSwipeConfig!.onSwipeStarted?.call();
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
    final isFling = velocity.abs() >= effectiveGestureConfig.velocityThreshold &&
        (_lockedDirection == SwipeDirection.right ? velocity > 0 : velocity < 0);
    final shouldComplete =
        isFling || ratio >= effectiveAnimationConfig.activationThreshold;
    if (shouldComplete) {
      _updateState(SwipeState.animatingToOpen);
      _animateToOpen(
          _controller.value,
          _lockedDirection == SwipeDirection.right ? maxT : -maxT,
          velocity);
    } else {
      _updateState(SwipeState.animatingToClose);
      _snapBack(_controller.value, velocity);
    }
  }

  void _snapBack(double fromOffset, double velocity) {
    final spring = effectiveAnimationConfig.snapBackSpring;
    final simulation = SpringSimulation(
      SpringDescription(
          mass: spring.mass, stiffness: spring.stiffness, damping: spring.damping),
      fromOffset,
      0.0,
      velocity,
    );
    _controller.animateWith(simulation);
  }

  void _animateToOpen(double fromOffset, double toOffset, double velocity) {
    final spring = effectiveAnimationConfig.completionSpring;
    final simulation = SpringSimulation(
      SpringDescription(
          mass: spring.mass, stiffness: spring.stiffness, damping: spring.damping),
      fromOffset,
      toOffset,
      velocity,
    );
    _controller.animateWith(simulation);
  }

  Widget _maybeWrapWithBodyTapInterceptor(Widget child) {
    if (_state != SwipeState.revealed || effectiveLeftSwipeConfig == null) {
      return child;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleBodyTapInRevealedState,
      child: SizedBox.expand(child: child),
    );
  }

  void _handleBodyTapInRevealedState() {
    _awaitingConfirmation = false;
    _updateState(SwipeState.animatingToClose);
    _snapBack(_controller.value, 0.0);
  }

  Widget _buildBackground(BuildContext context, SwipeProgress progress) {
    if (!effectiveGestureConfig.enabledDirections.contains(progress.direction)) {
      return const SizedBox.shrink();
    }
    final builder = progress.direction == SwipeDirection.right
        ? effectiveVisualConfig.rightBackground
        : effectiveVisualConfig.leftBackground;
    if (builder == null) return const SizedBox.shrink();
    return builder(context, progress);
  }

  Widget _buildProgressIndicator() {
    final config = effectiveRightSwipeConfig!;
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
    final config = effectiveLeftSwipeConfig!;
    final panelWidth = config.actionPanelWidth ??
        80.0 * config.actions.length.clamp(1, 3);
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

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        _widgetWidth = width;
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate: (details) => _handleDragUpdate(details, width),
          onHorizontalDragEnd: (details) => _handleDragEnd(details, width),
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
                );
                if (_lockedDirection == SwipeDirection.right &&
                    effectiveRightSwipeConfig?.enableHaptic == true &&
                    progress.isActivated &&
                    !_hapticThresholdFired) {
                  HapticFeedback.lightImpact();
                  _hapticThresholdFired = true;
                }
                if (_lockedDirection == SwipeDirection.left &&
                    effectiveLeftSwipeConfig?.enableHaptic == true &&
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
                      Positioned.fill(child: _buildBackground(context, progress)),
                    if (confirmOverlay != null) confirmOverlay,
                    translatedChild,
                    if (effectiveLeftSwipeConfig?.mode == LeftSwipeMode.reveal &&
                        _state == SwipeState.revealed &&
                        effectiveLeftSwipeConfig!.actions.isNotEmpty)
                      _buildRevealPanel(width),
                    if (effectiveRightSwipeConfig != null &&
                        effectiveRightSwipeConfig!.showProgressIndicator)
                      _buildProgressIndicator(),
                  ],
                );
              },
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

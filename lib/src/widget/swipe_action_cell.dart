import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../actions/intentional/intentional_swipe_config.dart';
import '../actions/intentional/left_swipe_mode.dart';
import '../actions/intentional/post_action_behavior.dart';
import '../actions/intentional/swipe_action_panel.dart';
import '../actions/progressive/progress_indicator_config.dart';
import '../actions/progressive/progressive_swipe_config.dart';
import '../actions/progressive/progressive_swipe_indicator.dart';
import '../actions/progressive/progressive_value_logic.dart';
import '../animation/swipe_animation_config.dart';
import '../core/swipe_direction.dart';
import '../core/swipe_progress.dart';
import '../core/swipe_state.dart';
import '../core/typedefs.dart';
import '../gesture/swipe_gesture_config.dart';

/// A widget that wraps any child and provides spring-based horizontal swipe interaction.
class SwipeActionCell extends StatefulWidget {
  /// Creates a [SwipeActionCell].
  const SwipeActionCell({
    super.key,
    required this.child,
    this.gestureConfig = const SwipeGestureConfig(),
    this.animationConfig = const SwipeAnimationConfig(),
    this.onStateChanged,
    this.onProgressChanged,
    this.enabled = true,
    this.leftBackground,
    this.rightBackground,
    this.clipBehavior = Clip.hardEdge,
    this.borderRadius,
    this.rightSwipe,
    this.leftSwipe,
  });

  /// The widget displayed inside the swipe cell.
  final Widget child;

  /// Configuration for gesture recognition behavior.
  final SwipeGestureConfig gestureConfig;

  /// Configuration for animation physics.
  final SwipeAnimationConfig animationConfig;

  /// Called whenever the swipe state machine transitions to a new state.
  final ValueChanged<SwipeState>? onStateChanged;

  /// Called on every frame during a drag with the current swipe progress.
  final ValueChanged<SwipeProgress>? onProgressChanged;

  /// Whether swipe interactions are active.
  final bool enabled;

  /// Builder for the background revealed during a left swipe.
  final SwipeBackgroundBuilder? leftBackground;

  /// Builder for the background revealed during a right swipe.
  final SwipeBackgroundBuilder? rightBackground;

  /// How to clip the background and child stack.
  final Clip clipBehavior;

  /// Optional rounded corners for clipping.
  final BorderRadius? borderRadius;

  /// Configuration for right-swipe progressive (incremental) action behavior.
  final ProgressiveSwipeConfig? rightSwipe;

  /// Configuration for left-swipe intentional (one-shot) action behavior.
  ///
  /// When non-null, left swipes past the activation threshold trigger either a
  /// one-shot action ([LeftSwipeMode.autoTrigger]) or open an action panel
  /// ([LeftSwipeMode.reveal]) according to [IntentionalSwipeConfig.mode].
  ///
  /// When `null` (default), left-swipe intentional behavior is entirely disabled.
  /// The [leftBackground] builder still applies for visual feedback during drag.
  final IntentionalSwipeConfig? leftSwipe;

  @override
  State<SwipeActionCell> createState() => _SwipeActionCellState();
}

class _SwipeActionCellState extends State<SwipeActionCell>
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

  // F4 intentional fields.

  /// Cached widget width from [LayoutBuilder]; used for animateOut target.
  double _widgetWidth = 400.0;

  /// True during a post-action snap-back so [onSwipeCancelled] is not fired.
  bool _isPostActionSnapBack = false;

  /// True after the first swipe completes when [requireConfirmation] is true.
  bool _awaitingConfirmation = false;

  /// Read-only observable of the current horizontal pixel offset.
  /// Exposed for widget testing via a GlobalKey.
  ValueListenable<double> get swipeOffsetListenable => _controller;
  ValueNotifier<double>? get progressValueNotifier => _progressValueNotifier;

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
    _initProgressiveNotifier();
  }

  void _initProgressiveNotifier() {
    if (widget.rightSwipe != null) {
      final config = widget.rightSwipe!;
      final initialVal = config.value ??
          config.initialValue.clamp(config.minValue, config.maxValue);
      _progressValueNotifier = ValueNotifier(initialVal);
    }
  }

  @override
  void didUpdateWidget(SwipeActionCell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newConfig = widget.rightSwipe;
    final oldConfig = oldWidget.rightSwipe;

    if (newConfig != null) {
      if (_progressValueNotifier == null) {
        _initProgressiveNotifier();
      } else {
        if (newConfig.value != null &&
            newConfig.value != _progressValueNotifier!.value) {
          _progressValueNotifier!.value = newConfig.value!;
        }
      }
    } else if (oldConfig != null) {
      _progressValueNotifier?.dispose();
      _progressValueNotifier = null;
    }
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_handleAnimationStatusChange);
    _controller.dispose();
    _progressValueNotifier?.dispose();
    super.dispose();
  }

  // ─── Animation status handler ───────────────────────────────────────────────

  void _handleAnimationStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (_state == SwipeState.animatingOut) {
        // Terminal state — no further transition. Developer removes the item.
        return;
      } else if (_state == SwipeState.animatingToClose) {
        final wasProgressiveRight = _lockedDirection == SwipeDirection.right &&
            widget.rightSwipe != null;
        final wasIntentionalLeft = _lockedDirection == SwipeDirection.left &&
            widget.leftSwipe?.mode == LeftSwipeMode.autoTrigger;
        final wasPanelClose = _lockedDirection == SwipeDirection.left &&
            widget.leftSwipe?.mode == LeftSwipeMode.reveal;
        _lockedDirection = SwipeDirection.none;
        _awaitingConfirmation = false;
        _updateState(SwipeState.idle);
        if (wasProgressiveRight && !_isPostIncrementSnapBack) {
          widget.rightSwipe!.onSwipeCancelled?.call();
        }
        if (wasIntentionalLeft && !_isPostActionSnapBack) {
          widget.leftSwipe!.onSwipeCancelled?.call();
        }
        if (wasPanelClose) {
          widget.leftSwipe!.onPanelClosed?.call();
        }
        _isPostIncrementSnapBack = false;
        _isPostActionSnapBack = false;
      } else if (_state == SwipeState.animatingToOpen) {
        if (_lockedDirection == SwipeDirection.right &&
            widget.rightSwipe != null) {
          _applyProgressiveIncrement();
          _isPostIncrementSnapBack = true;
          _updateState(SwipeState.animatingToClose);
          _snapBack(_controller.value, 0.0);
        } else if (_lockedDirection == SwipeDirection.left &&
            widget.leftSwipe != null) {
          _handleIntentionalActionSettled();
        } else {
          _updateState(SwipeState.revealed);
        }
      }
    }
  }

  // ─── F4 intentional action ──────────────────────────────────────────────────

  /// Called when [animatingToOpen] completes for a left swipe with [leftSwipe] set.
  void _handleIntentionalActionSettled() {
    final config = widget.leftSwipe!;
    if (config.mode == LeftSwipeMode.reveal) {
      _updateState(SwipeState.revealed);
      config.onPanelOpened?.call();
    } else {
      // autoTrigger
      if (config.requireConfirmation && !_awaitingConfirmation) {
        _awaitingConfirmation = true;
        _updateState(SwipeState.revealed); // hold for confirmation
      } else {
        _applyIntentionalAction();
      }
    }
  }

  /// Fires the action callback and applies the post-action behavior.
  void _applyIntentionalAction() {
    final config = widget.leftSwipe!;
    _awaitingConfirmation = false;
    if (config.enableHaptic) HapticFeedback.mediumImpact();
    config.onActionTriggered?.call();
    _applyPostActionBehavior();
  }

  /// Applies [PostActionBehavior] after an auto-trigger action fires.
  void _applyPostActionBehavior() {
    final config = widget.leftSwipe!;
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

  /// Animates the cell fully off-screen to the left. Terminal — no snap-back.
  void _animateOut() {
    final spring = widget.animationConfig.completionSpring;
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

  /// Returns the effective max-translation for left swipes.
  ///
  /// In reveal mode, this is the panel width (explicit or auto-computed).
  /// In auto-trigger / unconfigured mode, it falls back to the configured or
  /// default max translation.
  double _leftMaxTranslation(double widgetWidth) {
    final config = widget.leftSwipe;
    if (config?.mode == LeftSwipeMode.reveal && config!.actions.isNotEmpty) {
      return config.actionPanelWidth ?? _computeAutoPanelWidth(widgetWidth);
    }
    return widget.animationConfig.maxTranslationLeft ?? widgetWidth * 0.6;
  }

  /// Auto-computes the action panel width from the number of actions.
  double _computeAutoPanelWidth(double widgetWidth) {
    final count =
        widget.leftSwipe!.actions.length.clamp(1, 3).toDouble();
    return (count * 80.0).clamp(60.0, widgetWidth * 0.65);
  }

  /// Returns the effective panel width for [SwipeActionPanel] and Positioned.
  double _computeEffectivePanelWidth(double widgetWidth) {
    final config = widget.leftSwipe!;
    return config.actionPanelWidth ?? _computeAutoPanelWidth(widgetWidth);
  }

  // ─── F3 progressive ─────────────────────────────────────────────────────────

  void _applyProgressiveIncrement() {
    final config = widget.rightSwipe!;
    final current = _progressValueNotifier!.value;
    final result =
        computeNextProgressiveValue(current: current, config: config);

    final isControlled = config.value != null;

    if (result.nextValue != current) {
      if (!isControlled) {
        _progressValueNotifier!.value = result.nextValue;
      }
      config.onProgressChanged?.call(result.nextValue, current);
    }
    if (result.hitMax) config.onMaxReached?.call();
    if (config.enableHaptic) HapticFeedback.mediumImpact();
    config.onSwipeCompleted?.call(result.nextValue);
  }

  // ─── State machine ───────────────────────────────────────────────────────────

  void _updateState(SwipeState newState) {
    if (_state == newState) return;
    setState(() {
      _state = newState;
    });
    widget.onStateChanged?.call(newState);
  }

  // ─── Gesture physics ─────────────────────────────────────────────────────────

  double _applyResistance(
      double rawOffset, double maxTranslation, double factor) {
    if (maxTranslation <= 0) return 0.0;
    final sign = rawOffset.sign;
    final abs = rawOffset.abs();

    if (abs <= maxTranslation) {
      return rawOffset;
    }

    if (factor <= 0.0) {
      return sign * maxTranslation;
    }

    final overflow = abs - maxTranslation;
    final resistedOverflow =
        (1.0 - 1.0 / (overflow * factor / maxTranslation + 1.0)) *
            maxTranslation;

    return sign * (maxTranslation + resistedOverflow);
  }

  void _handleDragStart(DragStartDetails details) {
    // Ignore new drags when the cell is animating off-screen (terminal state).
    if (_state == SwipeState.animatingOut) return;

    _controller.stop();
    _accumulatedDx = 0.0;

    // When a reveal panel is open (cell held left), pre-lock the direction to
    // left so that a rightward swipe is handled as "closing the panel" (moving
    // back toward origin) rather than triggering a right-swipe action.
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

      if (_accumulatedDx.abs() < widget.gestureConfig.deadZone &&
          _controller.value == 0.0) {
        return;
      }

      if (_controller.value != 0.0 ||
          _accumulatedDx.abs() >= widget.gestureConfig.deadZone) {
        _lockedDirection = (_controller.value + _accumulatedDx) > 0
            ? SwipeDirection.right
            : SwipeDirection.left;

        if (_lockedDirection == SwipeDirection.right &&
            widget.rightSwipe != null &&
            !_swipeStartedFired) {
          widget.rightSwipe!.onSwipeStarted?.call();
          _swipeStartedFired = true;
        }
      } else {
        return;
      }
    }

    if (!widget.gestureConfig.enabledDirections.contains(_lockedDirection)) {
      return;
    }

    final maxT = _lockedDirection == SwipeDirection.right
        ? (widget.animationConfig.maxTranslationRight ?? widgetWidth * 0.6)
        : _leftMaxTranslation(widgetWidth);

    if (maxT <= 0) return;

    final rawNewOffset = _controller.value + dx;
    _controller.value = _applyResistance(
      rawNewOffset,
      maxT,
      widget.animationConfig.resistanceFactor,
    );
  }

  void _handleDragEnd(DragEndDetails details, double widgetWidth) {
    if (_state == SwipeState.animatingOut) return;
    if (_lockedDirection == SwipeDirection.none) {
      _updateState(SwipeState.idle);
      return;
    }

    final maxT = _lockedDirection == SwipeDirection.right
        ? (widget.animationConfig.maxTranslationRight ?? widgetWidth * 0.6)
        : _leftMaxTranslation(widgetWidth);

    if (maxT <= 0) {
      _snapBack(0.0, 0.0);
      return;
    }

    final velocity = details.primaryVelocity ?? 0.0;

    // A rightward release while locked in the left direction, OR a drag that
    // carried the cell past centre (positive offset), means the user is trying
    // to close the panel (return to origin). Snap back.
    if (_lockedDirection == SwipeDirection.left &&
        (velocity > 0 || _controller.value >= 0)) {
      _updateState(SwipeState.animatingToClose);
      _snapBack(_controller.value, velocity > 0 ? velocity : 0.0);
      return;
    }

    final ratio = _controller.value.abs() / maxT;

    final isFling = velocity.abs() >= widget.gestureConfig.velocityThreshold &&
        (_lockedDirection == SwipeDirection.right
            ? velocity > 0
            : velocity < 0);

    final shouldComplete =
        isFling || ratio >= widget.animationConfig.activationThreshold;

    if (shouldComplete) {
      _updateState(SwipeState.animatingToOpen);
      _animateToOpen(
        _controller.value,
        _lockedDirection == SwipeDirection.right ? maxT : -maxT,
        velocity,
      );
    } else {
      _updateState(SwipeState.animatingToClose);
      _snapBack(_controller.value, velocity);
    }
  }

  void _snapBack(double fromOffset, double velocity) {
    final spring = widget.animationConfig.snapBackSpring;
    final simulation = SpringSimulation(
      SpringDescription(
        mass: spring.mass,
        stiffness: spring.stiffness,
        damping: spring.damping,
      ),
      fromOffset,
      0.0,
      velocity,
    );
    _controller.animateWith(simulation);
  }

  void _animateToOpen(double fromOffset, double toOffset, double velocity) {
    final spring = widget.animationConfig.completionSpring;
    final simulation = SpringSimulation(
      SpringDescription(
        mass: spring.mass,
        stiffness: spring.stiffness,
        damping: spring.damping,
      ),
      fromOffset,
      toOffset,
      velocity,
    );
    _controller.animateWith(simulation);
  }

  // ─── Body-tap interceptor ────────────────────────────────────────────────────

  /// Conditionally wraps [child] with a tap detector that handles taps when
  /// the cell is in the [SwipeState.revealed] state with [leftSwipe] set.
  Widget _maybeWrapWithBodyTapInterceptor(Widget child) {
    if (_state != SwipeState.revealed || widget.leftSwipe == null) {
      return child;
    }
    // SizedBox.expand forces the GestureDetector to fill the full cell area
    // (400×height), not just the natural bounds of [child]. Without this, a
    // small child (e.g. Text) results in a tiny hit area that fails to absorb
    // taps across the entire translated cell surface.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _handleBodyTapInRevealedState,
      child: SizedBox.expand(child: child),
    );
  }

  void _handleBodyTapInRevealedState() {
    if (_awaitingConfirmation) {
      // Cancel confirmation — snap back to idle.
      _awaitingConfirmation = false;
      _updateState(SwipeState.animatingToClose);
      _snapBack(_controller.value, 0.0);
    } else {
      // Close reveal panel or stay-mode cell.
      _updateState(SwipeState.animatingToClose);
      _snapBack(_controller.value, 0.0);
    }
  }

  // ─── Build helpers ──────────────────────────────────────────────────────────

  Widget _buildBackground(BuildContext context, SwipeProgress progress) {
    if (progress.direction == SwipeDirection.none) {
      return const SizedBox.shrink();
    }
    final builder = progress.direction == SwipeDirection.right
        ? widget.rightBackground
        : widget.leftBackground;
    if (builder == null) return const SizedBox.shrink();
    return builder(context, progress);
  }

  Widget _buildProgressIndicator() {
    final config = widget.rightSwipe!;
    final indicatorConfig =
        config.progressIndicatorConfig ?? const ProgressIndicatorConfig();

    assert(
      !config.maxValue.isInfinite,
      'showProgressIndicator requires a finite maxValue',
    );

    if (config.maxValue.isInfinite) return const SizedBox.shrink();

    return Positioned(
      top: 0,
      bottom: 0,
      left: 0,
      width: indicatorConfig.width,
      child: RepaintBoundary(
        child: ValueListenableBuilder<double>(
          valueListenable: _progressValueNotifier!,
          builder: (context, value, _) {
            final fillRatio = (value / config.maxValue).clamp(0.0, 1.0);
            return ProgressiveSwipeIndicator(
              fillRatio: fillRatio,
              config: indicatorConfig,
            );
          },
        ),
      ),
    );
  }

  /// Builds the reveal-mode [SwipeActionPanel], positioned at the right edge.
  Widget _buildRevealPanel(double widgetWidth) {
    final config = widget.leftSwipe!;
    final panelWidth = _computeEffectivePanelWidth(widgetWidth);
    final actions = config.actions.take(3).toList();
    assert(
      config.actions.length <= 3,
      'SwipeActionPanel: actions must contain 1–3 items; '
      '${config.actions.length} provided; only the first 3 will be rendered.',
    );
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
    if (widget.borderRadius != null) {
      return ClipRRect(
        borderRadius: widget.borderRadius!,
        clipBehavior: widget.clipBehavior,
        child: child,
      );
    }
    if (widget.clipBehavior != Clip.none) {
      return ClipRect(clipBehavior: widget.clipBehavior, child: child);
    }
    return child;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Cache widget width for animateOut target calculation.
        _widgetWidth = width;

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragStart: _handleDragStart,
          onHorizontalDragUpdate: (details) =>
              _handleDragUpdate(details, width),
          onHorizontalDragEnd: (details) => _handleDragEnd(details, width),
          child: _wrapWithClip(
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final offset = _controller.value;

                final maxT = _lockedDirection == SwipeDirection.right
                    ? (widget.animationConfig.maxTranslationRight ??
                        width * 0.6)
                    : _leftMaxTranslation(width);

                final double ratio;
                if (_lockedDirection == SwipeDirection.right) {
                  ratio = maxT > 0 ? (offset / maxT).clamp(0.0, 1.0) : 0.0;
                } else if (_lockedDirection == SwipeDirection.left) {
                  ratio =
                      maxT > 0 ? (offset.abs() / maxT).clamp(0.0, 1.0) : 0.0;
                } else {
                  ratio = 0.0;
                }
                final progress = SwipeProgress(
                  direction: _lockedDirection,
                  ratio: ratio,
                  isActivated:
                      ratio >= widget.animationConfig.activationThreshold,
                  rawOffset: offset,
                );

                // Right-swipe haptic (F3).
                if (widget.rightSwipe?.enableHaptic == true &&
                    _lockedDirection == SwipeDirection.right &&
                    progress.isActivated &&
                    !_hapticThresholdFired) {
                  HapticFeedback.lightImpact();
                  _hapticThresholdFired = true;
                }

                // Left-swipe haptic (F4).
                if (widget.leftSwipe?.enableHaptic == true &&
                    _lockedDirection == SwipeDirection.left &&
                    progress.isActivated &&
                    !_hapticThresholdFired) {
                  HapticFeedback.lightImpact();
                  _hapticThresholdFired = true;
                }

                if (widget.onProgressChanged != null) {
                  widget.onProgressChanged!(progress);
                }

                final translatedChild = Transform.translate(
                  offset: Offset(offset, 0),
                  child: _maybeWrapWithBodyTapInterceptor(child!),
                );

                // Confirmation background-area tap overlay.
                // Translucent so body taps still reach [_maybeWrapWithBodyTapInterceptor].
                final confirmOverlay = _awaitingConfirmation
                    ? Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: _applyIntentionalAction,
                        ),
                      )
                    : null;

                return Stack(
                  children: [
                    if (widget.leftBackground != null ||
                        widget.rightBackground != null)
                      Positioned.fill(
                        child: _buildBackground(context, progress),
                      ),
                    if (confirmOverlay != null) confirmOverlay,
                    translatedChild,
                    // Reveal panel — shown only when state is revealed and mode is reveal.
                    if (widget.leftSwipe?.mode == LeftSwipeMode.reveal &&
                        _state == SwipeState.revealed &&
                        widget.leftSwipe!.actions.isNotEmpty)
                      _buildRevealPanel(width),
                    if (widget.rightSwipe?.showProgressIndicator == true)
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

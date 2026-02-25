import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

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

  @override
  State<SwipeActionCell> createState() => _SwipeActionCellState();
}

class _SwipeActionCellState extends State<SwipeActionCell>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  SwipeState _state = SwipeState.idle;
  SwipeDirection _lockedDirection = SwipeDirection.none;
  double _accumulatedDx = 0.0;

  /// Read-only observable of the current horizontal pixel offset.
  /// Exposed for widget testing via a GlobalKey.
  ValueListenable<double> get swipeOffsetListenable => _controller;

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

  @override
  void dispose() {
    _controller.removeStatusListener(_handleAnimationStatusChange);
    _controller.dispose();
    super.dispose();
  }

  void _handleAnimationStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      if (_state == SwipeState.animatingToClose) {
        _lockedDirection = SwipeDirection.none;
        _updateState(SwipeState.idle);
      } else if (_state == SwipeState.animatingToOpen) {
        _updateState(SwipeState.revealed);
      }
    }
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

    if (abs <= maxTranslation) {
      return rawOffset;
    }

    if (factor <= 0.0) {
      return sign * maxTranslation;
    }

    final overflow = abs - maxTranslation;
    // iOS-derived logarithmic formula:
    // resistedOverflow = (1 - 1 / (overflow * factor / maxTranslation + 1)) * maxTranslation
    final resistedOverflow =
        (1.0 - 1.0 / (overflow * factor / maxTranslation + 1.0)) *
            maxTranslation;

    return sign * (maxTranslation + resistedOverflow);
  }

  void _handleDragStart(DragStartDetails details) {
    _controller.stop();
    _accumulatedDx = 0.0;
    // Always reset direction lock on new drag to allow re-locking
    // (US5 requirement for starting drag from revealed state)
    _lockedDirection = SwipeDirection.none;
    _updateState(SwipeState.dragging);
  }

  void _handleDragUpdate(DragUpdateDetails details, double widgetWidth) {
    final dx = details.delta.dx;

    if (_lockedDirection == SwipeDirection.none) {
      _accumulatedDx += dx;

      // If we already have an offset (interrupted animation or starting from revealed),
      // we might want to allow moving immediately if the drag is in the direction
      // that reduces the offset. But for simplicity and matching spec:

      if (_accumulatedDx.abs() < widget.gestureConfig.deadZone &&
          _controller.value == 0.0) {
        return;
      }

      // If we have an existing offset, we skip dead zone for intuitive catch
      if (_controller.value != 0.0 ||
          _accumulatedDx.abs() >= widget.gestureConfig.deadZone) {
        _lockedDirection = (_controller.value + _accumulatedDx) > 0
            ? SwipeDirection.right
            : SwipeDirection.left;
      } else {
        return;
      }
    }

    if (!widget.gestureConfig.enabledDirections.contains(_lockedDirection)) {
      return;
    }

    final maxT = _lockedDirection == SwipeDirection.right
        ? (widget.animationConfig.maxTranslationRight ?? widgetWidth * 0.6)
        : (widget.animationConfig.maxTranslationLeft ?? widgetWidth * 0.6);

    if (maxT <= 0) return;

    final rawNewOffset = _controller.value + dx;
    _controller.value = _applyResistance(
      rawNewOffset,
      maxT,
      widget.animationConfig.resistanceFactor,
    );
  }

  void _handleDragEnd(DragEndDetails details, double widgetWidth) {
    if (_lockedDirection == SwipeDirection.none) {
      _updateState(SwipeState.idle);
      return;
    }

    final maxT = _lockedDirection == SwipeDirection.right
        ? (widget.animationConfig.maxTranslationRight ?? widgetWidth * 0.6)
        : (widget.animationConfig.maxTranslationLeft ?? widgetWidth * 0.6);

    if (maxT <= 0) {
      _snapBack(0.0, 0.0);
      return;
    }

    final velocity = details.primaryVelocity ?? 0.0;
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
                    : (widget.animationConfig.maxTranslationLeft ??
                        width * 0.6);

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

                if (widget.onProgressChanged != null) {
                  widget.onProgressChanged!(progress);
                }

                final translate = Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );

                if (widget.leftBackground == null &&
                    widget.rightBackground == null) {
                  return translate;
                }

                return Stack(
                  children: [
                    Positioned.fill(
                      child: _buildBackground(context, progress),
                    ),
                    translate,
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

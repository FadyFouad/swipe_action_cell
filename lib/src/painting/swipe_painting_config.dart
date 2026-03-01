import 'package:flutter/widgets.dart';
import '../core/swipe_progress.dart';
import '../core/swipe_state.dart';
import 'particle_config.dart';

/// Signature for custom painter hooks attached to [SwipeActionCell].
///
/// Called every frame during any [SwipeState] phase. The returned
/// [CustomPainter] is passed directly to [CustomPaint]. Return a painter
/// whose [CustomPainter.shouldRepaint] reflects your repaint logic.
///
/// In debug mode, exceptions thrown by this callback propagate immediately.
/// In release mode, exceptions are caught and the paint layer is skipped
/// for that frame.
typedef SwipePainterCallback = CustomPainter Function(
  SwipeProgress progress,
  SwipeState state,
);

/// Configuration for custom painting and decoration hooks on [SwipeActionCell].
///
/// Null configuration disables all custom painting features, resulting in
/// zero rendering overhead.
@immutable
class SwipePaintingConfig {
  /// Creates a [SwipePaintingConfig].
  const SwipePaintingConfig({
    this.backgroundPainter,
    this.foregroundPainter,
    this.restingDecoration,
    this.activatedDecoration,
    this.particleConfig,
  });

  /// Painter rendered below the background widget. Null = no layer added.
  final SwipePainterCallback? backgroundPainter;

  /// Painter rendered above the child widget. Null = no layer added.
  /// Hit testing is unaffected (IgnorePointer is applied).
  final SwipePainterCallback? foregroundPainter;

  /// Decoration applied to the cell at progress 0.0.
  final Decoration? restingDecoration;

  /// Decoration applied to the cell at progress 1.0.
  /// Null = resting decoration applied at all times.
  final Decoration? activatedDecoration;

  /// Particle burst configuration. Null = no particle animation.
  final ParticleConfig? particleConfig;

  /// Returns a copy of this config with the specified fields replaced.
  SwipePaintingConfig copyWith({
    SwipePainterCallback? backgroundPainter,
    SwipePainterCallback? foregroundPainter,
    Decoration? restingDecoration,
    Decoration? activatedDecoration,
    ParticleConfig? particleConfig,
  }) {
    return SwipePaintingConfig(
      backgroundPainter: backgroundPainter ?? this.backgroundPainter,
      foregroundPainter: foregroundPainter ?? this.foregroundPainter,
      restingDecoration: restingDecoration ?? this.restingDecoration,
      activatedDecoration: activatedDecoration ?? this.activatedDecoration,
      particleConfig: particleConfig ?? this.particleConfig,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SwipePaintingConfig &&
        other.backgroundPainter == backgroundPainter &&
        other.foregroundPainter == foregroundPainter &&
        other.restingDecoration == restingDecoration &&
        other.activatedDecoration == activatedDecoration &&
        other.particleConfig == particleConfig;
  }

  @override
  int get hashCode => Object.hash(
        backgroundPainter,
        foregroundPainter,
        restingDecoration,
        activatedDecoration,
        particleConfig,
      );
}

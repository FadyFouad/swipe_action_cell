import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// Internal data class representing a single particle in the burst.
class Particle {
  /// Creates a particle.
  const Particle({
    required this.angle,
    required this.maxDistance,
    required this.color,
  });

  /// The angle in radians.
  final double angle;

  /// The maximum distance this particle travels.
  final double maxDistance;

  /// The color of the particle.
  final Color color;
}

/// Internal custom painter that draws fading particles expanding outward.
class SwipeParticlePainter extends CustomPainter {
  /// Creates a painter for the particle burst.
  SwipeParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.origin,
  });

  /// The list of particles to draw.
  final List<Particle> particles;

  /// The current animation progress from 0.0 to 1.0.
  final double animationValue;

  /// The center point from which particles expand.
  final Offset origin;

  @override
  void paint(Canvas canvas, Size size) {
    if (animationValue <= 0.0 || animationValue >= 1.0) return;

    final opacity = (1.0 - animationValue).clamp(0.0, 1.0);

    for (final p in particles) {
      final distance = p.maxDistance * animationValue;
      final dx = math.cos(p.angle) * distance;
      final dy = math.sin(p.angle) * distance;

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(origin + Offset(dx, dy), 3.0, paint);
    }
  }

  @override
  bool shouldRepaint(SwipeParticlePainter old) {
    return animationValue != old.animationValue || origin != old.origin;
  }
}

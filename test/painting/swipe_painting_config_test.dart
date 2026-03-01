import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:swipe_action_cell/src/core/swipe_state.dart";
import "package:swipe_action_cell/src/core/swipe_progress.dart";
import "package:swipe_action_cell/src/painting/swipe_painting_config.dart";
import "package:swipe_action_cell/src/painting/particle_config.dart";

class _FakePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void main() {
  group("SwipePaintingConfig", () {
    test("const construction with all nulls", () {
      const config = SwipePaintingConfig();
      expect(config.backgroundPainter, isNull);
      expect(config.foregroundPainter, isNull);
      expect(config.restingDecoration, isNull);
      expect(config.activatedDecoration, isNull);
      expect(config.particleConfig, isNull);
    });

    test("copyWith preserves unchanged fields", () {
      final p = (SwipeProgress _, SwipeState __) => _FakePainter();
      final config = SwipePaintingConfig(backgroundPainter: p);
      final copied = config.copyWith(restingDecoration: const BoxDecoration());
      expect(copied.backgroundPainter, p);
      expect(copied.restingDecoration, isNotNull);
      expect(copied.foregroundPainter, isNull);
    });

    test("equality and hashCode", () {
      final p = (SwipeProgress _, SwipeState __) => _FakePainter();
      final c1 = SwipePaintingConfig(
          backgroundPainter: p, restingDecoration: const BoxDecoration());
      final c2 = SwipePaintingConfig(
          backgroundPainter: p, restingDecoration: const BoxDecoration());
      final c3 = SwipePaintingConfig();
      expect(c1, c2);
      expect(c1.hashCode, c2.hashCode);
      expect(c1, isNot(c3));
    });
  });

  group("ParticleConfig", () {
    test("const construction with defaults", () {
      const config = ParticleConfig();
      expect(config.count, 12);
      expect(config.colors.isEmpty, isTrue);
      expect(config.spreadAngle, 360.0);
      expect(config.duration, const Duration(milliseconds: 500));
    });

    test("custom values", () {
      const config = ParticleConfig(
        count: 0,
        colors: [Colors.red, Colors.blue],
        spreadAngle: 180.0,
        duration: Duration(milliseconds: 300),
      );
      expect(config.count, 0);
      expect(config.colors.length, 2);
      expect(config.spreadAngle, 180.0);
      expect(config.duration, const Duration(milliseconds: 300));
    });

    test("copyWith preserves unchanged fields", () {
      const config = ParticleConfig(count: 5);
      final copied = config.copyWith(spreadAngle: 90.0);
      expect(copied.count, 5);
      expect(copied.spreadAngle, 90.0);
      expect(copied.duration, const Duration(milliseconds: 500));
    });

    test("equality and hashCode", () {
      const c1 = ParticleConfig(count: 5, spreadAngle: 90.0);
      const c2 = ParticleConfig(count: 5, spreadAngle: 90.0);
      const c3 = ParticleConfig(count: 5, spreadAngle: 180.0);
      expect(c1, c2);
      expect(c1.hashCode, c2.hashCode);
      expect(c1, isNot(c3));
    });
  });
}

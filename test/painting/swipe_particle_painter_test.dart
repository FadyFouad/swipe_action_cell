import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:swipe_action_cell/src/painting/swipe_particle_painter.dart";

void main() {
  group("SwipeParticlePainter US4", () {
    test("shouldRepaint returns true when animationValue changes", () {
      final p1 = SwipeParticlePainter(
          particles: [], animationValue: 0.1, origin: Offset.zero);
      final p2 = SwipeParticlePainter(
          particles: [], animationValue: 0.2, origin: Offset.zero);
      expect(p2.shouldRepaint(p1), isTrue);
    });

    test("shouldRepaint returns false when unchanged", () {
      final p1 = SwipeParticlePainter(
          particles: [], animationValue: 0.1, origin: Offset.zero);
      final p2 = SwipeParticlePainter(
          particles: [], animationValue: 0.1, origin: Offset.zero);
      expect(p2.shouldRepaint(p1), isFalse);
    });
  });
}

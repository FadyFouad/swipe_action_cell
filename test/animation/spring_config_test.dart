import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/src/animation/spring_config.dart';

void main() {
  group('SpringConfig', () {
    test('supports value equality', () {
      const c1 = SpringConfig(mass: 1.0, stiffness: 500.0, damping: 28.0);
      const c2 = SpringConfig(mass: 1.0, stiffness: 500.0, damping: 28.0);
      const c3 = SpringConfig(mass: 1.0, stiffness: 400.0, damping: 25.0);

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1, isNot(equals(c3)));
    });

    test('copyWith updates specified fields', () {
      const c1 = SpringConfig(mass: 1.0, stiffness: 500.0, damping: 28.0);
      final c2 = c1.copyWith(stiffness: 600.0);

      expect(c2.mass, equals(1.0));
      expect(c2.stiffness, equals(600.0));
      expect(c2.damping, equals(28.0));
    });

    test('presets are correct', () {
      expect(SpringConfig.snapBack.stiffness, equals(400.0));
      expect(SpringConfig.snapBack.damping, equals(25.0));
      expect(SpringConfig.completion.stiffness, equals(600.0));
      expect(SpringConfig.completion.damping, equals(32.0));
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/src/animation/spring_config.dart';
import 'package:swipe_action_cell/src/animation/swipe_animation_config.dart';

void main() {
  group('SwipeAnimationConfig', () {
    test('supports value equality', () {
      const c1 = SwipeAnimationConfig(
        activationThreshold: 0.4,
        snapBackSpring: SpringConfig.snapBack,
        completionSpring: SpringConfig.completion,
        resistanceFactor: 0.55,
      );
      const c2 = SwipeAnimationConfig(
        activationThreshold: 0.4,
        snapBackSpring: SpringConfig.snapBack,
        completionSpring: SpringConfig.completion,
        resistanceFactor: 0.55,
      );
      const c3 = SwipeAnimationConfig(
        activationThreshold: 0.5,
      );

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1, isNot(equals(c3)));
    });

    test('copyWith updates specified fields', () {
      const c1 = SwipeAnimationConfig();
      final c2 =
          c1.copyWith(activationThreshold: 0.6, maxTranslationLeft: 100.0);

      expect(c2.activationThreshold, equals(0.6));
      expect(c2.maxTranslationLeft, equals(100.0));
      expect(c2.snapBackSpring, equals(c1.snapBackSpring));
    });

    test('default values match spec', () {
      const c1 = SwipeAnimationConfig();
      expect(c1.activationThreshold, equals(0.4));
      expect(c1.resistanceFactor, equals(0.55));
      expect(c1.maxTranslationLeft, isNull);
      expect(c1.maxTranslationRight, isNull);
    });
  });
}

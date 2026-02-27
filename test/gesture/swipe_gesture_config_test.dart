import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/src/core/swipe_direction.dart';
import 'package:swipe_action_cell/src/gesture/swipe_gesture_config.dart';

void main() {
  group('SwipeGestureConfig', () {
    test('supports value equality', () {
      const c1 = SwipeGestureConfig(
        deadZone: 12.0,
        enabledDirections: {SwipeDirection.left, SwipeDirection.right},
        velocityThreshold: 700.0,
        horizontalThresholdRatio: 1.5,
        closeOnScroll: true,
        respectEdgeGestures: true,
      );
      const c2 = SwipeGestureConfig(
        deadZone: 12.0,
        enabledDirections: {SwipeDirection.left, SwipeDirection.right},
        velocityThreshold: 700.0,
        horizontalThresholdRatio: 1.5,
        closeOnScroll: true,
        respectEdgeGestures: true,
      );
      const c3 = SwipeGestureConfig(
        deadZone: 20.0,
      );

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1, isNot(equals(c3)));

      // Differing in only one new field
      expect(
          c1,
          isNot(
              equals(const SwipeGestureConfig(horizontalThresholdRatio: 2.0))));
      expect(c1, isNot(equals(const SwipeGestureConfig(closeOnScroll: false))));
      expect(c1,
          isNot(equals(const SwipeGestureConfig(respectEdgeGestures: false))));

      expect(
          c1.hashCode,
          isNot(equals(const SwipeGestureConfig(horizontalThresholdRatio: 2.0)
              .hashCode)));
      expect(
          c1.hashCode,
          isNot(
              equals(const SwipeGestureConfig(closeOnScroll: false).hashCode)));
      expect(
          c1.hashCode,
          isNot(equals(
              const SwipeGestureConfig(respectEdgeGestures: false).hashCode)));
    });

    test('copyWith updates specified fields', () {
      const c1 = SwipeGestureConfig();
      final c2 = c1.copyWith(deadZone: 15.0);
      expect(c2.deadZone, equals(15.0));
      expect(c2.enabledDirections, equals(c1.enabledDirections));
      expect(c2.horizontalThresholdRatio, equals(c1.horizontalThresholdRatio));

      final c3 = c1.copyWith(horizontalThresholdRatio: 2.0);
      expect(c3.horizontalThresholdRatio, equals(2.0));
      expect(c3.closeOnScroll, equals(c1.closeOnScroll));

      final c4 = c1.copyWith(closeOnScroll: false);
      expect(c4.closeOnScroll, equals(false));

      final c5 = c1.copyWith(respectEdgeGestures: false);
      expect(c5.respectEdgeGestures, equals(false));
    });

    test('asserts horizontalThresholdRatio >= 1.0', () {
      expect(
        () => SwipeGestureConfig(horizontalThresholdRatio: 0.9),
        throwsA(
          isA<AssertionError>().having(
            (e) => e.message,
            'message',
            contains('horizontalThresholdRatio must be >= 1.0'),
          ),
        ),
      );

      // Lower boundary is valid
      expect(() => const SwipeGestureConfig(horizontalThresholdRatio: 1.0),
          returnsNormally);
    });

    test('tight preset uses 2.5 horizontalThresholdRatio', () {
      final config = SwipeGestureConfig.tight();
      expect(config.horizontalThresholdRatio, equals(2.5));
    });
  });
}

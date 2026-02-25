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
      );
      const c2 = SwipeGestureConfig(
        deadZone: 12.0,
        enabledDirections: {SwipeDirection.left, SwipeDirection.right},
        velocityThreshold: 700.0,
      );
      const c3 = SwipeGestureConfig(
        deadZone: 20.0,
      );

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1, isNot(equals(c3)));
    });

    test('copyWith updates specified fields', () {
      const c1 = SwipeGestureConfig();
      final c2 = c1.copyWith(deadZone: 15.0);

      expect(c2.deadZone, equals(15.0));
      expect(c2.enabledDirections, equals(c1.enabledDirections));
    });
  });
}
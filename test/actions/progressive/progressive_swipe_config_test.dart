import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('ProgressiveSwipeConfig', () {
    test('default values', () {
      const config = ProgressiveSwipeConfig();
      expect(config.value, isNull);
      expect(config.initialValue, equals(0.0));
      expect(config.stepValue, equals(1.0));
      expect(config.maxValue, equals(double.infinity));
      expect(config.minValue, equals(0.0));
      expect(config.overflowBehavior, equals(OverflowBehavior.clamp));
      expect(config.showProgressIndicator, isFalse);
      expect(config.enableHaptic, isFalse);
    });

    test('assert stepValue > 0', () {
      expect(() => ProgressiveSwipeConfig(stepValue: 0), throwsAssertionError);
      expect(() => ProgressiveSwipeConfig(stepValue: -1), throwsAssertionError);
    });

    test('assert minValue < maxValue', () {
      expect(() => ProgressiveSwipeConfig(minValue: 10, maxValue: 5),
          throwsAssertionError);
      expect(() => ProgressiveSwipeConfig(minValue: 5, maxValue: 5),
          throwsAssertionError);
    });

    test('copyWith', () {
      const config = ProgressiveSwipeConfig();
      final updated = config.copyWith(
        initialValue: 10.0,
        maxValue: 100.0,
      );
      expect(updated.initialValue, equals(10.0));
      expect(updated.maxValue, equals(100.0));
      expect(updated.stepValue, equals(config.stepValue));
    });

    test('equality and hashCode', () {
      const c1 = ProgressiveSwipeConfig(initialValue: 5.0);
      const c2 = ProgressiveSwipeConfig(initialValue: 5.0);
      const c3 = ProgressiveSwipeConfig(initialValue: 6.0);

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1, isNot(equals(c3)));
    });
  });
}

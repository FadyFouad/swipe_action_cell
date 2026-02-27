import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';
// ignore: implementation_imports
import 'package:swipe_action_cell/src/actions/progressive/progressive_value_logic.dart';

void main() {
  group('computeNextProgressiveValue', () {
    test('fixed step increment', () {
      const config = RightSwipeConfig(stepValue: 1.0, maxValue: 10.0);
      final result = computeNextProgressiveValue(current: 0.0, config: config);
      expect(result.nextValue, equals(1.0));
      expect(result.hitMax, isFalse);
    });

    test('clamp at max', () {
      const config = RightSwipeConfig(stepValue: 1.0, maxValue: 5.0);
      final result = computeNextProgressiveValue(current: 4.5, config: config);
      expect(result.nextValue, equals(5.0));
      expect(result.hitMax, isTrue);
    });

    test('clamp above max', () {
      const config = RightSwipeConfig(stepValue: 2.0, maxValue: 5.0);
      final result = computeNextProgressiveValue(current: 4.0, config: config);
      expect(result.nextValue, equals(5.0));
      expect(result.hitMax, isTrue);
    });

    test('wrap above max', () {
      const config = RightSwipeConfig(
        stepValue: 2.0,
        maxValue: 5.0,
        minValue: 0.0,
        overflowBehavior: OverflowBehavior.wrap,
      );
      final result = computeNextProgressiveValue(current: 4.0, config: config);
      expect(result.nextValue, equals(0.0));
      expect(result.hitMax, isTrue);
    });

    test('ignore max', () {
      const config = RightSwipeConfig(
        stepValue: 2.0,
        maxValue: 5.0,
        overflowBehavior: OverflowBehavior.ignore,
      );
      final result = computeNextProgressiveValue(current: 4.0, config: config);
      expect(result.nextValue, equals(6.0));
      expect(result.hitMax, isFalse);
    });

    test('step <= 0 is no-op', () {
      const config = RightSwipeConfig(stepValue: 1.0);
      final result0 = computeNextProgressiveValue(
        current: 5.0,
        config: config.copyWith(dynamicStep: (v) => 0.0),
      );
      expect(result0.nextValue, equals(5.0));

      final resultNeg = computeNextProgressiveValue(
        current: 5.0,
        config: config.copyWith(dynamicStep: (v) => -1.0),
      );
      expect(resultNeg.nextValue, equals(5.0));
    });
  });
}

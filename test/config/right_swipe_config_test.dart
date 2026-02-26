import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('RightSwipeConfig', () {
    test('const constructability', () {
      const config = RightSwipeConfig(
        stepValue: 1.0,
        maxValue: 10.0,
      );
      expect(config.stepValue, 1.0);
      expect(config.maxValue, 10.0);
    });

    test('stepValue <= 0 assertion fires', () {
      expect(
        () => RightSwipeConfig(stepValue: 0, maxValue: 10),
        throwsA(isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('stepValue must be > 0'),
        )),
      );
    });

    test('minValue >= maxValue assertion fires', () {
      expect(
        () => RightSwipeConfig(stepValue: 1, minValue: 10, maxValue: 10),
        throwsA(isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('minValue must be < maxValue'),
        )),
      );
    });

    test('copyWith no-arg equality', () {
      const config = RightSwipeConfig(stepValue: 1.0, maxValue: 10.0);
      expect(config.copyWith(), config);
    });

    test('copyWith with args changes only specified fields', () {
      const config = RightSwipeConfig(stepValue: 1.0, maxValue: 10.0);
      final updated = config.copyWith(stepValue: 2.0);
      expect(updated.stepValue, 2.0);
      expect(updated.maxValue, 10.0);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('SwipeGestureConfig presets', () {
    test('tight().deadZone >= 2 * loose().deadZone', () {
      expect(
        SwipeGestureConfig.tight().deadZone,
        greaterThanOrEqualTo(2 * SwipeGestureConfig.loose().deadZone),
      );
    });

    test('tight().deadZone > 0', () {
      expect(SwipeGestureConfig.tight().deadZone, greaterThan(0));
    });

    test('loose().deadZone > 0', () {
      expect(SwipeGestureConfig.loose().deadZone, greaterThan(0));
    });

    test('neither preset equals default instance', () {
      expect(SwipeGestureConfig.tight(), isNot(SwipeGestureConfig()));
      expect(SwipeGestureConfig.loose(), isNot(SwipeGestureConfig()));
    });

    test('presets are not equal to each other', () {
      expect(SwipeGestureConfig.tight(), isNot(SwipeGestureConfig.loose()));
    });

    test('both support copyWith', () {
      expect(SwipeGestureConfig.tight().copyWith(deadZone: 10.0).deadZone, 10.0);
      expect(SwipeGestureConfig.loose().copyWith(deadZone: 10.0).deadZone, 10.0);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('SwipeAnimationConfig presets', () {
    test(
        'snappy().completionSpring.stiffness >= 2 * smooth().completionSpring.stiffness',
        () {
      expect(
        SwipeAnimationConfig.snappy().completionSpring.stiffness,
        greaterThanOrEqualTo(
            2 * SwipeAnimationConfig.smooth().completionSpring.stiffness),
      );
    });

    test('snappy activates earlier than smooth', () {
      expect(
        SwipeAnimationConfig.snappy().activationThreshold,
        lessThan(SwipeAnimationConfig.smooth().activationThreshold),
      );
    });

    test('neither preset equals default instance', () {
      expect(SwipeAnimationConfig.snappy(), isNot(SwipeAnimationConfig()));
      expect(SwipeAnimationConfig.smooth(), isNot(SwipeAnimationConfig()));
    });

    test('presets are not equal to each other', () {
      expect(
          SwipeAnimationConfig.snappy(), isNot(SwipeAnimationConfig.smooth()));
    });

    test('both support copyWith', () {
      expect(
          SwipeAnimationConfig.snappy()
              .copyWith(activationThreshold: 0.5)
              .activationThreshold,
          0.5);
      expect(
          SwipeAnimationConfig.smooth()
              .copyWith(activationThreshold: 0.5)
              .activationThreshold,
          0.5);
    });
  });

  group('SwipeAnimationConfig validation', () {
    test('activationThreshold < 0.0 throws AssertionError', () {
      expect(
        () => SwipeAnimationConfig(activationThreshold: -0.1),
        throwsA(isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('activationThreshold must be between 0.0 and 1.0'),
        )),
      );
    });

    test('activationThreshold > 1.0 throws AssertionError', () {
      expect(
        () => SwipeAnimationConfig(activationThreshold: 1.1),
        throwsA(isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('activationThreshold must be between 0.0 and 1.0'),
        )),
      );
    });

    test('activationThreshold 0.0 and 1.0 pass', () {
      expect(
          const SwipeAnimationConfig(activationThreshold: 0.0)
              .activationThreshold,
          0.0);
      expect(
          const SwipeAnimationConfig(activationThreshold: 1.0)
              .activationThreshold,
          1.0);
    });
  });
}

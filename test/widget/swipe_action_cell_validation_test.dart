import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('Validation error messages (T030 / US4)', () {
    test(
        '(a) LeftSwipeConfig reveal mode with empty actions throws AssertionError '
        'with "reveal mode requires at least one action"', () {
      expect(
        () => LeftSwipeConfig(mode: LeftSwipeMode.reveal, actions: []),
        throwsA(isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('reveal mode requires at least one action'),
        )),
      );
    });

    test(
        '(b) SwipeAnimationConfig activationThreshold: -0.1 throws AssertionError '
        'with "activationThreshold must be between 0.0 and 1.0" and the value',
        () {
      expect(
        () => SwipeAnimationConfig(activationThreshold: -0.1),
        throwsA(isA<AssertionError>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('activationThreshold must be between 0.0 and 1.0'),
            contains('-0.1'),
          ),
        )),
      );
    });

    test(
        '(c) RightSwipeConfig stepValue: 0.0 throws AssertionError '
        'with "stepValue must be > 0" and the value', () {
      expect(
        () => RightSwipeConfig(stepValue: 0.0),
        throwsA(isA<AssertionError>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('stepValue must be > 0'),
            contains('0.0'),
          ),
        )),
      );
    });

    test(
        '(d) LeftSwipeConfig autoTrigger actionPanelWidth: -5.0 throws AssertionError '
        'with "actionPanelWidth must be > 0" and the value', () {
      expect(
        () => LeftSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          actionPanelWidth: -5.0,
        ),
        throwsA(isA<AssertionError>().having(
          (e) => e.message,
          'message',
          allOf(
            contains('actionPanelWidth must be > 0'),
            contains('-5.0'),
          ),
        )),
      );
    });
  });
}

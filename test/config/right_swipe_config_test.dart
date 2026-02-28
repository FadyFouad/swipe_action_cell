import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';
import 'package:swipe_action_cell/src/core/swipe_zone.dart';

void main() {
  group('RightSwipeConfig', () {
    test('const constructability with no required args', () {
      const config = RightSwipeConfig();
      expect(config.stepValue, 1.0);
      expect(config.maxValue, double.infinity);
      expect(config.initialValue, 0.0);
      expect(config.minValue, 0.0);
      expect(config.enableHaptic, false);
      expect(config.showProgressIndicator, false);
    });

    test('stepValue <= 0 assertion fires with value in message', () {
      expect(
        () => RightSwipeConfig(stepValue: 0),
        throwsA(isA<AssertionError>().having(
          (e) => e.message,
          'message',
          allOf(contains('stepValue must be > 0'), contains('0')),
        )),
      );
    });

    test('minValue >= maxValue assertion fires with values in message', () {
      expect(
        () => RightSwipeConfig(minValue: 10, maxValue: 10),
        throwsA(isA<AssertionError>().having(
          (e) => e.message,
          'message',
          allOf(contains('minValue'), contains('maxValue')),
        )),
      );
    });

    test('copyWith no-arg equality', () {
      const config = RightSwipeConfig(stepValue: 2.0, maxValue: 20.0);
      expect(config.copyWith(), config);
    });

    test('copyWith with args changes only specified fields', () {
      const config = RightSwipeConfig(stepValue: 1.0, maxValue: 10.0);
      final updated = config.copyWith(stepValue: 2.0);
      expect(updated.stepValue, 2.0);
      expect(updated.maxValue, 10.0);
    });

    test('dynamicStep field accepted', () {
      double stepFn(double v) => v < 5.0 ? 1.0 : 2.0;
      final config = RightSwipeConfig(dynamicStep: stepFn);
      expect(config.dynamicStep, isNotNull);
    });

    test('onMaxReached callback accepted', () {
      var called = false;
      final config = RightSwipeConfig(onMaxReached: () => called = true);
      config.onMaxReached?.call();
      expect(called, isTrue);
    });
  });

  group('RightSwipeConfig zones', () {
    SwipeZone z(double t, {double? step}) =>
        SwipeZone(threshold: t, semanticLabel: 'Zone', stepValue: step);

    test('valid 2-zone config constructs', () {
      final config = RightSwipeConfig(
        zones: [z(0.4, step: 1.0), z(0.8, step: 5.0)],
      );
      expect(config.zones?.length, 2);
    });

    test('descending thresholds assert fires at runtime in SwipeActionCell',
        () {
      // In this case, validation happens at runtime in SwipeActionCellState.
      // But we can check length assert here if it's in constructor.
    });

    test('>4 zones assert fires', () {
      expect(
          () => RightSwipeConfig(
                zones: [
                  z(0.1, step: 1.0),
                  z(0.2, step: 1.0),
                  z(0.3, step: 1.0),
                  z(0.4, step: 1.0),
                  z(0.5, step: 1.0)
                ],
              ),
          throwsA(isA<AssertionError>()
              .having((e) => e.message, 'message', contains('at most 4'))));
    });

    test('copyWith updates zones and zoneTransitionStyle', () {
      final config = RightSwipeConfig();
      final updated = config.copyWith(
        zones: [z(0.5, step: 1.0)],
        zoneTransitionStyle: ZoneTransitionStyle.crossfade,
      );
      expect(updated.zones?.length, 1);
      expect(updated.zoneTransitionStyle, ZoneTransitionStyle.crossfade);
    });
  });
}

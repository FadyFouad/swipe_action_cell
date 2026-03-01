import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/src/core/swipe_direction.dart';
import 'package:swipe_action_cell/src/core/swipe_progress.dart';

void main() {
  group('SwipeProgress', () {
    test('supports value equality', () {
      const p1 = SwipeProgress(
        direction: SwipeDirection.right,
        ratio: 0.5,
        isActivated: true,
        rawOffset: 50.0,
      );
      const p2 = SwipeProgress(
        direction: SwipeDirection.right,
        ratio: 0.5,
        isActivated: true,
        rawOffset: 50.0,
      );
      const p3 = SwipeProgress(
        direction: SwipeDirection.left,
        ratio: 0.1,
        isActivated: false,
        rawOffset: -10.0,
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
    });

    test('copyWith updates specified fields', () {
      const p1 = SwipeProgress(
        direction: SwipeDirection.right,
        ratio: 0.5,
        isActivated: true,
        rawOffset: 50.0,
      );

      final p2 = p1.copyWith(ratio: 0.8, rawOffset: 80.0);

      expect(p2.direction, equals(SwipeDirection.right));
      expect(p2.ratio, equals(0.8));
      expect(p2.isActivated, equals(true));
      expect(p2.rawOffset, equals(80.0));
    });

    test('toString is descriptive', () {
      const p1 = SwipeProgress(
        direction: SwipeDirection.right,
        ratio: 0.5,
        isActivated: true,
        rawOffset: 50.0,
      );

      expect(p1.toString(), contains('SwipeProgress'));
      expect(p1.toString(), contains('direction: SwipeDirection.right'));
      expect(p1.toString(), contains('ratio: 0.5'));
    });

    test('zero constant represents idle state', () {
      expect(SwipeProgress.zero.direction, equals(SwipeDirection.none));
      expect(SwipeProgress.zero.ratio, equals(0.0));
      expect(SwipeProgress.zero.isActivated, isFalse);
      expect(SwipeProgress.zero.rawOffset, equals(0.0));
    });
  });
}

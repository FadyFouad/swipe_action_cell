import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('SwipeProgress', () {
    test('zero constant has correct default values', () {
      const progress = SwipeProgress.zero;
      expect(progress.direction, SwipeDirection.none);
      expect(progress.ratio, 0.0);
      expect(progress.isActivated, isFalse);
      expect(progress.rawOffset, 0.0);
    });

    test('constructor assigns all fields correctly', () {
      const progress = SwipeProgress(
        direction: SwipeDirection.right,
        ratio: 0.75,
        isActivated: true,
        rawOffset: 120.0,
      );
      expect(progress.direction, SwipeDirection.right);
      expect(progress.ratio, 0.75);
      expect(progress.isActivated, isTrue);
      expect(progress.rawOffset, 120.0);
    });

    test('zero is a const', () {
      // Verify the constant is accessible and stable.
      expect(identical(SwipeProgress.zero, SwipeProgress.zero), isTrue);
    });
  });
}

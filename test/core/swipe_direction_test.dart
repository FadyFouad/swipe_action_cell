import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('SwipeDirection', () {
    test('has left, right, and none values', () {
      expect(SwipeDirection.values, containsAll([
        SwipeDirection.left,
        SwipeDirection.right,
        SwipeDirection.none,
      ]));
    });

    test('values are distinct', () {
      expect(SwipeDirection.left, isNot(SwipeDirection.right));
      expect(SwipeDirection.left, isNot(SwipeDirection.none));
      expect(SwipeDirection.right, isNot(SwipeDirection.none));
    });
  });
}

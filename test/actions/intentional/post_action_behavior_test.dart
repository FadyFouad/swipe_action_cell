import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('PostActionBehavior', () {
    test('has snapBack value', () {
      expect(PostActionBehavior.values, contains(PostActionBehavior.snapBack));
    });

    test('has animateOut value', () {
      expect(
          PostActionBehavior.values, contains(PostActionBehavior.animateOut));
    });

    test('has stay value', () {
      expect(PostActionBehavior.values, contains(PostActionBehavior.stay));
    });

    test('has exactly 3 values', () {
      expect(PostActionBehavior.values.length, 3);
    });

    test('all values are distinct', () {
      expect(PostActionBehavior.snapBack, isNot(PostActionBehavior.animateOut));
      expect(PostActionBehavior.snapBack, isNot(PostActionBehavior.stay));
      expect(PostActionBehavior.animateOut, isNot(PostActionBehavior.stay));
    });

    test('toString includes enum name', () {
      expect(PostActionBehavior.snapBack.toString(), contains('snapBack'));
      expect(PostActionBehavior.animateOut.toString(), contains('animateOut'));
      expect(PostActionBehavior.stay.toString(), contains('stay'));
    });
  });
}

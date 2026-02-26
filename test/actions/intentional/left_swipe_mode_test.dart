import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('LeftSwipeMode', () {
    test('has autoTrigger value', () {
      expect(LeftSwipeMode.values, contains(LeftSwipeMode.autoTrigger));
    });

    test('has reveal value', () {
      expect(LeftSwipeMode.values, contains(LeftSwipeMode.reveal));
    });

    test('has exactly 2 values', () {
      expect(LeftSwipeMode.values.length, 2);
    });

    test('autoTrigger is not reveal', () {
      expect(LeftSwipeMode.autoTrigger, isNot(LeftSwipeMode.reveal));
    });

    test('toString includes enum name', () {
      expect(LeftSwipeMode.autoTrigger.toString(),
          contains('autoTrigger'));
      expect(LeftSwipeMode.reveal.toString(), contains('reveal'));
    });
  });
}

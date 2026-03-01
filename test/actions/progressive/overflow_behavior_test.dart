import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('OverflowBehavior', () {
    test('values exist', () {
      expect(
          OverflowBehavior.values,
          containsAll([
            OverflowBehavior.clamp,
            OverflowBehavior.wrap,
            OverflowBehavior.ignore,
          ]));
    });

    test('can be used in exhaustive switch', () {
      const behavior = OverflowBehavior.clamp;
      final result = switch (behavior) {
        OverflowBehavior.clamp => 'clamped',
        OverflowBehavior.wrap => 'wrapped',
        OverflowBehavior.ignore => 'ignored',
      };
      expect(result, equals('clamped'));
    });
  });
}

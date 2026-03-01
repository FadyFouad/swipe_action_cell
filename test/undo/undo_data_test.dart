import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/src/undo/undo_data.dart';

void main() {
  group('UndoData', () {
    test('immutability and field access', () {
      bool revertCalled = false;
      final data = UndoData(
        oldValue: 1.0,
        newValue: 2.0,
        remainingDuration: const Duration(seconds: 5),
        revert: () => revertCalled = true,
      );
      expect(data.oldValue, 1.0);
      expect(data.newValue, 2.0);
      expect(data.remainingDuration, const Duration(seconds: 5));
      data.revert();
      expect(revertCalled, true);
    });

    test('oldValue and newValue can be null for intentional-action snapshots',
        () {
      final data = UndoData(
        oldValue: null,
        newValue: null,
        remainingDuration: const Duration(seconds: 5),
        revert: () {},
      );
      expect(data.oldValue, isNull);
      expect(data.newValue, isNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/src/controller/swipe_controller.dart';

void main() {
  group('SwipeController Undo', () {
    late SwipeController controller;

    setUp(() {
      controller = SwipeController();
    });

    tearDown(() {
      // controller.dispose();
    });

    test('isUndoPending is false when no cell attached', () {
      expect(controller.isUndoPending, isFalse);
    });

    test('undo() returns false when no cell attached', () {
      expect(controller.undo(), isFalse);
    });

    test('isUndoPending reflects reportUndoPending and notifies listeners', () {
      bool notified = false;
      controller.addListener(() => notified = true);

      controller.reportUndoPending(true);
      expect(controller.isUndoPending, isTrue);
      expect(notified, isTrue);

      notified = false;
      controller.reportUndoPending(false);
      expect(controller.isUndoPending, isFalse);
      expect(notified, isTrue);
    });

    test('reportUndoPending skips notification when value unchanged', () {
      bool notified = false;
      controller.addListener(() => notified = true);

      controller.reportUndoPending(false);
      expect(notified, isFalse);
    });

    test('undo() and commitPendingUndo() are graceful no-ops after dispose()',
        () {
      controller.dispose();
      expect(controller.undo(), isFalse);
      controller.commitPendingUndo();
      // No crash is success
    });
  });
}

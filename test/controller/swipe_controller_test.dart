import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('SwipeController', () {
    test('constructable', () {
      final controller = SwipeController();
      expect(controller, isNotNull);
    });

    test('dispose completes without error', () {
      final controller = SwipeController();
      controller.dispose();
    });
  });
}

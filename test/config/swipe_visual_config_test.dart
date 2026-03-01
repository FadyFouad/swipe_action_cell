import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('SwipeVisualConfig', () {
    test('const constructability', () {
      const config = SwipeVisualConfig(
        clipBehavior: Clip.antiAlias,
      );
      expect(config.clipBehavior, Clip.antiAlias);
    });

    test('default clipBehavior == Clip.hardEdge', () {
      const config = SwipeVisualConfig();
      expect(config.clipBehavior, Clip.hardEdge);
    });

    test('copyWith no-arg equality', () {
      const config = SwipeVisualConfig();
      expect(config.copyWith(), config);
    });

    test('copyWith with clipBehavior changes only that field', () {
      const config = SwipeVisualConfig(clipBehavior: Clip.hardEdge);
      final updated = config.copyWith(clipBehavior: Clip.antiAlias);
      expect(updated.clipBehavior, Clip.antiAlias);
    });
  });
}

import 'package:flutter/material.dart';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('LeftSwipeConfig', () {
    test('const constructability', () {
      const config = LeftSwipeConfig(
        mode: LeftSwipeMode.autoTrigger,
        onActionTriggered: null,
      );
      expect(config.mode, LeftSwipeMode.autoTrigger);
    });

    test('actionPanelWidth <= 0 assertion fires', () {
      expect(
        () => LeftSwipeConfig(actionPanelWidth: 0),
        throwsA(isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('actionPanelWidth must be > 0'),
        )),
      );
    });

    test('reveal-mode with empty actions assertion fires', () {
      expect(
        () => LeftSwipeConfig(
          mode: LeftSwipeMode.reveal,
          actions: [],
        ),
        throwsA(isA<AssertionError>().having(
          (e) => e.message,
          'message',
          contains('reveal mode requires at least one action'),
        )),
      );
    });

    test('reveal-mode with non-empty actions passes', () {
      final config = LeftSwipeConfig(
        mode: LeftSwipeMode.reveal,
        actions: [
          SwipeAction(backgroundColor: Color(0xFFE53935), foregroundColor: Color(0xFFFFFFFF), 
            icon: const Icon(Icons.archive),
            onTap: () {},
          ),
        ],
      );
      expect(config.actions, isNotEmpty);
    });

    test('autoTrigger with empty actions passes', () {
      const config = LeftSwipeConfig(
        mode: LeftSwipeMode.autoTrigger,
        actions: [],
      );
      expect(config.actions, isEmpty);
    });

    test('copyWith no-arg equality', () {
      const config = LeftSwipeConfig(mode: LeftSwipeMode.autoTrigger);
      expect(config.copyWith(), config);
    });
  });
}

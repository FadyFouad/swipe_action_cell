import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('LeftSwipeConfig', () {
    test('const constructability with required mode', () {
      const config = LeftSwipeConfig(
        mode: LeftSwipeMode.autoTrigger,
      );
      expect(config.mode, LeftSwipeMode.autoTrigger);
      expect(config.actionPanelWidth, isNull);
      expect(config.enableHaptic, false);
    });

    test('actionPanelWidth <= 0 assertion fires with value in message', () {
      expect(
        () => LeftSwipeConfig(
            mode: LeftSwipeMode.autoTrigger, actionPanelWidth: 0),
        throwsA(isA<AssertionError>().having(
          (e) => e.message,
          'message',
          allOf(contains('actionPanelWidth must be > 0'), contains('0')),
        )),
      );
    });

    test('null actionPanelWidth passes without assertion', () {
      const config = LeftSwipeConfig(
        mode: LeftSwipeMode.autoTrigger,
      );
      expect(config.actionPanelWidth, isNull);
    });

    test('reveal-mode with empty actions assertion fires with correct message',
        () {
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
          SwipeAction(
            backgroundColor: const Color(0xFFE53935),
            foregroundColor: const Color(0xFFFFFFFF),
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

    test('copyWith with args changes only specified fields', () {
      const config = LeftSwipeConfig(
        mode: LeftSwipeMode.autoTrigger,
        requireConfirmation: false,
      );
      final updated = config.copyWith(requireConfirmation: true);
      expect(updated.requireConfirmation, isTrue);
      expect(updated.mode, LeftSwipeMode.autoTrigger);
    });
  });
}

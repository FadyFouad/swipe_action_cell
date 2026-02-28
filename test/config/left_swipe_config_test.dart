import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';
import 'package:swipe_action_cell/src/core/swipe_zone.dart';

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

  group('LeftSwipeConfig zones', () {
    SwipeZone z(double t, {String? label}) => 
      SwipeZone(threshold: t, semanticLabel: label ?? 'Zone');

    test('valid 2-zone config constructs', () {
      final config = LeftSwipeConfig(
        mode: LeftSwipeMode.autoTrigger,
        zones: [z(0.4), z(0.8)],
      );
      expect(config.zones?.length, 2);
    });

    test('>4 zones assert fires', () {
      expect(
        () => LeftSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          zones: [z(0.1), z(0.2), z(0.3), z(0.4), z(0.5)],
        ),
        throwsA(isA<AssertionError>().having((e) => e.message, 'message', contains('at most 4'))));
    });

    test('1-entry list is valid', () {
      final config = LeftSwipeConfig(
        mode: LeftSwipeMode.autoTrigger,
        zones: [z(0.5)],
      );
      expect(config.zones?.length, 1);
    });

    test('copyWith updates zones and zoneTransitionStyle', () {
      final config = LeftSwipeConfig(mode: LeftSwipeMode.autoTrigger);
      final updated = config.copyWith(
        zones: [z(0.5)],
        zoneTransitionStyle: ZoneTransitionStyle.crossfade,
      );
      expect(updated.zones?.length, 1);
      expect(updated.zoneTransitionStyle, ZoneTransitionStyle.crossfade);
    });
  });
}

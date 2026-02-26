import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  const icon = Icon(Icons.delete);
  const bg = Color(0xFFE53935);
  const fg = Color(0xFFFFFFFF);
  void onTap() {}

  final sampleAction = SwipeAction(
    icon: icon,
    backgroundColor: bg,
    foregroundColor: fg,
    onTap: onTap,
  );

  group('IntentionalSwipeConfig', () {
    test('can be created with mode only', () {
      const config = IntentionalSwipeConfig(mode: LeftSwipeMode.autoTrigger);
      expect(config.mode, LeftSwipeMode.autoTrigger);
      expect(config.actions, isEmpty);
      expect(config.actionPanelWidth, isNull);
      expect(config.postActionBehavior, PostActionBehavior.snapBack);
      expect(config.requireConfirmation, false);
      expect(config.enableHaptic, false);
      expect(config.onActionTriggered, isNull);
      expect(config.onSwipeCancelled, isNull);
      expect(config.onPanelOpened, isNull);
      expect(config.onPanelClosed, isNull);
    });

    test('postActionBehavior defaults to snapBack', () {
      const config = IntentionalSwipeConfig(mode: LeftSwipeMode.autoTrigger);
      expect(config.postActionBehavior, PostActionBehavior.snapBack);
    });

    test('requireConfirmation defaults to false', () {
      const config = IntentionalSwipeConfig(mode: LeftSwipeMode.autoTrigger);
      expect(config.requireConfirmation, false);
    });

    test('enableHaptic defaults to false', () {
      const config = IntentionalSwipeConfig(mode: LeftSwipeMode.autoTrigger);
      expect(config.enableHaptic, false);
    });

    test('actionPanelWidth > 0 assert passes', () {
      expect(
        () => IntentionalSwipeConfig(
          mode: LeftSwipeMode.reveal,
          actionPanelWidth: 100.0,
        ),
        returnsNormally,
      );
    });

    test('actionPanelWidth <= 0 asserts', () {
      expect(
        () => IntentionalSwipeConfig(
          mode: LeftSwipeMode.reveal,
          actionPanelWidth: 0.0,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => IntentionalSwipeConfig(
          mode: LeftSwipeMode.reveal,
          actionPanelWidth: -10.0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('reveal mode with actions', () {
      final config = IntentionalSwipeConfig(
        mode: LeftSwipeMode.reveal,
        actions: [sampleAction],
      );
      expect(config.mode, LeftSwipeMode.reveal);
      expect(config.actions, [sampleAction]);
    });

    test('equality — two identical configs are equal', () {
      const a = IntentionalSwipeConfig(
        mode: LeftSwipeMode.autoTrigger,
        postActionBehavior: PostActionBehavior.animateOut,
        requireConfirmation: true,
        enableHaptic: true,
      );
      const b = IntentionalSwipeConfig(
        mode: LeftSwipeMode.autoTrigger,
        postActionBehavior: PostActionBehavior.animateOut,
        requireConfirmation: true,
        enableHaptic: true,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('equality — different mode not equal', () {
      const a = IntentionalSwipeConfig(mode: LeftSwipeMode.autoTrigger);
      const b = IntentionalSwipeConfig(mode: LeftSwipeMode.reveal);
      expect(a, isNot(equals(b)));
    });

    test('copyWith replaces mode', () {
      const original = IntentionalSwipeConfig(mode: LeftSwipeMode.autoTrigger);
      final copy = original.copyWith(mode: LeftSwipeMode.reveal);
      expect(copy.mode, LeftSwipeMode.reveal);
      expect(copy.postActionBehavior, PostActionBehavior.snapBack);
    });

    test('copyWith replaces postActionBehavior', () {
      const original = IntentionalSwipeConfig(mode: LeftSwipeMode.autoTrigger);
      final copy =
          original.copyWith(postActionBehavior: PostActionBehavior.stay);
      expect(copy.postActionBehavior, PostActionBehavior.stay);
    });

    test('copyWith replaces enableHaptic', () {
      const original = IntentionalSwipeConfig(mode: LeftSwipeMode.autoTrigger);
      final copy = original.copyWith(enableHaptic: true);
      expect(copy.enableHaptic, true);
    });

    test('copyWith replaces actions', () {
      const original =
          IntentionalSwipeConfig(mode: LeftSwipeMode.reveal, actions: []);
      final copy = original.copyWith(actions: [sampleAction]);
      expect(copy.actions, [sampleAction]);
    });

    test('copyWith with no args returns equivalent object', () {
      const original = IntentionalSwipeConfig(
        mode: LeftSwipeMode.autoTrigger,
        postActionBehavior: PostActionBehavior.stay,
        requireConfirmation: true,
        enableHaptic: true,
      );
      final copy = original.copyWith();
      expect(copy, equals(original));
    });
  });
}

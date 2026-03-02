import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/src/actions/full_swipe/full_swipe_config.dart';
import 'package:swipe_action_cell/src/actions/intentional/post_action_behavior.dart';
import 'package:swipe_action_cell/src/actions/intentional/swipe_action.dart';

void main() {
  group('FullSwipeConfig', () {
    final testAction = SwipeAction(
      icon: const Icon(Icons.delete),
      label: 'Delete',
      onTap: () {},
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
    );

    test('default values', () {
      final config = FullSwipeConfig(action: testAction);
      expect(config.enabled, isFalse);
      expect(config.threshold, 0.75);
      expect(config.action, testAction);
      expect(config.postActionBehavior, PostActionBehavior.animateOut);
      expect(config.expandAnimation, isTrue);
      expect(config.enableHaptic, isTrue);
      expect(config.fullSwipeProgressBehavior, isNull);
    });

    test('copyWith', () {
      final config = FullSwipeConfig(action: testAction);
      final updated = config.copyWith(
        enabled: true,
        threshold: 0.8,
        expandAnimation: false,
      );
      expect(updated.enabled, isTrue);
      expect(updated.threshold, 0.8);
      expect(updated.expandAnimation, isFalse);
      expect(updated.action, testAction);
    });

    test('equality', () {
      final c1 = FullSwipeConfig(action: testAction, threshold: 0.5);
      final c2 = FullSwipeConfig(action: testAction, threshold: 0.5);
      final c3 = FullSwipeConfig(action: testAction, threshold: 0.6);

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1, isNot(equals(c3)));
    });

    test('assertions', () {
      expect(() => FullSwipeConfig(action: testAction, threshold: 0.0), throwsAssertionError);
      expect(() => FullSwipeConfig(action: testAction, threshold: 1.1), throwsAssertionError);
    });
  });
}

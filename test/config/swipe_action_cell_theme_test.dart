import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('SwipeActionCellTheme (T025 — unit)', () {
    test('const constructable with no args', () {
      const theme = SwipeActionCellTheme();
      expect(theme.rightSwipeConfig, isNull);
      expect(theme.leftSwipeConfig, isNull);
      expect(theme.gestureConfig, isNull);
      expect(theme.animationConfig, isNull);
      expect(theme.visualConfig, isNull);
    });

    test('lerp(other, 0.0) returns this', () {
      const a = SwipeActionCellTheme(
        gestureConfig: SwipeGestureConfig(deadZone: 10.0),
      );
      const b = SwipeActionCellTheme(
        gestureConfig: SwipeGestureConfig(deadZone: 99.0),
      );
      expect(a.lerp(b, 0.0), equals(a));
    });

    test('lerp(other, 0.5) returns this (hard-cutover)', () {
      const a = SwipeActionCellTheme(
        gestureConfig: SwipeGestureConfig(deadZone: 10.0),
      );
      const b = SwipeActionCellTheme(
        gestureConfig: SwipeGestureConfig(deadZone: 99.0),
      );
      expect(a.lerp(b, 0.5), equals(a));
    });

    test('lerp(other, 1.0) returns other', () {
      const a = SwipeActionCellTheme(
        gestureConfig: SwipeGestureConfig(deadZone: 10.0),
      );
      const b = SwipeActionCellTheme(
        gestureConfig: SwipeGestureConfig(deadZone: 99.0),
      );
      expect(a.lerp(b, 1.0), equals(b));
    });

    test('lerp(null, 1.0) returns this', () {
      const a = SwipeActionCellTheme(
        gestureConfig: SwipeGestureConfig(deadZone: 10.0),
      );
      expect(a.lerp(null, 1.0), equals(a));
    });

    test('copyWith no-arg returns equal instance', () {
      const theme = SwipeActionCellTheme(
        gestureConfig: SwipeGestureConfig(deadZone: 20.0),
      );
      expect(theme.copyWith(), equals(theme));
    });

    test('copyWith with arg replaces only that field', () {
      const theme = SwipeActionCellTheme(
        gestureConfig: SwipeGestureConfig(deadZone: 20.0),
        animationConfig: SwipeAnimationConfig(activationThreshold: 0.3),
      );
      final updated = theme.copyWith(
        gestureConfig: const SwipeGestureConfig(deadZone: 5.0),
      );
      expect(updated.gestureConfig?.deadZone, 5.0);
      expect(updated.animationConfig?.activationThreshold, 0.3);
    });

    testWidgets('maybeOf(context) returns null when no theme installed',
        (tester) async {
      SwipeActionCellTheme? found;
      await tester.pumpWidget(MaterialApp(
        home: Builder(builder: (context) {
          found = SwipeActionCellTheme.maybeOf(context);
          return const SizedBox();
        }),
      ));
      expect(found, isNull);
    });
  });
}

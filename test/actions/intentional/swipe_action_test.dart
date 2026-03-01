import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('SwipeAction', () {
    const icon = Icon(Icons.delete);
    const bg = Color(0xFFE53935);
    const fg = Color(0xFFFFFFFF);
    void onTap() {}

    test('can be created with required fields', () {
      final action = SwipeAction(
        icon: icon,
        backgroundColor: bg,
        foregroundColor: fg,
        onTap: onTap,
      );
      expect(action.icon, icon);
      expect(action.backgroundColor, bg);
      expect(action.foregroundColor, fg);
      expect(action.label, isNull);
      expect(action.isDestructive, false);
      expect(action.flex, 1);
    });

    test('label defaults to null', () {
      final action = SwipeAction(
        icon: icon,
        backgroundColor: bg,
        foregroundColor: fg,
        onTap: onTap,
      );
      expect(action.label, isNull);
    });

    test('can set optional label', () {
      final action = SwipeAction(
        icon: icon,
        label: 'Delete',
        backgroundColor: bg,
        foregroundColor: fg,
        onTap: onTap,
      );
      expect(action.label, 'Delete');
    });

    test('isDestructive defaults to false', () {
      final action = SwipeAction(
        icon: icon,
        backgroundColor: bg,
        foregroundColor: fg,
        onTap: onTap,
      );
      expect(action.isDestructive, false);
    });

    test('flex defaults to 1', () {
      final action = SwipeAction(
        icon: icon,
        backgroundColor: bg,
        foregroundColor: fg,
        onTap: onTap,
      );
      expect(action.flex, 1);
    });

    test('flex 0 is valid', () {
      final action = SwipeAction(
        icon: icon,
        backgroundColor: bg,
        foregroundColor: fg,
        onTap: onTap,
        flex: 0,
      );
      expect(action.flex, 0);
    });

    test('flex < 0 asserts', () {
      expect(
        () => SwipeAction(
          icon: icon,
          backgroundColor: bg,
          foregroundColor: fg,
          onTap: onTap,
          flex: -1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('equality — two identical SwipeActions are equal', () {
      final a = SwipeAction(
        icon: icon,
        label: 'Delete',
        backgroundColor: bg,
        foregroundColor: fg,
        onTap: onTap,
        isDestructive: true,
        flex: 2,
      );
      final b = SwipeAction(
        icon: icon,
        label: 'Delete',
        backgroundColor: bg,
        foregroundColor: fg,
        onTap: onTap,
        isDestructive: true,
        flex: 2,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('equality — different label not equal', () {
      final a = SwipeAction(
        icon: icon,
        label: 'Delete',
        backgroundColor: bg,
        foregroundColor: fg,
        onTap: onTap,
      );
      final b = SwipeAction(
        icon: icon,
        label: 'Archive',
        backgroundColor: bg,
        foregroundColor: fg,
        onTap: onTap,
      );
      expect(a, isNot(equals(b)));
    });

    test('copyWith replaces label', () {
      final original = SwipeAction(
        icon: icon,
        label: 'Delete',
        backgroundColor: bg,
        foregroundColor: fg,
        onTap: onTap,
      );
      final copy = original.copyWith(label: 'Archive');
      expect(copy.label, 'Archive');
      expect(copy.backgroundColor, bg);
      expect(copy.foregroundColor, fg);
    });

    test('copyWith replaces flex', () {
      final original = SwipeAction(
        icon: icon,
        backgroundColor: bg,
        foregroundColor: fg,
        onTap: onTap,
      );
      final copy = original.copyWith(flex: 3);
      expect(copy.flex, 3);
    });

    test('copyWith replaces isDestructive', () {
      final original = SwipeAction(
        icon: icon,
        backgroundColor: bg,
        foregroundColor: fg,
        onTap: onTap,
      );
      final copy = original.copyWith(isDestructive: true);
      expect(copy.isDestructive, true);
    });

    test('copyWith with no args returns equivalent object', () {
      final original = SwipeAction(
        icon: icon,
        label: 'Delete',
        backgroundColor: bg,
        foregroundColor: fg,
        onTap: onTap,
        isDestructive: true,
        flex: 2,
      );
      final copy = original.copyWith();
      expect(copy, equals(original));
    });
  });
}

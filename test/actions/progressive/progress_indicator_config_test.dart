import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('ProgressIndicatorConfig', () {
    test('default values', () {
      const config = ProgressIndicatorConfig();
      expect(config.color, equals(const Color(0xFF4CAF50)));
      expect(config.width, equals(4.0));
      expect(config.backgroundColor, isNull);
      expect(config.borderRadius, isNull);
    });

    test('assert width > 0', () {
      expect(() => ProgressIndicatorConfig(width: 0), throwsAssertionError);
      expect(() => ProgressIndicatorConfig(width: -1), throwsAssertionError);
    });

    test('copyWith', () {
      const config = ProgressIndicatorConfig();
      final updated = config.copyWith(
        color: const Color(0xFF000000),
        width: 10.0,
        backgroundColor: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(4.0),
      );
      expect(updated.color, equals(const Color(0xFF000000)));
      expect(updated.width, equals(10.0));
      expect(updated.backgroundColor, equals(const Color(0xFFFFFFFF)));
      expect(updated.borderRadius, equals(BorderRadius.circular(4.0)));
    });

    test('equality and hashCode', () {
      const c1 = ProgressIndicatorConfig(width: 5.0);
      const c2 = ProgressIndicatorConfig(width: 5.0);
      const c3 = ProgressIndicatorConfig(width: 6.0);

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1, isNot(equals(c3)));
    });
  });
}

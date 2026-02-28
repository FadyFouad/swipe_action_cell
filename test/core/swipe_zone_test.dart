import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/src/core/swipe_zone.dart';

void main() {
  group('SwipeZone', () {
    test('threshold must be between 0.0 and 1.0 exclusive', () {
      expect(() => SwipeZone(threshold: 0.0, semanticLabel: 'A'),
          throwsAssertionError);
      expect(() => SwipeZone(threshold: 1.0, semanticLabel: 'A'),
          throwsAssertionError);
      expect(() => SwipeZone(threshold: -0.1, semanticLabel: 'A'),
          throwsAssertionError);
      expect(() => SwipeZone(threshold: 1.1, semanticLabel: 'A'),
          throwsAssertionError);
      expect(
          const SwipeZone(threshold: 0.5, semanticLabel: 'A').threshold, 0.5);
    });

    test('semanticLabel must not be empty', () {
      expect(() => SwipeZone(threshold: 0.5, semanticLabel: ''),
          throwsAssertionError);
    });

    test('supports value equality', () {
      const z1 = SwipeZone(threshold: 0.5, semanticLabel: 'Archive');
      const z2 = SwipeZone(threshold: 0.5, semanticLabel: 'Archive');
      const z3 = SwipeZone(threshold: 0.6, semanticLabel: 'Archive');

      expect(z1, equals(z2));
      expect(z1.hashCode, equals(z2.hashCode));
      expect(z1, isNot(equals(z3)));
    });

    test('copyWith updates specified fields', () {
      const z1 = SwipeZone(threshold: 0.5, semanticLabel: 'Archive');
      final z2 = z1.copyWith(threshold: 0.8, semanticLabel: 'Delete');

      expect(z2.threshold, 0.8);
      expect(z2.semanticLabel, 'Delete');
    });
  });

  group('Enums', () {
    test('ZoneTransitionStyle has exactly 3 values', () {
      expect(ZoneTransitionStyle.values.length, 3);
      expect(
          ZoneTransitionStyle.values,
          containsAll([
            ZoneTransitionStyle.crossfade,
            ZoneTransitionStyle.slide,
            ZoneTransitionStyle.instant,
          ]));
    });

    test('SwipeZoneHaptic has exactly 3 values', () {
      expect(SwipeZoneHaptic.values.length, 3);
      expect(
          SwipeZoneHaptic.values,
          containsAll([
            SwipeZoneHaptic.light,
            SwipeZoneHaptic.medium,
            SwipeZoneHaptic.heavy,
          ]));
    });
  });
}

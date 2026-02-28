import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/src/core/swipe_zone.dart';
import 'package:swipe_action_cell/src/zones/zone_resolver.dart';

void main() {
  SwipeZone z(double t, {String? label, double? step}) => 
    SwipeZone(threshold: t, semanticLabel: label ?? 'Zone', stepValue: step);

  group('resolveActiveZoneIndex', () {
    test('returns -1 for empty list', () {
      expect(resolveActiveZoneIndex([], 0.5), -1);
    });

    test('returns -1 when ratio below all thresholds', () {
      expect(resolveActiveZoneIndex([z(0.3)], 0.2), -1);
    });

    test('returns index when ratio equals threshold', () {
      expect(resolveActiveZoneIndex([z(0.3)], 0.3), 0);
    });

    test('returns index when ratio between thresholds', () {
      expect(resolveActiveZoneIndex([z(0.3), z(0.6)], 0.4), 0);
    });

    test('returns highest index when ratio exceeds multiple thresholds', () {
      expect(resolveActiveZoneIndex([z(0.3), z(0.6), z(0.9)], 0.7), 1);
      expect(resolveActiveZoneIndex([z(0.3), z(0.6), z(0.9)], 0.95), 2);
    });
  });

  group('resolveActiveZone', () {
    test('returns null when no zone index found', () {
      expect(resolveActiveZone([z(0.3)], 0.2), isNull);
    });

    test('returns correct zone when index found', () {
      final zones = [z(0.3, label: 'A'), z(0.6, label: 'B')];
      expect(resolveActiveZone(zones, 0.45)?.semanticLabel, 'A');
      expect(resolveActiveZone(zones, 0.7)?.semanticLabel, 'B');
    });
  });

  group('assertZonesValid', () {
    test('throws on more than 4 zones', () {
      final zones = [z(0.1), z(0.2), z(0.3), z(0.4), z(0.5)];
      expect(() => assertZonesValid(zones), 
             throwsA(isA<AssertionError>().having((e) => e.message, 'message', contains('at most 4'))));
    });

    test('throws on duplicate thresholds', () {
      final zones = [z(0.3), z(0.3)];
      expect(() => assertZonesValid(zones), 
             throwsA(isA<AssertionError>().having((e) => e.message, 'message', contains('ascending'))));
    });

    test('throws on descending thresholds', () {
      final zones = [z(0.6), z(0.3)];
      expect(() => assertZonesValid(zones), 
             throwsA(isA<AssertionError>().having((e) => e.message, 'message', contains('ascending'))));
    });

    test('throws on progressive zones with missing stepValue', () {
      final zones = [z(0.3, step: 1.0), z(0.6, step: null)];
      expect(() => assertZonesValid(zones, progressive: true), 
             throwsA(isA<AssertionError>().having((e) => e.message, 'message', contains('stepValue'))));
    });

    test('passes on valid configurations', () {
      assertZonesValid([z(0.3), z(0.6)]);
      assertZonesValid([z(0.3, step: 1.0), z(0.6, step: 5.0)], progressive: true);
    });
  });
}

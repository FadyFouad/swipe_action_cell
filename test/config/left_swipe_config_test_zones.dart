
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

    test('descending thresholds assert fires', () {
      expect(
        () => LeftSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          zones: [z(0.8), z(0.4)],
        ),
        throwsA(isA<AssertionError>().having((e) => e.message, 'message', contains('ascending'))));
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

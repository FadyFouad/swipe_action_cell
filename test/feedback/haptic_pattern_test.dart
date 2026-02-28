import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/src/feedback/swipe_feedback_config.dart';

void main() {
  group('HapticStep', () {
    test('supports value equality', () {
      const s1 =
          HapticStep(type: HapticType.lightImpact, delayBeforeNextMs: 50);
      const s2 =
          HapticStep(type: HapticType.lightImpact, delayBeforeNextMs: 50);
      const s3 = HapticStep(type: HapticType.mediumImpact);

      expect(s1, equals(s2));
      expect(s1.hashCode, equals(s2.hashCode));
      expect(s1, isNot(equals(s3)));
    });
  });

  group('HapticPattern', () {
    test('supports value equality', () {
      const p1 = HapticPattern([HapticStep(type: HapticType.lightImpact)]);
      const p2 = HapticPattern([HapticStep(type: HapticType.lightImpact)]);
      const p3 = HapticPattern.medium;

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(p3)));
    });

    test('named factories work', () {
      expect(HapticPattern.light.steps.first.type, HapticType.lightImpact);
      expect(HapticPattern.medium.steps.first.type, HapticType.mediumImpact);
      expect(HapticPattern.heavy.steps.first.type, HapticType.heavyImpact);
      expect(HapticPattern.tick.steps.first.type, HapticType.selectionTick);
      expect(HapticPattern.success.steps.first.type,
          HapticType.successNotification);
      expect(
          HapticPattern.error.steps.first.type, HapticType.errorNotification);
      expect(HapticPattern.silent.steps, isEmpty);
    });
  });
}

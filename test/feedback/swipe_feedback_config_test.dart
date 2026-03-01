import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/src/feedback/swipe_feedback_config.dart';

void main() {
  group('SwipeFeedbackConfig', () {
    test('const construction with defaults', () {
      const config = SwipeFeedbackConfig();
      expect(config.enableHaptic, isTrue);
      expect(config.enableAudio, isFalse);
      expect(config.hapticOverrides, isNull);
      expect(config.onShouldPlaySound, isNull);
    });

    test('supports value equality', () {
      const c1 = SwipeFeedbackConfig(enableHaptic: false);
      const c2 = SwipeFeedbackConfig(enableHaptic: false);
      const c3 = SwipeFeedbackConfig(enableAudio: true);

      expect(c1, equals(c2));
      expect(c1.hashCode, equals(c2.hashCode));
      expect(c1, isNot(equals(c3)));
    });

    test('copyWith works', () {
      const config = SwipeFeedbackConfig();
      final updated = config.copyWith(enableAudio: true);
      expect(updated.enableAudio, isTrue);
      expect(updated.enableHaptic, isTrue);
    });
  });
}

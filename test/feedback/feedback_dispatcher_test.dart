import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/src/feedback/feedback_dispatcher.dart';
import 'package:swipe_action_cell/src/feedback/swipe_feedback_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> hapticCalls = [];

  setUp(() {
    hapticCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform,
            (MethodCall methodCall) async {
      if (methodCall.method == 'HapticFeedback.vibrate') {
        hapticCalls.add(methodCall);
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  group('FeedbackDispatcher Basic Dispatch', () {
    test('fires light impact for thresholdCrossed by default', () {
      final dispatcher = FeedbackDispatcher.resolve(
        cellConfig: const SwipeFeedbackConfig(),
      );
      dispatcher.fire(SwipeFeedbackEvent.thresholdCrossed);
      expect(hapticCalls.length, 1);
      expect(hapticCalls.first.arguments, 'HapticFeedbackType.lightImpact');
    });
  });

  group('FeedbackDispatcher Audio Hooks', () {
    test('invokes onShouldPlaySound when enableAudio is true', () {
      SwipeSoundEvent? capturedEvent;
      final dispatcher = FeedbackDispatcher.resolve(
        cellConfig: SwipeFeedbackConfig(
          enableAudio: true,
          onShouldPlaySound: (e) => capturedEvent = e,
        ),
      );

      dispatcher.fire(SwipeFeedbackEvent.thresholdCrossed);
      expect(capturedEvent, SwipeSoundEvent.thresholdCrossed);
    });

    test('does not invoke audio when enableAudio is false', () {
      bool invoked = false;
      final dispatcher = FeedbackDispatcher.resolve(
        cellConfig: SwipeFeedbackConfig(
          enableAudio: false,
          onShouldPlaySound: (e) => invoked = true,
        ),
      );

      dispatcher.fire(SwipeFeedbackEvent.thresholdCrossed);
      expect(invoked, isFalse);
    });

    test('silently discards exceptions from audio hook', () {
      final dispatcher = FeedbackDispatcher.resolve(
        cellConfig: SwipeFeedbackConfig(
          enableAudio: true,
          onShouldPlaySound: (e) => throw Exception('Audio Error'),
        ),
      );

      // Should not throw
      dispatcher.fire(SwipeFeedbackEvent.thresholdCrossed);
    });
  });
}

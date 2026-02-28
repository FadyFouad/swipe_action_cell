import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

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

  Widget buildCell({
    SwipeFeedbackConfig? feedbackConfig,
    bool legacyHaptic = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 400,
            child: SwipeActionCell(
              feedbackConfig: feedbackConfig,
              rightSwipeConfig: RightSwipeConfig(
                enableHaptic: legacyHaptic,
                onSwipeCompleted: (_) {},
              ),
              child: Container(
                  width: 400,
                  height: 100,
                  color: Colors.white,
                  child: const Text('cell')),
            ),
          ),
        ),
      ),
    );
  }

  group('US1: Unified Feedback Configuration', () {
    testWidgets(
        'SwipeFeedbackConfig(enableHaptic: true) fires haptic on threshold',
        (tester) async {
      await tester.pumpWidget(buildCell(
        feedbackConfig: const SwipeFeedbackConfig(enableHaptic: true),
      ));

      // Swipe right to 40%% (threshold is 0.3 by default)
      await tester.drag(find.text('cell'), const Offset(160, 0));
      await tester.pump();

      expect(
          hapticCalls.any(
              (call) => call.arguments == 'HapticFeedbackType.lightImpact'),
          isTrue);
    });

    testWidgets('SwipeFeedbackConfig(enableHaptic: false) silences haptic',
        (tester) async {
      await tester.pumpWidget(buildCell(
        feedbackConfig: const SwipeFeedbackConfig(enableHaptic: false),
      ));

      await tester.drag(find.text('cell'), const Offset(160, 0));
      await tester.pump();

      expect(hapticCalls, isEmpty);
    });
  });
}

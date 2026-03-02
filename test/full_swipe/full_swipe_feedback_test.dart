import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';
import 'package:swipe_action_cell/src/actions/full_swipe/full_swipe_config.dart';

void main() {
  group('Full-Swipe US4 Feedback', () {
    final List<MethodCall> hapticLog = <MethodCall>[];

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
        if (methodCall.method == 'HapticFeedback.vibrate') {
          hapticLog.add(methodCall);
        }
        return null;
      });
      hapticLog.clear();
    });

    testWidgets('fires haptic on threshold crossing', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell(
                feedbackConfig: const SwipeFeedbackConfig(enableHaptic: true),
                leftSwipeConfig: LeftSwipeConfig(
                  mode: LeftSwipeMode.reveal,
                  actions: [
                    SwipeAction(
                      icon: const Icon(Icons.delete),
                      label: 'Delete',
                      onTap: () {},
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    )
                  ],
                  fullSwipeConfig: FullSwipeConfig(
                    enabled: true,
                    threshold: 0.7,
                    action: SwipeAction(
                      icon: const Icon(Icons.delete),
                      label: 'Delete',
                      onTap: () {},
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                child: const SizedBox(height: 100, child: Text('Cell')),
              ),
            ),
          ),
        ),
      ));

      await tester.drag(find.text('Cell'), const Offset(-320, 0));
      await tester.pumpAndSettle();

      expect(hapticLog, isNotEmpty, reason: 'Some haptic should have fired');
    });
  });
}

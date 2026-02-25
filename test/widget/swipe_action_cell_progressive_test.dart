import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('SwipeActionCell Progressive', () {
    group('Basic Increment (US1)', () {
      testWidgets('single right swipe past threshold increments value (T010)',
          (tester) async {
        double? capturedNew;
        double? capturedOld;
        double? completedValue;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SwipeActionCell(
                animationConfig: const SwipeAnimationConfig(
                  maxTranslationRight: 100.0,
                ),
                rightSwipe: ProgressiveSwipeConfig(
                  stepValue: 1.0,
                  maxValue: 10.0,
                  onProgressChanged: (n, o) {
                    capturedNew = n;
                    capturedOld = o;
                  },
                  onSwipeCompleted: (v) {
                    completedValue = v;
                  },
                ),
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );

        final gesture = await tester
            .startGesture(tester.getCenter(find.byType(SwipeActionCell)));
        await gesture.moveBy(const Offset(50.0, 0.0));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(capturedNew, equals(1.0));
        expect(capturedOld, equals(0.0));
        expect(completedValue, equals(1.0));
      });

      testWidgets('below-threshold release produces no change (T011)',
          (tester) async {
        bool changed = false;
        bool cancelled = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SwipeActionCell(
                animationConfig: const SwipeAnimationConfig(
                  maxTranslationRight: 100.0,
                ),
                rightSwipe: ProgressiveSwipeConfig(
                  onProgressChanged: (_, __) => changed = true,
                  onSwipeCancelled: () => cancelled = true,
                ),
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );

        // Drag 20px (below threshold 0.4 * 100 = 40px)
        final gesture = await tester
            .startGesture(tester.getCenter(find.byType(SwipeActionCell)));
        await gesture.moveBy(const Offset(20.0, 0.0));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(changed, isFalse);
        expect(cancelled, isTrue);
      });

      testWidgets('multiple sequential swipes accumulate (T012)',
          (tester) async {
        final List<double> values = [];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SwipeActionCell(
                animationConfig: const SwipeAnimationConfig(
                  maxTranslationRight: 100.0,
                ),
                rightSwipe: ProgressiveSwipeConfig(
                  stepValue: 2.0,
                  onProgressChanged: (n, o) => values.add(n),
                ),
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );

        for (int i = 0; i < 3; i++) {
          final gesture = await tester
              .startGesture(tester.getCenter(find.byType(SwipeActionCell)));
          await gesture.moveBy(const Offset(50.0, 0.0));
          await tester.pump();
          await gesture.up();
          await tester.pumpAndSettle();
        }

        expect(values, equals([2.0, 4.0, 6.0]));
      });

      testWidgets('fling triggers increment (T013)', (tester) async {
        double? newValue;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SwipeActionCell(
                animationConfig: const SwipeAnimationConfig(
                  maxTranslationRight: 100.0,
                ),
                rightSwipe: ProgressiveSwipeConfig(
                  onSwipeCompleted: (v) => newValue = v,
                ),
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );

        final gesture = await tester
            .startGesture(tester.getCenter(find.byType(SwipeActionCell)));
        for (int i = 0; i < 5; i++) {
          await gesture.moveBy(const Offset(20.0, 0.0));
          await tester.pump(const Duration(milliseconds: 16));
        }
        await gesture.up();
        await tester.pumpAndSettle();

        expect(newValue, equals(1.0));
      });

      testWidgets('gesture during animation being discarded (T014)',
          (tester) async {
        int count = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SwipeActionCell(
                animationConfig: const SwipeAnimationConfig(
                  maxTranslationRight: 100.0,
                ),
                rightSwipe: ProgressiveSwipeConfig(
                  onSwipeCompleted: (_) => count++,
                ),
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );

        // Start first swipe
        final gesture1 = await tester
            .startGesture(tester.getCenter(find.byType(SwipeActionCell)));
        await gesture1.moveBy(const Offset(50.0, 0.0));
        await tester.pump();
        await gesture1.up();

        // Mid-animation, start second swipe
        await tester.pump(const Duration(milliseconds: 50));
        final gesture2 = await tester
            .startGesture(tester.getCenter(find.byType(SwipeActionCell)));
        await gesture2.moveBy(const Offset(50.0, 0.0));
        await tester.pump();
        await gesture2.up();

        await tester.pumpAndSettle();
        expect(count, equals(1));
      });
    });

    group('Overflow Behaviors (US2)', () {
      testWidgets('overflowBehavior: clamp stops at maxValue (T019)',
          (tester) async {
        double? currentVal;
        bool maxReached = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SwipeActionCell(
                animationConfig:
                    const SwipeAnimationConfig(maxTranslationRight: 100.0),
                rightSwipe: ProgressiveSwipeConfig(
                  initialValue: 8.0,
                  stepValue: 3.0,
                  maxValue: 10.0,
                  overflowBehavior: OverflowBehavior.clamp,
                  onProgressChanged: (n, o) => currentVal = n,
                  onMaxReached: () => maxReached = true,
                ),
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );

        // Swipe 1: 8.0 + 3.0 = 11.0 -> clamped to 10.0
        final gesture = await tester
            .startGesture(tester.getCenter(find.byType(SwipeActionCell)));
        await gesture.moveBy(const Offset(50.0, 0.0));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(currentVal, equals(10.0));
        expect(maxReached, isTrue);

        // Swipe 2: already at 10.0, should stay at 10.0 and fire onMaxReached again
        maxReached = false;
        final gesture2 = await tester
            .startGesture(tester.getCenter(find.byType(SwipeActionCell)));
        await gesture2.moveBy(const Offset(50.0, 0.0));
        await tester.pump();
        await gesture2.up();
        await tester.pumpAndSettle();

        expect(currentVal, equals(10.0));
        expect(maxReached, isTrue);
      });

      testWidgets('overflowBehavior: wrap resets to minValue (T020)',
          (tester) async {
        double? currentVal;
        bool maxReached = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SwipeActionCell(
                animationConfig:
                    const SwipeAnimationConfig(maxTranslationRight: 100.0),
                rightSwipe: ProgressiveSwipeConfig(
                  initialValue: 9.0,
                  stepValue: 2.0,
                  maxValue: 10.0,
                  minValue: 0.0,
                  overflowBehavior: OverflowBehavior.wrap,
                  onProgressChanged: (n, o) => currentVal = n,
                  onMaxReached: () => maxReached = true,
                ),
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );

        // Swipe: 9.0 + 2.0 = 11.0 -> wrap to 0.0
        final gesture = await tester
            .startGesture(tester.getCenter(find.byType(SwipeActionCell)));
        await gesture.moveBy(const Offset(50.0, 0.0));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(currentVal, equals(0.0));
        expect(maxReached, isTrue);
      });

      testWidgets('overflowBehavior: ignore allows exceeding maxValue (T021)',
          (tester) async {
        double? currentVal;
        bool maxReached = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SwipeActionCell(
                animationConfig:
                    const SwipeAnimationConfig(maxTranslationRight: 100.0),
                rightSwipe: ProgressiveSwipeConfig(
                  initialValue: 9.0,
                  stepValue: 2.0,
                  maxValue: 10.0,
                  overflowBehavior: OverflowBehavior.ignore,
                  onProgressChanged: (n, o) => currentVal = n,
                  onMaxReached: () => maxReached = true,
                ),
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );

        // Swipe: 9.0 + 2.0 = 11.0 -> 11.0 (ignore max)
        final gesture = await tester
            .startGesture(tester.getCenter(find.byType(SwipeActionCell)));
        await gesture.moveBy(const Offset(50.0, 0.0));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(currentVal, equals(11.0));
        expect(maxReached, isFalse);
      });

      testWidgets('dynamicStep overrides stepValue (T022)', (tester) async {
        double? currentVal;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SwipeActionCell(
                animationConfig:
                    const SwipeAnimationConfig(maxTranslationRight: 100.0),
                rightSwipe: ProgressiveSwipeConfig(
                  initialValue: 0.0,
                  stepValue: 1.0,
                  dynamicStep: (current) =>
                      current + 5.0, // 0+5=5, next is 5+10=15...
                  onProgressChanged: (n, o) => currentVal = n,
                ),
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );

        // Swipe 1: 0.0 + (0.0 + 5.0) = 5.0
        final gesture = await tester
            .startGesture(tester.getCenter(find.byType(SwipeActionCell)));
        await gesture.moveBy(const Offset(50.0, 0.0));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(currentVal, equals(5.0));

        // Swipe 2: 5.0 + (5.0 + 5.0) = 15.0
        final gesture2 = await tester
            .startGesture(tester.getCenter(find.byType(SwipeActionCell)));
        await gesture2.moveBy(const Offset(50.0, 0.0));
        await tester.pump();
        await gesture2.up();
        await tester.pumpAndSettle();

        expect(currentVal, equals(15.0));
      });
    });

    group('Controlled Mode (US4)', () {
      testWidgets('controlled mode does not self-update internal state (T027)',
          (tester) async {
        double currentVal = 5.0;
        double? reportedNew;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: SwipeActionCell(
                    animationConfig:
                        const SwipeAnimationConfig(maxTranslationRight: 100.0),
                    rightSwipe: ProgressiveSwipeConfig(
                      value: currentVal, // activating controlled mode
                      stepValue: 1.0,
                      onProgressChanged: (n, o) {
                        reportedNew = n;
                        // Developer chooses NOT to setState here
                      },
                    ),
                    child: const SizedBox(width: 100, height: 100),
                  ),
                );
              },
            ),
          ),
        );

        // Swipe
        final gesture = await tester
            .startGesture(tester.getCenter(find.byType(SwipeActionCell)));
        await gesture.moveBy(const Offset(50.0, 0.0));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(reportedNew, equals(6.0));

        // Internal state (ValueNotifier) should match widget.value (5.0)
        final state = tester.state(find.byType(SwipeActionCell)) as dynamic;
        expect(state.progressValueNotifier.value, equals(5.0));
      });

      testWidgets('controlled mode updates when widget.value changes (T028)',
          (tester) async {
        double currentVal = 5.0;

        await tester.pumpWidget(
          MaterialApp(
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  body: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () => setState(() => currentVal = 10.0),
                        child: const Text('Update'),
                      ),
                      SwipeActionCell(
                        rightSwipe: ProgressiveSwipeConfig(
                          value: currentVal,
                        ),
                        child: const SizedBox(width: 100, height: 100),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );

        final state = tester.state(find.byType(SwipeActionCell)) as dynamic;
        expect(state.progressValueNotifier.value, equals(5.0));

        await tester.tap(find.text('Update'));
        await tester.pump();

        expect(state.progressValueNotifier.value, equals(10.0));
      });
    });

    group('Haptic Feedback (US5)', () {
      testWidgets('light haptic fires once on threshold crossing (T030)',
          (tester) async {
        final List<String> calls = [];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (methodCall) async {
            if (methodCall.method == 'HapticFeedback.vibrate') {
              calls.add(methodCall.arguments as String);
            }
            return null;
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SwipeActionCell(
                animationConfig:
                    const SwipeAnimationConfig(maxTranslationRight: 100.0),
                rightSwipe: const ProgressiveSwipeConfig(
                  enableHaptic: true,
                ),
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );

        final gesture = await tester
            .startGesture(tester.getCenter(find.byType(SwipeActionCell)));

        // Drag 30px (below threshold 40)
        await gesture.moveBy(const Offset(30.0, 0.0));
        await tester.pump();
        expect(calls, isEmpty);

        // Drag to 50px (crosses threshold)
        await gesture.moveBy(const Offset(20.0, 0.0));
        await tester.pump();
        expect(calls, contains('HapticFeedbackType.lightImpact'));

        calls.clear();

        // Drag back and forth across threshold - should NOT fire again
        await gesture.moveBy(const Offset(-20.0, 0.0)); // 30px
        await tester.pump();
        await gesture.moveBy(const Offset(20.0, 0.0)); // 50px
        await tester.pump();
        expect(calls, isEmpty);

        await gesture.up();
        await tester.pumpAndSettle();
      });

      testWidgets('medium haptic fires on successful increment (T031)',
          (tester) async {
        final List<String> calls = [];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (methodCall) async {
            if (methodCall.method == 'HapticFeedback.vibrate') {
              calls.add(methodCall.arguments as String);
            }
            return null;
          },
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SwipeActionCell(
                animationConfig:
                    const SwipeAnimationConfig(maxTranslationRight: 100.0),
                rightSwipe: const ProgressiveSwipeConfig(
                  enableHaptic: true,
                ),
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );

        final gesture = await tester
            .startGesture(tester.getCenter(find.byType(SwipeActionCell)));
        await gesture.moveBy(const Offset(50.0, 0.0));
        await tester.pump();

        // Light haptic should have fired
        expect(calls, contains('HapticFeedbackType.lightImpact'));
        calls.clear();

        await gesture.up();
        await tester.pumpAndSettle();

        // Medium haptic should fire on increment
        expect(calls, contains('HapticFeedbackType.mediumImpact'));
      });
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';
import 'package:swipe_action_cell/src/core/swipe_zone.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<MethodCall> hapticCalls = [];

  void setupHaptics() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (MethodCall methodCall) async {
      if (methodCall.method == 'HapticFeedback.vibrate') {
        hapticCalls.add(methodCall);
      }
      return null;
    });
  }

  group('SwipeActionCell Zones (US1 & US2)', () {
    SwipeZone z(double t, {String? label, double? step, VoidCallback? onActivated, SwipeZoneHaptic? haptic}) => 
      SwipeZone(
        threshold: t, 
        semanticLabel: label ?? 'Zone', 
        stepValue: step, 
        onActivated: onActivated,
        hapticPattern: haptic,
      );

    testWidgets('intentional left swipe: fires only the highest crossed zone', (tester) async {
      int zone1Fired = 0;
      int zone2Fired = 0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell(
                key: const Key('cell1'),
                leftSwipeConfig: LeftSwipeConfig(
                  mode: LeftSwipeMode.autoTrigger,
                  zones: [
                    z(0.4, onActivated: () => zone1Fired++),
                    z(0.8, onActivated: () => zone2Fired++),
                  ],
                ),
                child: Container(width: 400, height: 100, color: Colors.white),
              ),
            ),
          ),
        ),
      ));

      // Swipe left to 50% (crosses zone 1)
      await tester.drag(find.byKey(const Key('cell1')), const Offset(-80, 0));
      await tester.pumpAndSettle();
      expect(zone1Fired, 1);
      expect(zone2Fired, 0);

      // Reset and swipe to 90% (crosses zone 1 and 2)
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell(
                key: const Key('cell2'),
                leftSwipeConfig: LeftSwipeConfig(
                  mode: LeftSwipeMode.autoTrigger,
                  zones: [
                    z(0.4, onActivated: () => zone1Fired++),
                    z(0.8, onActivated: () => zone2Fired++),
                  ],
                ),
                child: Container(width: 400, height: 100, color: Colors.white),
              ),
            ),
          ),
        ),
      ));
      await tester.drag(find.byKey(const Key('cell2')), const Offset(-130, 0));
      await tester.pumpAndSettle();
      expect(zone2Fired, 1);
    });

    testWidgets('progressive right swipe: uses correct stepValue per zone', (tester) async {
      double currentValue = 0.0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell(
                key: const Key('cell3'),
                rightSwipeConfig: RightSwipeConfig(
                  zones: [
                    z(0.3, step: 1.0),
                    z(0.6, step: 5.0),
                  ],
                  onSwipeCompleted: (v) => currentValue = v,
                ),
                child: Container(width: 400, height: 100, color: Colors.white),
              ),
            ),
          ),
        ),
      ));

      // Swipe right to 40% (zone 1)
      await tester.drag(find.byKey(const Key('cell3')), const Offset(80, 0));
      await tester.pumpAndSettle();
      expect(currentValue, 1.0);

      // Reset and swipe right to 70% (zone 2)
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell(
                key: const Key('cell4'),
                rightSwipeConfig: RightSwipeConfig(
                  zones: [
                    z(0.3, step: 1.0),
                    z(0.6, step: 5.0),
                  ],
                  onSwipeCompleted: (v) => currentValue = v,
                ),
                child: Container(width: 400, height: 100, color: Colors.white),
              ),
            ),
          ),
        ),
      ));
      await tester.drag(find.byKey(const Key('cell4')), const Offset(200, 0));
      await tester.pumpAndSettle();
      expect(currentValue, 5.0);
    });

    testWidgets('haptic fires on forward crossing exactly once per zone', (tester) async {
      setupHaptics();
      hapticCalls.clear();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell(
                key: const Key('cell5'),
                rightSwipeConfig: RightSwipeConfig(
                  zones: [
                    z(0.3, haptic: SwipeZoneHaptic.light, step: 1.0),
                    z(0.6, haptic: SwipeZoneHaptic.medium, step: 1.0),
                  ],
                ),
                child: Container(width: 400, height: 100, color: Colors.white),
              ),
            ),
          ),
        ),
      ));

      final gesture = await tester.startGesture(tester.getCenter(find.byKey(const Key('cell5'))));
      
      // Cross zone 1
      await gesture.moveBy(const Offset(80, 0)); // 35%
      await tester.pump();
      expect(hapticCalls.length, 1);
      expect(hapticCalls.last.arguments, 'HapticFeedbackType.lightImpact');

      // Cross zone 2
      await gesture.moveBy(const Offset(100, 0)); // 60%
      await tester.pump();
      expect(hapticCalls.length, 2);
      expect(hapticCalls.last.arguments, 'HapticFeedbackType.mediumImpact');

      // Retreat back to zone 1 (no new haptic)
      await gesture.moveBy(const Offset(-100, 0)); // 35%
      await tester.pump();
      expect(hapticCalls.length, 2);

      // Cross zone 2 again forward
      await gesture.moveBy(const Offset(100, 0)); // 60%
      await tester.pump();
      expect(hapticCalls.length, 3);
      
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('SwipeActionCell Regression (Backward Compatibility)', () {
    testWidgets('plain LeftSwipeConfig (no zones) still works', (tester) async {
      bool fired = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell(
                key: const Key('reg1'),
                leftSwipeConfig: LeftSwipeConfig(
                  mode: LeftSwipeMode.autoTrigger,
                  onActionTriggered: () => fired = true,
                ),
                child: Container(width: 400, height: 100, color: Colors.white),
              ),
            ),
          ),
        ),
      ));

      await tester.drag(find.byKey(const Key('reg1')), const Offset(-100, 0), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(fired, isTrue);
    });

    testWidgets('plain RightSwipeConfig (no zones) still works', (tester) async {
      double value = 0.0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell(
                key: const Key('reg2'),
                rightSwipeConfig: RightSwipeConfig(
                  stepValue: 10.0,
                  onSwipeCompleted: (v) => value = v,
                ),
                child: Container(width: 400, height: 100, color: Colors.white),
              ),
            ),
          ),
        ),
      ));

      await tester.drag(find.byKey(const Key('reg2')), const Offset(200, 0), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(value, 10.0);
    });
  });
}

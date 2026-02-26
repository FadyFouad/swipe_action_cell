import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('F3: Progressive Swipe (Right)', () {
    testWidgets('Swipe right past stepValue fires onSwipeCompleted',
        (tester) async {
      double? result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCell(
            rightSwipeConfig: RightSwipeConfig(
              stepValue: 25.0,
              maxValue: 100.0,
              onSwipeCompleted: (val) => result = val,
            ),
            child: const SizedBox(width: 400, height: 60, child: Text('cell')),
          ),
        ),
      ));

      // Drag right by 50 (two steps)
      final gesture = await tester.startGesture(const Offset(10, 30));
      await gesture.moveBy(const Offset(50, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(result, 25.0);
    });

    testWidgets('Swipe started callback fires', (tester) async {
      bool started = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCell(
            rightSwipeConfig: RightSwipeConfig(
              stepValue: 25.0,
              maxValue: 100.0,
              onSwipeStarted: () => started = true,
            ),
            child: const SizedBox(width: 400, height: 60, child: Text('cell')),
          ),
        ),
      ));

      final gesture = await tester.startGesture(const Offset(10, 30));
      await gesture.moveBy(const Offset(20, 0));
      expect(started, isTrue);
      await gesture.up();
    });

    testWidgets('initialValue is respected', (tester) async {
      double? current;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCell(
            rightSwipeConfig: RightSwipeConfig(
              stepValue: 1.0,
              minValue: 0.0,
              maxValue: 10.0,
              initialValue: 8.0,
              onSwipeCompleted: (v) => current = v,
            ),
            child: const SizedBox(width: 400, height: 60, child: Text('cell')),
          ),
        ),
      ));

      // Swipe one step
      final gesture = await tester.startGesture(const Offset(10, 30));
      await gesture.moveBy(const Offset(50, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(current, 9.0);
    });

    testWidgets('controlled value overrides internal state', (tester) async {
      double currentVal = 5.0;
      
      Widget build(double val) => MaterialApp(
            home: Scaffold(
              body: SwipeActionCell(
                rightSwipeConfig: RightSwipeConfig(
                  stepValue: 1.0,
                  minValue: 0.0,
                  maxValue: 10.0,
                  value: val,
                ),
                child: const SizedBox(width: 400, height: 60, child: Text('cell')),
              ),
            ),
          );

      await tester.pumpWidget(build(currentVal));
      
      // Update external state
      currentVal = 9.0;
      await tester.pumpWidget(build(currentVal));

      // Swipe one step
      double? result;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCell(
            rightSwipeConfig: RightSwipeConfig(
              stepValue: 1.0,
              minValue: 0.0,
              maxValue: 10.0,
              value: currentVal,
              onSwipeCompleted: (v) => result = val,
            ),
            child: const SizedBox(width: 400, height: 60, child: Text('cell')),
          ),
        ),
      ));

      final gesture = await tester.startGesture(const Offset(10, 30));
      await gesture.moveBy(const Offset(50, 0));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(result, 10.0);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('F3: Progressive Swipe (Right)', () {
    testWidgets('Swipe right past stepValue fires onSwipeCompleted',
        (tester) async {
      double result = -1.0;
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

      // Drag right by 200 to pass activation threshold
      await tester.drag(find.byType(SwipeActionCell), const Offset(200, 0));
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

      await tester.drag(find.byType(SwipeActionCell), const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(started, isTrue);
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

      await tester.drag(find.byType(SwipeActionCell), const Offset(200, 0));
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
                child:
                    const SizedBox(width: 400, height: 60, child: Text('cell')),
              ),
            ),
          );

      await tester.pumpWidget(build(currentVal));

      // Update external state
      currentVal = 9.0;
      await tester.pumpWidget(build(currentVal));

      // Swipe one step
      double result = -1.0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCell(
            rightSwipeConfig: RightSwipeConfig(
              stepValue: 1.0,
              minValue: 0.0,
              maxValue: 10.0,
              value: currentVal,
              onSwipeCompleted: (v) => result = v,
            ),
            child: const SizedBox(width: 400, height: 60, child: Text('cell')),
          ),
        ),
      ));

      await tester.drag(find.byType(SwipeActionCell), const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(result, 10.0);
    });
  });
}

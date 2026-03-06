import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';
import 'package:swipe_action_cell/src/actions/full_swipe/full_swipe_config.dart';

void main() {
  group('Full-Swipe US2 Progressive Increment', () {
    testWidgets('setToMax jumps progressive value to maxValue', (tester) async {
      double latestValue = 0.0;
      final action = SwipeAction(
        icon: const Icon(Icons.add),
        label: 'Add',
        onTap: () {},
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell(
                rightSwipeConfig: RightSwipeConfig(
                  maxValue: 100,
                  onProgressChanged: (val, prev) => latestValue = val,
                  onSwipeCompleted: (_) {},
                  fullSwipeConfig: FullSwipeConfig(
                    enabled: true,
                    threshold: 0.7,
                    action: action,
                    fullSwipeProgressBehavior: FullSwipeProgressBehavior.setToMax,
                  ),
                ),
                child: const SizedBox(height: 100, child: Text('Cell')),
              ),
            ),
          ),
        ),
      ));

      // Drag 80% (320 pixels)
      await tester.drag(find.text('Cell'), const Offset(320, 0));
      await tester.pumpAndSettle();

      expect(latestValue, 100.0, reason: 'Value should jump to maxValue (100)');
    });

    testWidgets('customAction fires onTap instead of jumping value', (tester) async {
      bool actionFired = false;
      double latestValue = 0.0;
      
      final action = SwipeAction(
        icon: const Icon(Icons.star),
        label: 'Star',
        onTap: () => actionFired = true,
        backgroundColor: Colors.amber,
        foregroundColor: Colors.white,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell(
                rightSwipeConfig: RightSwipeConfig(
                  maxValue: 100,
                  onProgressChanged: (val, prev) => latestValue = val,
                  onSwipeCompleted: (_) {},
                  fullSwipeConfig: FullSwipeConfig(
                    enabled: true,
                    threshold: 0.7,
                    action: action,
                    fullSwipeProgressBehavior: FullSwipeProgressBehavior.customAction,
                  ),
                ),
                child: const SizedBox(height: 100, child: Text('Cell')),
              ),
            ),
          ),
        ),
      ));

      // Drag 80%
      await tester.drag(find.text('Cell'), const Offset(320, 0));
      await tester.pumpAndSettle();

      expect(actionFired, isTrue, reason: 'Custom action onTap should fire');
      // In customAction mode, it might still have incremented slightly due to normal progressive logic
      // during drag, but it shouldn't be 100.
      expect(latestValue, isNot(100.0));
    });
  });
}

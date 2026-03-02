import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';
import 'package:swipe_action_cell/src/actions/full_swipe/full_swipe_config.dart';

void main() {
  group('Full-Swipe US1 Gesture Trigger', () {
    testWidgets('full swipe past threshold triggers action and callback', (tester) async {
      bool actionFired = false;
      bool callbackFired = false;

      final action = SwipeAction(
        icon: const Icon(Icons.delete),
        label: 'Delete',
        onTap: () => actionFired = true,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell(
                onFullSwipeTriggered: (dir, act) => callbackFired = true,
                leftSwipeConfig: LeftSwipeConfig(
                  mode: LeftSwipeMode.reveal,
                  actions: [action],
                  fullSwipeConfig: FullSwipeConfig(
                    enabled: true,
                    threshold: 0.7,
                    action: action,
                  ),
                ),
                child: const SizedBox(height: 100, child: Text('Cell')),
              ),
            ),
          ),
        ),
      ));

      // Drag 80% (320 pixels on 400 width)
      await tester.drag(find.text('Cell'), const Offset(-320, 0));
      await tester.pumpAndSettle();

      expect(actionFired, isTrue, reason: 'SwipeAction.onTap should fire');
      expect(callbackFired, isTrue, reason: 'onFullSwipeTriggered should fire');
    });

    testWidgets('dragging below threshold but above reveal threshold does NOT fire action', (tester) async {
      bool actionFired = false;

      final action = SwipeAction(
        icon: const Icon(Icons.delete),
        label: 'Delete',
        onTap: () => actionFired = true,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell(
                leftSwipeConfig: LeftSwipeConfig(
                  mode: LeftSwipeMode.reveal,
                  actions: [action],
                  fullSwipeConfig: FullSwipeConfig(
                    enabled: true,
                    threshold: 0.7,
                    action: action,
                  ),
                ),
                child: const SizedBox(height: 100, child: Text('Cell')),
              ),
            ),
          ),
        ),
      ));

      // Drag 50% (200 pixels on 400 width)
      await tester.drag(find.text('Cell'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(actionFired, isFalse, reason: 'Action should NOT fire below full-swipe threshold');
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';
import 'package:swipe_action_cell/src/actions/full_swipe/full_swipe_config.dart';

void main() {
  group('Full-Swipe REVEAL Mode Trigger', () {
    testWidgets('reveal mode release past threshold triggers first action', (tester) async {
      int actionFired = -1;

      final action1 = SwipeAction(
        icon: const Icon(Icons.delete),
        label: 'Delete',
        onTap: () => actionFired = 1,
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      );
      final action2 = SwipeAction(
        icon: const Icon(Icons.archive),
        label: 'Archive',
        onTap: () => actionFired = 2,
        backgroundColor: Colors.green,
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
                  actions: [action1, action2],
                  fullSwipeConfig: FullSwipeConfig(
                    enabled: true,
                    threshold: 0.7,
                    action: action1,
                  ),
                ),
                child: const SizedBox(height: 100, child: Text('Cell')),
              ),
            ),
          ),
        ),
      ));

      // Drag 80% (320px)
      await tester.drag(find.text('Cell'), const Offset(-320, 0));
      await tester.pumpAndSettle();

      expect(actionFired, 1, reason: 'First action should fire due to full-swipe');
    });

    testWidgets('reveal mode release below full-swipe threshold stays open', (tester) async {
      int actionFired = -1;

      final action1 = SwipeAction(
        icon: const Icon(Icons.delete),
        label: 'Delete',
        onTap: () => actionFired = 1,
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
                  actions: [action1],
                  fullSwipeConfig: FullSwipeConfig(
                    enabled: true,
                    threshold: 0.7,
                    action: action1,
                  ),
                ),
                child: const SizedBox(height: 100, child: Text('Cell')),
              ),
            ),
          ),
        ),
      ));

      // Drag 50% (200px) — above 0.4 activation but below 0.7 full-swipe
      await tester.drag(find.text('Cell'), const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(actionFired, -1, reason: 'Action should NOT fire below full-swipe threshold');
      expect(tester.state<SwipeActionCellState>(find.byType(SwipeActionCell)).currentSwipeState, SwipeState.revealed);
    });
  });
}

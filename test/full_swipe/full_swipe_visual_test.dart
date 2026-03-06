import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';
import 'package:swipe_action_cell/src/actions/full_swipe/full_swipe_config.dart';

void main() {
  group('Full-Swipe US3 Visual Progress', () {
    testWidgets('fullSwipeRatio is 0.5 at activationThreshold', (tester) async {
      double? capturedRatio;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell(
                onProgressChanged: (p) => capturedRatio = p.fullSwipeRatio,
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
                    threshold: 0.8,
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

      // activationThreshold is 0.4 by default. 40% of 400 = 160.
      await tester.drag(find.text('Cell'), const Offset(-160, 0));
      await tester.pump();
      expect(capturedRatio, 0.5);
    });

    testWidgets('fullSwipeRatio is 1.0 at fullSwipe threshold', (tester) async {
      double? capturedRatio;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell(
                onProgressChanged: (p) => capturedRatio = p.fullSwipeRatio,
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
                    threshold: 0.8,
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

      // 80% of 400 = 320.
      final gesture = await tester.startGesture(tester.getCenter(find.text('Cell')));
      await gesture.moveBy(const Offset(-320, 0));
      await tester.pump();
      expect(capturedRatio, 1.0);
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}

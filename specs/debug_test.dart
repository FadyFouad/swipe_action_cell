import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  testWidgets('debug stay right swipe', (tester) async {
    bool triggered = false;
    final states = <SwipeState>[];
    
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 60,
          child: SwipeActionCell(
            onStateChanged: (s) {
              print('State changed to: $s');
              states.add(s);
            },
            leftSwipeConfig: LeftSwipeConfig(
              mode: LeftSwipeMode.autoTrigger,
              postActionBehavior: PostActionBehavior.stay,
              onActionTriggered: () => triggered = true,
            ),
            child: const Text('cell'),
          ),
        ),
      ),
    ));

    print('--- SWIPING LEFT ---');
    final gesture = await tester.startGesture(const Offset(300, 30));
    await gesture.moveBy(const Offset(-260, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    
    print('After swipe left, states: $states');
    
    print('--- SWIPING RIGHT ---');
    final gesture2 = await tester.startGesture(const Offset(100, 30));
    await tester.pump();
    print('After pointer down');
    
    await gesture2.moveBy(const Offset(100, 0));
    await tester.pump();
    print('After moveBy 100');
    
    await gesture2.moveBy(const Offset(160, 0));
    await tester.pump();
    print('After moveBy 160');
    
    await gesture2.up();
    await tester.pumpAndSettle();
    print('After pointer up and settle, states: $states');
  });
}

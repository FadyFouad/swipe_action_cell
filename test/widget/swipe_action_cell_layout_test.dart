import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';
import 'package:swipe_action_cell/src/actions/intentional/swipe_action_panel.dart';

void main() {
  testWidgets('Swipe actions match child height when parent is taller', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 200,
              width: 400,
              child: SwipeActionCell(
                leftSwipeConfig: LeftSwipeConfig(
                  mode: LeftSwipeMode.reveal,
                  actions: [
                    SwipeAction(
                      icon: const Icon(Icons.delete),
                      onTap: () {},
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ],
                ),
                child: const SizedBox(
                  height: 100,
                  width: 400,
                  child: ColoredBox(color: Colors.blue),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Swipe to reveal
    await tester.drag(find.byType(SwipeActionCell), const Offset(-50, 0), warnIfMissed: false);
    await tester.pump();

    final panelFinder = find.byType(SwipeActionPanel);
    expect(panelFinder, findsOneWidget);

    final panelSize = tester.getSize(panelFinder);
    
    // Desired behavior: panelSize.height should be 100 (matching the child)
    // even though the parent (SizedBox) is 200.
    expect(panelSize.height, 100.0);
  });

  testWidgets('Swipe actions match total child height including internal padding', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SwipeActionCell(
            leftSwipeConfig: LeftSwipeConfig(
              mode: LeftSwipeMode.reveal,
              actions: [
                SwipeAction(
                  icon: const Icon(Icons.delete),
                  onTap: () {},
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ],
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: SizedBox(
                height: 60,
                width: 400,
                child: ColoredBox(color: Colors.blue),
              ),
            ),
          ),
        ),
      ),
    );

    // Swipe to reveal
    await tester.drag(find.byType(SwipeActionCell), const Offset(-50, 0), warnIfMissed: false);
    await tester.pump();

    final panelFinder = find.byType(SwipeActionPanel);
    expect(panelFinder, findsOneWidget);

    final panelSize = tester.getSize(panelFinder);
    
    // Total height should be 60 + 20 + 20 = 100
    expect(panelSize.height, 100.0);
  });
}

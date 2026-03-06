import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  testWidgets('Debug Layout', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 200,
              child: SwipeActionCell(
                leftSwipeConfig: LeftSwipeConfig(
                  mode: LeftSwipeMode.reveal,
                  actions: [
                    SwipeAction(
                      icon: const Icon(Icons.archive),
                      label: 'Archive',
                      onTap: () {},
                      backgroundColor: Colors.blue,
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

    await tester.drag(find.byType(SwipeActionCell), const Offset(-50, 0));
    await tester.pump();

    final panelFinder = find.byType(SwipeActionPanel);
    final panelSize = tester.getSize(panelFinder);
    expect(panelSize.height, 100.0);

    debugDumpApp();
  });
}

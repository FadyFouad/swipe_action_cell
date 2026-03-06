import os

def replace_in_file(file_path, old_text, new_text):
    with open(file_path, 'r') as f:
        content = f.read()
    if old_text not in content:
        print(f"ERROR: Could not find old_text in {file_path}")
        return False
    new_content = content.replace(old_text, new_text)
    with open(file_path, 'w') as f:
        f.write(new_content)
    print(f"SUCCESS: Replaced in {file_path}")
    return True

file_path = '../test/full_swipe/full_swipe_expand_visual_test.dart'

# Append more tests to the end of the group
old_end = """      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}"""

new_tests = """      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('T007: drag past threshold (ratio 1.0) then drag back (ratio 0.0) — all actions restore', (tester) async {
      final action1 = SwipeAction(label: 'A1', icon: const Icon(Icons.archive), backgroundColor: Colors.blue, foregroundColor: Colors.white, onTap: () {});
      final action2 = SwipeAction(label: 'A2', icon: const Icon(Icons.delete), backgroundColor: Colors.red, foregroundColor: Colors.white, onTap: () {});

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell(
                leftSwipeConfig: LeftSwipeConfig(
                  mode: LeftSwipeMode.reveal,
                  actions: [action1, action2],
                  actionPanelWidth: 200,
                  fullSwipeConfig: FullSwipeConfig(
                    enabled: true,
                    threshold: 0.8,
                    action: action2,
                    expandAnimation: true,
                  ),
                ),
                child: const SizedBox(height: 100, child: Text('Cell')),
              ),
            ),
          ),
        ),
      ));

      final gesture = await tester.startGesture(tester.getCenter(find.text('Cell')));
      // Drag to 1.0 ratio
      await gesture.moveBy(const Offset(-320, 0));
      await tester.pump();

      var panelSizedBoxes = find.descendant(
        of: find.byType(SwipeActionPanel),
        matching: find.byType(SizedBox),
      ).evaluate().where((e) => (e.widget as SizedBox).child is ClipRect).map((e) => e.widget as SizedBox).toList();
      expect(panelSizedBoxes[1].width, closeTo(320.0, 0.001));

      // Drag back to 0.0 ratio (activationThreshold 0.4 * 400 = 160)
      await gesture.moveBy(const Offset(160, 0));
      await tester.pump();

      panelSizedBoxes = find.descendant(
        of: find.byType(SwipeActionPanel),
        matching: find.byType(SizedBox),
      ).evaluate().where((e) => (e.widget as SizedBox).child is ClipRect).map((e) => e.widget as SizedBox).toList();
      
      // Panel width at 160 is 160. normalWidth = 80.
      expect(panelSizedBoxes[0].width, closeTo(80.0, 0.001));
      expect(panelSizedBoxes[1].width, closeTo(80.0, 0.001));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('T019: designated action at index 0 (first) works correctly', (tester) async {
      final action1 = SwipeAction(label: 'A1', icon: const Icon(Icons.archive), backgroundColor: Colors.blue, foregroundColor: Colors.white, onTap: () {});
      final action2 = SwipeAction(label: 'A2', icon: const Icon(Icons.delete), backgroundColor: Colors.red, foregroundColor: Colors.white, onTap: () {});

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell(
                leftSwipeConfig: LeftSwipeConfig(
                  mode: LeftSwipeMode.reveal,
                  actions: [action1, action2],
                  actionPanelWidth: 200,
                  fullSwipeConfig: FullSwipeConfig(
                    enabled: true,
                    threshold: 0.8,
                    action: action1, // First one
                    expandAnimation: true,
                  ),
                ),
                child: const SizedBox(height: 100, child: Text('Cell')),
              ),
            ),
          ),
        ),
      ));

      final gesture = await tester.startGesture(tester.getCenter(find.text('Cell')));
      await gesture.moveBy(const Offset(-240, 0)); // ratio 0.5
      await tester.pump();

      final panelSizedBoxes = find.descendant(
        of: find.byType(SwipeActionPanel),
        matching: find.byType(SizedBox),
      ).evaluate().where((e) => (e.widget as SizedBox).child is ClipRect).map((e) => e.widget as SizedBox).toList();

      // panelWidth 240. normal 120. ratio 0.5.
      // A1 (index 0) = 240 - 60 = 180.
      // A2 (index 1) = 120 * 0.5 = 60.
      expect(panelSizedBoxes[0].width, closeTo(180.0, 0.001));
      expect(panelSizedBoxes[1].width, closeTo(60.0, 0.001));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('T021: icon stays centered during expand', (tester) async {
      final action = SwipeAction(label: 'A1', icon: const Icon(Icons.archive, key: Key('icon')), backgroundColor: Colors.blue, foregroundColor: Colors.white, onTap: () {});

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell(
                leftSwipeConfig: LeftSwipeConfig(
                  mode: LeftSwipeMode.reveal,
                  actions: [action],
                  actionPanelWidth: 200,
                  fullSwipeConfig: FullSwipeConfig(
                    enabled: true,
                    threshold: 0.8,
                    action: action,
                    expandAnimation: true,
                  ),
                ),
                child: const SizedBox(height: 100, child: Text('Cell')),
              ),
            ),
          ),
        ),
      ));

      final gesture = await tester.startGesture(tester.getCenter(find.text('Cell')));
      await gesture.moveBy(const Offset(-300, 0)); 
      await tester.pump();

      // Check center of the action panel vs center of the icon
      final panelCenter = tester.getCenter(find.byType(SwipeActionPanel));
      final iconCenter = tester.getCenter(find.byKey(const Key('icon')));
      
      expect(panelCenter.dx, closeTo(iconCenter.dx, 0.001));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('T022: expandAnimation: false disables expand', (tester) async {
       final action1 = SwipeAction(label: 'A1', icon: const Icon(Icons.archive), backgroundColor: Colors.blue, foregroundColor: Colors.white, onTap: () {});
      final action2 = SwipeAction(label: 'A2', icon: const Icon(Icons.delete), backgroundColor: Colors.red, foregroundColor: Colors.white, onTap: () {});

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 400,
              child: SwipeActionCell(
                leftSwipeConfig: LeftSwipeConfig(
                  mode: LeftSwipeMode.reveal,
                  actions: [action1, action2],
                  actionPanelWidth: 200,
                  fullSwipeConfig: FullSwipeConfig(
                    enabled: true,
                    threshold: 0.8,
                    action: action2,
                    expandAnimation: false, // DISABLED
                  ),
                ),
                child: const SizedBox(height: 100, child: Text('Cell')),
              ),
            ),
          ),
        ),
      ));

      final gesture = await tester.startGesture(tester.getCenter(find.text('Cell')));
      await gesture.moveBy(const Offset(-320, 0)); // ratio 1.0
      await tester.pump();

      // Should use Expanded/Row logic (equal widths)
      final actionButtons = find.descendant(of: find.byType(SwipeActionPanel), matching: find.byType(GestureDetector));
      expect(actionButtons.evaluate().length, 2);
      
      final rect1 = tester.getRect(actionButtons.at(0));
      final rect2 = tester.getRect(actionButtons.at(1));
      
      expect(rect1.width, closeTo(rect2.width, 0.001));

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}"""

replace_in_file(file_path, old_end, new_tests)

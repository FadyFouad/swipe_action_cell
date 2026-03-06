import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';
import 'package:swipe_action_cell/src/actions/intentional/swipe_action_panel.dart';

void main() {
  group('Full-Swipe Expand Visuals', () {
    testWidgets('at fullSwipeRatio == 0.5 at activationThreshold',
        (tester) async {
      final action1 = SwipeAction(
        icon: const Icon(Icons.archive),
        label: 'Archive',
        onTap: () {},
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      );
      final action2 = SwipeAction(
        icon: const Icon(Icons.delete),
        label: 'Delete',
        onTap: () {},
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

      // Drag to 40% (160 pixels) - exactly at activationThreshold (default 0.4)
      // rawRatio = 0.4. progress = 0.4 / 0.8 = 0.5.
      // totalRevealedWidth = 160. normalWidth = 80.
      // Archive = 80 * 0.5 = 40.
      // Delete = 160 - 40 = 120.
      final gesture = await tester.startGesture(tester.getCenter(find.text('Cell')));
      await gesture.moveBy(const Offset(-160, 0));
      await tester.pump();

      final panelSizedBoxes = find.descendant(
        of: find.byType(SwipeActionPanel),
        matching: find.byType(SizedBox),
      ).evaluate().where((e) => (e.widget as SizedBox).child is ClipRect).map((e) => e.widget as SizedBox).toList();

      expect(panelSizedBoxes.length, 2);
      expect(panelSizedBoxes[0].width, closeTo(40.0, 0.001));
      expect(panelSizedBoxes[1].width, closeTo(120.0, 0.001));
      
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
        'at fullSwipeRatio == 0.75 at 240 pixels',
        (tester) async {
      final action1 = SwipeAction(
        icon: const Icon(Icons.archive),
        label: 'Archive',
        onTap: () {},
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      );
      final action2 = SwipeAction(
        icon: const Icon(Icons.delete),
        label: 'Delete',
        onTap: () {},
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

      // rawRatio = 240 / 400 = 0.6.
      // threshold = 0.8. progress = 0.6 / 0.8 = 0.75.
      // totalRevealedWidth = 240. normalWidth = 120.
      // Archive = 120 * (1 - 0.75) = 30.
      // Delete = 240 - 30 = 210.
      final gesture = await tester.startGesture(tester.getCenter(find.text('Cell')));
      await gesture.moveBy(const Offset(-240, 0));
      await tester.pump();

      final panelSizedBoxes = find.descendant(
        of: find.byType(SwipeActionPanel),
        matching: find.byType(SizedBox),
      ).evaluate().where((e) => (e.widget as SizedBox).child is ClipRect).map((e) => e.widget as SizedBox).toList();

      expect(panelSizedBoxes.length, 2);
      expect(panelSizedBoxes[0].width, closeTo(30.0, 0.001));
      expect(panelSizedBoxes[1].width, closeTo(210.0, 0.001));

      final opacityWidget = tester.widget<Opacity>(
          find.descendant(of: find.byType(SwipeActionPanel), matching: find.byType(Opacity)).first);
      expect(opacityWidget.opacity, closeTo(0.25, 0.001));
      
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('at fullSwipeRatio == 1.0 at 320 pixels',
        (tester) async {
      final action1 = SwipeAction(
        icon: const Icon(Icons.archive),
        label: 'Archive',
        onTap: () {},
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      );
      final action2 = SwipeAction(
        icon: const Icon(Icons.delete),
        label: 'Delete',
        onTap: () {},
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

      // rawRatio = 320 / 400 = 0.8. progress = 1.0.
      final gesture = await tester.startGesture(tester.getCenter(find.text('Cell')));
      await gesture.moveBy(const Offset(-320, 0));
      await tester.pump();

      final panelSizedBoxes = find.descendant(
        of: find.byType(SwipeActionPanel),
        matching: find.byType(SizedBox),
      ).evaluate().where((e) => (e.widget as SizedBox).child is ClipRect).map((e) => e.widget as SizedBox).toList();

      expect(panelSizedBoxes.length, 2);
      expect(panelSizedBoxes[0].width, closeTo(0.0, 0.001));
      expect(panelSizedBoxes[1].width, closeTo(320.0, 0.001));
      
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('single action expand always fills width',
        (tester) async {
      final action = SwipeAction(
        icon: const Icon(Icons.delete),
        label: 'Delete',
        onTap: () {},
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
      await gesture.moveBy(const Offset(-240, 0));
      await tester.pump();

      final panelSizedBoxes = find.descendant(
        of: find.byType(SwipeActionPanel),
        matching: find.byType(SizedBox),
      ).evaluate().where((e) => (e.widget as SizedBox).child is ClipRect).map((e) => e.widget as SizedBox).toList();

      expect(panelSizedBoxes[0].width, closeTo(240.0, 0.001));
      
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('designated action in middle: actions on both sides shrink', (tester) async {
      final action1 = SwipeAction(label: 'A1', icon: const Icon(Icons.archive), backgroundColor: Colors.blue, foregroundColor: Colors.white, onTap: () {});
      final action2 = SwipeAction(label: 'A2', icon: const Icon(Icons.edit), backgroundColor: Colors.green, foregroundColor: Colors.white, onTap: () {});
      final action3 = SwipeAction(label: 'A3', icon: const Icon(Icons.delete), backgroundColor: Colors.red, foregroundColor: Colors.white, onTap: () {});

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: SwipeActionCell(
                leftSwipeConfig: LeftSwipeConfig(
                  mode: LeftSwipeMode.reveal,
                  actions: [action1, action2, action3],
                  actionPanelWidth: 300,
                  fullSwipeConfig: FullSwipeConfig(
                    enabled: true,
                    threshold: 0.8,
                    action: action2, // Middle one
                    expandAnimation: true,
                  ),
                ),
                child: const SizedBox(height: 100, child: Text('Cell')),
              ),
            ),
          ),
        ),
      ));

      // rawRatio = 180 / 300 = 0.6. threshold = 0.8. progress = 0.75.
      // totalRevealedWidth = 180. normalWidth = 60.
      // non-designated = 60 * (1 - 0.75) = 15.
      // designated = 180 - (15 + 15) = 150.
      final gesture = await tester.startGesture(tester.getCenter(find.text('Cell')));
      await gesture.moveBy(const Offset(-180, 0));
      await tester.pump();

      final panelSizedBoxes = find.descendant(
        of: find.byType(SwipeActionPanel),
        matching: find.byType(SizedBox),
      ).evaluate().where((e) => (e.widget as SizedBox).child is ClipRect).map((e) => e.widget as SizedBox).toList();

      expect(panelSizedBoxes.length, 3);
      expect(panelSizedBoxes[0].width, closeTo(15.0, 0.001));
      expect(panelSizedBoxes[1].width, closeTo(150.0, 0.001));
      expect(panelSizedBoxes[2].width, closeTo(15.0, 0.001));
      
      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('T007: drag back restores partially', (tester) async {
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
      // Drag past threshold (320 px)
      await gesture.moveBy(const Offset(-320, 0));
      await tester.pump();

      // Drag back to 160 pixels. ratio 0.4. progress 0.5.
      // normalWidth = 80. Archive = 40. Delete = 120.
      await gesture.moveBy(const Offset(160, 0));
      await tester.pump();

      final panelSizedBoxes = find.descendant(
        of: find.byType(SwipeActionPanel),
        matching: find.byType(SizedBox),
      ).evaluate().where((e) => (e.widget as SizedBox).child is ClipRect).map((e) => e.widget as SizedBox).toList();
      
      expect(panelSizedBoxes[0].width, closeTo(40.0, 0.001));
      expect(panelSizedBoxes[1].width, closeTo(120.0, 0.001));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('T019: designated action at index 0', (tester) async {
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

      // Drag to 240. rawRatio 0.6. progress 0.75.
      // totalRevealedWidth 240. normalWidth 120.
      // A2 (shrinking) = 120 * (1 - 0.75) = 30.
      // A1 (expanding) = 240 - 30 = 210.
      final gesture = await tester.startGesture(tester.getCenter(find.text('Cell')));
      await gesture.moveBy(const Offset(-240, 0));
      await tester.pump();

      final panelSizedBoxes = find.descendant(
        of: find.byType(SwipeActionPanel),
        matching: find.byType(SizedBox),
      ).evaluate().where((e) => (e.widget as SizedBox).child is ClipRect).map((e) => e.widget as SizedBox).toList();

      expect(panelSizedBoxes[0].width, closeTo(210.0, 0.001));
      expect(panelSizedBoxes[1].width, closeTo(30.0, 0.001));

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}

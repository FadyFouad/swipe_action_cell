import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';
import 'package:swipe_action_cell/src/undo/swipe_undo_config.dart';
import 'package:swipe_action_cell/src/undo/undo_data.dart';
import 'package:swipe_action_cell/src/undo/swipe_undo_overlay.dart';

void main() {
  group('SwipeActionCell Undo Integration', () {
    late SwipeController controller;

    setUp(() {
      controller = SwipeController();
    });

    tearDown(() {
      controller.dispose();
    });

    testWidgets('overlay appears after right-swipe increment', (tester) async {
      bool undoAvailable = false;
      UndoData? capturedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: SwipeActionCell(
                controller: controller,
                undoConfig: SwipeUndoConfig(
                  duration: const Duration(seconds: 5),
                  onUndoAvailable: (data) {
                    undoAvailable = true;
                    capturedData = data;
                  },
                ),
                rightSwipeConfig: const RightSwipeConfig(stepValue: 1.0),
                child: const SizedBox(
                    height: 100, width: 400, child: Text('Cell')),
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.text('Cell'), const Offset(300, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.isUndoPending, isTrue);
      expect(undoAvailable, isTrue);
      expect(capturedData?.oldValue, 0.0);
      expect(capturedData?.newValue, 1.0);
      expect(find.byType(SwipeUndoOverlay), findsOneWidget);
      await tester.pump(const Duration(seconds: 6)); // Expire timer
    });

    testWidgets('tapping Undo reverts progressive value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: SwipeActionCell(
                controller: controller,
                undoConfig: const SwipeUndoConfig(),
                rightSwipeConfig: const RightSwipeConfig(stepValue: 1.0),
                child: const SizedBox(
                    height: 100, width: 400, child: Text('Cell')),
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.text('Cell'), const Offset(300, 0));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(controller.currentProgress, 1.0);
      expect(controller.isUndoPending, isTrue);

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(controller.currentProgress, 0.0);
      expect(controller.isUndoPending, isFalse);
    });
  });
}

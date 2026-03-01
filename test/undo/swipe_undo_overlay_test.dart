import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/src/undo/swipe_undo_config.dart';
import 'package:swipe_action_cell/src/undo/swipe_undo_overlay.dart';

void main() {
  group('SwipeUndoOverlay', () {
    late AnimationController controller;

    setUpAll(() {
      // Stub for SwipeUndoOverlay because it is internal
    });

    testWidgets('renders undoButtonLabel text and actionLabel', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeUndoOverlay(
              config: const SwipeUndoOverlayConfig(
                undoButtonLabel: 'Revert',
                actionLabel: 'Item Deleted',
              ),
              progressAnimation: const AlwaysStoppedAnimation(1.0),
              onUndo: () {},
              semanticUndoLabel: 'Undo Action',
            ),
          ),
        ),
      );

      expect(find.text('Revert'), findsOneWidget);
      expect(find.text('Item Deleted'), findsOneWidget);
    });

    testWidgets('Undo button tap fires onUndo', (tester) async {
      bool undoFired = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeUndoOverlay(
              config: const SwipeUndoOverlayConfig(),
              progressAnimation: const AlwaysStoppedAnimation(1.0),
              onUndo: () => undoFired = true,
              semanticUndoLabel: 'Undo',
            ),
          ),
        ),
      );

      await tester.tap(find.text('Undo'));
      expect(undoFired, isTrue);
    });

    testWidgets('progress bar width is proportional to animation value', (tester) async {
      // This test might be tricky due to FractionallySizedBox
      // We'll just check if it renders for now.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeUndoOverlay(
              config: const SwipeUndoOverlayConfig(progressBarHeight: 4.0),
              progressAnimation: const AlwaysStoppedAnimation(0.5),
              onUndo: () {},
              semanticUndoLabel: 'Undo',
            ),
          ),
        ),
      );

      final fractionalSizedBox = tester.widget<FractionallySizedBox>(
        find.byType(FractionallySizedBox),
      );
      expect(fractionalSizedBox.widthFactor, 0.5);
    });

    testWidgets('Semantics are present', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeUndoOverlay(
              config: const SwipeUndoOverlayConfig(),
              progressAnimation: const AlwaysStoppedAnimation(1.0),
              onUndo: () {},
              semanticUndoLabel: 'Revert deleting item',
            ),
          ),
        ),
      );

      expect(
        tester.getSemantics(find.byType(TextButton)),
        matchesSemantics(
          label: 'Revert deleting item',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
          
        ),
      );
    });
  });
}

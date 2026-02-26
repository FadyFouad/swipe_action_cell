import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';
// ignore: implementation_imports
import 'package:swipe_action_cell/src/widget/swipe_action_cell.dart';

void main() {
  group('SwipeActionCellTheme (US5)', () {
    testWidgets('inherits gestureConfig from theme', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCellTheme(
            gestureConfig: const SwipeGestureConfig(deadZone: 55.0),
            child: SwipeActionCell(
              child: const Text('cell'),
            ),
          ),
        ),
      ));

      final state = tester.state<SwipeActionCellState>(find.byType(SwipeActionCell));
      expect(state.effectiveGestureConfig.deadZone, 55.0);
    });

    testWidgets('local config overrides theme', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCellTheme(
            gestureConfig: const SwipeGestureConfig(deadZone: 55.0),
            child: SwipeActionCell(
              gestureConfig: const SwipeGestureConfig(deadZone: 10.0),
              child: const Text('cell'),
            ),
          ),
        ),
      ));

      final state = tester.state<SwipeActionCellState>(find.byType(SwipeActionCell));
      expect(state.effectiveGestureConfig.deadZone, 10.0);
    });

    testWidgets('inherits animationConfig from theme', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCellTheme(
            animationConfig: const SwipeAnimationConfig(activationThreshold: 0.8),
            child: SwipeActionCell(
              child: const Text('cell'),
            ),
          ),
        ),
      ));

      final state = tester.state<SwipeActionCellState>(find.byType(SwipeActionCell));
      expect(state.effectiveAnimationConfig.activationThreshold, 0.8);
    });
  });
}

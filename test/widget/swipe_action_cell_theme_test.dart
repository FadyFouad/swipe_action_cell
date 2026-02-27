import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: implementation_imports
import 'package:swipe_action_cell/src/widget/swipe_action_cell.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

/// Wraps [child] in a [MaterialApp] with [SwipeActionCellTheme] installed as a
/// [ThemeExtension].
Widget withTheme(SwipeActionCellTheme theme, Widget child) {
  return MaterialApp(
    theme: ThemeData(extensions: [theme]),
    home: Scaffold(body: child),
  );
}

void main() {
  group('SwipeActionCellTheme widget inheritance (T026)', () {
    testWidgets(
        '(a) theme-provided gestureConfig used when no local override',
        (tester) async {
      await tester.pumpWidget(withTheme(
        const SwipeActionCellTheme(
          gestureConfig: SwipeGestureConfig(deadZone: 55.0),
        ),
        SwipeActionCell(child: const Text('cell')),
      ));

      final state =
          tester.state<SwipeActionCellState>(find.byType(SwipeActionCell));
      expect(state.effectiveGestureConfig.deadZone, 55.0);
    });

    testWidgets(
        '(b) local gestureConfig overrides theme; other theme configs still apply',
        (tester) async {
      await tester.pumpWidget(withTheme(
        const SwipeActionCellTheme(
          gestureConfig: SwipeGestureConfig(deadZone: 55.0),
          animationConfig: SwipeAnimationConfig(activationThreshold: 0.8),
        ),
        SwipeActionCell(
          gestureConfig: const SwipeGestureConfig(deadZone: 10.0),
          child: const Text('cell'),
        ),
      ));

      final state =
          tester.state<SwipeActionCellState>(find.byType(SwipeActionCell));
      expect(state.effectiveGestureConfig.deadZone, 10.0);
      expect(state.effectiveAnimationConfig.activationThreshold, 0.8);
    });

    testWidgets('(c) no theme in tree → package defaults, no crash',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCell(child: const Text('cell')),
        ),
      ));

      final state =
          tester.state<SwipeActionCellState>(find.byType(SwipeActionCell));
      expect(state.effectiveGestureConfig.deadZone,
          const SwipeGestureConfig().deadZone);
    });

    testWidgets(
        '(d) theme visualConfig applies to cells without local visualConfig',
        (tester) async {
      const visual = SwipeVisualConfig(clipBehavior: Clip.antiAlias);
      await tester.pumpWidget(withTheme(
        const SwipeActionCellTheme(visualConfig: visual),
        SwipeActionCell(child: const Text('cell')),
      ));

      final state =
          tester.state<SwipeActionCellState>(find.byType(SwipeActionCell));
      expect(state.effectiveVisualConfig.clipBehavior, Clip.antiAlias);
    });

    testWidgets(
        '(e) local animationConfig overrides theme; other cells unchanged',
        (tester) async {
      final key1 = GlobalKey();
      final key2 = GlobalKey();

      await tester.pumpWidget(withTheme(
        const SwipeActionCellTheme(
          animationConfig: SwipeAnimationConfig(activationThreshold: 0.5),
        ),
        Column(
          children: [
            SwipeActionCell(
              key: key1,
              animationConfig: SwipeAnimationConfig.snappy(),
              child: const Text('cell1'),
            ),
            SwipeActionCell(
              key: key2,
              child: const Text('cell2'),
            ),
          ],
        ),
      ));

      final state1 = tester.state<SwipeActionCellState>(
          find.byType(SwipeActionCell).first);
      final state2 = tester
          .state<SwipeActionCellState>(find.byType(SwipeActionCell).last);

      expect(state1.effectiveAnimationConfig,
          SwipeAnimationConfig.snappy());
      expect(state2.effectiveAnimationConfig.activationThreshold, 0.5);
    });
  });
}

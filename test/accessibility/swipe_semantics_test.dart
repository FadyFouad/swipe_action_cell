import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

/// Helper to build a testable SwipeActionCell inside a constrained LTR context.
Widget _buildTestApp({
  TextDirection textDirection = TextDirection.ltr,
  RightSwipeConfig? rightSwipeConfig,
  LeftSwipeConfig? leftSwipeConfig,
  RightSwipeConfig? forwardSwipeConfig,
  LeftSwipeConfig? backwardSwipeConfig,
  ForceDirection forceDirection = ForceDirection.auto,
  SwipeSemanticConfig? semanticConfig,
}) {
  return Directionality(
    textDirection: textDirection,
    child: MediaQuery(
      data: const MediaQueryData(),
      child: Center(
        child: SizedBox(
          width: 400,
          height: 80,
          child: SwipeActionCell(
            rightSwipeConfig: rightSwipeConfig,
            leftSwipeConfig: leftSwipeConfig,
            forwardSwipeConfig: forwardSwipeConfig,
            backwardSwipeConfig: backwardSwipeConfig,
            forceDirection: forceDirection,
            semanticConfig: semanticConfig,
            child: const Text('Cell'),
          ),
        ),
      ),
    ),
  );
}

/// Extracts the list of custom semantics action IDs from the semantics node.
List<int> _getCustomActionIds(WidgetTester tester, Finder finder) {
  final semanticsNode = tester.getSemantics(finder);
  final data = semanticsNode.getSemanticsData();
  return data.customSemanticsActionIds?.toList() ?? [];
}

void main() {
  group('US1 — Screen Reader: Semantics tree structure', () {
    testWidgets('cell exposes Semantics node with cellLabel', (tester) async {
      await tester.pumpWidget(_buildTestApp(
        rightSwipeConfig: const RightSwipeConfig(),
        semanticConfig: const SwipeSemanticConfig(
          cellLabel: SemanticLabel.string('My item'),
        ),
      ));

      final semanticsNode = tester.getSemantics(find.byType(SwipeActionCell));
      final data = semanticsNode.getSemanticsData();
      expect(data.label, contains('My item'));
    });

    testWidgets(
        'custom actions registered when rightSwipeConfig non-null',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        rightSwipeConfig: const RightSwipeConfig(),
      ));

      final actionIds = _getCustomActionIds(
          tester, find.byType(SwipeActionCell));
      expect(actionIds, isNotEmpty);
    });

    testWidgets(
        'custom actions registered when leftSwipeConfig non-null',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          onActionTriggered: () {},
        ),
      ));

      final actionIds = _getCustomActionIds(
          tester, find.byType(SwipeActionCell));
      expect(actionIds, isNotEmpty);
    });

    testWidgets('no custom actions registered when both configs null',
        (tester) async {
      await tester.pumpWidget(_buildTestApp());

      final actionIds = _getCustomActionIds(
          tester, find.byType(SwipeActionCell));
      expect(actionIds, isEmpty);
    });

    testWidgets('two custom actions when both configs present',
        (tester) async {
      await tester.pumpWidget(_buildTestApp(
        rightSwipeConfig: const RightSwipeConfig(),
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          onActionTriggered: () {},
        ),
      ));

      final actionIds = _getCustomActionIds(
          tester, find.byType(SwipeActionCell));
      expect(actionIds.length, 2);
    });
  });

  group('US1 — Screen Reader: Label resolution', () {
    testWidgets('default forward label differs between LTR and RTL',
        (tester) async {
      // LTR — should have "Swipe right to progress".
      await tester.pumpWidget(_buildTestApp(
        rightSwipeConfig: const RightSwipeConfig(),
      ));

      final ltrIds = _getCustomActionIds(
          tester, find.byType(SwipeActionCell));
      expect(ltrIds, isNotEmpty);

      // RTL — should have "Swipe left to progress" (different action ID).
      await tester.pumpWidget(_buildTestApp(
        textDirection: TextDirection.rtl,
        rightSwipeConfig: const RightSwipeConfig(),
      ));

      final rtlIds = _getCustomActionIds(
          tester, find.byType(SwipeActionCell));
      expect(rtlIds, isNotEmpty);

      // The action IDs should differ because labels differ.
      expect(ltrIds.first, isNot(equals(rtlIds.first)));
    });

    testWidgets('custom rightSwipeLabel produces different action ID',
        (tester) async {
      // Default label.
      await tester.pumpWidget(_buildTestApp(
        rightSwipeConfig: const RightSwipeConfig(),
      ));
      final defaultIds = _getCustomActionIds(
          tester, find.byType(SwipeActionCell));

      // Custom label.
      await tester.pumpWidget(_buildTestApp(
        rightSwipeConfig: const RightSwipeConfig(),
        semanticConfig: const SwipeSemanticConfig(
          rightSwipeLabel: SemanticLabel.string('Complete task'),
        ),
      ));
      final customIds = _getCustomActionIds(
          tester, find.byType(SwipeActionCell));

      expect(defaultIds.first, isNot(equals(customIds.first)));
    });
  });
}

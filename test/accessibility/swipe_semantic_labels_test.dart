import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

/// Extracts the list of custom semantics action IDs from the semantics node.
List<int> _getCustomActionIds(WidgetTester tester, Finder finder) {
  final semanticsNode = tester.getSemantics(finder);
  final data = semanticsNode.getSemanticsData();
  return data.customSemanticsActionIds?.toList() ?? [];
}

void main() {
  group('US5 — Localized Semantic Labels', () {
    testWidgets('custom label via builder produces valid semantic action',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: Center(
              child: SizedBox(
                width: 400,
                height: 80,
                child: SwipeActionCell(
                  rightSwipeConfig: const RightSwipeConfig(),
                  semanticConfig: SwipeSemanticConfig(
                    rightSwipeLabel: SemanticLabel.builder((ctx) => 'Complete'),
                  ),
                  child: const Text('Cell'),
                ),
              ),
            ),
          ),
        ),
      );

      final actionIds =
          _getCustomActionIds(tester, find.byType(SwipeActionCell));
      expect(actionIds, isNotEmpty);
    });

    testWidgets('empty builder result falls back to default', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: Center(
              child: SizedBox(
                width: 400,
                height: 80,
                child: SwipeActionCell(
                  rightSwipeConfig: const RightSwipeConfig(),
                  semanticConfig: const SwipeSemanticConfig(
                    rightSwipeLabel: SemanticLabel.builder(_emptyBuilder),
                  ),
                  child: const Text('Cell'),
                ),
              ),
            ),
          ),
        ),
      );

      // Should have action IDs (fell back to default label).
      final actionIds =
          _getCustomActionIds(tester, find.byType(SwipeActionCell));
      expect(actionIds, isNotEmpty);
    });

    testWidgets('RTL default labels produce different IDs from LTR defaults',
        (tester) async {
      // LTR.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: Center(
              child: SizedBox(
                width: 400,
                height: 80,
                child: SwipeActionCell(
                  rightSwipeConfig: const RightSwipeConfig(),
                  child: const Text('Cell'),
                ),
              ),
            ),
          ),
        ),
      );

      final ltrIds = _getCustomActionIds(tester, find.byType(SwipeActionCell));

      // RTL.
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: MediaQuery(
            data: const MediaQueryData(),
            child: Center(
              child: SizedBox(
                width: 400,
                height: 80,
                child: SwipeActionCell(
                  rightSwipeConfig: const RightSwipeConfig(),
                  child: const Text('Cell'),
                ),
              ),
            ),
          ),
        ),
      );

      final rtlIds = _getCustomActionIds(tester, find.byType(SwipeActionCell));

      expect(ltrIds, isNotEmpty);
      expect(rtlIds, isNotEmpty);
      // LTR and RTL labels should differ → different action IDs.
      expect(ltrIds.first, isNot(equals(rtlIds.first)));
    });
  });
}

String _emptyBuilder(BuildContext _) => '';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('SemanticLabel', () {
    testWidgets('.string() resolves to static string', (tester) async {
      const label = SemanticLabel.string('hello');
      late String result;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(builder: (ctx) {
            result = label.resolve(ctx);
            return const SizedBox();
          }),
        ),
      );
      expect(result, 'hello');
    });

    testWidgets('.builder() resolves to built string', (tester) async {
      const label = SemanticLabel.builder(_testBuilder);
      late String result;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(builder: (ctx) {
            result = label.resolve(ctx);
            return const SizedBox();
          }),
        ),
      );
      expect(result, 'built');
    });

    testWidgets('.builder() returning empty → empty string', (tester) async {
      const label = SemanticLabel.builder(_emptyBuilder);
      late String result;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(builder: (ctx) {
            result = label.resolve(ctx);
            return const SizedBox();
          }),
        ),
      );
      expect(result, '');
    });
  });

  group('SwipeSemanticConfig', () {
    test('default constructor — all fields null', () {
      const config = SwipeSemanticConfig();
      expect(config.cellLabel, isNull);
      expect(config.rightSwipeLabel, isNull);
      expect(config.leftSwipeLabel, isNull);
      expect(config.panelOpenLabel, isNull);
      expect(config.progressAnnouncementBuilder, isNull);
    });

    test('const construction compiles', () {
      // This test passes at compile time.
      const SwipeSemanticConfig(
        cellLabel: SemanticLabel.string('cell'),
        rightSwipeLabel: SemanticLabel.string('right'),
      );
    });

    test('copyWith replaces specified fields', () {
      const original = SwipeSemanticConfig(
        cellLabel: SemanticLabel.string('original'),
      );
      final copied = original.copyWith(
        cellLabel: const SemanticLabel.string('replaced'),
        rightSwipeLabel: const SemanticLabel.string('new right'),
      );
      // The original is unchanged for null fields.
      expect(original.rightSwipeLabel, isNull);
      // The copy has the new values.
      expect(copied.rightSwipeLabel, isNotNull);
    });
  });
}

String _testBuilder(BuildContext _) => 'built';
String _emptyBuilder(BuildContext _) => '';

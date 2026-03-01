import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('ForceDirection enum', () {
    test('has three values', () {
      expect(ForceDirection.values.length, 3);
    });
  });

  group('SwipeDirectionResolver.isRtl', () {
    testWidgets('auto + LTR → false', (tester) async {
      late bool result;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(builder: (ctx) {
            result = SwipeDirectionResolver.isRtl(ctx, ForceDirection.auto);
            return const SizedBox();
          }),
        ),
      );
      expect(result, false);
    });

    testWidgets('auto + RTL → true', (tester) async {
      late bool result;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(builder: (ctx) {
            result = SwipeDirectionResolver.isRtl(ctx, ForceDirection.auto);
            return const SizedBox();
          }),
        ),
      );
      expect(result, true);
    });

    testWidgets('ltr override in RTL → false', (tester) async {
      late bool result;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Builder(builder: (ctx) {
            result = SwipeDirectionResolver.isRtl(ctx, ForceDirection.ltr);
            return const SizedBox();
          }),
        ),
      );
      expect(result, false);
    });

    testWidgets('rtl override in LTR → true', (tester) async {
      late bool result;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(builder: (ctx) {
            result = SwipeDirectionResolver.isRtl(ctx, ForceDirection.rtl);
            return const SizedBox();
          }),
        ),
      );
      expect(result, true);
    });
  });

  group('SwipeDirectionResolver.forwardPhysical', () {
    test('LTR → right', () {
      expect(
          SwipeDirectionResolver.forwardPhysical(false), SwipeDirection.right);
    });
    test('RTL → left', () {
      expect(SwipeDirectionResolver.forwardPhysical(true), SwipeDirection.left);
    });
  });

  group('SwipeDirectionResolver.backwardPhysical', () {
    test('LTR → left', () {
      expect(
          SwipeDirectionResolver.backwardPhysical(false), SwipeDirection.left);
    });
    test('RTL → right', () {
      expect(
          SwipeDirectionResolver.backwardPhysical(true), SwipeDirection.right);
    });
  });

  group('SwipeDirectionResolver.configForPhysical', () {
    const configA = 'A';
    const configB = 'B';

    test('LTR + right → rightConfig', () {
      expect(
        SwipeDirectionResolver.configForPhysical<String>(
          SwipeDirection.right,
          isRtl: false,
          rightConfig: configA,
          leftConfig: configB,
        ),
        configA,
      );
    });

    test('LTR + left → leftConfig', () {
      expect(
        SwipeDirectionResolver.configForPhysical<String>(
          SwipeDirection.left,
          isRtl: false,
          rightConfig: configA,
          leftConfig: configB,
        ),
        configB,
      );
    });

    test('RTL + right → leftConfig', () {
      expect(
        SwipeDirectionResolver.configForPhysical<String>(
          SwipeDirection.right,
          isRtl: true,
          rightConfig: configA,
          leftConfig: configB,
        ),
        configB,
      );
    });

    test('RTL + left → rightConfig', () {
      expect(
        SwipeDirectionResolver.configForPhysical<String>(
          SwipeDirection.left,
          isRtl: true,
          rightConfig: configA,
          leftConfig: configB,
        ),
        configA,
      );
    });
  });
}

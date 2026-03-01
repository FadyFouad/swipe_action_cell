import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('SwipeActionBackground', () {
    testWidgets('ratio = 0.0 → icon invisible (BG-T01)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionBackground(
              icon: const Icon(Icons.delete),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              progress: const SwipeProgress(
                direction: SwipeDirection.right,
                ratio: 0.0,
                isActivated: false,
                rawOffset: 0.0,
              ),
            ),
          ),
        ),
      );

      final opacityWidget = tester.widget<Opacity>(find.descendant(
          of: find.byType(SwipeActionBackground),
          matching: find.byType(Opacity)));
      expect(opacityWidget.opacity, equals(0.0));
    });

    testWidgets('ratio = 0.5 → icon partially visible (BG-T02)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionBackground(
              icon: const Icon(Icons.delete),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              progress: const SwipeProgress(
                direction: SwipeDirection.right,
                ratio: 0.5,
                isActivated: false,
                rawOffset: 50.0,
              ),
            ),
          ),
        ),
      );

      final opacityWidget = tester.widget<Opacity>(find.descendant(
          of: find.byType(SwipeActionBackground),
          matching: find.byType(Opacity)));
      expect(opacityWidget.opacity, equals(0.5));

      final scaleWidget = tester.widget<Transform>(find.descendant(
          of: find.byType(SwipeActionBackground),
          matching: find.byKey(const Key("bg_scale"))));
      // Transform.scale uses Matrix4.diagonal3Values(scale, scale, 1.0)
      final scale = scaleWidget.transform.entry(0, 0);
      expect(scale, moreOrLessEquals(0.5, epsilon: 0.01));
    });

    testWidgets('ratio = 1.0 → icon fully visible (BG-T03)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionBackground(
              icon: const Icon(Icons.delete),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              progress: const SwipeProgress(
                direction: SwipeDirection.right,
                ratio: 1.0,
                isActivated: false,
                rawOffset: 100.0,
              ),
            ),
          ),
        ),
      );

      final opacityWidget = tester.widget<Opacity>(find.descendant(
          of: find.byType(SwipeActionBackground),
          matching: find.byType(Opacity)));
      expect(opacityWidget.opacity, equals(1.0));
    });

    testWidgets('label non-null → Text in tree (BG-T04)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionBackground(
              icon: const Icon(Icons.delete),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              label: 'Delete',
              progress: const SwipeProgress(
                direction: SwipeDirection.right,
                ratio: 1.0,
                isActivated: false,
                rawOffset: 100.0,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('label null → no Text in tree (BG-T05)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionBackground(
              icon: const Icon(Icons.delete),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              progress: const SwipeProgress(
                direction: SwipeDirection.right,
                ratio: 1.0,
                isActivated: false,
                rawOffset: 100.0,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Text), findsNothing);
    });

    testWidgets('isActivated false→true → bump fires (BG-T06)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionBackground(
              icon: const Icon(Icons.delete),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              progress: const SwipeProgress(
                direction: SwipeDirection.right,
                ratio: 1.0,
                isActivated: false,
                rawOffset: 100.0,
              ),
            ),
          ),
        ),
      );

      // Change to isActivated: true
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionBackground(
              icon: const Icon(Icons.delete),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              progress: const SwipeProgress(
                direction: SwipeDirection.right,
                ratio: 1.0,
                isActivated: true,
                rawOffset: 100.0,
              ),
            ),
          ),
        ),
      );

      // Animate for 150ms (peak of bump)
      await tester.pump(const Duration(milliseconds: 150));

      final scaleWidget = tester.widget<Transform>(find.descendant(
          of: find.byType(SwipeActionBackground),
          matching: find.byKey(const Key("bg_scale"))));
      final scale = scaleWidget.transform.entry(0, 0);
      // Should be ratio(1.0) * (1.0 + bump(0.3)) = 1.3
      expect(scale, greaterThan(1.1));
    });

    testWidgets('background color darkens at ratio = 1.0 (BG-T07)',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionBackground(
              icon: const Icon(Icons.delete),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              progress: const SwipeProgress(
                direction: SwipeDirection.right,
                ratio: 0.0,
                isActivated: false,
                rawOffset: 0.0,
              ),
            ),
          ),
        ),
      );

      final coloredBox0 = tester.widget<ColoredBox>(find.descendant(
          of: find.byType(SwipeActionBackground),
          matching: find.byType(ColoredBox)));
      final color0 = coloredBox0.color;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionBackground(
              icon: const Icon(Icons.delete),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              progress: const SwipeProgress(
                direction: SwipeDirection.right,
                ratio: 1.0,
                isActivated: false,
                rawOffset: 100.0,
              ),
            ),
          ),
        ),
      );

      final coloredBox1 = tester.widget<ColoredBox>(find.descendant(
          of: find.byType(SwipeActionBackground),
          matching: find.byType(ColoredBox)));
      final color1 = coloredBox1.color;

      expect(color1, isNot(equals(color0)));
      // HSL lightness reduction means it should be darker
      expect(HSLColor.fromColor(color1).lightness,
          lessThan(HSLColor.fromColor(color0).lightness));
    });

    testWidgets('icon above label in column layout (BG-T08)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionBackground(
              icon: const Icon(Icons.delete, key: Key('icon')),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              label: 'Delete',
              progress: const SwipeProgress(
                direction: SwipeDirection.right,
                ratio: 1.0,
                isActivated: false,
                rawOffset: 100.0,
              ),
            ),
          ),
        ),
      );

      final iconPos = tester.getTopLeft(find.byKey(const Key('icon')));
      final labelPos = tester.getTopLeft(find.text('Delete'));
      expect(iconPos.dy, lessThan(labelPos.dy));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';
import 'package:swipe_action_cell/src/actions/progressive/progressive_swipe_indicator.dart';

void main() {
  group('ProgressiveSwipeIndicator', () {
    testWidgets('renders CustomPaint with correct size (T024)', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              height: 100,
              child: ProgressiveSwipeIndicator(
                fillRatio: 0.5,
                config: ProgressIndicatorConfig(width: 10.0),
              ),
            ),
          ),
        ),
      );

      final customPaint = find.byType(CustomPaint);
      expect(customPaint, findsOneWidget);
      expect(tester.getSize(customPaint).width, equals(10.0));
    });

    testWidgets('assert fillRatio in [0, 1] (T024)', (tester) async {
      expect(() => ProgressiveSwipeIndicator(fillRatio: -0.1),
          throwsAssertionError);
      expect(() => ProgressiveSwipeIndicator(fillRatio: 1.1),
          throwsAssertionError);
    });
  });
}

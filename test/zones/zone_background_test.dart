import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/src/core/swipe_direction.dart';
import 'package:swipe_action_cell/src/core/swipe_progress.dart';
import 'package:swipe_action_cell/src/core/swipe_zone.dart';
import 'package:swipe_action_cell/src/zones/zone_background.dart';

void main() {
  SwipeZone z(double t, {Color? color, String? label}) =>
      SwipeZone(threshold: t, semanticLabel: label ?? 'Zone', color: color);

  group('ZoneAwareBackground', () {
    testWidgets('renders nothing when ratio < first zone threshold',
        (tester) async {
      final zones = [z(0.3, color: Colors.red)];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ZoneAwareBackground(
            zones: zones,
            progress: const SwipeProgress(
                direction: SwipeDirection.right,
                ratio: 0.2,
                isActivated: false,
                rawOffset: 20.0),
          ),
        ),
      ));
      // ZoneAwareBackground returns SizedBox.shrink() which doesn't render a child
      // ScaleTransition -> SizedBox.shrink()
      expect(find.byType(Container), findsNothing);
    });

    testWidgets('renders first zone color when ratio >= zone[0].threshold',
        (tester) async {
      final zones = [z(0.3, color: Colors.red)];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ZoneAwareBackground(
            zones: zones,
            progress: const SwipeProgress(
                direction: SwipeDirection.right,
                ratio: 0.4,
                isActivated: true,
                rawOffset: 40.0),
          ),
        ),
      ));
      expect(find.byType(Container), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container));
      expect(container.color, Colors.red);
    });

    testWidgets('renders second zone color when ratio >= zone[1].threshold',
        (tester) async {
      final zones = [z(0.3, color: Colors.red), z(0.6, color: Colors.blue)];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ZoneAwareBackground(
            zones: zones,
            progress: const SwipeProgress(
                direction: SwipeDirection.right,
                ratio: 0.7,
                isActivated: true,
                rawOffset: 70.0),
          ),
        ),
      ));
      expect(find.byType(Container), findsOneWidget);
      final container = tester.widget<Container>(find.byType(Container));
      expect(container.color, Colors.blue);
    });
  });
}

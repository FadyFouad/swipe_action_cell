import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('SwipeActionCell', () {
    testWidgets('renders child widget', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwipeActionCell(
              child: Text('hello'),
            ),
          ),
        ),
      );
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('dead-zone suppression (US1)', (WidgetTester tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionCell(
              key: key,
              gestureConfig: const SwipeGestureConfig(deadZone: 12.0),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final state = tester.state(find.byKey(key)) as dynamic;
      final listenable = state.swipeOffsetListenable as ValueListenable<double>;

      expect(listenable.value, equals(0.0));

      // Drag 10px (within dead zone)
      final gesture =
          await tester.startGesture(tester.getCenter(find.byKey(key)));
      await gesture.moveBy(const Offset(10.0, 0.0));
      await tester.pump();

      expect(listenable.value, equals(0.0));
      await gesture.up();
    });

    testWidgets('live drag following (US1)', (WidgetTester tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionCell(
              key: key,
              gestureConfig: const SwipeGestureConfig(deadZone: 12.0),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final state = tester.state(find.byKey(key)) as dynamic;
      final listenable = state.swipeOffsetListenable as ValueListenable<double>;

      // Drag 50px (beyond dead zone)
      final gesture =
          await tester.startGesture(tester.getCenter(find.byKey(key)));
      await gesture.moveBy(const Offset(50.0, 0.0));
      await tester.pump();

      // Should have moved (exact value depends on resistance but should be > 0)
      expect(listenable.value, greaterThan(0.0));
      await gesture.up();
    });

    testWidgets('sub-threshold release snaps back (US2)',
        (WidgetTester tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionCell(
              key: key,
              animationConfig: const SwipeAnimationConfig(
                activationThreshold: 0.4,
                maxTranslationRight: 100.0,
              ),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final state = tester.state(find.byKey(key)) as dynamic;
      final listenable = state.swipeOffsetListenable as ValueListenable<double>;

      // Drag 25px (25% of 100px, below 40% threshold)
      final gesture =
          await tester.startGesture(tester.getCenter(find.byKey(key)));
      await gesture.moveBy(const Offset(25.0, 0.0));
      await tester.pump();
      expect(listenable.value, greaterThan(0.0));

      // Release
      await gesture.up();
      await tester.pumpAndSettle();

      expect(listenable.value, moreOrLessEquals(0.0, epsilon: 1.0));
    });

    testWidgets('above-threshold release completes (US3)', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionCell(
              key: key,
              animationConfig: const SwipeAnimationConfig(
                activationThreshold: 0.4,
                maxTranslationRight: 100.0,
              ),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final state = tester.state(find.byKey(key)) as dynamic;
      final listenable = state.swipeOffsetListenable as ValueListenable<double>;

      // Drag 60px (60% of 100px, above 40% threshold)
      final gesture =
          await tester.startGesture(tester.getCenter(find.byKey(key)));
      await gesture.moveBy(const Offset(60.0, 0.0));
      await tester.pump();

      // Release
      await gesture.up();
      await tester.pumpAndSettle();

      expect(listenable.value, moreOrLessEquals(100.0, epsilon: 1.0));
    });

    testWidgets('fling completes (US4)', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionCell(
              key: key,
              animationConfig: const SwipeAnimationConfig(
                activationThreshold: 0.4,
                maxTranslationRight: 100.0,
              ),
              gestureConfig: const SwipeGestureConfig(
                velocityThreshold: 700.0,
                deadZone: 0,
              ),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final state = tester.state(find.byKey(key)) as dynamic;
      final listenable = state.swipeOffsetListenable as ValueListenable<double>;

      final gesture =
          await tester.startGesture(tester.getCenter(find.byKey(key)));
      for (int i = 0; i < 5; i++) {
        await gesture.moveBy(const Offset(12.0, 0.0));
        await tester.pump(const Duration(milliseconds: 16));
      }

      await gesture.up();
      await tester.pumpAndSettle();

      expect(listenable.value, moreOrLessEquals(100.0, epsilon: 1.0));
    });

    testWidgets('low-velocity rejection (US4)', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionCell(
              key: key,
              animationConfig: const SwipeAnimationConfig(
                activationThreshold: 0.4,
                maxTranslationRight: 100.0,
              ),
              gestureConfig: const SwipeGestureConfig(
                velocityThreshold: 700.0,
              ),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final state = tester.state(find.byKey(key)) as dynamic;
      final listenable = state.swipeOffsetListenable as ValueListenable<double>;

      // Drag 15px slowly (no velocity)
      await tester.drag(find.byKey(key), const Offset(15.0, 0.0),
          warnIfMissed: false);
      await tester.pumpAndSettle();

      // Should snap back
      expect(listenable.value, moreOrLessEquals(0.0, epsilon: 1.0));
    });

    testWidgets('mid-animation interrupt (US5)', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionCell(
              key: key,
              animationConfig: const SwipeAnimationConfig(
                maxTranslationRight: 100.0,
              ),
              gestureConfig: const SwipeGestureConfig(deadZone: 0),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final state = tester.state(find.byKey(key)) as dynamic;
      final listenable = state.swipeOffsetListenable as ValueListenable<double>;

      // 1. Start drag and release to trigger snap-back
      final gesture1 =
          await tester.startGesture(tester.getCenter(find.byKey(key)));
      await gesture1.moveBy(const Offset(30.0, 0.0));
      await tester.pump();
      await gesture1.up();
      await tester.pump(); // Start animation

      // 2. Let it animate for 16ms * 3 frames
      for (int i = 0; i < 3; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      final offsetMid = listenable.value;
      // We expect it to have moved back towards 0 from 30
      expect(offsetMid, lessThan(30.0));
      expect(offsetMid, greaterThan(0.0));

      // 3. Start new drag - should stop animation
      final gesture2 =
          await tester.startGesture(tester.getCenter(find.byKey(key)));
      await tester.pump();

      final offsetAfterInterrupt = listenable.value;
      expect(offsetAfterInterrupt, moreOrLessEquals(offsetMid, epsilon: 2.0));

      // 4. Continue dragging
      await gesture2.moveBy(const Offset(10.0, 0.0));
      await tester.pump();
      expect(listenable.value,
          moreOrLessEquals(offsetAfterInterrupt + 10.0, epsilon: 1.0));

      await gesture2.up();
      await tester.pumpAndSettle();
    });

    testWidgets('parameter deadZone effect (T035)', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionCell(
              key: key,
              gestureConfig: const SwipeGestureConfig(deadZone: 50.0),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final state = tester.state(find.byKey(key)) as dynamic;
      final listenable = state.swipeOffsetListenable as ValueListenable<double>;

      final gesture =
          await tester.startGesture(tester.getCenter(find.byKey(key)));
      await gesture.moveBy(const Offset(40.0, 0.0));
      await tester.pump();

      // Should not have moved yet (deadZone is 50)
      expect(listenable.value, equals(0.0));

      await gesture.moveBy(const Offset(20.0, 0.0)); // Total 60
      await tester.pump();
      expect(listenable.value, greaterThan(0.0));

      await gesture.up();
    });

    testWidgets('parameter activationThreshold effect (T035)', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionCell(
              key: key,
              animationConfig: const SwipeAnimationConfig(
                activationThreshold: 0.8,
                maxTranslationRight: 100.0,
              ),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final state = tester.state(find.byKey(key)) as dynamic;
      final listenable = state.swipeOffsetListenable as ValueListenable<double>;

      // Drag 50px (50% of 100px, above default 40% but below custom 80%)
      final gesture =
          await tester.startGesture(tester.getCenter(find.byKey(key)));
      await gesture.moveBy(const Offset(50.0, 0.0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Should snap back (because threshold is 80%)
      expect(listenable.value, moreOrLessEquals(0.0, epsilon: 1.0));
    });

    testWidgets('renders child without altering constraints (T037)',
        (tester) async {
      const child = SizedBox(width: 50, height: 50);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SwipeActionCell(
                child: child,
              ),
            ),
          ),
        ),
      );

      final size = tester.getSize(find.byWidget(child));
      expect(size.width, equals(50.0));
      expect(size.height, equals(50.0));
    });

    testWidgets('consecutive rapid drag-release cycles (T036)', (tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionCell(
              key: key,
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final state = tester.state(find.byKey(key)) as dynamic;
      final listenable = state.swipeOffsetListenable as ValueListenable<double>;

      for (int i = 0; i < 10; i++) {
        final gesture =
            await tester.startGesture(tester.getCenter(find.byKey(key)));
        await gesture.moveBy(const Offset(30.0, 0.0));
        await tester.pump();
        await gesture.up();
        // Interrupt mid-animation next iteration or let it settle
        if (i % 2 == 0) {
          await tester.pump(const Duration(milliseconds: 20));
        } else {
          await tester.pumpAndSettle();
        }
      }

      await tester.pumpAndSettle();
      expect(listenable.value, moreOrLessEquals(0.0, epsilon: 1.0));
    });

    testWidgets('disabled direction (US1)', (WidgetTester tester) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SwipeActionCell(
              key: key,
              gestureConfig: const SwipeGestureConfig(
                enabledDirections: {SwipeDirection.left},
              ),
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final state = tester.state(find.byKey(key)) as dynamic;
      final listenable = state.swipeOffsetListenable as ValueListenable<double>;

      // Drag right (disabled)
      final gesture =
          await tester.startGesture(tester.getCenter(find.byKey(key)));
      await gesture.moveBy(const Offset(50.0, 0.0));
      await tester.pump();

      expect(listenable.value, equals(0.0));
      await gesture.up();
    });

    group('Background Visual Layer (US1)', () {
      testWidgets(
          'right drag shows right background and hides left (BG-W01, BG-W03)',
          (tester) async {
        const rightKey = Key('right_bg');
        const leftKey = Key('left_bg');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SwipeActionCell(
                rightBackground: (context, progress) =>
                    const SizedBox(key: rightKey),
                leftBackground: (context, progress) =>
                    const SizedBox(key: leftKey),
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );

        // Drag right
        final gesture = await tester
            .startGesture(tester.getCenter(find.byType(SwipeActionCell)));
        await gesture.moveBy(const Offset(50.0, 0.0));
        await tester.pump();

        expect(find.byKey(rightKey), findsOneWidget);
        expect(find.byKey(leftKey), findsNothing);
        await gesture.up();
      });

      testWidgets(
          'left drag shows left background and hides right (BG-W02, BG-W04)',
          (tester) async {
        const rightKey = Key('right_bg');
        const leftKey = Key('left_bg');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SwipeActionCell(
                rightBackground: (context, progress) =>
                    const SizedBox(key: rightKey),
                leftBackground: (context, progress) =>
                    const SizedBox(key: leftKey),
                gestureConfig: const SwipeGestureConfig(
                  enabledDirections: {
                    SwipeDirection.left,
                    SwipeDirection.right
                  },
                ),
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );

        // Drag left
        final gesture = await tester
            .startGesture(tester.getCenter(find.byType(SwipeActionCell)));
        await gesture.moveBy(const Offset(-50.0, 0.0));
        await tester.pump();

        expect(find.byKey(leftKey), findsOneWidget);
        expect(find.byKey(rightKey), findsNothing);
        await gesture.up();
      });

      testWidgets('null builder shows no background (BG-W05)', (tester) async {
        const leftKey = Key('left_bg');

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SwipeActionCell(
                rightBackground: null,
                leftBackground: (context, progress) =>
                    const SizedBox(key: leftKey),
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );

        // Drag right
        final gesture = await tester
            .startGesture(tester.getCenter(find.byType(SwipeActionCell)));
        await gesture.moveBy(const Offset(50.0, 0.0));
        await tester.pump();

        // No right background, and no left background should be visible
        expect(find.byKey(leftKey), findsNothing);
        await gesture.up();
      });

      testWidgets('background does not change child bounding box (BG-W09)',
          (tester) async {
        const childKey = Key('child');
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SwipeActionCell(
                  rightBackground: (context, progress) =>
                      const SizedBox(width: 200, height: 200),
                  child: const SizedBox(key: childKey, width: 100, height: 100),
                ),
              ),
            ),
          ),
        );

        final initialSize = tester.getSize(find.byKey(childKey));
        expect(initialSize.width, equals(100.0));
        expect(initialSize.height, equals(100.0));

        // Drag right to reveal background
        final gesture =
            await tester.startGesture(tester.getCenter(find.byKey(childKey)));
        await gesture.moveBy(const Offset(50.0, 0.0));
        await tester.pump();

        final sizeDuringSwipe = tester.getSize(find.byKey(childKey));
        expect(sizeDuringSwipe.width, equals(100.0));
        expect(sizeDuringSwipe.height, equals(100.0));
        await gesture.up();
      });

      testWidgets(
          'background builder called during snap-back but not after (BG-W10)',
          (tester) async {
        int callCount = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SwipeActionCell(
                rightBackground: (context, progress) {
                  callCount++;
                  return const SizedBox();
                },
                animationConfig: const SwipeAnimationConfig(
                  maxTranslationRight: 100.0,
                  activationThreshold: 0.5,
                ),
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );

        // Reset call count after initial build
        callCount = 0;

        // Drag 40px
        final gesture = await tester
            .startGesture(tester.getCenter(find.byType(SwipeActionCell)));
        await gesture.moveBy(const Offset(40.0, 0.0));
        await tester.pump();
        expect(callCount, greaterThan(0));
        int dragCallCount = callCount;

        // Release (below 50% threshold)
        await gesture.up();
        await tester.pump(); // Start animation
        expect(callCount, greaterThan(dragCallCount));
        int afterReleaseCount = callCount;

        // Animate partially
        await tester.pump(const Duration(milliseconds: 50));
        expect(callCount, greaterThan(afterReleaseCount));

        // Settle
        await tester.pumpAndSettle();
        int finalCount = callCount;

        // Pump again - should NOT call builder anymore
        await tester.pump();
        expect(callCount, equals(finalCount));
      });

      testWidgets(
          'ratio values during snap-back are monotonically decreasing (BG-W11)',
          (tester) async {
        final List<double> ratios = [];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SwipeActionCell(
                rightBackground: (context, progress) {
                  if (progress.direction == SwipeDirection.right) {
                    ratios.add(progress.ratio);
                  }
                  return const SizedBox();
                },
                animationConfig: const SwipeAnimationConfig(
                  maxTranslationRight: 100.0,
                  activationThreshold: 0.5,
                ),
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );

        // Drag 40px
        final gesture = await tester
            .startGesture(tester.getCenter(find.byType(SwipeActionCell)));
        await gesture.moveBy(const Offset(40.0, 0.0));
        await tester.pump();

        ratios.clear();

        // Release
        await gesture.up();

        // We need to pump multiple times to capture animation frames
        // Use a small duration to get more frames
        while (tester.binding.hasScheduledFrame ||
            ratios.isEmpty ||
            ratios.last > 0.01) {
          await tester.pump(const Duration(milliseconds: 16));
          if (ratios.length > 100) break; // Safety break
        }

        expect(ratios, isNotEmpty);
        for (int i = 0; i < ratios.length - 1; i++) {
          expect(ratios[i + 1], lessThanOrEqualTo(ratios[i] + 0.01),
              reason:
                  'Ratio at index ${i + 1} (${ratios[i + 1]}) should be <= ratio at index $i (${ratios[i]})');
        }
        expect(ratios.last, moreOrLessEquals(0.0, epsilon: 0.1));
      });

      testWidgets('default clipBehavior is Clip.hardEdge (BG-W06)',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SwipeActionCell(
                child: SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );

        final clipRect = find.byType(ClipRect);
        expect(clipRect, findsOneWidget);
        expect((tester.widget(clipRect) as ClipRect).clipBehavior,
            equals(Clip.hardEdge));
      });

      testWidgets('borderRadius non-null shows ClipRRect (BG-W07)',
          (tester) async {
        final radius = BorderRadius.circular(12);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SwipeActionCell(
                borderRadius: radius,
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );

        final clipRRect = find.byType(ClipRRect);
        expect(clipRRect, findsOneWidget);
        expect((tester.widget(clipRRect) as ClipRRect).borderRadius,
            equals(radius));
      });

      testWidgets('clipBehavior.none and no radius shows no clip (BG-W08)',
          (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SwipeActionCell(
                clipBehavior: Clip.none,
                child: SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        );

        expect(find.byType(ClipRect), findsNothing);
        expect(find.byType(ClipRRect), findsNothing);
      });
    });
  });
}

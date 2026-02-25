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
      final gesture = await tester.startGesture(tester.getCenter(find.byKey(key)));
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
      final gesture = await tester.startGesture(tester.getCenter(find.byKey(key)));
      await gesture.moveBy(const Offset(50.0, 0.0));
      await tester.pump();

      // Should have moved (exact value depends on resistance but should be > 0)
      expect(listenable.value, greaterThan(0.0));
      await gesture.up();
    });

    testWidgets('sub-threshold release snaps back (US2)', (WidgetTester tester) async {
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
      final gesture = await tester.startGesture(tester.getCenter(find.byKey(key)));
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
      final gesture = await tester.startGesture(tester.getCenter(find.byKey(key)));
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

      final gesture = await tester.startGesture(tester.getCenter(find.byKey(key)));
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
      await tester.drag(find.byKey(key), const Offset(15.0, 0.0), warnIfMissed: false);
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
      final gesture1 = await tester.startGesture(tester.getCenter(find.byKey(key)));
      await gesture1.moveBy(const Offset(30.0, 0.0));
      await tester.pump();
      await gesture1.up();
      await tester.pump(); // Start animation
      
      // 2. Let it animate for 16ms * 3 frames
      for(int i=0; i<3; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      
      final offsetMid = listenable.value;
      // We expect it to have moved back towards 0 from 30
      expect(offsetMid, lessThan(30.0));
      expect(offsetMid, greaterThan(0.0));

      // 3. Start new drag - should stop animation
      final gesture2 = await tester.startGesture(tester.getCenter(find.byKey(key)));
      await tester.pump(); 
      
      final offsetAfterInterrupt = listenable.value;
      expect(offsetAfterInterrupt, moreOrLessEquals(offsetMid, epsilon: 2.0));
      
      // 4. Continue dragging
      await gesture2.moveBy(const Offset(10.0, 0.0));
      await tester.pump();
      expect(listenable.value, moreOrLessEquals(offsetAfterInterrupt + 10.0, epsilon: 1.0));
      
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

      final gesture = await tester.startGesture(tester.getCenter(find.byKey(key)));
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
      final gesture = await tester.startGesture(tester.getCenter(find.byKey(key)));
      await gesture.moveBy(const Offset(50.0, 0.0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      // Should snap back (because threshold is 80%)
      expect(listenable.value, moreOrLessEquals(0.0, epsilon: 1.0));
    });

    testWidgets('renders child without altering constraints (T037)', (tester) async {
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
        final gesture = await tester.startGesture(tester.getCenter(find.byKey(key)));
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
      final gesture = await tester.startGesture(tester.getCenter(find.byKey(key)));
      await gesture.moveBy(const Offset(50.0, 0.0));
      await tester.pump();

      expect(listenable.value, equals(0.0));
      await gesture.up();
    });
  });
}

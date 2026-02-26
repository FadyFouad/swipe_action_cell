import "package:flutter/services.dart";

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Builds a [SwipeActionCell] inside a fixed-width test harness.
Widget buildCell({
  required Widget child,
  IntentionalSwipeConfig? leftSwipe,
  ProgressiveSwipeConfig? rightSwipe,
  SwipeBackgroundBuilder? leftBackground,
  ValueChanged<SwipeState>? onStateChanged,
  bool enabled = true,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 400,
        height: 60,
        child: SwipeActionCell(
          enabled: enabled,
          leftSwipe: leftSwipe,
          rightSwipe: rightSwipe,
          leftBackground: leftBackground,
          onStateChanged: onStateChanged,
          child: child,
        ),
      ),
    ),
  );
}

/// Simulates a left swipe past the activation threshold.
Future<void> swipeLeft(
  WidgetTester tester, {
  double distance = 260.0,
}) async {
  final gesture = await tester.startGesture(const Offset(300, 30));
  await gesture.moveBy(Offset(-distance, 0));
  await gesture.up();
  await tester.pumpAndSettle();
}

/// Simulates a right swipe past the activation threshold.
Future<void> swipeRight(WidgetTester tester, {double distance = 260.0}) async {
  await tester.drag(find.byType(SwipeActionCell), Offset(distance, 0));
  await tester.pumpAndSettle();
}

/// Simulates a left swipe that ends below the activation threshold.
Future<void> swipeLeftBelowThreshold(WidgetTester tester) async {
  final gesture = await tester.startGesture(const Offset(300, 30));
  await gesture.moveBy(const Offset(-20, 0));
  await gesture.up();
  await tester.pumpAndSettle();
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ─── US1: Auto-Trigger Basic ────────────────────────────────────────────────

  group('US1: Auto-Trigger Basic', () {
    testWidgets('above-threshold left swipe fires onActionTriggered',
        (tester) async {
      bool triggered = false;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipe: IntentionalSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          onActionTriggered: () => triggered = true,
        ),
      ));

      await swipeLeft(tester);

      expect(triggered, isTrue);
    });

    testWidgets('below-threshold release does NOT fire onActionTriggered',
        (tester) async {
      bool triggered = false;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipe: IntentionalSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          onActionTriggered: () => triggered = true,
        ),
      ));

      await swipeLeftBelowThreshold(tester);

      expect(triggered, isFalse);
    });

    testWidgets('below-threshold release fires onSwipeCancelled', (tester) async {
      bool cancelled = false;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipe: IntentionalSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          onSwipeCancelled: () => cancelled = true,
        ),
      ));

      await swipeLeftBelowThreshold(tester);

      expect(cancelled, isTrue);
    });

    testWidgets('fling left triggers action', (tester) async {
      bool triggered = false;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipe: IntentionalSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          onActionTriggered: () => triggered = true,
        ),
      ));

      await tester.fling(
          find.byType(SwipeActionCell), const Offset(-200, 0), 800);
      await tester.pumpAndSettle();

      expect(triggered, isTrue);
    });

    testWidgets('onActionTriggered fires exactly once per swipe', (tester) async {
      int count = 0;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipe: IntentionalSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          onActionTriggered: () => count++,
        ),
      ));

      await swipeLeft(tester);

      expect(count, 1);
    });

    testWidgets('snapBack: onSwipeCancelled does NOT fire after action',
        (tester) async {
      bool cancelled = false;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipe: IntentionalSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          postActionBehavior: PostActionBehavior.snapBack,
          onSwipeCancelled: () => cancelled = true,
        ),
      ));

      await swipeLeft(tester);

      expect(cancelled, isFalse);
    });

    testWidgets('animation interrupt: new drag continues without crash',
        (tester) async {
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipe: const IntentionalSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
        ),
      ));

      // Start a swipe but interrupt mid-animation.
      final gesture = await tester.startGesture(const Offset(300, 30));
      await gesture.moveBy(const Offset(-260, 0));
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 50)); // mid-animation

      // Start new gesture during animation.
      final gesture2 = await tester.startGesture(const Offset(100, 30));
      await gesture2.moveBy(const Offset(20, 0));
      await gesture2.up();
      await tester.pumpAndSettle();

      // No crash — cell is still functioning.
      expect(find.byType(SwipeActionCell), findsOneWidget);
    });
  });

  // ─── US2: Reveal Mode ───────────────────────────────────────────────────────

  group('US2: Reveal Mode', () {
    SwipeAction makeAction({
      required String label,
      required VoidCallback onTap,
      bool isDestructive = false,
    }) {
      return SwipeAction(
        icon: const Icon(Icons.archive),
        label: label,
        backgroundColor: const Color(0xFF43A047),
        foregroundColor: const Color(0xFFFFFFFF),
        onTap: onTap,
        isDestructive: isDestructive,
      );
    }

    testWidgets('reveal panel opens on left swipe and onPanelOpened fires',
        (tester) async {
      bool opened = false;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipe: IntentionalSwipeConfig(
          mode: LeftSwipeMode.reveal,
          actions: [makeAction(label: 'Archive', onTap: () {})],
          onPanelOpened: () => opened = true,
        ),
      ));

      await swipeLeft(tester);

      expect(opened, isTrue);
      expect(find.byType(SwipeActionPanel), findsOneWidget);
    });

    testWidgets('action button tap fires onTap and onPanelClosed',
        (tester) async {
      bool tapped = false;
      bool closed = false;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipe: IntentionalSwipeConfig(
          mode: LeftSwipeMode.reveal,
          actions: [makeAction(label: 'Archive', onTap: () => tapped = true)],
          onPanelClosed: () => closed = true,
        ),
      ));

      await swipeLeft(tester);
      expect(find.byType(SwipeActionPanel), findsOneWidget);

      // Tap the action button (GestureDetector inside the panel).
      await tester.tap(find.byType(GestureDetector).last);
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      expect(closed, isTrue);
    });

    testWidgets('cell body tap closes panel and fires onPanelClosed (no onTap)',
        (tester) async {
      bool tapped = false;
      bool closed = false;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipe: IntentionalSwipeConfig(
          mode: LeftSwipeMode.reveal,
          actions: [makeAction(label: 'Archive', onTap: () => tapped = true)],
          onPanelClosed: () => closed = true,
        ),
      ));

      await swipeLeft(tester);
      expect(find.byType(SwipeActionPanel), findsOneWidget);

      // Tap within the visible cell body (cell translated to x=-80, so
      // (100, 30) is within the body interceptor's hit area).
      await tester.tapAt(const Offset(100, 30));
      await tester.pumpAndSettle();

      expect(tapped, isFalse);
      expect(closed, isTrue);
      expect(find.byType(SwipeActionPanel), findsNothing);
    });

    testWidgets('right swipe while panel open closes panel and fires onPanelClosed',
        (tester) async {
      bool closed = false;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipe: IntentionalSwipeConfig(
          mode: LeftSwipeMode.reveal,
          actions: [makeAction(label: 'Archive', onTap: () {})],
          onPanelClosed: () => closed = true,
        ),
      ));

      await swipeLeft(tester);
      expect(find.byType(SwipeActionPanel), findsOneWidget);

      await swipeRight(tester);

      expect(closed, isTrue);
      expect(find.byType(SwipeActionPanel), findsNothing);
    });
  });

  // ─── US3: Post-Action Behavior ──────────────────────────────────────────────

  group('US3: Post-Action Behavior', () {
    testWidgets('snapBack: onSwipeCancelled does not fire after action',
        (tester) async {
      bool cancelled = false;
      final states = <SwipeState>[];
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        onStateChanged: (s) => states.add(s),
        leftSwipe: IntentionalSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          postActionBehavior: PostActionBehavior.snapBack,
          onSwipeCancelled: () => cancelled = true,
          onActionTriggered: () {},
        ),
      ));

      await swipeLeft(tester);

      expect(cancelled, isFalse);
      expect(states, contains(SwipeState.idle));
    });

    testWidgets('animateOut: state transitions to animatingOut after action',
        (tester) async {
      bool triggered = false;
      final states = <SwipeState>[];
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        onStateChanged: (s) => states.add(s),
        leftSwipe: IntentionalSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          postActionBehavior: PostActionBehavior.animateOut,
          onActionTriggered: () => triggered = true,
        ),
      ));

      await swipeLeft(tester);

      expect(triggered, isTrue);
      expect(states, contains(SwipeState.animatingOut));
    });

    testWidgets('animateOut: new drag during slide-out is ignored', (tester) async {
      final states = <SwipeState>[];
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        onStateChanged: (s) => states.add(s),
        leftSwipe: const IntentionalSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          postActionBehavior: PostActionBehavior.animateOut,
        ),
      ));

      final gesture = await tester.startGesture(const Offset(300, 30));
      await gesture.moveBy(const Offset(-260, 0));
      await gesture.up();
      // Don't settle — we're mid-animateOut.
      await tester.pump(const Duration(milliseconds: 50));

      // Try to start a new drag while animatingOut.
      final gesture2 = await tester.startGesture(const Offset(200, 30));
      await gesture2.moveBy(const Offset(-50, 0));
      await gesture2.up();
      await tester.pumpAndSettle();

      // Should not have gone back to dragging from animatingOut.
      final afterAnimatingOut =
          states.skipWhile((s) => s != SwipeState.animatingOut).toList();
      expect(afterAnimatingOut.first, SwipeState.animatingOut);
      expect(afterAnimatingOut.skip(1), isNot(contains(SwipeState.dragging)));
    });

    testWidgets(
        'stay: state is revealed after action; right swipe returns to idle',
        (tester) async {
      bool triggered = false;
      final states = <SwipeState>[];
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        onStateChanged: (s) => states.add(s),
        leftSwipe: IntentionalSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          postActionBehavior: PostActionBehavior.stay,
          onActionTriggered: () => triggered = true,
        ),
      ));

      await swipeLeft(tester);

      expect(triggered, isTrue);
      expect(states, contains(SwipeState.revealed));

      await swipeRight(tester);

      expect(states.last, SwipeState.idle);
    });
  });

  // ─── US5: Require-Confirmation ───────────────────────────────────────────────

  group('US5: Require-Confirmation', () {
    testWidgets(
        'requireConfirmation: first swipe → state revealed, onActionTriggered NOT fired',
        (tester) async {
      bool triggered = false;
      final states = <SwipeState>[];
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        onStateChanged: (s) => states.add(s),
        leftSwipe: IntentionalSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          requireConfirmation: true,
          onActionTriggered: () => triggered = true,
        ),
      ));

      await swipeLeft(tester);

      expect(triggered, isFalse);
      expect(states, contains(SwipeState.revealed));
    });

    testWidgets(
        'requireConfirmation: second swipe past threshold fires onActionTriggered',
        (tester) async {
      bool triggered = false;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipe: IntentionalSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          requireConfirmation: true,
          onActionTriggered: () => triggered = true,
        ),
      ));

      // First swipe — goes to revealed (confirmation state).
      await swipeLeft(tester);
      expect(triggered, isFalse);

      // Second swipe — confirms.
      await swipeLeft(tester);
      expect(triggered, isTrue);
    });

    testWidgets(
        'requireConfirmation: body tap from confirmation state cancels',
        (tester) async {
      bool triggered = false;
      final states = <SwipeState>[];
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        onStateChanged: (s) => states.add(s),
        leftSwipe: IntentionalSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          requireConfirmation: true,
          onActionTriggered: () => triggered = true,
        ),
      ));

      await swipeLeft(tester);
      expect(triggered, isFalse);

      // After swipe, cell body translated left. Tap within the visible cell body
      // area (x=100, y=30) — guaranteed to be within the body interceptor area
      // and on-screen.
      await tester.tapAt(const Offset(100, 30));
      await tester.pumpAndSettle();

      expect(triggered, isFalse);
      expect(states.last, SwipeState.idle);
    });

    testWidgets(
        'requireConfirmation: right swipe from confirmation state cancels',
        (tester) async {
      bool triggered = false;
      final states = <SwipeState>[];
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        onStateChanged: (s) => states.add(s),
        leftSwipe: IntentionalSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          requireConfirmation: true,
          onActionTriggered: () => triggered = true,
        ),
      ));

      await swipeLeft(tester);
      expect(triggered, isFalse);

      await swipeRight(tester);

      expect(triggered, isFalse);
      expect(states.last, SwipeState.idle);
    });

    testWidgets(
        'requireConfirmation: tap on leftBackground area fires onActionTriggered',
        (tester) async {
      bool triggered = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 60,
            child: SwipeActionCell(
              leftBackground: (_, __) =>
                  const ColoredBox(color: Color(0xFFE53935)),
              leftSwipe: IntentionalSwipeConfig(
                mode: LeftSwipeMode.autoTrigger,
                requireConfirmation: true,
                onActionTriggered: () => triggered = true,
              ),
              child: const SizedBox(width: 400, height: 60),
            ),
          ),
        ),
      ));

      await swipeLeft(tester);
      expect(triggered, isFalse);

      // Tap on the exposed background area.
      // The cell slid left ~240px so background is visible at the right edge.
      await tester.tapAt(const Offset(350, 30));
      await tester.pumpAndSettle();

      expect(triggered, isTrue);
    });
  });

  // ─── US7: Coexistence with F3 ────────────────────────────────────────────────

  group('US7: Coexistence with F3 (rightSwipe + leftSwipe)', () {
    testWidgets(
        'right swipe fires only F3 callbacks; no left-swipe callbacks fire',
        (tester) async {
      bool rightFired = false;
      bool leftFired = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 60,
            child: SwipeActionCell(
              rightSwipe: ProgressiveSwipeConfig(
                stepValue: 1.0,
                maxValue: 10.0,
                onSwipeCompleted: (_) => rightFired = true,
              ),
              leftSwipe: IntentionalSwipeConfig(
                mode: LeftSwipeMode.autoTrigger,
                onActionTriggered: () => leftFired = true,
              ),
              child: const Text('cell'),
            ),
          ),
        ),
      ));

      await swipeRight(tester);

      expect(rightFired, isTrue);
      expect(leftFired, isFalse);
    });

    testWidgets(
        'left swipe fires only F4 callbacks; no right-swipe callbacks fire',
        (tester) async {
      bool rightFired = false;
      bool leftFired = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 60,
            child: SwipeActionCell(
              rightSwipe: ProgressiveSwipeConfig(
                stepValue: 1.0,
                maxValue: 10.0,
                onSwipeCompleted: (_) => rightFired = true,
              ),
              leftSwipe: IntentionalSwipeConfig(
                mode: LeftSwipeMode.autoTrigger,
                onActionTriggered: () => leftFired = true,
              ),
              child: const Text('cell'),
            ),
          ),
        ),
      ));

      await swipeLeft(tester);

      expect(leftFired, isTrue);
      expect(rightFired, isFalse);
    });

    testWidgets(
        'reveal panel open → right swipe closes panel; F3 does NOT fire',
        (tester) async {
      bool rightFired = false;
      bool panelClosed = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 60,
            child: SwipeActionCell(
              rightSwipe: ProgressiveSwipeConfig(
                stepValue: 1.0,
                maxValue: 10.0,
                onSwipeCompleted: (_) => rightFired = true,
              ),
              leftSwipe: IntentionalSwipeConfig(
                mode: LeftSwipeMode.reveal,
                actions: [
                  SwipeAction(
                    icon: const Icon(Icons.archive),
                    backgroundColor: const Color(0xFF43A047),
                    foregroundColor: const Color(0xFFFFFFFF),
                    onTap: () {},
                  ),
                ],
                onPanelClosed: () => panelClosed = true,
              ),
              child: const Text('cell'),
            ),
          ),
        ),
      ));

      await swipeLeft(tester);
      expect(find.byType(SwipeActionPanel), findsOneWidget);

      await swipeRight(tester);

      expect(panelClosed, isTrue);
      expect(rightFired, isFalse);
      expect(find.byType(SwipeActionPanel), findsNothing);
    });
  });

  // ─── leftSwipe: null — regression ─────────────────────────────────────────

  group('leftSwipe: null — no regression', () {
    testWidgets('null leftSwipe: right swipe still works', (tester) async {
      bool rightFired = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 60,
            child: SwipeActionCell(
              rightSwipe: ProgressiveSwipeConfig(
                stepValue: 1.0,
                maxValue: 10.0,
                onSwipeCompleted: (_) => rightFired = true,
              ),
              child: const Text('cell'),
            ),
          ),
        ),
      ));

      await swipeRight(tester);
      expect(rightFired, isTrue);
    });

    testWidgets('null leftSwipe: left swipe enters revealed state',
        (tester) async {
      final states = <SwipeState>[];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 60,
            child: SwipeActionCell(
              onStateChanged: (s) => states.add(s),
              child: const Text('cell'),
            ),
          ),
        ),
      ));

      await swipeLeft(tester);

      expect(states, contains(SwipeState.revealed));
    });
  });

  // ─── US4: Destructive Confirm-Expand ───────────────────────────────────────

  group('US4: Destructive Action Confirm-Expand', () {
    testWidgets('destructive button in cell requires two taps', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipe: IntentionalSwipeConfig(
          mode: LeftSwipeMode.reveal,
          actions: [
            SwipeAction(
              icon: const Icon(Icons.delete),
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: const Color(0xFFFFFFFF),
              onTap: () => tapped = true,
              isDestructive: true,
            ),
          ],
        ),
      ));

      await swipeLeft(tester);
      expect(find.byType(SwipeActionPanel), findsOneWidget);

      // First tap — expand.
      await tester.tap(find.byType(GestureDetector).last);
      await tester.pumpAndSettle();
      expect(tapped, isFalse);

      // Second tap — confirm.
      await tester.tap(find.byType(GestureDetector).last);
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  // ─── US6: Haptic Feedback ───────────────────────────────────────────────────

  group('US6: Haptic Feedback', () {
    testWidgets('enableHaptic: true fires light and medium impacts', (tester) async {
      final log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'HapticFeedback.vibrate') {
            log.add(methodCall);
          }
          return null;
        },
      );

      bool triggered = false;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipe: IntentionalSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          enableHaptic: true,
          onActionTriggered: () => triggered = true,
        ),
      ));

      await swipeLeft(tester);

      // Expect at least two haptic calls: light at threshold, medium on action.
      expect(log.length, greaterThanOrEqualTo(2));
      expect(triggered, isTrue);
    });
  });
}

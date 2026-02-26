import "package:flutter/services.dart";
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';
// ignore: implementation_imports
import 'package:swipe_action_cell/src/widget/swipe_action_cell.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

/// Builds a [SwipeActionCell] inside a fixed-width test harness.
Widget buildCell({
  required Widget child,
  LeftSwipeConfig? leftSwipeConfig,
  RightSwipeConfig? rightSwipeConfig,
  SwipeBackgroundBuilder? leftBackground,
  ValueChanged<SwipeState>? onStateChanged,
  bool enabled = true,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 800,
        height: 60,
        child: SwipeActionCell(
          enabled: enabled,
          leftSwipeConfig: leftSwipeConfig,
          rightSwipeConfig: rightSwipeConfig,
          visualConfig: SwipeVisualConfig(leftBackground: leftBackground),
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
  await tester.drag(find.byType(SwipeActionCell), Offset(-distance, 0));
  await tester.pumpAndSettle();
}

/// Simulates a right swipe past the activation threshold.
Future<void> swipeRight(
  WidgetTester tester, {
  double distance = 260.0,
}) async {
  await tester.drag(find.byType(SwipeActionCell), Offset(distance, 0));
  await tester.pumpAndSettle();
}

/// Simulates a fling to the left.
Future<void> flingLeft(WidgetTester tester) async {
  await tester.fling(find.byType(SwipeActionCell), const Offset(-260, 0), 1000);
  await tester.pumpAndSettle();
}

/// Simulates a small left swipe that stays below threshold.
Future<void> swipeLeftBelowThreshold(WidgetTester tester) async {
  final gesture = await tester.startGesture(const Offset(400, 30));
  await tester.pump();
  await gesture.moveBy(const Offset(-20, 0));
  await gesture.up();
  await tester.pumpAndSettle();
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('US1: Auto-Trigger Basic', () {
    testWidgets('above-threshold left swipe fires onActionTriggered', (tester) async {
      bool triggered = false;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          onActionTriggered: () => triggered = true,
        ),
      ));

      await swipeLeft(tester);

      expect(triggered, isTrue);
    });

    testWidgets('fling left triggers action', (tester) async {
      bool triggered = false;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          onActionTriggered: () => triggered = true,
        ),
      ));

      await flingLeft(tester);

      expect(triggered, isTrue);
    });

    testWidgets('below-threshold release does NOT fire onActionTriggered', (tester) async {
      bool triggered = false;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipeConfig: LeftSwipeConfig(
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
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          onSwipeCancelled: () => cancelled = true,
        ),
      ));

      await swipeLeftBelowThreshold(tester);

      expect(cancelled, isTrue);
    });
  });

  group('US2: Reveal Panel Basic', () {
    testWidgets('swipe left past threshold opens panel', (tester) async {
      bool opened = false;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.reveal,
          actions: [
            SwipeAction(
              icon: const Icon(Icons.archive),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              onTap: () {},
            ),
          ],
          onPanelOpened: () => opened = true,
        ),
      ));

      await swipeLeft(tester);

      expect(find.byType(SwipeActionPanel), findsOneWidget);
      expect(opened, isTrue);
    });

    testWidgets('tapping action button triggers onTap and closes panel', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.reveal,
          actions: [
            SwipeAction(
              icon: const Icon(Icons.archive),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              onTap: () => tapped = true,
            ),
          ],
        ),
      ));

      await swipeLeft(tester);
      await tester.tap(find.byIcon(Icons.archive));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      expect(find.byType(SwipeActionPanel), findsNothing);
    });

    testWidgets('tapping cell body while panel open closes panel', (tester) async {
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.reveal,
          actions: [
            SwipeAction(
              icon: const Icon(Icons.archive),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              onTap: () {},
            ),
          ],
        ),
      ));

      await swipeLeft(tester);
      expect(find.byType(SwipeActionPanel), findsOneWidget);

      await tester.tap(find.text('cell'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(SwipeActionPanel), findsNothing);
    });
  });

  group('US3: Post-Action Behavior', () {
    testWidgets('PostActionBehavior.snapBack returns to idle', (tester) async {
      final states = <SwipeState>[];
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        onStateChanged: (s) => states.add(s),
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          postActionBehavior: PostActionBehavior.snapBack,
          onActionTriggered: () {},
        ),
      ));

      await swipeLeft(tester);

      expect(states.last, SwipeState.idle);
    });

    testWidgets('PostActionBehavior.animateOut fires', (tester) async {
      final states = <SwipeState>[];
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        onStateChanged: (s) => states.add(s),
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          postActionBehavior: PostActionBehavior.animateOut,
          onActionTriggered: () {},
        ),
      ));

      await swipeLeft(tester);

      expect(states, contains(SwipeState.animatingOut));
    });

    testWidgets('PostActionBehavior.stay keeps cell open', (tester) async {
      final states = <SwipeState>[];
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        onStateChanged: (s) => states.add(s),
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          postActionBehavior: PostActionBehavior.stay,
          onActionTriggered: () {},
        ),
      ));

      await swipeLeft(tester);

      expect(states.last, SwipeState.revealed);
    });
  });

  group('US5: Confirmation Gate', () {
    testWidgets('requireConfirmation: true enters revealed state instead of firing', (tester) async {
      bool triggered = false;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          requireConfirmation: true,
          onActionTriggered: () => triggered = true,
        ),
      ));

      await swipeLeft(tester);

      expect(triggered, isFalse);
    });

    testWidgets('confirmation: second swipe triggers action', (tester) async {
      int triggeredCount = 0;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          requireConfirmation: true,
          onActionTriggered: () => triggeredCount++,
        ),
      ));

      await swipeLeft(tester);
      expect(triggeredCount, 0);

      await swipeLeft(tester);
      expect(triggeredCount, 1);
    });

    testWidgets('confirmation: background tap triggers action', (tester) async {
      bool triggered = false;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftBackground: (_, __) => const Text('BG'),
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          requireConfirmation: true,
          onActionTriggered: () => triggered = true,
        ),
      ));

      await swipeLeft(tester);
      expect(triggered, isFalse);

      await tester.tap(find.text('BG'));
      await tester.pumpAndSettle();
      expect(triggered, isTrue);
    });

    testWidgets('confirmation: body tap cancels action', (tester) async {
      bool triggered = false;
      bool cancelled = false;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          requireConfirmation: true,
          onActionTriggered: () => triggered = true,
          onSwipeCancelled: () => cancelled = true,
        ),
      ));

      await swipeLeft(tester);
      await tester.tap(find.text('cell'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(triggered, isFalse);
      expect(cancelled, isTrue);
    });
  });

  group('US7: Coexistence with F3 (rightSwipe + leftSwipe)', () {
    testWidgets('right swipe still works with leftSwipe configured', (tester) async {
      double? value;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.autoTrigger,
          onActionTriggered: () {},
        ),
        rightSwipeConfig: RightSwipeConfig(
          stepValue: 20,
          maxValue: 100,
          onSwipeCompleted: (v) => value = v,
        ),
      ));

      await swipeRight(tester);
      expect(value, 20.0);
    });

    testWidgets('reveal panel open -> right swipe closes panel; F3 does NOT fire', (tester) async {
      double? value;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.reveal,
          actions: [
            SwipeAction(icon: const Icon(Icons.abc), backgroundColor: Colors.red, foregroundColor: Colors.white, onTap: () {}),
          ],
        ),
        rightSwipeConfig: RightSwipeConfig(
          stepValue: 20,
          maxValue: 100,
          onSwipeCompleted: (v) => value = v,
        ),
      ));

      await swipeLeft(tester);
      expect(find.byType(SwipeActionPanel), findsOneWidget);

      await swipeRight(tester);
      expect(find.byType(SwipeActionPanel), findsNothing);
      expect(value, isNull);
    });
  });

  group('leftSwipeConfig: null — no regression', () {
    testWidgets('null leftSwipeConfig: right swipe still works', (tester) async {
      double? value;
      await tester.pumpWidget(buildCell(
        child: const Text('cell'),
        leftSwipeConfig: null,
        rightSwipeConfig: RightSwipeConfig(
          stepValue: 20,
          maxValue: 100,
          onSwipeCompleted: (v) => value = v,
        ),
      ));

      await swipeRight(tester);
      expect(value, 20.0);
    });

    testWidgets('null leftSwipeConfig: left swipe enters revealed state', (tester) async {
      final states = <SwipeState>[];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
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
        leftSwipeConfig: LeftSwipeConfig(
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
        leftSwipeConfig: LeftSwipeConfig(
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

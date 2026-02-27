import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _buildCellInProvider({
  SwipeController? controller,
  Key? cellKey,
  SwipeGroupController? groupController,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: SwipeControllerProvider(
      groupController: groupController,
      child: SizedBox(
        width: 400,
        height: 60,
        child: SwipeActionCell(
          key: cellKey,
          controller: controller,
          leftSwipeConfig: LeftSwipeConfig(
            mode: LeftSwipeMode.reveal,
            actions: [
              SwipeAction(
                icon: const Icon(IconData(0xe547, fontFamily: 'MaterialIcons')),
                label: 'Delete',
                backgroundColor: const Color(0xFFFF0000),
                foregroundColor: const Color(0xFFFFFFFF),
                onTap: () {},
              ),
            ],
          ),
          child: const SizedBox(height: 60, child: Text('Item')),
        ),
      ),
    ),
  );
}

Widget _buildTwoCellsInProvider({
  Key? cellAKey,
  Key? cellBKey,
  SwipeGroupController? groupController,
}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: SwipeControllerProvider(
      groupController: groupController,
      child: SizedBox(
        width: 400,
        height: 120,
        child: Column(
          children: [
            SizedBox(
              height: 60,
              child: SwipeActionCell(
                key: cellAKey,
                leftSwipeConfig: LeftSwipeConfig(
                  mode: LeftSwipeMode.reveal,
                  actions: [
                    SwipeAction(
                      icon: const Icon(
                          IconData(0xe547, fontFamily: 'MaterialIcons')),
                      label: 'Delete A',
                      backgroundColor: const Color(0xFFFF0000),
                      foregroundColor: const Color(0xFFFFFFFF),
                      onTap: () {},
                    ),
                  ],
                ),
                child: const SizedBox(height: 60, child: Text('A')),
              ),
            ),
            SizedBox(
              height: 60,
              child: SwipeActionCell(
                key: cellBKey,
                leftSwipeConfig: LeftSwipeConfig(
                  mode: LeftSwipeMode.reveal,
                  actions: [
                    SwipeAction(
                      icon: const Icon(
                          IconData(0xe547, fontFamily: 'MaterialIcons')),
                      label: 'Delete B',
                      backgroundColor: const Color(0xFFFF0000),
                      foregroundColor: const Color(0xFFFFFFFF),
                      onTap: () {},
                    ),
                  ],
                ),
                child: const SizedBox(height: 60, child: Text('B')),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  // ── T011: US4 — SwipeControllerProvider widget tests ─────────────────────

  group('SwipeControllerProvider (US4)', () {
    // (a) cells without explicit controller auto-register when mounted inside provider
    testWidgets('cells auto-register when mounted inside provider', (tester) async {
      await tester.pumpWidget(_buildCellInProvider());
      await tester.pump();
      // If auto-registration crashed, the test would throw.
      expect(tester.takeException(), isNull);
    });

    // (b) accordion via programmatic open: open A → open B → A closes
    testWidgets('accordion: open cell A then open B causes A to close',
        (tester) async {
      final controllerA = SwipeController();
      final controllerB = SwipeController();
      addTearDown(controllerA.dispose);
      addTearDown(controllerB.dispose);

      final keyA = GlobalKey();
      final keyB = GlobalKey();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SwipeControllerProvider(
            child: SizedBox(
              width: 400,
              height: 120,
              child: Column(
                children: [
                  SizedBox(
                    height: 60,
                    child: SwipeActionCell(
                      key: keyA,
                      controller: controllerA,
                      leftSwipeConfig: LeftSwipeConfig(
                        mode: LeftSwipeMode.reveal,
                        actions: [
                          SwipeAction(
                            icon: const Icon(
                                IconData(0xe547, fontFamily: 'MaterialIcons')),
                            label: 'Delete',
                            backgroundColor: const Color(0xFFFF0000),
                            foregroundColor: const Color(0xFFFFFFFF),
                            onTap: () {},
                          ),
                        ],
                      ),
                      child: const Text('A'),
                    ),
                  ),
                  SizedBox(
                    height: 60,
                    child: SwipeActionCell(
                      key: keyB,
                      controller: controllerB,
                      leftSwipeConfig: LeftSwipeConfig(
                        mode: LeftSwipeMode.reveal,
                        actions: [
                          SwipeAction(
                            icon: const Icon(
                                IconData(0xe547, fontFamily: 'MaterialIcons')),
                            label: 'Delete',
                            backgroundColor: const Color(0xFFFF0000),
                            foregroundColor: const Color(0xFFFFFFFF),
                            onTap: () {},
                          ),
                        ],
                      ),
                      child: const Text('B'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Open cell A.
      controllerA.openLeft();
      await tester.pumpAndSettle();
      expect(controllerA.isOpen, isTrue);

      // Open cell B — A should accordion-close.
      controllerB.openLeft();
      await tester.pumpAndSettle();

      expect(controllerB.isOpen, isTrue);
      expect(controllerA.isOpen, isFalse,
          reason: 'Cell A should be closed when cell B opens (accordion)');
    });

    // (c) cell unregisters on dispose — no crash when group calls closeAll after
    testWidgets('cell unregisters on dispose — group.closeAll() is safe after',
        (tester) async {
      final group = SwipeGroupController();
      addTearDown(group.dispose);

      bool showCell = true;
      late StateSetter outerSetState;

      await tester.pumpWidget(
        StatefulBuilder(builder: (ctx, setState) {
          outerSetState = setState;
          return Directionality(
            textDirection: TextDirection.ltr,
            child: SwipeControllerProvider(
              groupController: group,
              child: SizedBox(
                width: 400,
                height: 60,
                child: showCell
                    ? SwipeActionCell(
                        leftSwipeConfig: LeftSwipeConfig(
                          mode: LeftSwipeMode.reveal,
                          actions: [
                            SwipeAction(
                              icon: const Icon(IconData(0xe547,
                                  fontFamily: 'MaterialIcons')),
                              label: 'Delete',
                              backgroundColor: const Color(0xFFFF0000),
                              foregroundColor: const Color(0xFFFFFFFF),
                              onTap: () {},
                            ),
                          ],
                        ),
                        child: const Text('Item'),
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          );
        }),
      );
      await tester.pump();

      // Remove the cell — it should unregister from group.
      outerSetState(() => showCell = false);
      await tester.pump();

      // Calling closeAll on the group after cell disposal should not crash.
      expect(() => group.closeAll(), returnsNormally);
      expect(tester.takeException(), isNull);
    });

    // (d) no provider in tree → SwipeActionCell works normally
    testWidgets('SwipeActionCell works normally when no provider is in the tree',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 400,
            height: 60,
            child: SwipeActionCell(
              leftSwipeConfig: LeftSwipeConfig(
                mode: LeftSwipeMode.reveal,
                actions: [
                  SwipeAction(
                    icon: const Icon(
                        IconData(0xe547, fontFamily: 'MaterialIcons')),
                    label: 'Delete',
                    backgroundColor: const Color(0xFFFF0000),
                    foregroundColor: const Color(0xFFFFFFFF),
                    onTap: () {},
                  ),
                ],
              ),
              child: const Text('Item'),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    // (e) cell with explicit controller registers that controller — consumer retains access
    testWidgets(
        'cell with explicit controller registers it in provider group — consumer retains programmatic access',
        (tester) async {
      final controller = SwipeController();
      addTearDown(controller.dispose);

      await tester.pumpWidget(_buildCellInProvider(controller: controller));
      await tester.pump();

      // Programmatic control still works.
      controller.openLeft();
      await tester.pumpAndSettle();

      expect(controller.isOpen, isTrue);
    });

    // (f) explicit groupController passed to provider is used
    testWidgets('explicit groupController passed to provider is used', (tester) async {
      final group = SwipeGroupController();
      addTearDown(group.dispose);

      final controllerA = SwipeController();
      final controllerB = SwipeController();
      addTearDown(controllerA.dispose);
      addTearDown(controllerB.dispose);

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SwipeControllerProvider(
            groupController: group,
            child: SizedBox(
              width: 400,
              height: 120,
              child: Column(
                children: [
                  SizedBox(
                    height: 60,
                    child: SwipeActionCell(
                      controller: controllerA,
                      leftSwipeConfig: LeftSwipeConfig(
                        mode: LeftSwipeMode.reveal,
                        actions: [
                          SwipeAction(
                            icon: const Icon(
                                IconData(0xe547, fontFamily: 'MaterialIcons')),
                            label: 'Delete',
                            backgroundColor: const Color(0xFFFF0000),
                            foregroundColor: const Color(0xFFFFFFFF),
                            onTap: () {},
                          ),
                        ],
                      ),
                      child: const Text('A'),
                    ),
                  ),
                  SizedBox(
                    height: 60,
                    child: SwipeActionCell(
                      controller: controllerB,
                      leftSwipeConfig: LeftSwipeConfig(
                        mode: LeftSwipeMode.reveal,
                        actions: [
                          SwipeAction(
                            icon: const Icon(
                                IconData(0xe547, fontFamily: 'MaterialIcons')),
                            label: 'Delete',
                            backgroundColor: const Color(0xFFFF0000),
                            foregroundColor: const Color(0xFFFFFFFF),
                            onTap: () {},
                          ),
                        ],
                      ),
                      child: const Text('B'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // Open A
      controllerA.openLeft();
      await tester.pumpAndSettle();

      // group.closeAll() should close A.
      group.closeAll();
      await tester.pumpAndSettle();

      expect(controllerA.isOpen, isFalse);
    });
  });
}

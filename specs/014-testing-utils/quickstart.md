# Quickstart: Consumer Testing Utilities (F015)

**Branch**: `014-testing-utils` | **Date**: 2026-03-01

These scenarios map directly to the acceptance criteria in `spec.md`. All tests use only `testing.dart` — no additional imports required.

---

## Scenario 1 — Swipe Gesture Simulation (US1)

### Setup
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/testing.dart';

// Under test: SwipeActionCell.delete
```

### Test
```dart
testWidgets('US1: swipeLeft triggers undo flow', (tester) async {
  bool deleted = false;

  await tester.pumpWidget(SwipeTestHarness(
    child: SwipeActionCell.delete(
      child: const ListTile(title: Text('Item')),
      onDeleted: () => deleted = true,
    ),
  ));

  // Default ratio = 0.5 (50% of cell width)
  await SwipeTester.swipeLeft(tester, find.byType(SwipeActionCell));

  // Undo strip visible — deletion NOT fired yet
  expect(deleted, isFalse);
  tester.expectRevealed(find.byType(SwipeActionCell)); // optional: check state

  // Custom ratio
  await SwipeTester.swipeLeft(
    tester, find.byType(SwipeActionCell), ratio: 0.9,
  );
});
```

### What to verify
- [ ] `swipeLeft` with default `ratio: 0.5` completes without error
- [ ] `swipeRight` with `ratio: 0.8` triggers right-swipe action
- [ ] `flingLeft(velocity: 1200)` triggers the cell's left-swipe autoTrigger action
- [ ] `swipeLeft` on a cell with no `leftSwipeConfig` → no error, no action
- [ ] Same `swipeLeft(ratio: 0.5)` called twice → identical outcome (deterministic)

---

## Scenario 2 — Mid-Drag Inspection with `dragTo` (US1)

### Test
```dart
testWidgets('US1: dragTo allows mid-drag progress inspection', (tester) async {
  await tester.pumpWidget(SwipeTestHarness(
    child: SwipeActionCell(
      rightSwipeConfig: RightSwipeConfig(onSwipeCompleted: (_) {}),
      child: SizedBox(width: 400, height: 56, child: Text('item')),
    ),
  ));

  final rect = tester.getRect(find.byType(SwipeActionCell));
  // Drag to 50% of cell width rightward
  await SwipeTester.dragTo(
    tester,
    find.byType(SwipeActionCell),
    Offset(rect.width * 0.5, 0),
  );

  // Mid-drag: state should be dragging
  tester.expectSwipeState(
    find.byType(SwipeActionCell), SwipeState.dragging,
  );
  tester.expectProgress(find.byType(SwipeActionCell), 0.5, tolerance: 0.05);
});
```

### What to verify
- [ ] `dragTo(Offset(-100, 0))` → cell is 100px to the left without settling
- [ ] State is `SwipeState.dragging` immediately after `dragTo`
- [ ] `expectProgress` passes with tolerance 0.05 at mid-drag position
- [ ] Zero-offset `dragTo(Offset.zero)` → no crash, no state change

---

## Scenario 3 — `tapAction` on Revealed Cell (US1)

### Test
```dart
testWidgets('US1: tapAction taps correct action button', (tester) async {
  String? tapped;

  await tester.pumpWidget(SwipeTestHarness(
    child: SwipeActionCell(
      leftSwipeConfig: LeftSwipeConfig(
        mode: LeftSwipeMode.reveal,
        actions: [
          SwipeAction(
            icon: const Icon(Icons.reply),
            backgroundColor: Colors.blue,
            onTap: () => tapped = 'reply',
          ),
          SwipeAction(
            icon: const Icon(Icons.more_horiz),
            backgroundColor: Colors.grey,
            onTap: () => tapped = 'more',
          ),
        ],
      ),
      child: const ListTile(title: Text('Mail')),
    ),
  ));

  // Reveal the panel first
  await SwipeTester.swipeLeft(tester, find.byType(SwipeActionCell), ratio: 0.9);
  tester.expectRevealed(find.byType(SwipeActionCell));

  // Tap action at index 1
  await SwipeTester.tapAction(tester, find.byType(SwipeActionCell), 1);
  expect(tapped, 'more');
});
```

### What to verify
- [ ] `tapAction(index: 0)` fires the first action's `onTap`
- [ ] `tapAction(index: 1)` fires the second action's `onTap`
- [ ] `tapAction` when cell is NOT revealed → immediate test failure with descriptive message
- [ ] `tapAction(index: 99)` (out of bounds) → test failure with bounds message

---

## Scenario 4 — State Assertion Extensions (US2)

### Test
```dart
testWidgets('US2: expectSwipeState provides clear failure messages', (tester) async {
  await tester.pumpWidget(SwipeTestHarness(
    child: SwipeActionCell(
      leftSwipeConfig: LeftSwipeConfig(
        mode: LeftSwipeMode.reveal,
        actions: [SwipeAction(
          icon: const Icon(Icons.delete),
          backgroundColor: Colors.red,
          onTap: () {},
        )],
      ),
      child: const ListTile(title: Text('Item')),
    ),
  ));

  // Idle at start
  tester.expectIdle(find.byType(SwipeActionCell));

  // After swipe
  await SwipeTester.swipeLeft(tester, find.byType(SwipeActionCell), ratio: 0.9);
  tester.expectRevealed(find.byType(SwipeActionCell));
  tester.expectSwipeState(find.byType(SwipeActionCell), SwipeState.revealed);
});
```

### What to verify
- [ ] `expectIdle` passes when cell is at rest
- [ ] `expectRevealed` passes after a completing left swipe to reveal
- [ ] `expectIdle` fails with "Expected SwipeState.idle but found SwipeState.revealed" when cell is open
- [ ] `expectProgress(0.0, tolerance: 0.001)` passes at idle
- [ ] `expectProgress(0.5, tolerance: 0.05)` passes during a 50% drag
- [ ] `expectProgress(0.0)` fails at 50% drag with actual value shown in message

---

## Scenario 5 — MockSwipeController Call Tracking (US3)

### Test
```dart
testWidgets('US3: MockSwipeController tracks method calls', (tester) async {
  final mock = MockSwipeController();

  await tester.pumpWidget(SwipeTestHarness(
    child: MyComponent(controller: mock), // Component under test
  ));

  // Simulate the component calling openLeft
  mock.openLeft(); // called externally as if widget did it
  expect(mock.openLeftCallCount, 1);
  expect(mock.openCallCount, 1); // combined count

  mock.openRight();
  expect(mock.openRightCallCount, 1);
  expect(mock.openCallCount, 2);

  mock.close();
  expect(mock.closeCallCount, 1);

  mock.undo();
  expect(mock.undoCallCount, 1);

  // Reset
  mock.resetCalls();
  expect(mock.openCallCount, 0);
  expect(mock.closeCallCount, 0);
});
```

### What to verify
- [ ] Each method's call count starts at 0
- [ ] Calling a method N times sets its count to N
- [ ] `openCallCount == openLeftCallCount + openRightCallCount`
- [ ] `resetCalls()` zeroes all counts without affecting `stubbedState`
- [ ] `stubbedState` change is reflected immediately from `currentState` getter
- [ ] No mockito import needed — test compiles with only `flutter_test` + `testing.dart`

---

## Scenario 6 — SwipeTestHarness (US4)

### Test
```dart
testWidgets('US4: SwipeTestHarness provides working test scaffold', (tester) async {
  // Minimal: no configuration — uses all defaults
  await tester.pumpWidget(SwipeTestHarness(
    child: SwipeActionCell.delete(
      child: const ListTile(title: Text('Item')),
      onDeleted: () {},
    ),
  ));

  // Renders without "No Material ancestor" or "No Directionality" errors
  expect(find.text('Item'), findsOneWidget);
});

testWidgets('US4: RTL layout via textDirection parameter', (tester) async {
  await tester.pumpWidget(SwipeTestHarness(
    textDirection: TextDirection.rtl,
    child: SwipeActionCell.delete(
      child: const ListTile(title: Text('عنصر')),
      onDeleted: () {},
    ),
  ));

  // In RTL, physical right swipe is the delete action
  // (semantics reversed by F008)
  await SwipeTester.swipeRight(tester, find.byType(SwipeActionCell));
  tester.expectSwipeState(
    find.byType(SwipeActionCell), SwipeState.animatingOut,
  );
});
```

### What to verify
- [ ] Pumps without any ancestor-missing errors
- [ ] Defaults to LTR, English, 390×844
- [ ] `textDirection: rtl` correctly reverses swipe semantics
- [ ] `screenSize: Size(414, 896)` sets `MediaQuery.of(context).size`
- [ ] Pumping without `MaterialApp` ancestor does not throw

---

## Scenario 7 — Single Import (SC-014-002)

### What to verify

The following test file uses all four utility components with a single import:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/testing.dart'; // ← ONLY import needed

void main() {
  testWidgets('all utilities from one import', (tester) async {
    final mock = MockSwipeController();                     // US3
    await tester.pumpWidget(SwipeTestHarness(              // US4
      child: SwipeActionCell.delete(
        child: const ListTile(title: Text('item')),
        onDeleted: () {},
      ),
    ));
    await SwipeTester.swipeLeft(                           // US1
        tester, find.byType(SwipeActionCell));
    tester.expectRevealed(find.byType(SwipeActionCell));   // US2
  });
}
```

- [ ] File compiles with only `flutter_test` and `testing.dart` imported
- [ ] All four utility types are accessible
- [ ] `SwipeState`, `SwipeController`, `SwipeActionCellState` are also available from `testing.dart`

---

## Scenario 8 — 10-Line Delete Test (SC-014-001)

```dart
testWidgets('delete: onDeleted fires after undo expires (10 lines)', (tester) async {
  bool deleted = false;
  await tester.pumpWidget(SwipeTestHarness(child: SwipeActionCell.delete(
    child: const ListTile(title: Text('x')), onDeleted: () => deleted = true)));
  await SwipeTester.swipeLeft(tester, find.byType(SwipeActionCell));
  expect(deleted, isFalse);                           // undo strip shown
  await tester.pump(const Duration(seconds: 6));      // undo window expires
  await tester.pumpAndSettle();
  expect(deleted, isTrue);                            // deletion fired
});
```

### What to verify
- [ ] This test body is 10 lines or fewer (counting meaningful non-blank lines)
- [ ] Test passes with correct behavior

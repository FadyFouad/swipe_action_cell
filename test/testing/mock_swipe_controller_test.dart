import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:swipe_action_cell/swipe_action_cell.dart";
import "package:swipe_action_cell/src/testing/mock_swipe_controller.dart";

class MyComponent extends StatelessWidget {
  final SwipeController controller;
  const MyComponent({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => controller.openLeft(),
      child: const Text("Open"),
    );
  }
}

void main() {
  group("MockSwipeController US3", () {
    test("initial counts are zero", () {
      final mock = MockSwipeController();
      expect(mock.openLeftCallCount, 0);
      expect(mock.openRightCallCount, 0);
      expect(mock.openCallCount, 0);
      expect(mock.closeCallCount, 0);
      expect(mock.resetProgressCallCount, 0);
      expect(mock.undoCallCount, 0);
    });

    test("methods increment counts and calculate openCallCount correctly", () {
      final mock = MockSwipeController();
      mock.openLeft();
      mock.openRight();
      mock.openRight();
      mock.close();
      mock.resetProgress();
      mock.undo();

      expect(mock.openLeftCallCount, 1);
      expect(mock.openRightCallCount, 2);
      expect(mock.openCallCount, 3);
      expect(mock.closeCallCount, 1);
      expect(mock.resetProgressCallCount, 1);
      expect(mock.undoCallCount, 1);
    });

    test("resetCalls zeroes all counts without changing stubbedState", () {
      final mock = MockSwipeController();
      mock.openLeft();
      mock.stubbedState = SwipeState.revealed;
      mock.resetCalls();

      expect(mock.openLeftCallCount, 0);
      expect(mock.openCallCount, 0);
      expect(mock.currentState, SwipeState.revealed);
    });

    test("stubbed values are returned by getters", () {
      final mock = MockSwipeController();
      expect(mock.currentState, SwipeState.idle);
      expect(mock.currentProgress, 0.0);

      mock.stubbedState = SwipeState.dragging;
      mock.stubbedProgress = 0.5;

      expect(mock.currentState, SwipeState.dragging);
      expect(mock.currentProgress, 0.5);
    });

    test("undo returns false", () {
      final mock = MockSwipeController();
      expect(mock.undo(), isFalse);
    });

    testWidgets("works injected into widget (no mockito)", (tester) async {
      final mock = MockSwipeController();
      await tester.pumpWidget(
          MaterialApp(home: Scaffold(body: MyComponent(controller: mock))));
      await tester.tap(find.text("Open"));
      expect(mock.openLeftCallCount, 1);
      expect(mock.openCallCount, 1);
    });
  });
}

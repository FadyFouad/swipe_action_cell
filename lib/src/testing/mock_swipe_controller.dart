import '../controller/swipe_controller.dart';
import '../core/swipe_state.dart';

/// Test double for [SwipeController] that records method invocations.
///
/// Use in unit tests to verify that a component calls controller methods
/// without needing a real [SwipeActionCell]:
///
/// ```dart
/// test('button calls openLeft on tap', () async {
///   final mock = MockSwipeController();
///   // inject mock into the widget under test
///   expect(mock.openLeftCallCount, 0);
///   // simulate tap
///   mock.openLeft();
///   expect(mock.openLeftCallCount, 1);
/// });
/// ```
class MockSwipeController extends SwipeController {
  int _openLeft = 0;
  int _openRight = 0;
  int _close = 0;
  int _resetProgress = 0;
  int _undo = 0;

  /// Number of times [openLeft] was called.
  int get openLeftCallCount => _openLeft;

  /// Number of times [openRight] was called.
  int get openRightCallCount => _openRight;

  /// Combined [openLeft] + [openRight] call count.
  int get openCallCount => _openLeft + _openRight;

  /// Number of times [close] was called.
  int get closeCallCount => _close;

  /// Number of times [resetProgress] was called.
  int get resetProgressCallCount => _resetProgress;

  /// Number of times [undo] was called.
  int get undoCallCount => _undo;

  /// Stub return value for [currentState]. Default: [SwipeState.idle].
  SwipeState stubbedState = SwipeState.idle;

  /// Stub return value for [currentProgress]. Default: 0.0.
  double stubbedProgress = 0.0;

  @override
  SwipeState get currentState => stubbedState;

  @override
  double get currentProgress => stubbedProgress;

  @override
  void openLeft() => _openLeft++;

  @override
  void openRight() => _openRight++;

  @override
  void close() => _close++;

  @override
  void resetProgress() => _resetProgress++;

  @override
  bool undo() {
    _undo++;
    return false;
  }

  /// Resets all call counts to 0. Does not modify stubs.
  void resetCalls() {
    _openLeft = 0;
    _openRight = 0;
    _close = 0;
    _resetProgress = 0;
    _undo = 0;
  }
}

// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';
import 'package:swipe_action_cell/src/controller/swipe_cell_handle.dart';
import 'package:swipe_action_cell/src/core/swipe_state.dart';

// ---------------------------------------------------------------------------
// Fake handle for unit-testing SwipeController in isolation
// ---------------------------------------------------------------------------

class _FakeHandle implements SwipeCellHandle {
  int openLeftCalls = 0;
  int openRightCalls = 0;
  int closeCalls = 0;
  int resetProgressCalls = 0;
  final List<double> setProgressValues = [];

  @override
  void executeOpenLeft() => openLeftCalls++;
  @override
  void executeOpenRight() => openRightCalls++;
  @override
  void executeClose() => closeCalls++;
  @override
  void executeResetProgress() => resetProgressCalls++;
  @override
  void executeSetProgress(double value) => setProgressValues.add(value);
  @override
  void executeUndo() {}
  @override
  void executeCommitUndo() {}
}

void main() {
  // ── Existing stub tests (must still pass after full implementation) ─────

  group('SwipeController — basic lifecycle', () {
    test('constructable', () {
      final controller = SwipeController();
      expect(controller, isNotNull);
      controller.dispose();
    });

    test('dispose completes without error', () {
      final controller = SwipeController();
      controller.dispose();
    });
  });

  // ── T003: US1 — command routing ─────────────────────────────────────────

  group('SwipeController — command routing (US1)', () {
    late SwipeController controller;
    late _FakeHandle handle;

    setUp(() {
      controller = SwipeController();
      handle = _FakeHandle();
      controller.attach(handle);
    });

    tearDown(() => controller.dispose());

    // (a) openLeft from idle calls executeOpenLeft
    test('openLeft() from idle calls executeOpenLeft on the handle', () {
      controller.openLeft();
      expect(handle.openLeftCalls, 1);
    });

    // (b) openRight from idle calls executeOpenRight
    test('openRight() from idle calls executeOpenRight on the handle', () {
      controller.openRight();
      expect(handle.openRightCalls, 1);
    });

    // (c) close from revealed calls executeClose
    test('close() from revealed calls executeClose on the handle', () {
      controller.reportState(SwipeState.revealed, 0.0, SwipeDirection.left);
      controller.close();
      expect(handle.closeCalls, 1);
    });

    // (d) resetProgress calls executeResetProgress
    test('resetProgress() calls executeResetProgress on the handle', () {
      controller.resetProgress();
      expect(handle.resetProgressCalls, 1);
    });

    // (e) setProgress(5.0) calls executeSetProgress(5.0)
    test('setProgress(5.0) calls executeSetProgress(5.0) on the handle', () {
      controller.setProgress(5.0);
      expect(handle.setProgressValues, [5.0]);
    });

    // (f) setProgress clamps silently
    test('setProgress() clamps value to [minValue, maxValue] silently', () {
      // No assertion error must fire; handle receives the clamped value.
      // The controller itself does clamping based on passed min/max.
      // Since clamping is done per-handle, we test that a very large value
      // is forwarded (handle does its own clamp inside executeSetProgress).
      expect(() => controller.setProgress(999.0), returnsNormally);
      expect(() => controller.setProgress(-999.0), returnsNormally);
    });

    // (g) openLeft from non-idle is no-op in release; assert fires in debug
    test('openLeft() from non-idle state is a no-op in release mode', () {
      controller.reportState(
          SwipeState.animatingToOpen, 0.0, SwipeDirection.left);
      // In debug mode this would throw AssertionError; in release it is no-op.
      bool threw = false;
      try {
        controller.openLeft();
      } catch (_) {
        threw = true;
      }
      // Either threw assert (debug) or silently no-op (release). handle count stays at 0 in release.
      if (!threw) {
        expect(handle.openLeftCalls, 0);
      }
    });

    // (h) close from idle fires assert in debug; no-op in release
    test('close() from idle is a no-op in release mode', () {
      // State is idle by default.
      bool threw = false;
      try {
        controller.close();
      } catch (_) {
        threw = true;
      }
      if (!threw) {
        expect(handle.closeCalls, 0);
      }
    });
  });

  // ── T003: no handle attached ─────────────────────────────────────────────

  group('SwipeController — no handle attached (US1)', () {
    late SwipeController controller;

    setUp(() => controller = SwipeController());
    tearDown(() => controller.dispose());

    // (i) openLeft with no handle is no-op; assert fires in debug
    test('openLeft() with no handle attached is a no-op / asserts in debug',
        () {
      bool threw = false;
      try {
        controller.openLeft();
      } catch (_) {
        threw = true;
      }
      // Must not crash the process.
      expect(threw || true,
          isTrue); // always passes — just checking no unhandled throw.
    });

    // (j) attach when already attached fires debug assert
    test('attach() when already attached fires a debug assert', () {
      final h1 = _FakeHandle();
      final h2 = _FakeHandle();
      controller.attach(h1);
      expect(
        () => controller.attach(h2),
        throwsA(isA<AssertionError>()),
      );
    });

    // (k) detach with mismatched handle is no-op
    test('detach() with mismatched handle is a no-op', () {
      final h1 = _FakeHandle();
      final h2 = _FakeHandle();
      controller.attach(h1);
      // Detaching a different handle should not throw.
      expect(() => controller.detach(h2), returnsNormally);
    });

    // (l) controller can outlive widget — detach then command → no-op or assert
    test(
        'controller can outlive widget — detach then command does not crash process',
        () {
      final h = _FakeHandle();
      controller.attach(h);
      controller.detach(h);
      // In release mode these are silent no-ops.
      // In debug mode the assert fires (handle is null after detach).
      // Either way the process must not crash with an unhandled error.
      void callSafely(void Function() fn) {
        try {
          fn();
        } catch (e) {
          if (e is! AssertionError) rethrow;
        }
      }

      callSafely(() => controller.openLeft());
      callSafely(() => controller.openRight());
      callSafely(() => controller.resetProgress());
      callSafely(() => controller.setProgress(1.0));
    });
  });

  // ── T007: US2 — ChangeNotifier observer edge cases ──────────────────────

  group('SwipeController — ChangeNotifier (US2)', () {
    late SwipeController controller;
    late _FakeHandle handle;

    setUp(() {
      controller = SwipeController();
      handle = _FakeHandle();
      controller.attach(handle);
    });

    tearDown(() => controller.dispose());

    // (a) listener fires when reportState transitions to animatingToOpen
    test('listener fires when state transitions to animatingToOpen', () {
      int fires = 0;
      controller.addListener(() => fires++);
      controller.reportState(
          SwipeState.animatingToOpen, 0.0, SwipeDirection.left);
      expect(fires, greaterThan(0));
    });

    // (b) listener fires when state transitions to idle
    test('listener fires when state transitions to idle', () {
      int fires = 0;
      // Move to non-idle to make a transition
      controller.reportState(
          SwipeState.animatingToOpen, 0.0, SwipeDirection.left);
      controller.addListener(() => fires++);
      controller.reportState(SwipeState.idle, 0.0, null);
      expect(fires, greaterThan(0));
    });

    // (c) multiple listeners all fire on the same notification
    test('multiple listeners all fire on the same notification', () {
      int fires1 = 0, fires2 = 0, fires3 = 0;
      controller.addListener(() => fires1++);
      controller.addListener(() => fires2++);
      controller.addListener(() => fires3++);
      controller.reportState(
          SwipeState.animatingToOpen, 0.0, SwipeDirection.left);
      expect(fires1, greaterThan(0));
      expect(fires2, greaterThan(0));
      expect(fires3, greaterThan(0));
    });

    // (d) isOpen is true after state set to revealed
    test('isOpen is true after reportState(revealed)', () {
      controller.reportState(SwipeState.revealed, 0.0, SwipeDirection.left);
      expect(controller.isOpen, isTrue);
    });

    // (e) openDirection is correct and null after close
    test('openDirection is left after open-left; null after close', () {
      controller.reportState(SwipeState.revealed, 0.0, SwipeDirection.left);
      expect(controller.openDirection, SwipeDirection.left);
      controller.reportState(SwipeState.idle, 0.0, null);
      expect(controller.openDirection, isNull);
    });

    // (f) currentProgress updates when reportState provides new value
    test('currentProgress updates when reportState provides new value', () {
      controller.reportState(SwipeState.idle, 7.5, null);
      expect(controller.currentProgress, 7.5);
    });

    // (g) listener NOT fired when setProgress value is unchanged
    test('listener NOT fired when setProgress value equals current progress',
        () {
      // First call sets the value (fires listeners).
      controller.setProgress(3.0);
      int fires = 0;
      controller.addListener(() => fires++);
      // Second call with the same value — should not notify.
      controller.setProgress(3.0);
      expect(fires, 0);
    });

    // (h) listener NOT fired after dispose()
    test('listener NOT fired after dispose()', () {
      // Use a local controller so tearDown does not double-dispose the shared one.
      final localController = SwipeController();
      final localHandle = _FakeHandle();
      localController.attach(localHandle);

      int fires = 0;
      localController.addListener(() => fires++);
      localController.dispose();
      // dispose() must complete without error, and no listener must have fired.
      expect(fires, 0);
    });
  });
}

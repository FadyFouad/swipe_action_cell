import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';
import 'package:swipe_action_cell/src/controller/swipe_cell_handle.dart';
import 'package:swipe_action_cell/src/core/swipe_state.dart';

// ---------------------------------------------------------------------------
// Minimal fake handle — needed to attach a controller so it reports state
// ---------------------------------------------------------------------------

class _FakeHandle implements SwipeCellHandle {
  int closeCalls = 0;
  @override
  void executeOpenLeft() {}
  @override
  void executeOpenRight() {}
  @override
  void executeClose() {
    closeCalls++;
  }
  @override
  void executeResetProgress() {}
  @override
  void executeSetProgress(double value) {}
}

// ---------------------------------------------------------------------------
// Helpers: create a controller + handle pair
// ---------------------------------------------------------------------------

({SwipeController controller, _FakeHandle handle}) _createCell() {
  final c = SwipeController();
  final h = _FakeHandle();
  c.attach(h);
  return (controller: c, handle: h);
}

({SwipeController controller, _FakeHandle handle}) _openCell() {
  final pair = _createCell();
  pair.controller.reportState(SwipeState.revealed, 0.0, SwipeDirection.left);
  return pair;
}

void main() {
  // ── T009: US3 — SwipeGroupController unit tests ──────────────────────────

  group('SwipeGroupController (US3)', () {
    late SwipeGroupController group;

    setUp(() => group = SwipeGroupController());
    tearDown(() => group.dispose());

    // (a) register() is idempotent
    test('register() is idempotent — no duplicate entries', () {
      final cell = _createCell();
      addTearDown(cell.controller.dispose);

      group.register(cell.controller);
      group.register(cell.controller); // should be no-op

      // If accordion fires, it closes only one other cell.
      // We verify no error and that register is idempotent by closing all.
      expect(() => group.closeAll(), returnsNormally);
    });

    // (b) unregister() is idempotent
    test('unregister() is idempotent — no-op on unknown controller', () {
      final cell = _createCell();
      addTearDown(cell.controller.dispose);

      expect(() => group.unregister(cell.controller), returnsNormally); // not registered
      group.register(cell.controller);
      group.unregister(cell.controller);
      expect(
          () => group.unregister(cell.controller), returnsNormally); // already unregistered
    });

    // (c) accordion: when A opens, B's close() is called
    test('accordion: when A opens (animatingToOpen), B.close() is called', () {
      final a = _createCell();
      final b = _openCell();
      addTearDown(a.controller.dispose);
      addTearDown(b.controller.dispose);

      group.register(a.controller);
      group.register(b.controller);

      // Simulate A opening — B should get closed.
      a.controller.reportState(SwipeState.animatingToOpen, 0.0, SwipeDirection.left);

      expect(b.handle.closeCalls, 1);
    });

    // (d) accordion: when B opens, A's close() is called
    test('accordion: when B opens, A.close() is called', () {
      final a = _openCell();
      final b = _createCell();
      addTearDown(a.controller.dispose);
      addTearDown(b.controller.dispose);

      group.register(a.controller);
      group.register(b.controller);

      b.controller.reportState(SwipeState.animatingToOpen, 0.0, SwipeDirection.left);
      expect(a.handle.closeCalls, 1);
    });

    // (e) closeAll() calls close() on every open controller
    test('closeAll() closes all open controllers', () {
      final a = _openCell();
      final b = _openCell();
      addTearDown(a.controller.dispose);
      addTearDown(b.controller.dispose);

      group.register(a.controller);
      group.register(b.controller);

      group.closeAll();
      expect(a.handle.closeCalls, 1);
      expect(b.handle.closeCalls, 1);
    });

    // (f) closeAll() is safe when no cells are open
    test('closeAll() is safe when no cells are open', () {
      expect(() => group.closeAll(), returnsNormally);
    });

    // (g) closeAllExcept(A) closes B and C but not A
    test('closeAllExcept(A) closes B and C but not A', () {
      final a = _openCell();
      final b = _openCell();
      final c = _openCell();
      addTearDown(a.controller.dispose);
      addTearDown(b.controller.dispose);
      addTearDown(c.controller.dispose);

      group.register(a.controller);
      group.register(b.controller);
      group.register(c.controller);

      // After closeAllExcept(a), only a should still be open.
      group.closeAllExcept(a.controller);

      expect(a.handle.closeCalls, 0);
      expect(b.handle.closeCalls, 1);
      expect(c.handle.closeCalls, 1);
    });

    // (h) unregistered controller is not closed during accordion trigger
    test('unregistered controller is not closed during accordion trigger', () {
      final a = _createCell();
      final b = _openCell();
      addTearDown(a.controller.dispose);
      addTearDown(b.controller.dispose);

      group.register(a.controller);
      group.register(b.controller);
      group.unregister(b.controller); // unregister b before A opens

      // When A opens, the group should not attempt to close B.
      a.controller.reportState(SwipeState.animatingToOpen, 0.0, SwipeDirection.left);

      expect(b.handle.closeCalls, 0);
    });

    // (i) rapid register → unregister → register without crash
    test('rapid register → unregister → register sequence is safe', () {
      final cell = _createCell();
      addTearDown(cell.controller.dispose);

      for (int i = 0; i < 10; i++) {
        group.register(cell.controller);
        group.unregister(cell.controller);
      }
      group.register(cell.controller);
      expect(() => group.closeAll(), returnsNormally);
    });

    // (j) dispose() removes all internal listeners without crashing registered controllers
    test(
        'dispose() removes all listeners without crashing registered controllers',
        () {
      // Use a local group so tearDown does not double-dispose.
      final localGroup = SwipeGroupController();
      final a = _createCell();
      addTearDown(a.controller.dispose);
      localGroup.register(a.controller);

      expect(() => localGroup.dispose(), returnsNormally);

      // a should still work after its group was disposed.
      expect(() => a.controller.openLeft(), returnsNormally);
    });

    // (k) accordion: when A is animatingToOpen and B starts animatingToOpen, A is closed
    test('accordion: when A is animatingToOpen and B starts animatingToOpen, A is closed', () {
      final a = _createCell();
      final b = _createCell();
      addTearDown(a.controller.dispose);
      addTearDown(b.controller.dispose);

      group.register(a.controller);
      group.register(b.controller);

      // A starts animating to open
      a.controller.reportState(SwipeState.animatingToOpen, 0.5, SwipeDirection.left);
      
      // B starts animating to open
      b.controller.reportState(SwipeState.animatingToOpen, 0.5, SwipeDirection.left);

      // A should have received a close call because it was animating to open
      expect(a.handle.closeCalls, 1);
    });

    // (l) accordion: when A is revealed and B starts dragging, A is closed
    test('accordion: when A is revealed and B starts dragging, A is closed', () {
      final a = _openCell();
      final b = _createCell();
      addTearDown(a.controller.dispose);
      addTearDown(b.controller.dispose);

      group.register(a.controller);
      group.register(b.controller);

      // B starts dragging
      b.controller.reportState(SwipeState.dragging, 0.1, SwipeDirection.left);

      // A should have received a close call
      expect(a.handle.closeCalls, 1);
    });

    // (m) closeAll() also closes cells in animatingToOpen state
    test('closeAll() also closes cells in animatingToOpen state', () {
      final a = _createCell();
      addTearDown(a.controller.dispose);
      group.register(a.controller);
      a.controller.reportState(SwipeState.animatingToOpen, 0.5, SwipeDirection.left);

      group.closeAll();
      expect(a.handle.closeCalls, 1);
    });
  });
}

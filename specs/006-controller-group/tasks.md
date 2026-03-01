# Tasks: Programmatic Control & Multi-Cell Coordination

**Input**: Design documents from `/specs/006-controller-group/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/controller-api.md ✅

**Tests**: Included — Constitution VII mandates test-first. All tests MUST be written to fail
before the implementation code they exercise is written.

**Organization**: Tasks are grouped by user story (US1–US4 from spec.md). US1 is the MVP
and unblocks US2 (same controller/widget files). US3 requires US1 (needs real SwipeController
state). US4 requires US3 (SwipeGroupController must exist before the provider can coordinate it).

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no cross-story dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- **File paths are absolute from the repository root**

---

## Phase 1: Setup

**Purpose**: Establish a known-good baseline before any changes.

- [X] T001 Run `flutter test` to confirm all 152 existing tests pass before starting; record baseline count

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: The `SwipeCellHandle` abstract class is the cross-file bridge protocol that
both `SwipeController` (Phase 3) and `SwipeActionCellState` (Phase 3) must import. It must
exist before either can be implemented.

- [ ] T002 Create `SwipeCellHandle` abstract class in `lib/src/controller/swipe_cell_handle.dart` with five methods: `executeOpenLeft()`, `executeOpenRight()`, `executeClose()`, `executeResetProgress()`, `executeSetProgress(double value)`; add dartdoc on every member; do NOT export from barrel

**Checkpoint**: `flutter analyze lib/src/controller/swipe_cell_handle.dart` — zero warnings

---

## Phase 3: User Story 1 — Programmatic Single-Cell Control (Priority: P1) 🎯 MVP

**Goal**: A developer creates a `SwipeController`, passes it to `SwipeActionCell`, and
calls `openLeft()`, `close()`, `setProgress()`, etc. to drive the cell without gesture input.

**Independent Test**: Create a `SwipeActionCell` with `leftSwipeConfig` and an attached
`SwipeController`. Call `controller.openLeft()` — cell opens. Call `controller.close()` —
cell snaps back. Set `rightSwipeConfig` and call `controller.setProgress(5.0)` — value
updates. All without any touch/gesture simulation. This proves the full command API works.

### Tests for User Story 1

> **Write these tests FIRST — they must FAIL before T005 and T006 are written**

- [ ] T003 [P] [US1] Write failing unit tests for `SwipeController` in `test/controller/swipe_controller_test.dart`: expand existing file — (a) `openLeft()` from idle calls `executeOpenLeft()` on the attached handle, (b) `openRight()` from idle calls `executeOpenRight()`, (c) `close()` from revealed calls `executeClose()`, (d) `resetProgress()` calls `executeResetProgress()`, (e) `setProgress(5.0)` calls `executeSetProgress(5.0)`, (f) `setProgress()` clamps to `[minValue, maxValue]` silently, (g) `openLeft()` from non-idle is no-op in release; assert fires in debug, (h) `close()` from idle is no-op; assert fires in debug, (i) `openLeft()` with no handle attached is no-op; assert fires in debug, (j) `attach()` when already attached fires debug assert, (k) `detach()` with mismatched handle is no-op, (l) controller can outlive widget (`detach()` then command → no-op, no crash)
- [ ] T004 [P] [US1] Write failing widget tests for programmatic control in `test/widget/swipe_action_cell_controller_test.dart`: (a) `controller.openLeft()` animates cell open (state → revealed), (b) `controller.close()` snaps cell back (state → idle), (c) `controller.openRight()` triggers progressive increment + snap-back, (d) `controller.resetProgress()` resets `currentProgress` to `initialValue`, (e) `controller.setProgress(5.0)` sets `currentProgress` to 5.0, (f) no controller provided → widget creates internal controller and functions normally, (g) controller swap on `didUpdateWidget` detaches old and attaches new without crash, (h) widget rebuild with same controller does not re-attach or double-register

### Implementation for User Story 1

- [ ] T005 [US1] Implement full `SwipeController` in `lib/src/controller/swipe_controller.dart` (replaces stub): add `_handle`, `_currentState`, `_currentProgress`, `_openDirection` private fields; implement `currentState`, `currentProgress`, `isOpen`, `openDirection` getters; implement `openLeft()`, `openRight()`, `close()`, `resetProgress()`, `setProgress(double)` with state-machine validation (debug asserts for invalid transitions, no-op in release); implement `attach(SwipeCellHandle)`, `detach(SwipeCellHandle)`, `reportState(SwipeState, double, SwipeDirection?)` internal methods; dartdoc on every public member
- [ ] T006 [US1] Update `SwipeActionCellState` in `lib/src/widget/swipe_action_cell.dart`: (1) add `_internalController`, `_effectiveController` getter, `_registeredGroup`; (2) create `_internalController` in `initState()` when `widget.controller == null`; (3) implement `SwipeCellHandle` — `executeOpenLeft()` runs `_animateToOpen()` to left max-translation then allows `_handleIntentionalActionSettled()` to run, `executeOpenRight()` runs `_animateToOpen()` to right max-translation, `executeClose()` runs `_snapBack()` from current offset, `executeResetProgress()` sets `_progressValueNotifier.value = config.initialValue`, `executeSetProgress(v)` sets clamped value; (4) attach handle in `didChangeDependencies()`, detach + dispose internal controller in `dispose()`; (5) call `_effectiveController.reportState(newState, progress, direction)` at the end of `_updateState()` and on every progress value change; (6) handle controller swap in `didUpdateWidget()`; (7) add `_syncGroupRegistration()` stub (empty body — wired in US4 T013)

**Checkpoint**: `flutter analyze` zero warnings; `flutter test test/controller/swipe_controller_test.dart test/widget/swipe_action_cell_controller_test.dart` all pass — US1 complete and independently verifiable

---

## Phase 4: User Story 2 — Observe State for Reactive UI (Priority: P2)

**Goal**: A developer adds a listener to a `SwipeController` and reacts to state changes
(`isOpen`, `openDirection`, `currentProgress`) to update other UI without polling.

**Independent Test**: Add a listener to a `SwipeController` on a mounted cell. Trigger a
left-swipe gesture. Verify the listener fires and `isOpen == true`, `openDirection == left`.
Close the cell. Verify the listener fires and `isOpen == false`, `openDirection == null`.

### Tests for User Story 2

> **Write these tests FIRST — they must FAIL before T008 is implemented**

- [ ] T007 [US2] Write failing unit tests for `ChangeNotifier` behavior in `test/controller/swipe_controller_test.dart`: (a) adding a listener via `addListener()` — listener fires when `reportState()` transitions state to `animatingToOpen`, (b) listener fires when state transitions to `idle`, (c) multiple listeners all fire on the same notification, (d) `isOpen` is `true` after state set to `SwipeState.revealed`, (e) `openDirection` is `SwipeDirection.left` after open-left transition; `null` after close, (f) `currentProgress` updates when `reportState()` provides new value, (g) listener NOT fired when `setProgress()` value is unchanged, (h) listener NOT fired after `dispose()` is called

### Implementation for User Story 2

- [ ] T008 [US2] Patch `lib/src/controller/swipe_controller.dart` for observer edge cases found by T007: (a) ensure `openDirection` is set to `null` when `reportState()` receives a non-open state (idle, animatingToClose), (b) ensure `setProgress()` skips `notifyListeners()` when the clamped value equals the current `_currentProgress`, (c) ensure `notifyListeners()` is not called after `dispose()` has been called on the controller (guard with `_disposed` flag if needed)

**Checkpoint**: `flutter test test/controller/swipe_controller_test.dart` — all US1 + US2 tests pass; listener callbacks verified

---

## Phase 5: User Story 3 — Accordion Behavior via `SwipeGroupController` (Priority: P3)

**Goal**: A developer registers multiple `SwipeController` instances with a
`SwipeGroupController`. Opening any one cell automatically closes all others.

**Independent Test**: Create a `SwipeGroupController`. Register two `SwipeController`
instances (A, B) each attached to a mounted cell. Call `A.openLeft()` — verify B closes.
Call `B.openLeft()` — verify A closes. Call `closeAll()` — verify both close. No provider,
no widget tree needed for the pure unit tests.

### Tests for User Story 3

> **Write these tests FIRST — they must FAIL before T010 is implemented**

- [ ] T009 [US3] Write failing unit tests for `SwipeGroupController` in `test/controller/swipe_group_controller_test.dart`: (a) `register()` is idempotent (no duplicate entries), (b) `unregister()` is idempotent (no-op on unknown controller), (c) accordion: when A opens (state → `animatingToOpen`), B's `close()` is called, (d) accordion: when B opens, A's `close()` is called, (e) `closeAll()` calls `close()` on every open controller, (f) `closeAll()` is safe when no cells are open, (g) `closeAllExcept(A)` closes B and C but not A, (h) unregistered controller is not closed during accordion trigger, (i) rapid `register → unregister → register` sequence without crash or dangling listener, (j) `dispose()` removes all internal listeners without crashing registered controllers

### Implementation for User Story 3

- [ ] T010 [US3] Implement `SwipeGroupController` in `lib/src/controller/swipe_group_controller.dart`: `_controllers: final Set<SwipeController> = {}`, `_listeners: final Map<SwipeController, VoidCallback> = {}`; `register(c)` — guard against duplicates, create accordion listener (`if c.currentState == animatingToOpen → closeAllExcept(c)`) stored in `_listeners[c]`, call `c.addListener(listener)`; `unregister(c)` — guard against unknowns, call `c.removeListener(_listeners[c])`, remove from both maps; `closeAll()` — iterate `_controllers`, call `c.close()` on each where `c.isOpen`; `closeAllExcept(c)` — same but skip the given controller; `dispose()` — for each entry in `_listeners`, call `c.removeListener(listener)`; then call `super.dispose()`; dartdoc on every member

**Checkpoint**: `flutter test test/controller/swipe_group_controller_test.dart` — all accordion tests pass; US3 independently verifiable

---

## Phase 6: User Story 4 — Zero-Boilerplate Coordination via `SwipeControllerProvider` (Priority: P4)

**Goal**: A developer wraps a `ListView.builder` in `SwipeControllerProvider`. Cells
auto-register on mount and auto-unregister on dispose. Accordion behavior works across
all visible cells with zero manual controller management.

**Independent Test**: Wrap a `ListView.builder` (10 items) in `SwipeControllerProvider`
with no explicit controllers. Open item 3 by gesture — verify item 5 (also opened) closes
automatically. Scroll rapidly — no errors. No consumer-created `SwipeController` or
`SwipeGroupController` required.

### Tests for User Story 4

> **Write these tests FIRST — they must FAIL before T012 and T013 are implemented**

- [ ] T011 [US4] Write failing widget tests for `SwipeControllerProvider` in `test/widget/swipe_controller_provider_test.dart`: (a) cells without explicit controller auto-register when mounted inside provider, (b) accordion via gesture: open cell A → open cell B → cell A closes, (c) cell unregisters on dispose (removed from group — no crash when group calls closeAll after disposal), (d) rapid mount/unmount in lazy list (pump 100 items, fling-scroll, no errors), (e) cell with explicit consumer `SwipeController` registers that controller in the provider's group — consumer retains programmatic access, (f) no provider in tree → SwipeActionCell works normally (no crash, no accordion), (g) explicit `groupController` passed to `SwipeControllerProvider` is used instead of internal one; `controller.closeAll()` closes all cells

### Implementation for User Story 4

- [ ] T012 [US4] Implement `_SwipeControllerScope` and `SwipeControllerProvider` in `lib/src/controller/swipe_controller_provider.dart`: `_SwipeControllerScope extends InheritedWidget` with `final SwipeGroupController controller` and `static SwipeGroupController? maybeOf(BuildContext ctx)` using `ctx.getElementForInheritedWidgetOfExactType<_SwipeControllerScope>()?.widget` (non-reactive lookup — cells don't need to rebuild when group changes); `SwipeControllerProvider extends StatefulWidget` with `final SwipeGroupController? groupController` and `required Widget child`; state creates `_internalController = SwipeGroupController()` in `initState`, disposes it in `dispose`, builds `_SwipeControllerScope(controller: widget.groupController ?? _internalController, child: widget.child)`; add `static SwipeGroupController? maybeGroupOf(BuildContext ctx)` delegating to `_SwipeControllerScope.maybeOf(ctx)`; dartdoc on every public member
- [ ] T013 [US4] Complete `_syncGroupRegistration()` in `lib/src/widget/swipe_action_cell.dart` — body: `final newGroup = SwipeControllerProvider.maybeGroupOf(context); if (newGroup == _registeredGroup) return; _registeredGroup?.unregister(_effectiveController); _registeredGroup = newGroup; _registeredGroup?.register(_effectiveController);`; call this method from `didChangeDependencies()` (add after `_resolveEffectiveConfigs()`); also call `_registeredGroup?.unregister(_effectiveController)` at the start of `dispose()` before detach

**Checkpoint**: `flutter test test/widget/swipe_controller_provider_test.dart` — all provider and accordion tests pass; US4 independently verifiable

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final quality verification across all stories.

- [ ] T014 [P] Update `lib/swipe_action_cell.dart` barrel — add `export 'src/controller/swipe_group_controller.dart'` and `export 'src/controller/swipe_controller_provider.dart'`; confirm `swipe_cell_handle.dart` is NOT exported; confirm `swipe_controller.dart` is still exported from F6
- [ ] T015 [P] Verify the 2 existing stub tests in `test/controller/swipe_controller_test.dart` (\"constructable\", \"dispose completes without error\") still pass with the new full implementation; update test descriptions if needed to reflect F7 context
- [ ] T016 [P] Run `flutter analyze` across the entire package; fix all warnings and errors until output is clean
- [ ] T017 [P] Run `dart format --set-exit-if-changed .`; fix any formatting issues
- [ ] T018 Run `flutter test` to confirm all tests pass (existing 152 + all new controller and provider tests)
- [ ] T019 Manually verify all 5 quickstart.md examples compile and behave as documented
- [ ] T020 Run `flutter pub publish --dry-run` to verify the package is publishable with zero issues

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup)         → No dependencies — run immediately
Phase 2 (Foundational)  → Depends on Phase 1 — BLOCKS all user story phases
Phase 3 (US1)           → Depends on Phase 2 — BLOCKS Phase 4 (US2) and Phase 5 (US3)
Phase 4 (US2)           → Depends on Phase 3 (same controller/widget files)
Phase 5 (US3)           → Depends on Phase 3 (needs real SwipeController state)
Phase 6 (US4)           → Depends on Phase 5 (needs SwipeGroupController)
Phase 7 (Polish)        → Depends on all phases complete
```

### User Story Dependencies

```
US1 (P1): Depends on Foundational (Phase 2). No other US dependency.
US2 (P2): Depends on US1 (tests and fixes live in same files; no new implementation files).
US3 (P3): Depends on US1 (SwipeController must have real state for accordion listener).
US4 (P4): Depends on US3 (SwipeGroupController must exist for provider to create/manage one).
```

### Within Each User Story

1. Tests written to FAIL (Red) before implementation begins
2. Implementation makes tests PASS (Green)
3. Refactor only after Green

### Parallel Opportunities

- **Phase 3 tests**: T003 and T004 are parallel (different test files)
- **Phase 7 polish**: T014, T015, T016, T017 are parallel (different files and concerns)
- **US3 and US2**: T007+T008 (US2) and T009+T010 (US3) CAN run in parallel if two developers are available, since they touch different files (`swipe_controller.dart` edge cases vs. new `swipe_group_controller.dart`)

---

## Parallel Execution Examples

### Parallel: Phase 3 Tests (US1)

```
Launch simultaneously:
  Task: Write failing SwipeController unit tests → test/controller/swipe_controller_test.dart
  Task: Write failing widget integration tests    → test/widget/swipe_action_cell_controller_test.dart

Then sequentially:
  Task: Implement SwipeController full API        → lib/src/controller/swipe_controller.dart
  Task: Implement SwipeCellHandle on widget state → lib/src/widget/swipe_action_cell.dart
```

### Parallel: US2 + US3 (if two developers)

```
Developer A: US2 observer tests + fix         → test/controller/ + lib/src/controller/swipe_controller.dart
Developer B: US3 SwipeGroupController         → lib/src/controller/swipe_group_controller.dart + tests
```

### Parallel: Phase 7 Polish

```
Launch simultaneously:
  Task: Update barrel exports                  → lib/swipe_action_cell.dart
  Task: Update stub test descriptions          → test/controller/swipe_controller_test.dart
  Task: flutter analyze                        → (whole package)
  Task: dart format                            → (whole package)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002)
3. Complete Phase 3: User Story 1 (T003–T006)
4. **STOP and VALIDATE**: `flutter analyze` + `flutter test` — all clear; US1 independently verified
5. Ship: `SwipeController` with full programmatic API; consumers can adopt immediately

### Incremental Delivery

1. Phase 1 + 2: `SwipeCellHandle` bridge ready → controller and widget can be implemented
2. + US1 (Phase 3): Full `SwipeController` API → consumers drive cells programmatically
3. + US2 (Phase 4): Observer edge cases tightened → reactive UI patterns confirmed
4. + US3 (Phase 5): `SwipeGroupController` → accordion via manual group management
5. + US4 (Phase 6): `SwipeControllerProvider` → zero-boilerplate list coordination

Each increment adds value without breaking the previous state.

---

## Notes

- **`swipe_cell_handle.dart` must NOT be exported** (T002): It is package-internal. Adding it to the barrel would expose `SwipeCellHandle` to consumers who have no use for it and could create confusion or misuse.
- **T006 is the most invasive task**: It modifies `swipe_action_cell.dart`, which has the most existing tests. Run all tests after T006 to catch regressions before proceeding to US2.
- **`_syncGroupRegistration()` stub in T006**: T006 adds the method with an empty body. T013 fills in the body. This avoids a merge conflict between US1 and US4 work on the same file.
- **`executeOpenLeft()` implementation note** (T006): The method must set `_lockedDirection = SwipeDirection.left` before calling `_animateToOpen()`, exactly as `_handleDragEnd` does, so `_handleAnimationStatusChange` can route correctly to `_handleIntentionalActionSettled()`.
- **Accordion listener trigger** (T010): Listen to `currentState`; fire `closeAllExcept` when state becomes `SwipeState.animatingToOpen` — not `revealed`. This ensures closing starts before the opening animation completes, satisfying SC-002.
- **Non-reactive provider lookup** (T012): Use `getElementForInheritedWidgetOfExactType` (not `dependOnInheritedWidgetOfExactType`) so cells do NOT rebuild when the group controller reference changes. Cells only need the group at mount/unmount time.

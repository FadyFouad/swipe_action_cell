# Tasks: Consumer Testing Utilities (F015)

**Input**: Design documents from `/specs/014-testing-utils/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/public-api.md ✅, quickstart.md ✅

**Tests**: Included — Constitution VII mandates test-first (NON-NEGOTIABLE). Tests for each utility MUST be written and failing before implementation begins.

**Organization**: Tasks are grouped by user story (US1–US4). Cluster A (Phase 2, Foundational) MUST complete before any user story work begins.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies on in-progress tasks)
- **[Story]**: Which user story this task belongs to (US1–US4)
- Exact file paths are specified in each task description

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create directory scaffolding and enable `lib/` to import `flutter_test`.

- [x] T001 Create `lib/src/testing/` source directory with four empty stub files: `swipe_tester.dart`, `swipe_assertions.dart`, `mock_swipe_controller.dart`, `swipe_test_harness.dart`
- [x] T002 Create `test/testing/` test directory

**Checkpoint**: Directory structure in place — all file paths for subsequent tasks now exist.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Move `flutter_test` to `dependencies` and expose the state getters that ALL utilities depend on.

**⚠️ CRITICAL**: No user story implementation can begin until this phase is complete.

- [x] T003 Move `flutter_test: sdk: flutter` from `dev_dependencies` to `dependencies` in `pubspec.yaml` (required for `lib/src/testing/` files to import `WidgetTester`)
- [x] T004 Write a RED test for `SwipeActionCellState.currentSwipeState` and `currentSwipeRatio` getters in `test/testing/swipe_tester_test.dart` — test MUST fail before T005
- [x] T005 Add `SwipeState get currentSwipeState => _state;` and `double get currentSwipeRatio => _controller.value;` public getters with `///` dartdoc to `SwipeActionCellState` in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: `flutter test test/testing/swipe_tester_test.dart` compiles and the getter test passes. All four user story phases may now start (in parallel if staffed).

---

## Phase 3: User Story 1 — Gesture Simulation Helpers (Priority: P1) 🎯 MVP

**Goal**: Deliver `SwipeTester` — the core gesture simulation class that removes all pump cycle and pixel-math boilerplate from consumer tests.

**Independent Test**: Pump a `SwipeActionCell.delete` cell. Call `SwipeTester.swipeLeft` — verify undo strip appears. Call `SwipeTester.flingLeft` — verify delete callback fires. Call `SwipeTester.dragTo` — verify mid-drag state is inspectable. All without any other utility from this feature.

### Tests for User Story 1 ⚠️ Write and verify RED before T008

- [x] T006 [US1] Write failing tests for `SwipeTester.swipeLeft` (default ratio, custom ratio, cell with no config) and `SwipeTester.swipeRight` in `test/testing/swipe_tester_test.dart`
- [x] T007 [US1] Write failing tests for `SwipeTester.flingLeft` (velocity clamp), `SwipeTester.flingRight`, `SwipeTester.dragTo` (mid-drag no settle, zero-offset no-op), and `SwipeTester.tapAction` (revealed cell, non-revealed failure message, out-of-bounds failure) in `test/testing/swipe_tester_test.dart`

### Implementation for User Story 1

- [x] T008 [US1] Implement `SwipeTester` class with private constructor and all 6 static methods (`swipeLeft`, `swipeRight`, `flingLeft`, `flingRight`, `dragTo`, `tapAction`) with full `///` dartdoc in `lib/src/testing/swipe_tester.dart`

**Checkpoint**: All `swipe_tester_test.dart` tests pass. `SwipeActionCell.delete` integration scenario (10-line test from SC-014-001) works end-to-end.

---

## Phase 4: User Story 2 — State Assertion Extensions (Priority: P1)

**Goal**: Deliver `SwipeAssertions` — WidgetTester extension methods that provide readable pass/fail messages for cell state and progress.

**Independent Test**: After calling `swipeLeft(ratio: 0.9)`, call `expectRevealed(finder)` — passes. Call `expectIdle(finder)` — fails with message "Expected SwipeState.idle but found SwipeState.revealed". Call `expectProgress(finder, 0.0)` after snap-back — passes.

### Tests for User Story 2 ⚠️ Write and verify RED before T010

- [x] T009 [P] [US2] Write failing tests for `expectSwipeState` (pass when matching, fail with "Expected … but found …" message), `expectProgress` (pass within tolerance, fail showing expected/actual/delta), `expectRevealed` and `expectIdle` shorthands in `test/testing/swipe_assertions_test.dart`

### Implementation for User Story 2

- [x] T010 [US2] Implement `SwipeAssertions` extension on `WidgetTester` with `expectSwipeState`, `expectProgress`, `expectRevealed`, and `expectIdle` methods with full `///` dartdoc in `lib/src/testing/swipe_assertions.dart`

**Checkpoint**: All `swipe_assertions_test.dart` tests pass. Assertion failure messages match the format from data-model.md: `"Expected SwipeState.revealed but found SwipeState.idle"` and `"Expected progress 0.50 ± 0.01 but found 0.73 (delta: 0.23)"`.

---

## Phase 5: User Story 3 — Mock Swipe Controller (Priority: P2)

**Goal**: Deliver `MockSwipeController` — a zero-dependency test double for `SwipeController` that records call counts and accepts stub return values.

**Independent Test**: Create a widget that takes a `SwipeController` and calls `controller.openLeft()` on button tap. Inject a `MockSwipeController`. Tap the button. Assert `mock.openLeftCallCount == 1` and `mock.openCallCount == 1`. No mockito import needed.

### Tests for User Story 3 ⚠️ Write and verify RED before T012

- [x] T011 [P] [US3] Write failing tests for `MockSwipeController`: initial counts at zero, each method increments its count, `openCallCount == openLeftCallCount + openRightCallCount`, `resetCalls()` zeroes all counts without changing `stubbedState`, `stubbedState` change reflected in `currentState` getter, `undo()` returns `false` and increments `undoCallCount` in `test/testing/mock_swipe_controller_test.dart`

### Implementation for User Story 3

- [x] T012 [US3] Implement `MockSwipeController` extending `SwipeController` with private count fields, public read-only count getters, `openCallCount` computed getter, `stubbedState`/`stubbedProgress` mutable fields, overridden methods (no super calls), and `resetCalls()` method — full `///` dartdoc in `lib/src/testing/mock_swipe_controller.dart`

**Checkpoint**: All `mock_swipe_controller_test.dart` tests pass. Verify no mockito import appears in the test file.

---

## Phase 6: User Story 4 — Test Setup Harness (Priority: P2)

**Goal**: Deliver `SwipeTestHarness` — a `StatelessWidget` that eliminates ancestor boilerplate from every consumer widget test.

**Independent Test**: Pump `SwipeTestHarness(child: SwipeActionCell.delete(...))` with no other ancestors — no MediaQuery/Material/Directionality errors. Rebuild with `textDirection: TextDirection.rtl` — verify swipe directions reverse.

### Tests for User Story 4 ⚠️ Write and verify RED before T014

- [x] T013 [P] [US4] Write failing tests for `SwipeTestHarness`: pumps without ancestor errors, defaults to LTR/English/390×844, `textDirection: rtl` reverses swipe semantics, `screenSize: Size(414, 896)` propagates via `MediaQuery.of(context).size`, `const` constructor compiles in `test/testing/swipe_test_harness_test.dart`

### Implementation for User Story 4

- [x] T014 [US4] Implement `SwipeTestHarness extends StatelessWidget` with `const` constructor, `child`/`textDirection`/`locale`/`screenSize`/`controller?` fields, and `build()` returning `MediaQuery → Localizations → Directionality → Material` tree (no `MaterialApp`) with full `///` dartdoc in `lib/src/testing/swipe_test_harness.dart`

**Checkpoint**: All `swipe_test_harness_test.dart` tests pass. Both LTR and RTL scenarios work without any ancestor except `SwipeTestHarness`.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Wire exports, verify single-import invariant, and confirm zero analyzer warnings.

- [x] T015 Update `lib/testing.dart` with exports for all 4 utilities (`swipe_tester.dart`, `swipe_assertions.dart`, `mock_swipe_controller.dart`, `swipe_test_harness.dart`) plus selective core re-exports: `SwipeState`, `SwipeProgress`, `SwipeDirection` from `src/core/`, `SwipeController` from `src/controller/`, `SwipeActionCellState` from `src/widget/swipe_action_cell.dart` (show-only)
- [x] T016 Write `test/testing/single_import_test.dart` using ONLY `flutter_test` and `testing.dart` imports — verify all four utility types (`SwipeTester`, `SwipeAssertions`, `MockSwipeController`, `SwipeTestHarness`) plus `SwipeState` and `SwipeController` are accessible (SC-014-002)
- [x] T017 [P] Run `flutter analyze` and `dart format --set-exit-if-changed .` — fix all warnings and formatting issues in `lib/src/testing/`, `lib/testing.dart`, and `lib/src/widget/swipe_action_cell.dart`
- [x] T018 Run `flutter test` to confirm all new tests pass and the full regression suite is green

**Checkpoint**: `flutter analyze` reports zero issues. `flutter test` is green. `lib/testing.dart` import provides single-import access to all utilities.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1, T001–T002)**: No dependencies — start immediately
- **Foundational (Phase 2, T003–T005)**: Depends on Phase 1 — BLOCKS all user story phases
- **US1 (Phase 3, T006–T008)**: Depends on Phase 2 completion — no dependency on US2/US3/US4
- **US2 (Phase 4, T009–T010)**: Depends on Phase 2 completion — no dependency on US1/US3/US4
- **US3 (Phase 5, T011–T012)**: Depends on Phase 2 completion — no dependency on US1/US2/US4
- **US4 (Phase 6, T013–T014)**: Depends on Phase 2 completion — no dependency on US1/US2/US3
- **Polish (Phase 7, T015–T018)**: Depends on ALL user story phases completing

### User Story Dependencies

All four user stories depend only on Phase 2. They can proceed in parallel after T005 passes.

```
T001 → T002 → T003 → T004 → T005
                              ├── T006 → T007 → T008  (US1, sequential within story)
                              ├── T009 → T010          (US2, parallel with US1)
                              ├── T011 → T012          (US3, parallel with US1/US2)
                              └── T013 → T014          (US4, parallel with US1/US2/US3)
                                                   ↓
                              T015 → T016 → T017 → T018 (Polish, after all US done)
```

### Within Each User Story

1. Test tasks MUST be written and FAIL before implementation task begins
2. Test tasks that write to the same file are sequential (T006 → T007 within US1)
3. Implementation task depends on ALL test tasks for that story completing

---

## Parallel Execution Examples

### After Phase 2 completes: Launch all 4 user stories simultaneously

```bash
# Terminal A (US1 - SwipeTester):
Task T006: Write failing tests for swipeLeft/swipeRight in test/testing/swipe_tester_test.dart
Task T007: Write failing tests for flingLeft/dragTo/tapAction in test/testing/swipe_tester_test.dart
Task T008: Implement SwipeTester in lib/src/testing/swipe_tester.dart

# Terminal B (US2 - SwipeAssertions):
Task T009: Write failing tests for expectSwipeState/expectProgress in test/testing/swipe_assertions_test.dart
Task T010: Implement SwipeAssertions in lib/src/testing/swipe_assertions.dart

# Terminal C (US3 - MockSwipeController):
Task T011: Write failing tests for MockSwipeController in test/testing/mock_swipe_controller_test.dart
Task T012: Implement MockSwipeController in lib/src/testing/mock_swipe_controller.dart

# Terminal D (US4 - SwipeTestHarness):
Task T013: Write failing tests for SwipeTestHarness in test/testing/swipe_test_harness_test.dart
Task T014: Implement SwipeTestHarness in lib/src/testing/swipe_test_harness.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001–T002)
2. Complete Phase 2: Foundational (T003–T005) — CRITICAL
3. Complete Phase 3: US1 Gesture Simulation (T006–T008)
4. **STOP and VALIDATE**: `SwipeTester.swipeLeft/swipeRight/flingLeft/dragTo/tapAction` all work. Run 10-line delete test (SC-014-001).
5. Add US2 (T009–T010) for complete assertion support → minimal viable testing toolkit

### Incremental Delivery

1. Complete Setup + Foundational → state access works
2. Add US1 (SwipeTester) → gesture simulation live ✅ SC-014-001
3. Add US2 (SwipeAssertions) → full state inspection ✅ min viable toolkit
4. Add US3 (MockSwipeController) → controller testing covered ✅ SC-014-006
5. Add US4 (SwipeTestHarness) → boilerplate eliminated ✅ SC-014-007
6. Polish (T015–T018) → SC-014-002 (single import), SC-014-003 (zero prod deps) ✅

### Single-Developer Strategy

Sequential execution in priority order:

```
Phase 1 (Setup) → Phase 2 (Foundation) → Phase 3 (US1 P1) → Phase 4 (US2 P1)
→ Phase 5 (US3 P2) → Phase 6 (US4 P2) → Phase 7 (Polish)
```

---

## Notes

- **[P] tasks**: Different files, no in-progress dependencies — safe to run simultaneously
- **TDD mandatory**: Each implementation task has at least one test task before it (Constitution VII)
- **`flutter_test` in `dependencies`**: This is the one justified Constitution IV exception — it is an SDK package (not third-party), always available, and tree-shaken from production builds
- **`SwipeActionCellState` change (T005)**: Minimal — two read-only getters. No existing behavior changes.
- **`lib/testing.dart` (T015)**: Only adds exports; the library declaration and doc comment are already in place
- **Single import validation (T016)**: Write a real test file with only two imports — if it compiles and runs, SC-014-002 is satisfied
- Commit after T005 (foundation), after each US phase, and after T018 (final)

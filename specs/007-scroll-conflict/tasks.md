# Tasks: Scroll Conflict Resolution & Gesture Arena

**Input**: Design documents from `/specs/007-scroll-conflict/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/gesture-arena.md ✅

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.
**Test approach**: Constitution VII (NON-NEGOTIABLE) — tests MUST be written to fail before implementation code.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1–US4)

---

## Phase 1: Setup

**Purpose**: Verify directory scaffolding is ready for new files.

- [ ] T001 Confirm `lib/src/scroll/` exists with `.gitkeep` placeholder and `test/scroll/` is absent (will be created by T004 test file write)

---

## Phase 2: Foundational — `SwipeGestureConfig` Extensions

**Purpose**: Add the three new config fields. All four user stories depend on these fields being
present in `effectiveGestureConfig` before any gesture or widget logic is changed.

**⚠️ CRITICAL**: No user story implementation can begin until this phase is complete.

- [ ] T002 Write failing unit tests for `horizontalThresholdRatio`, `closeOnScroll`, `respectEdgeGestures` fields — including assertion, `==`, `hashCode`, `copyWith`, defaults, and `tight()` preset — in `test/gesture/swipe_gesture_config_test.dart`
- [ ] T003 Add `horizontalThresholdRatio` (default `1.5`), `closeOnScroll` (default `true`), `respectEdgeGestures` (default `true`) fields plus `assert(horizontalThresholdRatio >= 1.0, ...)` to the `const` constructor in `lib/src/gesture/swipe_gesture_config.dart`
- [ ] T004 Update `copyWith`, `==`, and `hashCode` to include all six fields in `lib/src/gesture/swipe_gesture_config.dart`
- [ ] T005 Update `SwipeGestureConfig.tight()` factory to add `horizontalThresholdRatio: 2.5` in `lib/src/gesture/swipe_gesture_config.dart`

**Checkpoint**: Run `flutter test test/gesture/swipe_gesture_config_test.dart` — all new tests must pass before proceeding.

---

## Phase 3: User Story 1 — Swipe and Scroll Coexist in a Flat List (P1) 🎯 MVP

**Goal**: Horizontal (swipe) and vertical (scroll) gestures are disambiguated by the gesture
arena before any action fires. Diagonal gestures resolve to the dominant direction. Fast flings
do not accidentally activate a cell.

**Independent Test**: Place a `SwipeActionCell` inside a `ListView.builder` with 20 items.
Verify (a) a rightward swipe increments the progressive counter, (b) a downward scroll moves the
list, and (c) a 45° diagonal resolves to its dominant direction.

### Tests for User Story 1 ⚠️ Write FIRST — must FAIL before T007

- [ ] T006 [P] [US1] Write failing widget tests for US1 scenarios (SC-01 through SC-04, SC-08): vertical scroll doesn't activate cell, horizontal swipe works, diagonal resolves at default 1.5× ratio, diagonal yields to scroll at 2.5× ratio, fast fling resolves to dominant direction — in `test/scroll/swipe_scroll_conflict_test.dart`

### Implementation for User Story 1

- [ ] T007 [P] [US1] Create `SwipeHorizontalRecognizer extends HorizontalDragGestureRecognizer` with mutable fields `thresholdRatio` and `respectEdgeGestures`, internal accumulators `_cumulativeH`/`_cumulativeV`/`_directionDecided`, `addAllowedPointer` (resets accumulators only — edge check added in T016), and `handleEvent` H/V ratio logic using `kTouchSlop` in `lib/src/scroll/swipe_gesture_recognizer.dart`
- [ ] T008 [US1] Add `import '../scroll/swipe_gesture_recognizer.dart'` and `_buildGestureRecognizers(double width)` method (wires `thresholdRatio` from `effectiveGestureConfig.horizontalThresholdRatio` plus `onStart`/`onUpdate`/`onEnd` handlers) to `SwipeActionCellState` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T009 [US1] Replace the `GestureDetector(onHorizontalDragStart/Update/End: ...)` inside `LayoutBuilder.builder` with `RawGestureDetector(behavior: HitTestBehavior.translucent, gestures: _buildGestureRecognizers(width), child: _wrapWithClip(...))` in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: Run `flutter test test/scroll/swipe_scroll_conflict_test.dart` — SC-01 through SC-04 and SC-08 must pass. Run `flutter test` — full existing suite must still pass.

---

## Phase 4: User Story 2 — Open Panels Close Automatically on Scroll (P2)

**Goal**: Any open reveal panel closes when the user initiates a vertical scroll. Programmatic
scrolls do not trigger auto-close. The behavior is configurable via `closeOnScroll`.

**Independent Test**: Open a reveal-mode panel, then scroll the parent `ListView` vertically.
Verify the panel closes before the cell scrolls out of view.

### Tests for User Story 2 ⚠️ Write FIRST — must FAIL before T011

- [ ] T010 [US2] Write failing widget tests for US2 scenarios (SC-05, SC-06, SC-07): revealed panel closes on user scroll with `closeOnScroll: true`, panel stays open with `closeOnScroll: false`, programmatic `scrollController.animateTo()` does not trigger auto-close — in `test/scroll/swipe_scroll_conflict_test.dart`

### Implementation for User Story 2

- [ ] T011 [US2] Add `_handleScrollStart(ScrollStartNotification notification)` method that calls `executeClose()` when `effectiveGestureConfig.closeOnScroll && notification.dragDetails != null && _state == SwipeState.revealed`, returning `false` — to `SwipeActionCellState` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T012 [US2] Wrap the `LayoutBuilder(...)` with `NotificationListener<ScrollStartNotification>(onNotification: _handleScrollStart, child: LayoutBuilder(...))` in the `build()` method of `SwipeActionCellState` in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: Run `flutter test test/scroll/swipe_scroll_conflict_test.dart` — SC-05, SC-06, SC-07 must pass. Full suite still passes.

---

## Phase 5: User Story 3 — Works Inside Nested Scrollable Containers (P3)

**Goal**: `PageView > ListView > SwipeActionCell` nesting works correctly — cell swipes,
list scrolls, and page turns are independently triggerable.

**Independent Test**: Build a `PageView` with two pages, each containing a `ListView` of cells.
Verify that a deliberate cell swipe does not turn the page, a fast full-width swipe turns the
page, and vertical scroll stays within the page.

### Tests for User Story 3 ⚠️ Write FIRST — must FAIL before T014

- [ ] T013 [US3] Write failing widget test for SC-09 (`PageView > ListView > SwipeActionCell`): verify a slow cell swipe activates the cell (not the page), and a vertical scroll moves the list (not the page) — in `test/scroll/swipe_scroll_conflict_test.dart`

### Implementation for User Story 3

- [ ] T014 [US3] Run SC-09 test; if it fails, diagnose the gesture arena competition between `SwipeHorizontalRecognizer` and `PageView`'s scroll recognizer and fix in `lib/src/scroll/swipe_gesture_recognizer.dart` (likely no code change needed — verify recognizer correctly resolves the arena)

**Checkpoint**: Run `flutter test test/scroll/swipe_scroll_conflict_test.dart` — SC-09 must pass.

---

## Phase 6: User Story 4 — Platform Back-Navigation Gesture Takes Priority (P4)

**Goal**: Gestures starting within the 20 logical-pixel left edge zone are not claimed by the
cell, allowing the platform back-navigation gesture to proceed normally. Configurable via
`respectEdgeGestures`.

**Independent Test**: Simulate a drag starting at `dx = 10` (inside edge zone). Verify no swipe
activates. Configure `respectEdgeGestures: false` and verify the swipe activates normally.

### Tests for User Story 4 ⚠️ Write FIRST — must FAIL before T016

- [ ] T015 [US4] Write failing widget tests for US4 scenarios (SC-10, SC-11): `respectEdgeGestures: true` drag from dx=10 does not activate swipe, `respectEdgeGestures: false` drag from dx=10 activates swipe normally — in `test/scroll/swipe_scroll_conflict_test.dart`

### Implementation for User Story 4

- [ ] T016 [P] [US4] Add edge-zone check to `addAllowedPointer`: `if (respectEdgeGestures && event.position.dx < _kEdgeZoneWidth) return;` before the accumulator reset in `lib/src/scroll/swipe_gesture_recognizer.dart`
- [ ] T017 [P] [US4] Update `_buildGestureRecognizers` initializer closure to set `..respectEdgeGestures = effectiveGestureConfig.respectEdgeGestures` alongside the existing `..thresholdRatio` assignment in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: Run `flutter test test/scroll/swipe_scroll_conflict_test.dart` — SC-10 and SC-11 must pass. Full suite still passes.

---

## Phase 7: Polish & Cross-Cutting Concerns

- [ ] T018 [P] Run `flutter analyze` from repo root and fix any warnings or errors in `lib/` and `test/`
- [ ] T019 [P] Run `dart format --set-exit-if-changed .` from repo root and fix any formatting issues
- [ ] T020 Run `flutter test` — confirm all F001–F005 regression tests AND all 11 new F007 widget scenarios pass
- [ ] T021 Verify `SwipeHorizontalRecognizer` does NOT appear in `lib/swipe_action_cell.dart` barrel exports
- [ ] T022 Validate all five quickstart.md code examples compile cleanly by running `flutter analyze` on a scratch file containing each snippet

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — **BLOCKS all user stories**
- **US1 (Phase 3)**: Depends on Phase 2 — no dependency on US2/US3/US4
- **US2 (Phase 4)**: Depends on Phase 2 and Phase 3 (NotificationListener wraps the RawGestureDetector built in US1)
- **US3 (Phase 5)**: Depends on Phase 3 — nested scrollable resolution uses the same recognizer
- **US4 (Phase 6)**: Depends on Phase 3 (recognizer file must exist before adding edge check)
- **Polish (Phase 7)**: Depends on all user story phases

### User Story Dependencies

- **US1 (P1)**: Start after Foundational — no story dependencies
- **US2 (P2)**: Start after US1 (wraps the `LayoutBuilder` introduced in US1)
- **US3 (P3)**: Start after US1 (tests the recognizer from US1 in a nested context)
- **US4 (P4)**: Start after US1 (adds to the recognizer file from US1)
- **US3 and US4** can proceed in parallel after US1

### Within Each User Story

- Tests MUST be written and **confirmed to fail** before implementation begins
- T007 [P] and T006 [P] can run in parallel (different files — recognizer vs test file)
- T016 [P] and T017 [P] can run in parallel (different files — recognizer vs widget)
- T018 [P] and T019 [P] (polish) can run in parallel

---

## Parallel Example: User Story 1

```
# Write tests and create recognizer simultaneously (different files):
Task T006: Write US1 tests in test/scroll/swipe_scroll_conflict_test.dart
Task T007: Create SwipeHorizontalRecognizer in lib/src/scroll/swipe_gesture_recognizer.dart

# Then sequentially (same file, each builds on previous):
Task T008: Add _buildGestureRecognizers to SwipeActionCellState
Task T009: Replace GestureDetector with RawGestureDetector
```

## Parallel Example: User Story 4

```
# After T015 (write US4 tests), run both implementation tasks in parallel:
Task T016: Add edge-zone check to addAllowedPointer in recognizer
Task T017: Wire respectEdgeGestures in _buildGestureRecognizers in widget
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002–T005)
3. Complete Phase 3: User Story 1 (T006–T009)
4. **STOP and VALIDATE**: `flutter test` — all F001–F005 tests pass; SC-01 through SC-04 and SC-08 pass
5. Package is production-safe for flat-list usage

### Incremental Delivery

1. Setup + Foundational → Config model ready
2. US1 → Gesture disambiguation works in flat lists (MVP!)
3. US2 → Auto-close on scroll works
4. US3 → Nested `PageView` layouts work
5. US4 → iOS/Android back-navigation is safe
6. Polish → Ship

---

## Notes

- [P] tasks operate on different files with no incomplete-task dependencies
- The `NotificationListener` in US2 MUST wrap the `LayoutBuilder` (not the other way around) — this is critical for receiving scroll notifications from any ancestor `Scrollable`
- `SwipeHorizontalRecognizer` is package-internal and MUST NOT appear in any barrel export
- The two inner `GestureDetector` widgets (body-tap interceptor and confirmation overlay) are unchanged — they handle tap events, not horizontal drag
- `return false` from `_handleScrollStart` is mandatory — it ensures the notification bubbles to parent scrollables (important for nested `PageView > ListView`)
- Commit after each checkpoint to enable easy rollback if a phase introduces a regression

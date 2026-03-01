---
description: "Task list for 002-swipe-background"
---

# Tasks: Swipe Background Visual Layer

**Input**: Design documents from `specs/002-swipe-background/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/public-api.md ✅

**Tests**: Included per plan.md (Constitution VII: Test-First is NON-NEGOTIABLE).

**Organization**: Tasks grouped by user story for independent implementation and testing.
US3 (SwipeActionBackground) is fully independent — it can proceed in parallel with US1 after Phase 2.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1–US4)

---

## Phase 1: Setup

**Purpose**: Create directory structure required for new source and test files.

- [x] T001 Create `lib/src/visual/` and `test/visual/` directories (e.g., `mkdir -p lib/src/visual test/visual`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Verify the `SwipeBackgroundBuilder` typedef scaffold from F001 is accessible before any background work begins.

**⚠️ CRITICAL**: Both US1 and US3 depend on `SwipeBackgroundBuilder` being exported. Confirm before proceeding.

- [x] T002 Verify `SwipeBackgroundBuilder` typedef is exported from `lib/swipe_action_cell.dart` — if missing, add `export 'src/core/typedefs.dart';` (it should already be present from F001)

**Checkpoint**: Foundation ready — US1 and US3 can now begin in parallel.

---

## Phase 3: User Story 1 — Custom Background per Direction (Priority: P1) 🎯 MVP

**Goal**: `SwipeActionCell` renders a direction-appropriate background widget behind the child during any swipe. Null builder = no background. Does not affect child layout or gesture detection.

**Independent Test**: Mount `SwipeActionCell` with both builders returning `Key`-tagged `ColoredBox` widgets. Drag right → right background key found, left key absent. Drag left → left background key found, right key absent. Set one builder to null → its direction shows no background.

### Tests for User Story 1 ⚠️ Write first — must FAIL before implementation

- [x] T003 [US1] Write direction-routing test group in `test/widget/swipe_action_cell_test.dart` — tests BG-W01 through BG-W05 and BG-W09 (right drag shows right bg; left drag shows left bg; right drag hides left bg; left drag hides right bg; null builder shows no bg; background does not change child bounding box)

### Implementation for User Story 1

- [x] T004 [US1] Add `leftBackground`, `rightBackground`, `clipBehavior` (default `Clip.hardEdge`), and `borderRadius` named parameters to `SwipeActionCell` constructor and `final` fields in `lib/src/widget/swipe_action_cell.dart` — include full `///` dartdoc on each field per Constitution VIII
- [x] T005 [US1] Add `_buildBackground(BuildContext context, SwipeProgress progress) → Widget` private method to `_SwipeActionCellState` in `lib/src/widget/swipe_action_cell.dart` — returns `SizedBox.shrink()` when `progress.direction == SwipeDirection.none` or when the direction's builder is null; otherwise calls and returns the builder result
- [x] T006 [US1] Refactor `AnimatedBuilder.builder` in `lib/src/widget/swipe_action_cell.dart`: move `SwipeProgress` computation outside `if (onProgressChanged != null)` guard so it always runs; add fast path (return `Transform.translate` directly when both builders are null); otherwise return `Stack([Positioned.fill(child: _buildBackground(...)), Transform.translate(...)])` — `widget.child` remains hoisted as `AnimatedBuilder.child`
- [x] T007 [US1] Add `_wrapWithClip(Widget child) → Widget` private method to `_SwipeActionCellState` in `lib/src/widget/swipe_action_cell.dart` — returns `ClipRRect` when `borderRadius != null`; returns `ClipRect` when `clipBehavior != Clip.none`; returns child unchanged otherwise — apply this method to wrap the `AnimatedBuilder` inside the `GestureDetector.child` slot
- [x] T008 [US1] Run direction-routing tests: `flutter test test/widget/swipe_action_cell_test.dart` — BG-W01 through BG-W05 and BG-W09 must all pass; all pre-existing F001 tests must continue to pass

**Checkpoint**: US1 complete — direction-aware backgrounds render correctly; child layout unaffected; null = no background.

---

## Phase 4: User Story 2 — Progress-Aware Background Rebuilding (Priority: P2)

**Goal**: Background builder receives a live `SwipeProgress` value on every animation frame, including throughout snap-back animation. The `ratio` decreases continuously from its release value back to `0.0` during snap-back; the builder is called each frame; the background slot is removed only when `ratio` reaches `0.0` and `direction` resets to `none`.

**Independent Test**: Mount a cell with a right background builder that appends each received `progress.ratio` to a list. Drag right, release below threshold (triggering snap-back). Verify ratio values were emitted during snap-back and are monotonically decreasing. Verify no builder call occurs after `pumpAndSettle` (idle state).

**Note**: No new production code is required if T006 (US1) correctly computes progress unconditionally and F001's state machine already maintains `_lockedDirection` during snap-back. These tests verify that guarantee.

### Tests for User Story 2 ⚠️ Write first — must FAIL before implementation

- [x] T009 [US2] Write snap-back behavior test group in `test/widget/swipe_action_cell_test.dart` — tests BG-W10 and BG-W11: (1) background builder is called during snap-back animation but not after `pumpAndSettle`; (2) ratio values emitted during snap-back are monotonically decreasing from release value to ~0.0

### Implementation for User Story 2

- [x] T010 [US2] Run snap-back tests: `flutter test test/widget/swipe_action_cell_test.dart` — BG-W10 and BG-W11 must pass; if either fails, inspect `_handleAnimationStatusChange` in `lib/src/widget/swipe_action_cell.dart` to confirm `_lockedDirection` is not reset before `animatingToClose` completes, and confirm progress is computed inside `AnimatedBuilder.builder` unconditionally (not gated)

**Checkpoint**: US2 complete — per-frame progress delivery during snap-back verified; background lifecycle correct.

---

## Phase 5: User Story 3 — Built-in Default Background Widget (Priority: P3)

**Goal**: `SwipeActionBackground` is a ready-to-use `StatefulWidget` that developers pass as the builder return value. Icon fades and scales with ratio (0.0=invisible, 1.0=fully visible). A brief scale bump (+30%) fires when `isActivated` first becomes true. Background color darkens slightly (−15% HSL lightness) as ratio → 1.0. Optional label renders below icon in a column.

**Independent Test**: Mount `SwipeActionBackground` in isolation (no `SwipeActionCell`) with a mock `SwipeProgress`. Verify icon `Opacity` at ratio=0.0 is 0.0; at ratio=1.0 is 1.0. Verify bump fires when `isActivated` transitions to true. Verify label appears/disappears based on null check.

**Note**: This phase can start in parallel with Phase 3 (US1) immediately after Phase 2 — `SwipeActionBackground` lives in a different file and has no dependency on the `SwipeActionCell` changes.

### Tests for User Story 3 ⚠️ Write first — must FAIL before implementation

- [x] T011 [P] [US3] Write 8 widget tests in `test/visual/swipe_action_background_test.dart` — BG-T01: icon opacity=0.0 at ratio=0.0; BG-T02: icon partially visible at ratio=0.5; BG-T03: icon fully visible at ratio=1.0; BG-T04: `Text` widget present when label non-null; BG-T05: no `Text` widget when label null; BG-T06: scale briefly exceeds 1.0 after `isActivated` false→true transition; BG-T07: `ColoredBox.color` differs at ratio=0.0 vs ratio=1.0; BG-T08: icon top-left.dy < label top-left.dy when both present

### Implementation for User Story 3

- [x] T012 [P] [US3] Create and fully implement `SwipeActionBackground` in `lib/src/visual/swipe_action_background.dart` including: `const` constructor with `icon`, `backgroundColor`, `foregroundColor`, `progress`, `label` params; `_SwipeActionBackgroundState` with `_bumpController` (300ms duration), `_bumpAnimation` (`TweenSequence` 0→0.3→0 easeOut/easeIn), `_wasActivated` bool; `didUpdateWidget` transition detection; `_intensifiedColor(ratio)` using `HSLColor.fromColor` with lightness −(0.15×ratio); `build` returning `AnimatedBuilder → ColoredBox → Center → Opacity → Transform.scale → Column([IconTheme(icon), optional Text(label)])`; full `///` dartdoc on all public members
- [x] T013 [US3] Run SwipeActionBackground tests: `flutter test test/visual/swipe_action_background_test.dart` — all 8 tests (BG-T01 to BG-T08) must pass

**Checkpoint**: US3 complete — `SwipeActionBackground` usable as a standalone widget; all visual behaviors verified in isolation.

---

## Phase 6: User Story 4 — Background Clipping and Border Radius (Priority: P4)

**Goal**: The background + child stack is clipped to the cell's bounds by default (`Clip.hardEdge`). When `borderRadius` is set, the clip follows the rounded rectangle. When `clipBehavior: Clip.none` and no `borderRadius`, no clipping is applied.

**Independent Test**: Mount a cell with `borderRadius: BorderRadius.circular(12)` and a background builder. Verify `ClipRRect` is in the widget tree. Mount with default config → `ClipRect` in tree. Mount with `clipBehavior: Clip.none` and no radius → neither `ClipRect` nor `ClipRRect` in tree.

**Note**: `_wrapWithClip` was already implemented in T007 (US1). This phase adds the targeted clipping tests that verify it.

### Tests for User Story 4 ⚠️ Write first — must FAIL before implementation if T007 was skipped; should pass immediately if T007 is complete

- [x] T014 [US4] Write clipping test group in `test/widget/swipe_action_cell_test.dart` — BG-W06: default `clipBehavior=Clip.hardEdge` → `ClipRect` in tree; BG-W07: `borderRadius: BorderRadius.circular(12)` → `ClipRRect` in tree; BG-W08: `clipBehavior: Clip.none` + no `borderRadius` → neither `ClipRect` nor `ClipRRect` in tree
- [x] T015 [US4] Run clipping tests: `flutter test test/widget/swipe_action_cell_test.dart` — BG-W06 through BG-W08 must pass; if any fail, verify `_wrapWithClip` in `lib/src/widget/swipe_action_cell.dart` correctly branches on `borderRadius != null` vs `clipBehavior != Clip.none` vs `Clip.none`

**Checkpoint**: US4 complete — all 4 user stories independently functional and verified.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Barrel export, full suite validation, static analysis, formatting.

- [x] T016 Add `export 'src/visual/swipe_action_background.dart';` under a `// Visual layer (002-swipe-background)` comment in `lib/swipe_action_cell.dart`
- [x] T017 [P] Run full test suite: `flutter test` — all tests (F001 pre-existing + BG-W01–W11 + BG-T01–T08) must pass with zero failures
- [x] T018 [P] Run static analysis: `flutter analyze` — must produce zero warnings or errors; fix any `public_member_api_docs` violations from newly added public members
- [x] T019 Run formatter check: `dart format --set-exit-if-changed .` — must exit 0; if non-zero, run `dart format .` and re-run check

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — blocks all user story phases
- **Phase 3 (US1)** and **Phase 5 (US3)**: Both depend on Phase 2 — **can start in parallel**
- **Phase 4 (US2)**: Depends on Phase 3 (US1) — same file, extends US1's implementation
- **Phase 6 (US4)**: Depends on Phase 3 (US1, specifically T007) — verifies T007's clipping logic
- **Phase 7 (Polish)**: Depends on all story phases complete

### User Story Dependencies

- **US1 (P1)**: After Phase 2 — independent of all other stories
- **US2 (P2)**: After US1 (T006 must compute progress unconditionally)
- **US3 (P3)**: After Phase 2 — **independent of US1/US2/US4** (different file)
- **US4 (P4)**: After US1 (T007 must implement `_wrapWithClip`)

### Within Each Phase

- Tests written and confirmed FAILING before implementation begins (Constitution VII)
- Implementation tasks within a phase are sequential (same files)
- Run task is always last in phase to confirm green

### Parallel Opportunities

| Tasks | Condition |
|-------|-----------|
| T011 (US3 tests) + T003 (US1 tests) | Both can be written in parallel after T002 |
| T012 (US3 impl) + T004–T007 (US1 impl) | Different files — fully parallel |
| T017 (flutter test) + T018 (flutter analyze) | Independent commands |

---

## Parallel Example: US1 and US3 after Phase 2

```
# Both can start immediately after T002:

Stream A — US1 (SwipeActionCell changes):
  T003 → T004 → T005 → T006 → T007 → T008

Stream B — US3 (SwipeActionBackground new widget):
  T011 → T012 → T013

# After both streams complete:
  T009 (US2 tests) → T010 (US2 run)
  T014 (US4 tests) → T015 (US4 run)
  T016 → T017 + T018 → T019
```

---

## Implementation Strategy

### MVP First (US1 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002)
3. Complete Phase 3: US1 (T003–T008)
4. **STOP and VALIDATE**: Direction-aware backgrounds work; child layout unaffected
5. Ship — developers can already wire custom builders per direction

### Incremental Delivery

1. Setup + Foundational → T001, T002
2. US1 → T003–T008 → **MVP: custom backgrounds per direction** ✅
3. US2 → T009–T010 → **+snap-back continuity verified** ✅
4. US3 → T011–T013 → **+SwipeActionBackground built-in** ✅
5. US4 → T014–T015 → **+clipping and border radius** ✅
6. Polish → T016–T019 → **package-ready** ✅

---

## Notes

- `[P]` tasks operate on different files — safe to execute concurrently
- `[Story]` label maps each task to a user story for traceability to spec.md
- Constitution VII (Test-First) is NON-NEGOTIABLE: write tests, confirm they fail, then implement
- All public members need `///` dartdoc (Constitution VIII) — `flutter analyze` will catch violations
- Do not modify `lib/src/core/swipe_progress.dart` or any F001 gesture/animation logic
- `widget.child` must remain hoisted as `AnimatedBuilder.child` — never move it into the builder lambda
- Fast path in T006 (no Stack when both builders are null) is required for Constitution X (60fps)

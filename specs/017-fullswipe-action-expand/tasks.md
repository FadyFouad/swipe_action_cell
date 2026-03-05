# Tasks: Full-Swipe Action Expand

**Input**: Design documents from `/specs/017-fullswipe-action-expand/`
**Prerequisites**: plan.md (required), spec.md (required), research.md, data-model.md, contracts/

**Tests**: Included — the spec explicitly requests new tests for visual expand behavior. Existing tests must also pass unchanged.

**Organization**: Tasks grouped by user story. Note: US1 (expand), US2 (reversible), and US5 (remove overlay) share the same implementation — they are combined into a single phase since they cannot be independently delivered.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

---

## Phase 1: Foundational (SwipeActionPanel Width Distribution)

**Purpose**: Add the core width interpolation capability to SwipeActionPanel. This is the blocking prerequisite for all user stories.

- [ ] T001 Add `fullSwipeRatio` (double, default 0.0) and `designatedActionIndex` (int?, default null) parameters with dartdoc to SwipeActionPanel constructor in `lib/src/actions/intentional/swipe_action_panel.dart`
- [ ] T002 Implement width distribution logic in `SwipeActionPanel.build()`: when `fullSwipeRatio > 0.0` and `designatedActionIndex != null`, replace `Expanded` children with `SizedBox(width: calculatedWidth)` children using the formula from data-model.md (normalWidth per action via flex ratios, non-designated shrink by `1.0 - fullSwipeRatio`, designated gets remaining width) in `lib/src/actions/intentional/swipe_action_panel.dart`
- [ ] T003 Add `ClipRect` wrapping around each action's content inside the `SizedBox` to prevent overflow as width shrinks below intrinsic content size in `lib/src/actions/intentional/swipe_action_panel.dart`

**Checkpoint**: SwipeActionPanel now accepts fullSwipeRatio and distributes widths — but not yet wired to SwipeActionCell

---

## Phase 2: User Story 1 + User Story 2 + User Story 5 — Core Expand & Remove Overlay (Priority: P1) MVP

**Goal**: Wire the expand behavior into SwipeActionCell and remove the separate overlay widget. US1 (expand), US2 (reversible — inherent in drag-driven math), and US5 (remove overlay) are delivered together.

**Independent Test**: Swipe a cell past activation threshold and verify designated action expands within the reveal panel. Swipe back and verify widths restore. Verify no FullSwipeExpandOverlay in widget tree.

### Tests for US1+US2+US5

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [ ] T004 [P] [US1] Write test: at `fullSwipeRatio == 0.0` all actions have equal width (`panelWidth / N`) in `test/full_swipe/full_swipe_expand_visual_test.dart`
- [ ] T005 [P] [US1] Write test: at `fullSwipeRatio == 0.5` designated action is wider than normalWidth, non-designated are narrower, sum of all widths == panelWidth in `test/full_swipe/full_swipe_expand_visual_test.dart`
- [ ] T006 [P] [US1] Write test: at `fullSwipeRatio == 1.0` designated action width == panelWidth, all other actions have width 0 in `test/full_swipe/full_swipe_expand_visual_test.dart`
- [ ] T007 [P] [US2] Write test: drag past threshold (ratio 1.0) then drag back (ratio 0.0) — all actions restore to equal widths in `test/full_swipe/full_swipe_expand_visual_test.dart`
- [ ] T008 [P] [US5] Write test: during full swipe, no `FullSwipeExpandOverlay` widget exists in widget tree in `test/full_swipe/full_swipe_expand_visual_test.dart`

### Implementation for US1+US2+US5

- [ ] T009 [US1] In `_buildRevealPanel()`, compute the designated action index by finding `fullSwipeConfig.action` in the actions list, and pass `fullSwipeRatio: _fullSwipeRatio` and `designatedActionIndex` (non-null only when `expandAnimation == true`) to `SwipeActionPanel` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T010 [US5] Remove the `FullSwipeExpandOverlay` widget from the `build()` Stack (lines ~2214–2225) in `lib/src/widget/swipe_action_cell.dart`
- [ ] T011 [US5] Remove the import of `full_swipe_expand_overlay.dart` from `lib/src/widget/swipe_action_cell.dart`
- [ ] T012 [US5] Delete the file `lib/src/actions/full_swipe/full_swipe_expand_overlay.dart`
- [ ] T013 [US5] Remove export of `FullSwipeExpandOverlay` from barrel file `lib/swipe_action_cell.dart` (if present; skip if internal-only)

**Checkpoint**: Designated action expands within reveal panel during full swipe. Overlay removed. Reversibility is automatic (drag-driven math). US1, US2, US5 all pass.

---

## Phase 3: User Story 3 — Shrinking Actions Fade Out (Priority: P2)

**Goal**: Non-designated actions fade to transparent as they shrink, preventing visual clutter from compressed content.

**Independent Test**: Swipe to midpoint and verify non-designated actions have opacity proportional to `1.0 - fullSwipeRatio`.

### Tests for US3

- [ ] T014 [P] [US3] Write test: at `fullSwipeRatio == 0.5`, non-designated actions have `Opacity` with value 0.5 in `test/full_swipe/full_swipe_expand_visual_test.dart`
- [ ] T015 [P] [US3] Write test: at `fullSwipeRatio == 1.0`, non-designated actions have `Opacity` with value 0.0 in `test/full_swipe/full_swipe_expand_visual_test.dart`

### Implementation for US3

- [ ] T016 [US3] Wrap each non-designated action in `Opacity(opacity: 1.0 - fullSwipeRatio)` within the `SizedBox > ClipRect` structure in `lib/src/actions/intentional/swipe_action_panel.dart`

**Checkpoint**: Shrinking actions now fade out proportionally. US3 passes.

---

## Phase 4: User Story 4 — Single Action Full Swipe (Priority: P2)

**Goal**: When only one action exists and it's the designated action, it expands from normalWidth to panelWidth with no sibling shrinking.

**Independent Test**: Configure a single-action cell with full swipe, drag past activation — action width grows to fill panelWidth.

### Tests for US4

- [ ] T017 [P] [US4] Write test: single action with `fullSwipeRatio == 0.5` — action width is between normalWidth and panelWidth in `test/full_swipe/full_swipe_expand_visual_test.dart`
- [ ] T018 [P] [US4] Write test: single action with `fullSwipeRatio == 1.0` — action width == panelWidth in `test/full_swipe/full_swipe_expand_visual_test.dart`

### Implementation for US4

No additional implementation needed — the width distribution math from T002 handles this automatically. When there are no non-designated actions, the designated action gets `panelWidth - 0 = panelWidth`. This phase only adds tests to verify the edge case.

**Checkpoint**: Single action full-swipe expand works. US4 passes.

---

## Phase 5: Edge Cases & Cross-Story Tests

**Purpose**: Verify edge cases and ensure existing tests still pass.

- [ ] T019 [P] Write test: designated action at index 0 (first) — later actions shrink correctly in `test/full_swipe/full_swipe_expand_visual_test.dart`
- [ ] T020 [P] Write test: designated action in the middle of 3 actions — actions on both sides shrink in `test/full_swipe/full_swipe_expand_visual_test.dart`
- [ ] T021 [P] Write test: icon stays centered within expanding designated action (verify `Center` widget presence) in `test/full_swipe/full_swipe_expand_visual_test.dart`
- [ ] T022 [P] Write test: `expandAnimation: false` disables expand (all actions stay equal width regardless of fullSwipeRatio) in `test/full_swipe/full_swipe_expand_visual_test.dart`
- [ ] T023 Run full existing test suite (`flutter test`) and verify all existing full-swipe tests pass without modification
- [ ] T024 Run `flutter analyze` and fix any warnings on modified/new files

**Checkpoint**: All edge cases verified. All existing tests pass. `flutter analyze` clean.

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Foundational)**: No dependencies — can start immediately
- **Phase 2 (US1+US2+US5)**: Depends on Phase 1 completion
- **Phase 3 (US3)**: Depends on Phase 1 completion (can run in parallel with Phase 2 since it modifies the same file differently — but safer to run sequentially)
- **Phase 4 (US4)**: Depends on Phase 1 completion (tests only — no implementation)
- **Phase 5 (Edge Cases)**: Depends on Phases 1–4 completion

### User Story Dependencies

- **US1 + US2 + US5 (P1)**: Core fix — must be done first. US2 (reversibility) is inherent in the drag-driven math, not a separate implementation.
- **US3 (P2)**: Opacity fade — can technically be implemented in Phase 1 (T003 is the natural place) but tested separately.
- **US4 (P2)**: No implementation — just test verification of existing math.

### Within Each Phase

- Tests (T004–T008, T014–T015, T017–T018) MUST be written and FAIL before implementation
- Panel changes (T001–T003) must complete before wiring (T009)
- Wiring (T009) before overlay removal (T010–T013)
- All implementation before existing test verification (T023)

### Parallel Opportunities

- T004, T005, T006, T007, T008 can all run in parallel (same test file, independent test cases)
- T014, T015 can run in parallel
- T017, T018 can run in parallel
- T010, T011 can run in parallel (both modify swipe_action_cell.dart but different sections)
- T019, T020, T021, T022 can all run in parallel

---

## Parallel Example: Phase 2 Tests

```text
# Write all US1+US2+US5 tests in parallel:
T004: "Test equal widths at ratio 0.0"
T005: "Test expanded width at ratio 0.5"
T006: "Test full expand at ratio 1.0"
T007: "Test reversibility on drag-back"
T008: "Test no FullSwipeExpandOverlay in tree"
```

---

## Implementation Strategy

### MVP First (US1 + US2 + US5)

1. Complete Phase 1: SwipeActionPanel width distribution (T001–T003)
2. Write Phase 2 tests (T004–T008) — verify they FAIL
3. Complete Phase 2 implementation (T009–T013)
4. Verify Phase 2 tests PASS
5. **STOP and VALIDATE**: Full-swipe expand works, overlay removed, reversible

### Incremental Delivery

1. Phase 1 + Phase 2 → MVP (core expand behavior) → Validate
2. Add Phase 3 (US3: opacity fade) → Validate
3. Add Phase 4 (US4: single action tests) → Validate
4. Phase 5 (edge cases + existing test verification) → Final validation

---

## Notes

- US1 and US2 share the same implementation — drag-driven width math is inherently reversible
- US5 is the cleanup counterpart to US1 — removing the overlay is only safe after the panel handles expansion
- Phase 3 (opacity) could be implemented alongside T002–T003 in Phase 1 since it modifies the same code block — but is tested separately for traceability
- The `_expandedIndex` destructive two-tap flow in SwipeActionPanel is NOT modified — it's orthogonal to the drag-driven expand
- Total: 3 files modified, 1 file deleted, 1 test file created

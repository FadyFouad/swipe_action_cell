# Tasks: Accessibility & RTL Layout Support (F8)

**Input**: Design documents from `specs/008-accessibility-rtl/`
**Prerequisites**: plan.md ✅ spec.md ✅ research.md ✅ data-model.md ✅ contracts/ ✅

**Tests**: Included — Constitution VII mandates test-first (NON-NEGOTIABLE). Tests appear before
their implementation tasks in every phase.

**Organization**: Tasks are grouped by user story to enable independent implementation and
testing of each story.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1–US5)
- All paths are relative to the repository root

---

## Phase 1: Setup

**Purpose**: Create missing test directory; verify structure is ready for new files.

- [ ] T001 Create `test/accessibility/` directory (mirrors `lib/src/accessibility/` for test organization)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Two independent modules that MUST be complete before any user story widget work
can begin. Groups A and B can be developed in parallel.

**⚠️ CRITICAL**: No user story implementation in the widget can begin until T007–T008 complete.

### Group A — Direction Resolver (blocks US3 config dispatch, US2 direction-aware keys)

- [ ] T002 [P] Write failing tests covering `ForceDirection` enum values and all `SwipeDirectionResolver` static method cases (LTR/RTL/override, forwardPhysical, backwardPhysical, configForPhysical) in `test/core/swipe_direction_resolver_test.dart`
- [ ] T003 [P] Implement `ForceDirection` enum (`auto`, `ltr`, `rtl`) and `SwipeDirectionResolver` abstract final class with `isRtl()`, `forwardPhysical()`, `backwardPhysical()`, `configForPhysical()` in `lib/src/core/swipe_direction_resolver.dart`

### Group B — Semantic Config Model (blocks US1 semantics wrapper, US5 label builders)

- [ ] T004 [P] Write failing tests for `SemanticLabel.string()`, `SemanticLabel.builder()`, `resolve()` fallback-to-empty, and `SwipeSemanticConfig` const construction and `copyWith` in `test/accessibility/swipe_semantic_config_test.dart`
- [ ] T005 [P] Implement `SemanticLabel` const-constructable value class (`.string()` and `.builder()` constructors, `resolve(BuildContext)` method returning empty string on null/empty builder result) in `lib/src/accessibility/swipe_semantic_config.dart`
- [ ] T006 [P] Implement `SwipeSemanticConfig` immutable config class with `cellLabel`, `rightSwipeLabel`, `leftSwipeLabel`, `panelOpenLabel`, `progressAnnouncementBuilder` fields and `copyWith` in `lib/src/accessibility/swipe_semantic_config.dart`

### Group C — Widget Parameter Skeleton (depends on T003 + T006; blocks all US widget tests)

- [ ] T007 Add `forwardSwipeConfig`, `backwardSwipeConfig`, `forceDirection`, `semanticConfig` parameters to `SwipeActionCell` constructor with correct types (`RightSwipeConfig?`, `LeftSwipeConfig?`, `ForceDirection`, `SwipeSemanticConfig?`) and defaults in `lib/src/widget/swipe_action_cell.dart`
- [ ] T008 Export `ForceDirection` from `lib/src/core/swipe_direction_resolver.dart`, and `SemanticLabel`, `SwipeSemanticConfig` from `lib/src/accessibility/swipe_semantic_config.dart` via `lib/swipe_action_cell.dart`

**Checkpoint**: Foundation ready. US1, US2, US3, US4, US5 widget phases can now begin.

---

## Phase 3: User Story 1 — Screen Reader Action Discovery (Priority: P1) 🎯 MVP

**Goal**: Every swipe action is discoverable and triggerable by screen reader users via
`CustomSemanticsAction`. State changes produce live announcements.

**Independent Test**: With a screen reader enabled, focus a configured swipe cell, open the
custom actions menu — both the progressive and intentional action labels appear. Activating
each produces the correct state change and an audible announcement.

### Tests for US1 ⚠️ Write first — must FAIL before T011

- [ ] T009 [US1] Write failing Semantics-tree tests: cell exposes `Semantics` node with `cellLabel`; `CustomSemanticsAction` for forward action registered when `rightSwipeConfig` non-null; `CustomSemanticsAction` for backward action registered when `leftSwipeConfig` non-null; neither registered when both configs null in `test/accessibility/swipe_semantics_test.dart`
- [ ] T010 [US1] Write failing label resolution tests: custom `rightSwipeLabel` overrides default; custom `leftSwipeLabel` overrides default; null config field falls back to direction-adaptive default; screen reader action trigger produces same observable state change (and announcement) as equivalent drag gesture in `test/accessibility/swipe_semantics_test.dart`

### Implementation for US1

- [ ] T011 [US1] Add `_cellFocusNode` (`FocusNode`) field to `SwipeActionCellState`; initialize in `initState()`; dispose in `dispose()` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T012 [US1] Implement private helpers: `_defaultForwardLabel(bool isRtl)` → "Swipe right to progress" / "Swipe left to progress"; `_defaultBackwardLabel(bool isRtl)` → "Swipe left for actions" / "Swipe right for actions"; `_resolveLabel(SemanticLabel?, String fallback, BuildContext)` with empty-string fallback logic in `lib/src/widget/swipe_action_cell.dart`
- [ ] T013 [US1] Build `Map<CustomSemanticsAction, VoidCallback> _buildSemanticActions(BuildContext)` that registers forward and backward actions only when their resolved configs are non-null, using resolved labels in `lib/src/widget/swipe_action_cell.dart`
- [ ] T014 [US1] Wrap the outermost build output with `Semantics(label: resolvedCellLabel, customSemanticsActions: _buildSemanticActions(context), child: ...)` in `SwipeActionCellState.build()` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T015 [US1] Implement `_triggerForwardFromSemantics()` and `_triggerBackwardFromSemantics()`: guard on `_isAnimating` (drop if true, per FR-007a); trigger the same internal action path as the gesture handler in `lib/src/widget/swipe_action_cell.dart`
- [ ] T016 [US1] Implement `_announceProgress(double current, double max)` (uses `progressAnnouncementBuilder` or auto-formats "Progress incremented to N of M") and `_announcePanelOpen()` (uses `panelOpenLabel` or "Action panel open") via `SemanticsService.announce()`, both guarded with `if (mounted)` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T017 [US1] Wire `_announceProgress()` to the snap-back animation completion callback after a successful progressive action, and `_announcePanelOpen()` to the `SwipeState.revealed` transition in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: US1 fully functional — screen reader can discover, activate, and hear outcomes for both swipe actions.

---

## Phase 4: User Story 3 — RTL Layout Auto-Detection (Priority: P2)

**Goal**: Wrapping a swipe cell in `Directionality(textDirection: TextDirection.rtl)` with no
other changes produces correct gesture dispatch and visual layout automatically.

**Independent Test**: Wrap a cell in an RTL `Directionality` widget. Drag left → progressive
action fires; drag right → intentional panel opens. Existing LTR behavior is unchanged.

### Tests for US3 ⚠️ Write first — must FAIL before T020

- [ ] T018 [P] [US3] Write failing LTR regression baseline tests: right drag activates `rightSwipeConfig`; left drag activates `leftSwipeConfig`; `rightBackground` shown during right drag; `leftBackground` shown during left drag in `test/widget/swipe_action_cell_rtl_test.dart`
- [ ] T019 [P] [US3] Write failing RTL remapping tests: under RTL `Directionality`, left drag activates `rightSwipeConfig` (forward); right drag activates `leftSwipeConfig` (backward); backgrounds flip to correct sides; `forwardSwipeConfig`/`backwardSwipeConfig` aliases activate on semantically correct physical direction; `forceDirection: ForceDirection.ltr` in RTL context behaves as LTR; `forceDirection: ForceDirection.rtl` in LTR context behaves as RTL in `test/widget/swipe_action_cell_rtl_test.dart`

### Implementation for US3

- [ ] T020 [US3] Add `bool get _isRtl` computed property to `SwipeActionCellState` using `SwipeDirectionResolver.isRtl(context, widget.forceDirection)` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T021 [US3] Add `_resolvedForwardConfig` getter (`widget.forwardSwipeConfig ?? widget.rightSwipeConfig`) and `_resolvedBackwardConfig` getter (`widget.backwardSwipeConfig ?? widget.leftSwipeConfig`) to `SwipeActionCellState` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T022 [US3] Add `bool get _dragIsForward` (`_lockedDirection == SwipeDirectionResolver.forwardPhysical(_isRtl)`) and `bool get _dragIsBackward` computed properties to `SwipeActionCellState` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T023 [US3] Replace all `_lockedDirection == SwipeDirection.right` comparisons (config selection, max-translation lookup, velocity checks) with `_dragIsForward`/`_dragIsBackward` throughout `_handleDragUpdate()` and `_handleDragEnd()` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T024 [US3] Update `_buildBackground()` to select `visualConfig.rightBackground` when drag is semantically forward and `visualConfig.leftBackground` when backward (replacing the current physical-direction check) in `lib/src/widget/swipe_action_cell.dart`
- [ ] T025 [US3] Replace remaining `effectiveRightSwipeConfig`/`effectiveLeftSwipeConfig` usages in `build()`, `_buildProgressIndicator()`, `_buildRevealPanel()`, and haptic-threshold guards with `_resolvedForwardConfig`/`_resolvedBackwardConfig` in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: US3 fully functional — RTL layout auto-detects and mirrors correctly; LTR unchanged.

---

## Phase 5: User Story 2 — Keyboard Navigation on Desktop and Web (Priority: P2)

**Goal**: A keyboard-only user can Tab to a swipe cell, use arrow keys to trigger actions,
Tab into panel buttons, and press Escape to close the panel with focus returning to the cell.

**Independent Test**: In a desktop or web flutter build, Tab to a swipe cell. Press right arrow
→ progressive action fires. Press left arrow → panel opens. Press Escape → panel closes, focus
returns to cell.

### Tests for US2 ⚠️ Write first — must FAIL before T028

- [ ] T026 [P] [US2] Write failing focus tests: cell is reachable by Tab; cell is not auto-focused on mount; Tab with panel closed moves to next focusable widget (not into panel) in `test/accessibility/swipe_keyboard_nav_test.dart`
- [ ] T027 [P] [US2] Write failing keyboard action tests: right arrow (LTR) triggers forward action; left arrow (LTR) opens backward panel; left arrow (RTL) triggers forward action; right arrow (RTL) opens backward panel; arrow input silently dropped when animation in progress; no-op when config is null for that direction in `test/accessibility/swipe_keyboard_nav_test.dart`
- [ ] T028 [P] [US2] Write failing Escape and focus restoration tests: Escape closes open panel and returns focus to cell; `SwipeController.close()` also returns focus to cell; Tab with panel open moves focus to first panel action button in `test/accessibility/swipe_keyboard_nav_test.dart`

### Implementation for US2

- [ ] T029 [US2] Wrap `Semantics(...)` node (from T014) with `Focus(focusNode: _cellFocusNode, onKey: _handleKeyEvent, child: Semantics(...))` in `SwipeActionCellState.build()` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T030 [US2] Implement `_handleKeyEvent(FocusNode, RawKeyEvent) → KeyEventResult`: map forward/backward arrow keys using `_isRtl`; call `_triggerForwardFromKeyboard()` / `_triggerBackwardFromKeyboard()` when not animating; handle Escape to close panel and request cell focus; return `KeyEventResult.handled` for arrow and Escape; `ignored` for all others in `lib/src/widget/swipe_action_cell.dart`
- [ ] T031 [US2] Implement `_triggerForwardFromKeyboard()` and `_triggerBackwardFromKeyboard()`: same `_isAnimating` guard as semantics triggers; share internal action path in `lib/src/widget/swipe_action_cell.dart`
- [ ] T032 [US2] Add focus restoration to `executeClose()` via `WidgetsBinding.instance.addPostFrameCallback`: if `mounted` and panel had been open, call `_cellFocusNode.requestFocus()` in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: US2 fully functional — full keyboard navigation operable on desktop/web.

---

## Phase 6: User Story 4 — Reduced Motion Compliance (Priority: P3)

**Goal**: When the device's "Reduce Motion" accessibility setting is on, all swipe transitions
complete in a single frame with no animation.

**Independent Test**: Wrap cell in `MediaQuery(data: MediaQueryData(disableAnimations: true), ...)`.
Perform a swipe gesture. Pump one frame. Cell is in final resting state — no further frames needed.

### Tests for US4 ⚠️ Write first — must FAIL before T034

- [ ] T033 [US4] Write failing reduced motion tests: with `MediaQuery.disableAnimations = true`, snap-back completes after a single `pump()` call (no `pumpAndSettle` needed); `animateToOpen` also completes in one pump; with `disableAnimations = false`, spring animation requires multiple frames in `test/accessibility/swipe_reduced_motion_test.dart`

### Implementation for US4

- [ ] T034 [US4] Add `if (MediaQuery.of(context).disableAnimations) { _controller.value = 0.0; return; }` guard at the start of `_snapBack()` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T035 [US4] Add `if (MediaQuery.of(context).disableAnimations) { _controller.value = toOffset; return; }` guard at the start of `_animateToOpen()` in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: US4 fully functional — all transitions are instant when reduce-motion is enabled.

---

## Phase 7: User Story 5 — Localized Semantic Labels (Priority: P3)

**Goal**: A developer can pass `SemanticLabel.builder((ctx) => AppLocalizations.of(ctx).label)`
to any label field; the screen reader announces the correct locale-appropriate string on every
build. Default labels adapt to the resolved direction (LTR/RTL).

**Independent Test**: Provide a builder that returns different strings per `Localizations.localeOf(context)`.
Change the locale in a test. Confirm the semantics tree emits the new locale's string without
any other widget change.

### Tests for US5 ⚠️ Write first — must FAIL before T037

- [ ] T036 [US5] Write failing localization tests: `SemanticLabel.builder` resolves fresh on each build (not cached); changing locale in widget tree causes semantics label to update; null/empty builder return falls back to direction-adaptive default (not empty string); LTR default labels and RTL default labels are distinct and correct in `test/accessibility/swipe_semantic_labels_test.dart`

### Implementation for US5

- [ ] T037 [US5] Confirm `SemanticLabel.resolve(BuildContext)` calls the builder function on every invocation with no internal caching; if any caching was added in T005, remove it in `lib/src/accessibility/swipe_semantic_config.dart`
- [ ] T038 [US5] Confirm `_defaultForwardLabel(bool isRtl)` and `_defaultBackwardLabel(bool isRtl)` (from T012) correctly emit RTL variants ("Swipe left to progress", "Swipe right for actions"); add missing RTL strings if absent in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: US5 fully functional — builder-based labels are locale-reactive and direction-adaptive defaults are correct in both LTR and RTL.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Dartdoc, full regression tests, static quality checks.

- [ ] T039 [P] Write `///` dartdoc comments for `ForceDirection` enum and each value, and `SwipeDirectionResolver` class and all public members in `lib/src/core/swipe_direction_resolver.dart`
- [ ] T040 [P] Write `///` dartdoc comments for `SemanticLabel` class and constructors, `resolve()`, `SwipeSemanticConfig` class and all fields and `copyWith` in `lib/src/accessibility/swipe_semantic_config.dart`
- [ ] T041 [P] Write `///` dartdoc comments for `SwipeActionCell.semanticConfig`, `SwipeActionCell.forwardSwipeConfig`, `SwipeActionCell.backwardSwipeConfig`, `SwipeActionCell.forceDirection` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T042 [P] Write full LTR regression tests: run all existing swipe_action_cell scenarios (progressive right swipe, intentional left swipe, controller close, theme inheritance, group controller) with no new params provided — confirm zero behavioral changes in `test/widget/swipe_action_cell_a11y_regression_test.dart`
- [ ] T043 [P] Write WCAG AA static contrast assertions: compute relative luminance of default background colors and assert ≥ 3:1 ratio for non-text UI components in `test/widget/swipe_action_cell_a11y_regression_test.dart`
- [ ] T044 Run `flutter analyze` on the whole project and resolve all warnings/errors (zero warnings required per Constitution)
- [ ] T045 Run `dart format --set-exit-if-changed .` on all modified and new files; fix any formatting issues
- [ ] T046 Run `flutter test` and confirm all tests pass with zero failures or skips

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup)
    └── Phase 2 (Foundational)
            ├── Group A (T002–T003) ─────────────────────┐
            ├── Group B (T004–T006) ─────────────────────┤
            └── Group C (T007–T008) ← depends A+B ───────┤
                        │                                 │
              ┌─────────┼────────────────────┐            │
              ↓         ↓                    ↓            │
          Phase 3    Phase 4             Phase 6          │
          (US1 P1)  (US3 P2)            (US4 P3)          │
              │         │                                  │
              └────┬────┘                                  │
                   ↓                                       │
               Phase 5                                     │
               (US2 P2) ← benefits from US1+US3 complete   │
                   │                                       │
               Phase 7                                     │
               (US5 P3) ← extends US1 label system ────────┘
                   │
               Phase 8
               (Polish)
```

### User Story Dependencies

- **US1 (P1)**: Depends on Phase 2 completion only. No dependency on other stories.
- **US3 (P2)**: Depends on Phase 2 (Group A + C). No dependency on US1.
- **US2 (P2)**: Depends on Phase 2 (Group A + C). Shares `_cellFocusNode` with US1 — start after US1 T011 completes.
- **US4 (P3)**: Depends on Phase 2 (Group C) only. Fully independent of US1/US2/US3.
- **US5 (P3)**: Extends US1 label system. Start after US1 is complete.

### Within Each User Story

Tests MUST be written and FAIL before any implementation task in the same story begins.
Within implementation: helpers before wrappers, wrappers before wiring.

### Parallel Opportunities

- **Phase 2 Group A ‖ Group B**: `swipe_direction_resolver.dart` and `swipe_semantic_config.dart`
  are independent files — develop concurrently.
- **US1 ‖ US3 ‖ US4**: All three depend on Phase 2 only; after T007–T008 complete these three
  stories can proceed simultaneously.
- **Within Phase 8**: T039, T040, T041, T042, T043 all touch different files — parallel.

---

## Parallel Example: Phase 2 Foundation

```
# Launch both foundation groups simultaneously:

Agent A: "Write failing tests and implement SwipeDirectionResolver
          in test/core/swipe_direction_resolver_test.dart and
          lib/src/core/swipe_direction_resolver.dart (T002–T003)"

Agent B: "Write failing tests and implement SemanticLabel + SwipeSemanticConfig
          in test/accessibility/swipe_semantic_config_test.dart and
          lib/src/accessibility/swipe_semantic_config.dart (T004–T006)"

# Then (after both complete):
Agent C: "Add widget parameters T007 and barrel exports T008"
```

## Parallel Example: US1 ‖ US3 ‖ US4

```
# After T007–T008 complete, launch all three simultaneously:

Agent A: "Implement US1 Screen Reader tasks T009–T017
          in test/accessibility/swipe_semantics_test.dart and
          lib/src/widget/swipe_action_cell.dart"

Agent B: "Implement US3 RTL tasks T018–T025
          in test/widget/swipe_action_cell_rtl_test.dart and
          lib/src/widget/swipe_action_cell.dart"
          ⚠️ NOTE: Same file as Agent A — coordinate to avoid conflicts.
          Sequential within the file is safer than parallel for T023–T025.

Agent C: "Implement US4 Reduced Motion tasks T033–T035
          in test/accessibility/swipe_reduced_motion_test.dart and
          lib/src/widget/swipe_action_cell.dart"
          ⚠️ NOTE: Same file — coordinate with A and B.
```

> **Same-file warning**: US1, US3, and US4 all modify `lib/src/widget/swipe_action_cell.dart`.
> If working solo, implement sequentially in priority order (US1 → US3 → US4). If working
> with agents, assign non-overlapping methods to each agent.

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 + Phase 2 (setup + foundation)
2. Complete Phase 3 (US1 — screen reader support)
3. **STOP and VALIDATE**: Semantics tree tests pass; screen reader can discover and activate actions
4. Ship — this alone closes the P1 accessibility gap

### Incremental Delivery

1. Phase 1 + 2 → Foundation ready
2. Phase 3 → US1 ✅ Ship: screen reader accessible (MVP)
3. Phase 4 → US3 ✅ Ship: RTL markets supported
4. Phase 5 → US2 ✅ Ship: keyboard-operable on desktop/web
5. Phase 6 → US4 ✅ Ship: vestibular/motion-sensitive users covered
6. Phase 7 → US5 ✅ Ship: fully localized accessibility labels
7. Phase 8 → Polish ✅ Merge to main

### Sequential Solo Strategy

```
T001 → T002→T003 → T004→T005→T006 → T007→T008
→ T009→T010 → T011→T012→T013→T014→T015→T016→T017  [US1]
→ T018→T019 → T020→T021→T022→T023→T024→T025        [US3]
→ T026→T027→T028 → T029→T030→T031→T032             [US2]
→ T033 → T034→T035                                  [US4]
→ T036 → T037→T038                                  [US5]
→ T039→T040→T041→T042→T043 → T044 → T045 → T046   [Polish]
```

---

## Task Count Summary

| Phase | Story | Tasks | Notes |
|-------|-------|-------|-------|
| Setup | — | 1 (T001) | Directory creation |
| Foundational | — | 7 (T002–T008) | A ‖ B then C |
| US1 Screen Reader | P1 | 9 (T009–T017) | Tests T009–T010 first |
| US3 RTL Layout | P2 | 8 (T018–T025) | Tests T018–T019 first |
| US2 Keyboard Nav | P2 | 7 (T026–T032) | Tests T026–T028 first |
| US4 Reduced Motion | P3 | 3 (T033–T035) | Test T033 first |
| US5 Localized Labels | P3 | 3 (T036–T038) | Test T036 first |
| Polish | — | 8 (T039–T046) | T039–T043 parallel |
| **Total** | | **46** | |

---

## Notes

- `[P]` tasks touch different files (or non-conflicting sections) and can safely parallelize
- Constitution VII: tests MUST be written and failing before implementation in every phase
- `lib/src/widget/swipe_action_cell.dart` is modified by US1, US2, US3, and US4 — serialize
  work on this file or assign non-overlapping methods to avoid merge conflicts
- `Positioned` within Stack auto-mirrors in RTL — no manual changes needed for `_buildRevealPanel`
  or `_buildProgressIndicator`
- `Transform.translate` does NOT auto-mirror — but since `_controller.value` tracks raw physical
  offset, it is already direction-correct in both LTR and RTL (no offset negation needed)
- Guard all `SemanticsService.announce()` and `FocusNode.requestFocus()` calls with `if (mounted)`

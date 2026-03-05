# Tasks: Full-Swipe Auto-Trigger (F016)

**Input**: Design documents from `specs/016-full-swipe-trigger/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/public-api.md ✓, quickstart.md ✓

**Tests**: Included — Constitution VII (Test-First) is NON-NEGOTIABLE. RED tests must be written and verified failing before each implementation cluster.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on in-progress tasks)
- **[Story]**: Which user story (US1–US6) this task belongs to
- Include exact file paths in descriptions

---

## Phase 1: Setup (Directory Structure)

**Purpose**: Create new source file skeletons before any implementation begins

- [x] T001 Create `lib/src/actions/full_swipe/` directory with empty `full_swipe_config.dart` and `full_swipe_expand_overlay.dart` stub files and `test/full_swipe/` directory with `.gitkeep`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data types and enum extensions that EVERY user story depends on. No user story work can begin until this phase is complete.

**⚠️ CRITICAL**: All Phase 3–8 tasks block on Phase 2 completion.

- [x] T002 Create `FullSwipeConfig` class and `FullSwipeProgressBehavior` enum with `const` constructor, `copyWith`, `==`, `hashCode`, dartdoc in `lib/src/actions/full_swipe/full_swipe_config.dart`
- [x] T003 Write RED unit tests for `FullSwipeConfig` (copyWith, ==, hashCode, const constructor, default field values) in `test/full_swipe/full_swipe_config_test.dart`
- [x] T004 [P] Add `fullSwipeRatio: double` (default `0.0`) to `SwipeProgress` — update `copyWith`, `==`, `hashCode`, `toString`, `zero` constant in `lib/src/core/swipe_progress.dart`
- [x] T005 [P] Add `fullSwipeConfig: FullSwipeConfig?` field (default `null`) to `LeftSwipeConfig` — update constructor, `copyWith`, `==`, `hashCode` in `lib/src/config/left_swipe_config.dart`
- [x] T006 [P] Add `fullSwipeConfig: FullSwipeConfig?` field (default `null`) to `RightSwipeConfig` — update constructor, `copyWith`, `==`, `hashCode` in `lib/src/config/right_swipe_config.dart`
- [x] T007 [P] Add `fullSwipeThresholdCrossed` and `fullSwipeActivation` values to `SwipeFeedbackEvent` enum in `lib/src/feedback/swipe_feedback_config.dart`

**Checkpoint**: Foundation ready — T004/T005/T006/T007 can run in parallel; T002 and T003 must be sequential (RED test must fail before T002, green after). User story implementation can begin after all six tasks complete.

---

## Phase 3: User Story 1 — Left Swipe to Delete / iOS Mail Pattern (Priority: P1) 🎯 MVP

**Goal**: When the user drags a cell left past `FullSwipeConfig.threshold` (default 75%) and releases, the designated action fires immediately, `onFullSwipeTriggered` callback is invoked, and the cell plays its `postActionBehavior` animation. Dragging back below the threshold before releasing cancels commitment. New gestures are locked out during the post-action animation.

**Independent Test**: Configure `SwipeActionCell` with left swipe reveal mode, `FullSwipeConfig(enabled: true, threshold: 0.75, action: deleteAction)`. Drag left 80% and release. Verify `deleteAction.onTap` fires, `onFullSwipeTriggered` fires with `direction: left, action: deleteAction`, and cell animates out. Drag left 80% then back to 60% before release — verify only normal reveal, no action fires.

### Tests for User Story 1 ⚠️ Write FIRST — must FAIL before implementation

- [x] T008 [P] [US1] Write RED test: full swipe past threshold triggers designated action and `onFullSwipeTriggered` callback in `test/full_swipe/full_swipe_gesture_test.dart`
- [x] T009 [P] [US1] Write RED test: dragging below full-swipe threshold but above reveal threshold = normal reveal, action does NOT fire in `test/full_swipe/full_swipe_gesture_test.dart`
- [x] T010 [P] [US1] Write RED test: gesture re-entry is blocked while `_fullSwipeTriggered` is true (post-action animation in progress) in `test/full_swipe/full_swipe_gesture_test.dart`

### Implementation for User Story 1

- [x] T011 [US1] Add `onFullSwipeTriggered: void Function(SwipeDirection, SwipeAction)?` parameter to `SwipeActionCell` constructor with dartdoc in `lib/src/widget/swipe_action_cell.dart`
- [x] T012 [US1] Add private state fields to `SwipeActionCellState`: `_isFullSwipeArmed` (bool), `_fullSwipeTriggered` (bool), `_fullSwipeRatio` (double) in `lib/src/widget/swipe_action_cell.dart`
- [x] T013 [US1] Implement `_resolvedFullSwipeConfig(SwipeDirection direction) → FullSwipeConfig?` helper method in `lib/src/widget/swipe_action_cell.dart`
- [x] T014 [US1] Implement `_validateFullSwipeConfigs()` with all four debug assertions (threshold > activationThreshold, threshold > max zone threshold, reveal mode action in panel, non-empty action label); call from `_resolveEffectiveConfigs` in `lib/src/widget/swipe_action_cell.dart`
- [x] T015 [US1] Implement `_checkFullSwipeThreshold(double absOffset, double widgetWidth)` per plan spec (compute `_fullSwipeRatio`, toggle `_isFullSwipeArmed`) and wire call into `_handleDragUpdate` after `_controller.value` is set in `lib/src/widget/swipe_action_cell.dart`
- [x] T016 [US1] Implement `_animateOutDirectional(SwipeDirection direction)` — animates to `±widgetWidth * 1.5` using existing `completionSpring`; respects `MediaQuery.disableAnimations` in `lib/src/widget/swipe_action_cell.dart`
- [x] T017 [US1] Implement `_applyFullSwipeAction(SwipeDirection direction, FullSwipeConfig cfg)` — sets `_fullSwipeTriggered`, fires action/callbacks, dispatches haptic, handles all three `PostActionBehavior` cases (`snapBack`, `animateOut`, `stay`) in `lib/src/widget/swipe_action_cell.dart`
- [x] T018 [US1] Wire full-swipe early-return block into `_handleDragEnd`: if `_isFullSwipeArmed` and config enabled, call `_applyFullSwipeAction` and return before normal zone check in `lib/src/widget/swipe_action_cell.dart`
- [x] T019 [US1] Add gesture lock release — in `_handleAnimationStatusChange`, at the start of `animatingToClose` and `animatingOut` completion branches, reset `_fullSwipeTriggered = false` in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: User Story 1 fully functional — gesture-triggered full-swipe fires action, callbacks work, gesture lock prevents double-trigger, postActionBehavior animations play correctly.

---

## Phase 4: User Story 2 — Visual Commit Indicator During Full-Swipe (Priority: P1)

**Goal**: As the drag ratio crosses `fullSwipeConfig.threshold`, the designated action's background expands to fill the cell, its icon scales to center stage, and all other action buttons fade out. Dragging back reverses this smoothly. A brief "locked-in" bump animation (1.0 → 1.15 → 1.0, 150ms) fires once on threshold entry. The `FullSwipeExpandOverlay` is driven by `fullSwipeRatio` (0.0–1.0) computed in `_checkFullSwipeThreshold` and the bump `AnimationController`.

**Independent Test**: Configure `expandAnimation: true` with a left full-swipe. Drag to 80%. Assert `FullSwipeExpandOverlay` is in the widget tree, designated action icon is centered, background matches action color, and sibling actions have opacity 0. Drag back to 60%. Assert normal reveal panel layout is restored.

### Tests for User Story 2 ⚠️ Write FIRST — must FAIL before implementation

- [x] T020 [P] [US2] Write RED test: expand animation plays when drag crosses threshold; verify `fullSwipeRatio` transitions from 0.0 to 1.0 in `test/full_swipe/full_swipe_visual_test.dart`
- [x] T021 [P] [US2] Write RED test: other actions fade out during expansion; dragging back below threshold reverses expansion smoothly in `test/full_swipe/full_swipe_visual_test.dart`

### Implementation for User Story 2

- [x] T022 [US2] Implement `FullSwipeExpandOverlay` stateless widget: fades out non-designated actions, scales/centers designated action icon, fills background color — all driven by `fullSwipeRatio` (0.0–1.0) and optional `bumpAnimation`; dartdoc all public members in `lib/src/actions/full_swipe/full_swipe_expand_overlay.dart`
- [x] T023 [US2] Integrate `FullSwipeExpandOverlay` into `SwipeActionCell` Stack — insert between reveal panel and `decoratedChild`, only when `fullSwipeConfig != null`; pass live `_fullSwipeRatio` and bump animation in `lib/src/widget/swipe_action_cell.dart`
- [x] T024 [US2] Add `_fullSwipeBumpController` (`AnimationController?`, 150ms `TweenSequence` 1.0 → 1.15 → 1.0) to `SwipeActionCellState`; initialize only when `fullSwipeConfig != null` (zero overhead when disabled) in `lib/src/widget/swipe_action_cell.dart`
- [x] T025 [US2] Wire bump animation: implement `_triggerFullSwipeBump()` called from `_checkFullSwipeThreshold` on arm entry; suppress when `MediaQuery.of(context).disableAnimations` is true in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: User Stories 1 AND 2 are both independently functional. Expand-to-fill visual plays bidirectionally; bounce animation fires on threshold entry; disabled state has zero extra widget tree nodes.

---

## Phase 5: User Story 3 — Right Swipe Full-Trigger / Symmetric with Left (Priority: P2)

**Goal**: `FullSwipeConfig` works symmetrically on right swipe. In progressive mode, `FullSwipeProgressBehavior.setToMax` jumps the value to `maxValue`; `customAction` fires a separate action. In reveal/intentional mode, behavior is identical to left swipe. The two-commitment-level pattern (auto-trigger at 40%, full-swipe at 75%) works on both directions.

**Independent Test**: Configure right swipe progressive mode with `maxValue: 10` and `FullSwipeConfig(fullSwipeProgressBehavior: setToMax)`. Drag right 80%. Assert progress jumps to 10 and `onFullSwipeTriggered` fires. Separately, configure left auto-trigger + full-swipe. Drag to 50% — archive fires. Drag to 80% — delete fires; archive does NOT fire.

### Tests for User Story 3 ⚠️ Write FIRST — must FAIL before implementation

- [x] T026 [P] [US3] Write RED test: right swipe progressive mode + `setToMax` — full swipe jumps progress to `maxValue` in `test/full_swipe/full_swipe_integration_test.dart`
- [x] T027 [P] [US3] Write RED test: left `autoTrigger` + `FullSwipeConfig` — two commitment levels; full-swipe fires delete, does NOT also fire archive in `test/full_swipe/full_swipe_integration_test.dart`

### Implementation for User Story 3

- [x] T028 [US3] Handle `FullSwipeProgressBehavior.setToMax` branch in `_applyFullSwipeAction`: update `_progressValueNotifier!.value` to `fwdCfg.maxValue`, fire `onMaxReached` and `onProgressChanged` callbacks in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: Right swipe full-trigger and dual-threshold left swipe both work correctly. `setToMax` jumps progressive value; two-action scenarios are independent.

---

## Phase 6: User Story 4 — Haptic Feedback at Threshold Crossing (Priority: P2)

**Goal**: When drag crosses the full-swipe threshold (either direction), `fullSwipeThresholdCrossed` haptic fires. On release above threshold, `fullSwipeActivation` haptic fires. Both are gated by `FullSwipeConfig.enableHaptic`. Consumers can override patterns via `SwipeFeedbackConfig.hapticOverrides`.

**Independent Test**: Configure `enableHaptic: true`. Spy on `FeedbackDispatcher`. Drag past threshold — assert `fullSwipeThresholdCrossed` event dispatched. Release — assert `fullSwipeActivation` dispatched. Repeat with `enableHaptic: false` — assert no events dispatched.

### Tests for User Story 4 ⚠️ Write FIRST — must FAIL before implementation

- [x] T029 [P] [US4] Write RED test: `fullSwipeThresholdCrossed` fires on crossing; `fullSwipeActivation` fires on release above threshold in `test/full_swipe/full_swipe_haptic_test.dart`
- [x] T030 [P] [US4] Write RED test: `enableHaptic: false` suppresses both haptic events in `test/full_swipe/full_swipe_haptic_test.dart`

### Implementation for User Story 4

- [x] T031 [US4] Add `_feedbackDispatcher?.fire(SwipeFeedbackEvent.fullSwipeThresholdCrossed, isForward: _dragIsForward)` dispatch in `_checkFullSwipeThreshold` on `_isFullSwipeArmed` state transition, gated by `cfg.enableHaptic` in `lib/src/widget/swipe_action_cell.dart`
- [x] T032 [US4] Add `_feedbackDispatcher?.fire(SwipeFeedbackEvent.fullSwipeActivation, isForward: _dragIsForward)` dispatch in `_applyFullSwipeAction`, gated by `cfg.enableHaptic`, before action execution in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: Haptic events fire correctly at threshold crossing and on activation. `enableHaptic: false` suppresses both. Haptic overrides via `SwipeFeedbackConfig` work.

---

## Phase 7: User Story 5 — Programmatic Full-Swipe via SwipeController (Priority: P3)

**Goal**: `SwipeController.triggerFullSwipe(SwipeDirection direction)` programmatically fires the designated full-swipe action — identical behavior to a gesture release above threshold (action fires, `onFullSwipeTriggered` called, haptic fires, post-action animation plays). No-op with debug assert when direction not configured or state is not idle.

**Independent Test**: Attach `SwipeController` to a cell with left full-swipe configured. Call `controller.triggerFullSwipe(SwipeDirection.left)`. Assert action fires and cell responds identically to gesture-triggered full-swipe. Call with right direction when not configured — assert no-op, no crash.

### Tests for User Story 5 ⚠️ Write FIRST — must FAIL before implementation

- [x] T033 [P] [US5] Write RED test: `triggerFullSwipe(left)` fires action and `onFullSwipeTriggered`; `triggerFullSwipe(right)` is no-op when right full-swipe not configured in `test/full_swipe/full_swipe_controller_test.dart`

### Implementation for User Story 5

- [x] T034 [US5] Add `void executeTriggerFullSwipe(SwipeDirection direction)` abstract method to `SwipeCellHandle` with dartdoc in `lib/src/controller/swipe_cell_handle.dart`
- [x] T035 [US5] Implement `executeTriggerFullSwipe` on `SwipeActionCellState`: assert config exists and state is idle, then call `_applyFullSwipeAction` in `lib/src/widget/swipe_action_cell.dart`
- [x] T036 [US5] Add `void triggerFullSwipe(SwipeDirection direction)` to `SwipeController` with dartdoc; delegate to `_handle!.executeTriggerFullSwipe(direction)` in `lib/src/controller/swipe_controller.dart`

**Checkpoint**: Programmatic full-swipe trigger works identically to gesture trigger. No-op cases are safe. Debug assertion fires descriptively on misconfigured calls.

---

## Phase 8: User Story 6 — Accessibility & Keyboard Navigation (Priority: P3)

**Goal**: Screen reader announces "Swipe fully to [action label]" for each enabled full-swipe direction. `Shift+ArrowLeft` (LTR) / `Shift+ArrowRight` (RTL) triggers left full-swipe; `Shift+ArrowRight` (LTR) / `Shift+ArrowLeft` (RTL) triggers right. RTL layout maps physical directions to correct semantic actions without consumer configuration.

**Independent Test**: Focus a cell with left full-swipe on Delete. Verify semantic tree includes "Swipe fully to Delete". Press `Shift+Left Arrow` — verify delete fires. Wrap in `Directionality(TextDirection.rtl)` — press `Shift+Right Arrow` — verify same semantic action fires.

### Tests for User Story 6 ⚠️ Write FIRST — must FAIL before implementation

- [x] T037 [P] [US6] Write RED test: `Semantics` widget includes "Swipe fully to [label]" custom action; `Shift+ArrowLeft` triggers left full-swipe action in `test/full_swipe/full_swipe_gesture_test.dart`
- [x] T038 [P] [US6] Write RED test: RTL layout — `Shift+ArrowRight` triggers semantic left (backward) full-swipe action in `test/full_swipe/full_swipe_integration_test.dart`

### Implementation for User Story 6

- [x] T039 [US6] Add `fullSwipeLeftLabel: SemanticLabel?` and `fullSwipeRightLabel: SemanticLabel?` fields to `SwipeSemanticConfig` with `copyWith` and dartdoc; default is `null` (falls back to `"Swipe fully to [action.label]"`) in `lib/src/accessibility/swipe_semantic_config.dart`
- [x] T040 [US6] Update `Semantics` widget in `SwipeActionCell` to include `customSemanticsActions` for full-swipe directions when enabled; use `semanticConfig.fullSwipeLeftLabel` / `fullSwipeRightLabel` or default label in `lib/src/widget/swipe_action_cell.dart`
- [x] T041 [US6] Add `Shift+ArrowLeft` / `Shift+ArrowRight` handler in existing `FocusNode.onKeyEvent` in `SwipeActionCellState`: map key to semantic direction considering `_isRtl`, call `_applyFullSwipeAction` if configured in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: All user stories US1–US6 are independently functional. Screen reader and keyboard paths work. RTL produces correct semantic mapping.

---

## Phase 9: Polish & Cross-Cutting Concerns

**Purpose**: Integration scenarios, templates, testing utilities, exports, and final regression gate

### Integration Tests

- [x] T042 [P] Write RED test: undo integration — full-swipe action with `UndoConfig` is undoable (undo window opens, revert restores cell) in `test/full_swipe/full_swipe_integration_test.dart`
- [x] T043 [P] Write RED test: `SwipeGroupController` closes open sibling cells when full-swipe triggers in `test/full_swipe/full_swipe_integration_test.dart`
- [x] T044 [P] Write RED test: disabled state (`fullSwipeConfig: null`) — widget tree contains zero `FullSwipeExpandOverlay` nodes, `fullSwipeRatio` is always 0.0, no `_fullSwipeBumpController` allocated in `test/full_swipe/full_swipe_config_test.dart`

### Templates

- [x] T045 Update `SwipeActionCell.delete` factory constructor to include default `FullSwipeConfig` built from the template's delete action (icon/color/callback) in `lib/src/templates/swipe_cell_templates.dart`
- [x] T046 [P] Update `SwipeActionCell.archive` factory constructor to include default `FullSwipeConfig` built from the template's archive action in `lib/src/templates/swipe_cell_templates.dart`
- [x] T047 Write RED test: both templates include non-null `FullSwipeConfig` with `enabled: true` by default in `test/full_swipe/full_swipe_integration_test.dart`

### Testing Utilities

- [x] T048 Implement `SwipeTester.fullSwipeLeft(tester, finder, {double ratio = 0.8})` and `SwipeTester.fullSwipeRight(tester, finder, {double ratio = 0.8})` helpers with dartdoc in `lib/src/testing/swipe_tester.dart`
- [x] T049 Write RED test: `SwipeTester.fullSwipeLeft` drags past threshold and releases; verify action fires in `test/full_swipe/full_swipe_integration_test.dart`

### Exports & Final Polish

- [x] T050 Add `export 'src/actions/full_swipe/full_swipe_config.dart';` to `lib/swipe_action_cell.dart` barrel
- [x] T051 Run `flutter analyze` — resolve all warnings to zero; `public_member_api_docs` must pass for every new public symbol
- [x] T052 Run `dart format .` — verify zero formatting differences
- [x] T053 Run `flutter test` — verify all 383 existing tests pass (regression gate) and all new full-swipe tests pass

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — **BLOCKS all user stories**
- **User Stories (Phases 3–8)**: All depend on Phase 2 completion
  - US1 and US2 are both P1 and can be worked on concurrently by different developers after Phase 2
  - US3 and US4 are P2 and can start as soon as Phase 2 is complete (can run alongside US1/US2)
  - US5 depends on US1 being complete (`_applyFullSwipeAction` must exist before `executeTriggerFullSwipe` delegates to it)
  - US6 depends on Phase 2 only (semantic config changes are independent of gesture implementation)
- **Polish (Phase 9)**: Depends on all user stories (US1–US6) being complete

### User Story Dependencies

- **US1 (P1)**: Requires Phase 2 completion only
- **US2 (P1)**: Requires Phase 2 and US1 (needs `_fullSwipeRatio` computed in `_checkFullSwipeThreshold` from US1-T015)
- **US3 (P2)**: Requires Phase 2 and US1 (uses `_applyFullSwipeAction` from US1-T017)
- **US4 (P2)**: Requires Phase 2 and US1 (haptic calls are additions to `_checkFullSwipeThreshold` and `_applyFullSwipeAction`)
- **US5 (P3)**: Requires US1 (delegates to `_applyFullSwipeAction`)
- **US6 (P3)**: Requires Phase 2 only for semantic config; keyboard handler needs `_applyFullSwipeAction` from US1

### Within Each User Story

- RED tests **must be written and verified failing** before implementation tasks
- Test tasks marked [P] within a story can be written concurrently (different scenarios in same file)
- Implementation tasks within a story run sequentially in the listed order (each builds on the previous)
- Story is complete when its RED tests turn green

### Parallel Opportunities

```
Phase 2: T004 ‖ T005 ‖ T006 ‖ T007  (all modify different files)
Phase 3: T008 ‖ T009 ‖ T010          (all write tests, different scenarios)
Phase 4: T020 ‖ T021                  (different visual test scenarios)
Phase 5: T026 ‖ T027                  (different integration test scenarios)
Phase 6: T029 ‖ T030                  (different haptic test scenarios)
Phase 7: T033 only (single scenario)
Phase 8: T037 ‖ T038                  (different a11y scenarios)
Phase 9: T042 ‖ T043 ‖ T044          (different integration test scenarios)
         T045 ‖ T046                  (different template files)
```

---

## Parallel Example: User Story 1 (Phase 3)

```
# Step 1 — Write all RED tests concurrently (different scenarios):
Task: T008 — full swipe past threshold triggers action
Task: T009 — below full-swipe above reveal = normal reveal
Task: T010 — gesture lock during post-action animation

# Step 2 — Verify all three tests FAIL. Then implement sequentially:
T011 → T012 → T013 → T014 → T015 → T016 → T017 → T018 → T019

# Step 3 — Verify all three RED tests are now GREEN.
```

## Parallel Example: User Story 2 (Phase 4) — can overlap US3 & US4

```
# US2, US3, US4 can all start after Phase 2 is complete + US1 is done.
# Different developers can work on US2, US3, US4 in parallel.

Developer A: T020 → T021 → T022 → T023 → T024 → T025  (US2 visual)
Developer B: T026 → T027 → T028                         (US3 right swipe)
Developer C: T029 → T030 → T031 → T032                 (US4 haptic)
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2 Only — both P1)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL)
3. Complete Phase 3: User Story 1 (gesture + callbacks + lock)
4. **STOP and VALIDATE**: Test US1 independently with `SwipeTester`
5. Complete Phase 4: User Story 2 (visual expand animation)
6. **STOP and VALIDATE**: Full visual + gesture loop working end-to-end
7. Deploy/demo — iOS Mail delete pattern is complete

### Incremental Delivery

1. Setup + Foundational → Foundation ready
2. US1 → Test independently → Demo (gesture-only full-swipe with no animation)
3. US2 → Test independently → Demo (visual expand animation playing)
4. US3 → Test independently → Demo (right swipe + progressive setToMax)
5. US4 → Test independently → Demo (haptic events at threshold)
6. US5 → Test independently → Demo (programmatic `triggerFullSwipe` API)
7. US6 → Test independently → Demo (keyboard shortcuts + screen reader)
8. Polish → Templates, testing utils, exports, regression gate

### Priority Sequencing

```
P1 (MVP):  Phase 2 → US1 (Phase 3) → US2 (Phase 4)
P2 (Next): US3 (Phase 5) ‖ US4 (Phase 6)
P3 (Full): US5 (Phase 7) ‖ US6 (Phase 8)
Polish:    Phase 9
```

---

## Notes

- Constitution VII (Test-First) is mandatory — no implementation task may begin until its RED test task is confirmed failing
- `[P]` tasks touch different files or different test scenarios in the same file; no write conflicts
- `[Story]` label maps each task to a user story for traceability and independent rollout
- The `_fullSwipeBumpController` must be `null` when `fullSwipeConfig == null` (Constitution IX — null = zero overhead)
- `FullSwipeExpandOverlay` is a `StatelessWidget` — all animation state lives in `SwipeActionCellState` (Constitution X — 60fps)
- Bump animation must be suppressed when `MediaQuery.disableAnimations` is true (FR-022)
- `_fullSwipeTriggered = false` reset in `_handleAnimationStatusChange` is the sole gesture lock release point (D4)
- Commit after each checkpoint validation — T053 is the final regression gate
- Total: **53 tasks** across 9 phases

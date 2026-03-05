# Tasks: Right-Swipe Progressive Action

**Input**: Design documents from `specs/003-progressive-swipe/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/progressive-api.md ✅

**Tests**: Included — Constitution VII (Test-First) is non-negotiable; all 6 user stories have test tasks preceding implementation tasks.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing. Within each phase, test tasks (write-to-fail) precede implementation tasks.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks in the same phase)
- **[Story]**: Which user story this task belongs to ([US1]–[US6])
- Exact file paths are included in every task description

---

## Phase 1: Setup

**Purpose**: Confirm a clean baseline before any changes are made.

- [x] T001 Run `flutter analyze` and `flutter test` from project root; verify `.gitignore` has patterns for `.dart_tool/`, `build/`, `coverage/`, and OS-specific artifacts (`.DS_Store`)

---

## Phase 2: Foundational — New Types & Pure Logic

**Purpose**: Create all new config types and the overflow computation function. Every user story depends on these being complete.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

### Tests (write to fail first)

- [x] T002 [P] Write `OverflowBehavior` tests in `test/actions/progressive/overflow_behavior_test.dart`
- [x] T003 [P] Write `ProgressIndicatorConfig` tests in `test/actions/progressive/progress_indicator_config_test.dart`
- [x] T004 [P] Write `ProgressiveSwipeConfig` tests in `test/actions/progressive/progressive_swipe_config_test.dart`
- [x] T005 [P] Write `computeNextProgressiveValue` tests in `test/actions/progressive/progressive_value_logic_test.dart`

### Implementation

- [x] T006 [P] Create `OverflowBehavior` enum in `lib/src/actions/progressive/overflow_behavior.dart`
- [x] T007 [P] Create `ProgressIndicatorConfig` in `lib/src/actions/progressive/progress_indicator_config.dart`
- [x] T008 [P] Create `ProgressiveSwipeConfig` in `lib/src/actions/progressive/progressive_swipe_config.dart`
- [x] T009 [P] Create `computeNextProgressiveValue` logic in `lib/src/actions/progressive/progressive_value_logic.dart`

**Checkpoint**: All 4 unit test suites pass. Foundation ready — user story implementation can now begin.

---

## Phase 3: User Story 1 — Basic Progressive Increment (Priority: P1) 🎯 MVP

**Goal**: A right swipe past the activation threshold increments the cumulative value by `stepValue`. Below-threshold release produces no change. Callbacks fire in the correct order. The cell snaps back to `idle` after every swipe — it never enters `revealed`.

### Tests for User Story 1 (write to fail first)

- [x] T010 Write widget tests for single right swipe past threshold in `test/widget/swipe_action_cell_progressive_test.dart`
- [x] T011 Write widget tests for below-threshold release in `test/widget/swipe_action_cell_progressive_test.dart`
- [x] T012 Write widget tests for multiple sequential swipes in `test/widget/swipe_action_cell_progressive_test.dart`
- [x] T013 Write widget tests for fling increment in `test/widget/swipe_action_cell_progressive_test.dart`
- [x] T014 Write widget tests for rapid gesture discarding during animation in `test/widget/swipe_action_cell_progressive_test.dart`

### Implementation for User Story 1

- [x] T015 Add `rightSwipe` parameter to `SwipeActionCell` constructor and field
- [x] T016 Initialize `_progressValueNotifier` in `initState`
- [x] T017 Implement `_applyProgressiveIncrement` and state machine logic in `_handleAnimationStatusChange`
- [x] T018 Integrate progressive check into `_handleDragUpdate` for `onSwipeStarted`

**Checkpoint**: US1 complete — cell increments on right swipe, snaps back to idle, callbacks fire correctly, flings trigger increment, rapid swipes do not double-fire.

---

## Phase 4: User Story 2 — Overflow Behavior (Priority: P2)

**Goal**: When the cumulative value reaches `maxValue`, one of three policies applies: clamp (stop), wrap (reset to `minValue`), or ignore (continue past max). `onMaxReached` fires for clamp and wrap but not ignore.

### Tests for User Story 2 (write to fail first)

- [x] T019 Write widget tests for `OverflowBehavior.clamp` in `test/widget/swipe_action_cell_progressive_test.dart`
- [x] T020 Write widget tests for `OverflowBehavior.wrap` in `test/widget/swipe_action_cell_progressive_test.dart`
- [x] T021 Write widget tests for `OverflowBehavior.ignore` in `test/widget/swipe_action_cell_progressive_test.dart`
- [x] T022 Write widget tests for `dynamicStep` override in `test/widget/swipe_action_cell_progressive_test.dart`

**Checkpoint**: US2 complete — all three overflow policies work correctly in a live widget context.

---

## Phase 5: User Story 3 — Visual Progress Indicator (Priority: P3)

**Goal**: When `showProgressIndicator: true` (with finite `maxValue`), a persistent colored bar on the cell's leading edge fills proportionally to the current value.

### Tests for User Story 3 (write to fail first)

- [x] T023 Write `ProgressiveSwipeIndicator` widget tests in `test/actions/progressive/progressive_swipe_indicator_test.dart`
- [x] T024 Write integration tests for indicator rendering in `SwipeActionCell`

### Implementation for User Story 3

- [x] T025 Create `ProgressiveSwipeIndicator` widget in `lib/src/actions/progressive/progressive_swipe_indicator.dart`
- [x] T026 Integrate `_buildProgressIndicator` into `SwipeActionCell.build`

**Checkpoint**: US3 complete — progress indicator renders, fills proportionally, updates live, and is absent by default.

---

## Phase 6: User Story 4 — Controlled Mode (Priority: P4)

**Goal**: When `value` is non-null, the widget is in controlled mode: it displays the provided value and does NOT self-update.

### Tests for User Story 4 (write to fail first)

- [x] T027 Write widget test for controlled mode self-update suppression in `test/widget/swipe_action_cell_progressive_test.dart`
- [x] T028 Write widget test for mirroring `widget.value` changes in `test/widget/swipe_action_cell_progressive_test.dart`

### Implementation for User Story 4

- [x] T029 Implement `didUpdateWidget` mirroring and update `_applyProgressiveIncrement` guard

**Checkpoint**: US4 complete — controlled mode maintains referential integrity; widget never self-mutates a developer-provided value.

---

## Phase 7: User Story 5 — Haptic Feedback (Priority: P6)

**Goal**: Light haptic on threshold crossing, medium haptic on successful increment.

### Tests for User Story 5 (write to fail first)

- [x] T030 Write widget test for light haptic on threshold crossing in `test/widget/swipe_action_cell_progressive_test.dart`
- [x] T031 Write widget test for medium haptic on successful increment in `test/widget/swipe_action_cell_progressive_test.dart`

### Implementation for User Story 5

- [x] T032 Implement threshold haptic in `_handleDragUpdate`
- [x] T033 Implement increment haptic in `_applyProgressiveIncrement`

**Checkpoint**: US5 complete — haptic patterns fire at correct milestones with no false positives.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Barrel exports, regression check against F001/F002, static analysis, and full test suite run.

- [x] T034 Add exports to `lib/swipe_action_cell.dart`
- [x] T035 Run full test suite: `flutter test`
- [x] T036 Run static analysis: `flutter analyze`
- [x] T037 Run formatter check: `dart format --set-exit-if-changed .`

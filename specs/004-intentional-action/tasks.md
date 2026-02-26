# Tasks: Left-Swipe Intentional Action

**Input**: Design documents from `specs/004-intentional-action/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/intentional-api.md ✅

**Tests**: Included — Constitution VII (Test-First) is non-negotiable; all 7 user stories have test tasks preceding implementation tasks.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing. Within each phase, test tasks (write-to-fail) precede implementation tasks.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks in the same phase)
- **[Story]**: Which user story this task belongs to ([US1]–[US7])
- Exact file paths are included in every task description

---

## Phase 1: Setup

**Purpose**: Confirm a clean baseline before any changes are made.

- [x] T001 Run `flutter analyze` and `flutter test` from the project root; verify `.gitignore` has patterns for `.dart_tool/`, `build/`, `coverage/`, and `.DS_Store`

---

## Phase 2: Foundational — New Types & Pure Logic

**Purpose**: Create all new config types, enums, and the `SwipeAction` data class. Every user story depends on these being complete.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

### Tests (write to fail first)

- [x] T002 [P] Write `LeftSwipeMode` enum tests (values, toString) in `test/actions/intentional/left_swipe_mode_test.dart`
- [x] T003 [P] Write `PostActionBehavior` enum tests (values, toString) in `test/actions/intentional/post_action_behavior_test.dart`
- [x] T004 [P] Write `SwipeAction` data class tests (equality, `copyWith`, `flex >= 0` assert, nullable `label`) in `test/actions/intentional/swipe_action_test.dart`
- [x] T005 [P] Write `IntentionalSwipeConfig` tests (equality, `copyWith`, `actionPanelWidth > 0` assert, mode field) in `test/actions/intentional/intentional_swipe_config_test.dart`

### Implementation

- [x] T006 [P] Create `LeftSwipeMode` enum with `autoTrigger` and `reveal` values and dartdoc in `lib/src/actions/intentional/left_swipe_mode.dart`
- [x] T007 [P] Create `PostActionBehavior` enum with `snapBack`, `animateOut`, `stay` values and dartdoc in `lib/src/actions/intentional/post_action_behavior.dart`
- [x] T008 [P] Create `SwipeAction` immutable data class (icon, optional label, backgroundColor, foregroundColor, onTap, isDestructive, flex; `const` constructor, `==`, `hashCode`, `copyWith`) in `lib/src/actions/intentional/swipe_action.dart`
- [x] T009 [P] Create `IntentionalSwipeConfig` immutable config class (mode, actions, actionPanelWidth, postActionBehavior, requireConfirmation, enableHaptic, all callbacks; `const` constructor, `==`, `hashCode`, `copyWith`) in `lib/src/actions/intentional/intentional_swipe_config.dart`
- [x] T010 Add `animatingOut` value with dartdoc to the `SwipeState` enum in `lib/src/core/swipe_state.dart`

**Checkpoint**: All 4 unit test suites pass. Foundational types ready — user story implementation can now begin.

---

## Phase 3: User Story 1 — Auto-Trigger Basic (Priority: P1) 🎯 MVP

**Goal**: A left swipe past the activation threshold fires `onActionTriggered` exactly once. Below-threshold release produces no callback. Cell snaps back to idle after action (`snapBack` default). Flings also trigger the action.

**Independent Test**: Configure a cell with `mode: autoTrigger` and an `onActionTriggered` callback; verify it fires on above-threshold release and not on below-threshold release.

### Tests for User Story 1 (write to fail first)

- [x] T011 [US1] Write widget test for above-threshold left swipe fires `onActionTriggered` exactly once in `test/widget/swipe_action_cell_intentional_test.dart`
- [x] T012 [US1] Write widget test for below-threshold release fires no callback in `test/widget/swipe_action_cell_intentional_test.dart`
- [x] T013 [US1] Write widget test for fling left triggers action even below threshold distance in `test/widget/swipe_action_cell_intentional_test.dart`
- [x] T014 [US1] Write widget test for animation interrupt — drag during animating state resumes from current translated position in `test/widget/swipe_action_cell_intentional_test.dart`

### Implementation for User Story 1

- [x] T015 [US1] Add `leftSwipe: IntentionalSwipeConfig?` parameter to `SwipeActionCell` constructor and field in `lib/src/widget/swipe_action_cell.dart`
- [x] T016 [US1] Add internal state fields `_widgetWidth`, `_isPostActionSnapBack`, `_awaitingConfirmation` to `_SwipeActionCellState` in `lib/src/widget/swipe_action_cell.dart`
- [x] T017 [US1] Store `_widgetWidth` from `LayoutBuilder` constraints; implement `_leftMaxTranslation(double widgetWidth)` and `_computeAutoPanelWidth(double widgetWidth)` helpers in `lib/src/widget/swipe_action_cell.dart`
- [x] T018 [US1] Implement `_handleIntentionalActionSettled()`, `_applyIntentionalAction()`, and `_applyPostActionBehavior()` (snapBack path only; animateOut and stay expanded in US3) in `lib/src/widget/swipe_action_cell.dart`
- [x] T019 [US1] Implement `_animateOut()` method (spring simulation to `-(widgetWidth * 1.5)`) in `lib/src/widget/swipe_action_cell.dart`
- [x] T020 [US1] Hook `_handleIntentionalActionSettled()` into `_handleAnimationStatusChange` for the `left + leftSwipe != null` branch; add `animatingOut` terminal guard; update `animatingToClose` completion to guard `onSwipeCancelled` with `_isPostActionSnapBack` in `lib/src/widget/swipe_action_cell.dart`
- [x] T021 [US1] Add `animatingOut` guard in `_handleDragStart` (ignore new drags when state is `animatingOut`); use `_leftMaxTranslation` in `_handleDragEnd` and `_handleDragUpdate` in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: US1 complete — cell fires action on left swipe, snaps back to idle, flings work, interrupts work, `onSwipeCancelled` fires correctly on cancel.

---

## Phase 4: User Story 2 — Reveal Mode: Action Panel (Priority: P2)

**Goal**: A left swipe in reveal mode springs open an action panel. Tapping a button fires its callback and closes the panel. Tapping the cell body or swiping right closes the panel with no action fired.

**Independent Test**: Configure a cell with `mode: reveal` and two `SwipeAction` items; verify panel opens on swipe, first button's `onTap` fires on tap, panel closes on cell-body tap.

### Tests for User Story 2 (write to fail first)

- [ ] T022 [P] [US2] Write `SwipeActionPanel` widget tests (renders 1–3 buttons, non-destructive button fires `onTap` and calls `onClose`, `onClose` called on any tap) in `test/actions/intentional/swipe_action_panel_test.dart`
- [ ] T023 [US2] Write widget test for reveal panel opens on left swipe past threshold and `onPanelOpened` fires in `test/widget/swipe_action_cell_intentional_test.dart`
- [ ] T024 [US2] Write widget test for action button tap fires `onTap` and `onPanelClosed` in `test/widget/swipe_action_cell_intentional_test.dart`
- [ ] T025 [US2] Write widget test for cell body tap closes panel and fires `onPanelClosed` (no `onTap`) in `test/widget/swipe_action_cell_intentional_test.dart`
- [ ] T026 [US2] Write widget test for right swipe while panel is open closes panel and fires `onPanelClosed` in `test/widget/swipe_action_cell_intentional_test.dart`

### Implementation for User Story 2

- [ ] T027 [US2] Create `SwipeActionPanel` `StatefulWidget` (Row of `Expanded` action buttons, each with `GestureDetector`; fires button's `onTap` then calls `onClose`; `enableHaptic` param plumbed through; `_expandedIndex` field stub for US4) in `lib/src/actions/intentional/swipe_action_panel.dart`
- [ ] T028 [US2] Implement reveal path in `_handleIntentionalActionSettled()`: transition to `SwipeState.revealed`, call `onPanelOpened` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T029 [US2] Implement `_maybeWrapWithBodyTapInterceptor(Widget child)` (wrap translated child when `_state == revealed && leftSwipe != null`; tap closes panel via `_snapBack`) and apply in `build()` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T030 [US2] Add `_buildRevealPanel(double width)` (`Positioned` `SwipeActionPanel` at right edge with width from `_computeEffectivePanelWidth`) and render it in `build()` Stack when `mode == reveal && state == revealed && actions.isNotEmpty` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T031 [US2] Wire `onPanelClosed` callback in `animatingToClose` completion handler for `mode == reveal` path in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: US2 complete — reveal panel opens, buttons close panel and fire callbacks, body tap and right swipe close panel with `onPanelClosed`.

---

## Phase 5: User Story 3 — Post-Action Behavior (Priority: P3)

**Goal**: After auto-trigger fires, `snapBack` returns to idle (default, already complete after US1), `animateOut` slides cell off screen (developer removes item), `stay` holds at open position (user right-swipes to close).

**Independent Test**: Configure three cells with `snapBack`, `animateOut`, and `stay`; verify each settles at the correct position after the action fires.

### Tests for User Story 3 (write to fail first)

- [ ] T032 [US3] Write widget test for `postActionBehavior: snapBack` — controller returns to 0.0 and `onSwipeCancelled` does NOT fire after successful trigger in `test/widget/swipe_action_cell_intentional_test.dart`
- [ ] T033 [US3] Write widget test for `postActionBehavior: animateOut` — state transitions to `animatingOut`, `onActionTriggered` fires, new drag during slide-out is ignored in `test/widget/swipe_action_cell_intentional_test.dart`
- [ ] T034 [US3] Write widget test for `postActionBehavior: stay` — state is `revealed` after action fires; right swipe returns cell to idle in `test/widget/swipe_action_cell_intentional_test.dart`

### Implementation for User Story 3

- [ ] T035 [US3] Implement `animateOut` path in `_applyPostActionBehavior()`: transition to `SwipeState.animatingOut`, call `_animateOut()` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T036 [US3] Implement `stay` path in `_applyPostActionBehavior()`: transition to `SwipeState.revealed`; confirm right swipe from `revealed` follows existing `dragging → animatingToClose → idle` path in `lib/src/widget/swipe_action_cell.dart`
- [ ] T037 [US3] Add `animatingOut` terminal case (`return` — no state transition) in `_handleAnimationStatusChange` completion handler in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: US3 complete — all three post-action behaviors work correctly; `animateOut` guards ignore new drags.

---

## Phase 6: User Story 4 — Destructive Action Confirm-Expand (Priority: P4)

**Goal**: Tapping a destructive action button expands it to full panel width on first tap (no `onTap` fires). Second tap fires `onTap` and closes the panel. Tapping elsewhere after expansion collapses without firing.

**Independent Test**: Configure a reveal cell with a single destructive action; verify first tap expands the button and second tap fires `onTap`.

### Tests for User Story 4 (write to fail first)

- [ ] T038 [US4] Write `SwipeActionPanel` test: destructive button first tap expands to `panelWidth` and `onTap` NOT called in `test/actions/intentional/swipe_action_panel_test.dart`
- [ ] T039 [US4] Write `SwipeActionPanel` test: destructive button second tap fires `onTap` and calls `onClose` in `test/actions/intentional/swipe_action_panel_test.dart`
- [ ] T040 [US4] Write `SwipeActionPanel` test: non-destructive button tap while destructive is expanded fires non-destructive `onTap` immediately in `test/actions/intentional/swipe_action_panel_test.dart`

### Implementation for User Story 4

- [ ] T041 [US4] Implement destructive confirm-expand in `SwipeActionPanel`: add `int? _expandedIndex` field; on first destructive tap set index via `setState`; on second tap fire `onTap` + call `onClose` + reset; use `AnimatedContainer` (duration: 200ms) for width expansion to `panelWidth`; hide other buttons while one is expanded in `lib/src/actions/intentional/swipe_action_panel.dart`

**Checkpoint**: US4 complete — destructive actions require two taps; expansion is animated; other buttons collapse or fire immediately.

---

## Phase 7: User Story 5 — Auto-Trigger Confirmation (Priority: P5)

**Goal**: With `requireConfirmation: true`, the first swipe holds the cell without firing the action. A second left swipe OR a tap on the `leftBackground` area confirms. Body tap or right swipe cancels.

**Independent Test**: Configure an auto-trigger cell with `requireConfirmation: true`; verify single swipe does NOT fire `onActionTriggered` and a confirming second swipe DOES fire it.

### Tests for User Story 5 (write to fail first)

- [ ] T042 [US5] Write widget test: `requireConfirmation: true` first swipe → state `revealed`, `onActionTriggered` NOT fired in `test/widget/swipe_action_cell_intentional_test.dart`
- [ ] T043 [US5] Write widget test: second left swipe past threshold from confirmation state → `onActionTriggered` fires in `test/widget/swipe_action_cell_intentional_test.dart`
- [ ] T044 [US5] Write widget test: tap on `leftBackground` area from confirmation state → `onActionTriggered` fires in `test/widget/swipe_action_cell_intentional_test.dart`
- [ ] T045 [US5] Write widget test: body tap from confirmation state → snaps back and `onActionTriggered` NOT fired in `test/widget/swipe_action_cell_intentional_test.dart`

### Implementation for User Story 5

- [ ] T046 [US5] Implement `_awaitingConfirmation` check in `_handleIntentionalActionSettled()`: when `requireConfirmation && !_awaitingConfirmation`, set flag and transition to `revealed` without firing action in `lib/src/widget/swipe_action_cell.dart`
- [ ] T047 [US5] Add confirmation background-area tap overlay: `Positioned.fill` `GestureDetector` (`HitTestBehavior.translucent`, calls `_applyIntentionalAction()`) rendered in `build()` Stack only when `_awaitingConfirmation == true` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T048 [US5] Update `_maybeWrapWithBodyTapInterceptor()` / `_handleBodyTapInRevealedState()`: body tap when `_awaitingConfirmation` → reset flag, snap back, do NOT fire action in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: US5 complete — confirmation gate works for second-swipe and background-tap confirm paths; body tap and right swipe cancel correctly.

---

## Phase 8: User Story 6 — Haptic Feedback (Priority: P6)

**Goal**: Light haptic fires once per drag when the activation threshold is crossed. Medium haptic fires when an action executes (auto-trigger fire or reveal button tap).

**Independent Test**: Enable haptic with a mocked platform channel; verify light haptic fires at threshold crossing and medium haptic fires on action execution.

### Tests for User Story 6 (write to fail first)

- [ ] T049 [US6] Write widget test for `enableHaptic: true` — light haptic fires exactly once at threshold crossing (mock `HapticFeedback` via platform channel in `TestDefaultBinaryMessengerBinding`) in `test/widget/swipe_action_cell_intentional_test.dart`
- [ ] T050 [US6] Write widget test for `enableHaptic: true` — medium haptic fires on `onActionTriggered` fire and on reveal button tap in `test/widget/swipe_action_cell_intentional_test.dart`

### Implementation for User Story 6

- [ ] T051 [US6] Add left-swipe threshold haptic check in `AnimatedBuilder` builder: `leftSwipe?.enableHaptic == true && _lockedDirection == left && progress.isActivated && !_hapticThresholdFired` → `HapticFeedback.lightImpact(); _hapticThresholdFired = true` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T052 [US6] Add `HapticFeedback.mediumImpact()` call in `_applyIntentionalAction()` (before `onActionTriggered` callback); add `enableHaptic` parameter to `SwipeActionPanel` and call `HapticFeedback.mediumImpact()` in `_handleButtonTap()` before firing `onTap` in `lib/src/actions/intentional/swipe_action_panel.dart`

**Checkpoint**: US6 complete — haptic patterns fire at correct milestones with no false positives or double-fires.

---

## Phase 9: User Story 7 — Coexistence with F3 (Priority: P7)

**Goal**: A cell with both `rightSwipe: ProgressiveSwipeConfig` and `leftSwipe: IntentionalSwipeConfig` works correctly in both directions with zero cross-direction interference.

**Independent Test**: Configure a cell with both `rightSwipe` and `leftSwipe`; swipe right then left; verify each fires only its own callbacks with no state leakage.

### Tests for User Story 7 (write to fail first)

- [ ] T053 [US7] Write widget test: right swipe on dual-config cell fires only F3 callbacks; no left-swipe callbacks fire in `test/widget/swipe_action_cell_intentional_test.dart`
- [ ] T054 [US7] Write widget test: left swipe on dual-config cell fires only F4 callbacks; no right-swipe callbacks fire in `test/widget/swipe_action_cell_intentional_test.dart`
- [ ] T055 [US7] Write widget test: reveal panel open → right swipe closes panel; F3 progressive does NOT fire in `test/widget/swipe_action_cell_intentional_test.dart`

### Implementation for User Story 7

- [ ] T056 [US7] Review and verify direction guards in `_handleAnimationStatusChange`, `_handleDragUpdate`, and `animatingToClose` completion handler: confirm `_lockedDirection` checks prevent cross-direction callback leakage; add any missing guards in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: US7 complete — both directions independently functional on the same cell instance with zero state leakage.

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Barrel exports, regression check against F001–F003, static analysis, full test suite.

- [ ] T057 Add 5 new exports to `lib/swipe_action_cell.dart`: `left_swipe_mode.dart`, `post_action_behavior.dart`, `swipe_action.dart`, `intentional_swipe_config.dart`, `swipe_action_panel.dart`
- [ ] T058 Run full test suite: `flutter test`
- [ ] T059 Run static analysis: `flutter analyze`
- [ ] T060 Run formatter check: `dart format --set-exit-if-changed .`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all user story phases
- **US1 (Phase 3)**: Depends on Foundational (Phase 2) completion
- **US2 (Phase 4)**: Depends on Foundational (Phase 2) completion; can start in parallel with US1
- **US3 (Phase 5)**: Depends on US1 (Phase 3) completion — extends auto-trigger with animateOut and stay
- **US4 (Phase 6)**: Depends on US2 (Phase 4) completion — extends `SwipeActionPanel` with destructive expand
- **US5 (Phase 7)**: Depends on US1 (Phase 3) completion — adds confirmation gate to auto-trigger; parallel with US3
- **US6 (Phase 8)**: Depends on US1 + US2 completion — haptic fires for both modes
- **US7 (Phase 9)**: Depends on US1 + US2 completion — coexistence test requires both modes; parallel with US6
- **Polish (Phase 10)**: Depends on all user story phases complete

### User Story Dependencies

- **US1 (P1)**: Independent after Foundational
- **US2 (P2)**: Independent after Foundational; parallel with US1
- **US3 (P3)**: Requires US1 complete
- **US4 (P4)**: Requires US2 complete
- **US5 (P5)**: Requires US1 complete; parallel with US3
- **US6 (P6)**: Requires US1 + US2 complete
- **US7 (P7)**: Requires US1 + US2 complete; parallel with US6

### Parallel Opportunities Within Phases

- **Phase 2**: T002–T005 all parallelizable (different test files); T006–T009 all parallelizable (different source files); T010 sequential (single enum file update)
- **Phase 3**: T011–T014 sequential (same test file); T015–T021 sequential (same widget file)
- **Phase 4**: T022 parallelizable with T023–T026 (different files); T023–T026 sequential (same test file)
- **Phase 6**: T038–T040 sequential (same `swipe_action_panel_test.dart` file); T041 sequential (single widget file)

---

## Parallel Execution Example: Foundational Phase

```
# Round 1 — tests (all different files, run in parallel):
Task A: T002 — Write LeftSwipeMode tests     → left_swipe_mode_test.dart
Task B: T003 — Write PostActionBehavior tests → post_action_behavior_test.dart
Task C: T004 — Write SwipeAction tests        → swipe_action_test.dart
Task D: T005 — Write IntentionalSwipeConfig tests → intentional_swipe_config_test.dart

# Round 2 — implementations (all different files, run in parallel):
Task A: T006 — Create LeftSwipeMode          → left_swipe_mode.dart
Task B: T007 — Create PostActionBehavior     → post_action_behavior.dart
Task C: T008 — Create SwipeAction            → swipe_action.dart
Task D: T009 — Create IntentionalSwipeConfig → intentional_swipe_config.dart

# Round 3 — sequential (single file):
Task A: T010 — Add animatingOut to SwipeState → swipe_state.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL — blocks all stories)
3. Complete Phase 3: US1 (auto-trigger, snapBack only)
4. **STOP and VALIDATE**: `flutter test test/widget/swipe_action_cell_intentional_test.dart` — US1 tests pass
5. Optionally demo: swipe left → action fires → cell snaps back

### Incremental Delivery

1. Setup + Foundational → types ready
2. US1 → auto-trigger with snapBack ✓
3. US2 → reveal mode with action panel ✓ (parallel with US1 after Foundational)
4. US3 → animateOut + stay behaviors ✓
5. US4 → destructive confirm-expand ✓
6. US5 → requireConfirmation ✓
7. US6 → haptic ✓
8. US7 → coexistence validation ✓
9. Polish → exports, analyze, format ✓

---

## Notes

- All `[P]` tasks touch different files — no merge conflicts when parallelized
- Each user story phase produces a testable increment independently
- `SwipeActionPanel` (US2) is self-contained; US4 is purely an internal change to it
- Constitution VII mandates test-first: run each test group and confirm RED before writing the implementation
- `SwipeState.animatingOut` (T010) must be added before any widget test references it
- The widget file (`lib/src/widget/swipe_action_cell.dart`) is modified across US1–US7; tasks are ordered to avoid conflicts
- Haptic tests (US6) require mocking `HapticFeedback` via `TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler`

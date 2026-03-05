# Tasks: Foundational Gesture & Spring Animation

**Input**: Design documents from `/specs/001-gesture-animation/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/widget-api.md ✅, quickstart.md ✅

**Tests**: Included — Constitution VII (Test-First) is explicitly enforced by plan.md; all 5 interaction flows require test coverage.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story. Within each phase, test tasks precede implementation tasks.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to ([US1]–[US5])
- Exact file paths are included in every task description

---

## Phase 1: Setup

**Purpose**: Confirm the existing scaffold compiles and tests pass before any changes are made.

- [X] T001 Run `flutter analyze` and `flutter test` to confirm a clean baseline on the current scaffold before beginning implementation

---

## Phase 2: Foundational — Data Classes & Config Objects

**Purpose**: Implement the three new config types and update `SwipeProgress` — these are required by every user story and MUST be complete before widget implementation begins.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

### Tests (write to fail first)

- [X] T002 [P] Write failing unit tests for `SwipeProgress` covering `copyWith`, `==`, `hashCode`, `toString`, and `zero` constant in `test/core/swipe_progress_test.dart`
- [X] T003 [P] Write failing unit tests for `SpringConfig` covering `const` constructor, `copyWith`, `==`, `hashCode`, and the `snapBack`/`completion` static const presets in `test/animation/spring_config_test.dart`
- [X] T004 [P] Write failing unit tests for `SwipeGestureConfig` covering `const` constructor, `copyWith`, `==`, `hashCode`, and `enabledDirections` invariant (must not contain `SwipeDirection.none`) in `test/gesture/swipe_gesture_config_test.dart`
- [X] T005 [P] Write failing unit tests for `SwipeAnimationConfig` covering `const` constructor, `copyWith`, `==`, `hashCode`, and nullable `maxTranslation*` fields in `test/animation/swipe_animation_config_test.dart`

### Implementation

- [X] T006 [P] Update `SwipeProgress` to add `copyWith`, `==`, `hashCode`, `toString`, and `static const zero` constant in `lib/src/core/swipe_progress.dart`
- [X] T007 [P] Create `SpringConfig` immutable data class with `const` constructor, `final` fields (`mass`, `stiffness`, `damping`), `copyWith`, `==`, `hashCode`, and `static const snapBack` and `static const completion` presets in `lib/src/animation/spring_config.dart`
- [X] T008 [P] Create `SwipeGestureConfig` immutable config class with `const` constructor, `final` fields (`deadZone`, `enabledDirections`, `velocityThreshold`), `copyWith`, `==`, `hashCode` in `lib/src/gesture/swipe_gesture_config.dart`
- [X] T009 Create `SwipeAnimationConfig` immutable config class with `const` constructor, `final` fields (`activationThreshold`, `snapBackSpring`, `completionSpring`, `resistanceFactor`, `maxTranslationLeft`, `maxTranslationRight`), `copyWith`, `==`, `hashCode` referencing `SpringConfig` presets in `lib/src/animation/swipe_animation_config.dart`
- [X] T010 Add `export 'src/animation/spring_config.dart'`, `export 'src/animation/swipe_animation_config.dart'`, and `export 'src/gesture/swipe_gesture_config.dart'` to `lib/swipe_action_cell.dart`

**Checkpoint**: All config unit tests pass. Foundation ready — user story implementation can now begin.

---

## Phase 3: User Story 1 — Live Drag Following (Priority: P1) 🎯 MVP

**Goal**: The cell visually translates in real time as the user drags, starting only after the dead zone is exceeded. Resistance increases near the translation bound. Disabled directions produce no motion.

**Independent Test**: Place `SwipeActionCell` wrapping a `ColoredBox` in a widget test. Simulate a horizontal drag beyond the dead zone and verify `swipeOffsetListenable` updates proportionally to drag displacement.

### Tests for User Story 1 (write to fail first)

- [X] T011 [US1] Write failing widget test for dead-zone suppression: drag within `deadZone` pixels produces no movement and `swipeOffsetListenable.value` stays at 0.0 in `test/widget/swipe_action_cell_test.dart`
- [X] T012 [US1] Write failing widget test for live drag following: drag beyond dead zone updates `swipeOffsetListenable.value` proportionally to displacement in `test/widget/swipe_action_cell_test.dart`
- [X] T013 [US1] Write failing widget test for disabled direction: right swipe with `enabledDirections: {SwipeDirection.left}` config produces zero translation in `test/widget/swipe_action_cell_test.dart`

### Implementation for User Story 1

- [X] T014 [US1] Implement `_SwipeActionCellState` with `TickerProviderStateMixin`, unbounded `AnimationController` (`lowerBound: double.negativeInfinity`, `upperBound: double.infinity`, initial `value: 0.0`), `initState`, `dispose`, and `ValueListenable<double> get swipeOffsetListenable => _controller` getter in `lib/src/widget/swipe_action_cell.dart`
- [X] T015 [US1] Implement `build` method using `LayoutBuilder` to resolve effective `maxTranslationLeft`/`Right` from widget width (`RenderBox.size.width * 0.6` when `null`); short-circuit to bare child when `enabled == false` in `lib/src/widget/swipe_action_cell.dart`
- [X] T016 [US1] Implement `AnimatedBuilder` wrapping `Transform.translate(offset: Offset(_controller.value, 0))` with the `GestureDetector` hoisted as the `child` parameter to avoid per-frame subtree rebuilds in `lib/src/widget/swipe_action_cell.dart`
- [X] T017 [US1] Implement `_handleDragStart`: call `_controller.stop()`, reset `_accumulatedDx = 0.0` and `_lockedDirection = SwipeDirection.none`, transition state to `SwipeState.dragging` via `setState`, fire `onStateChanged` in `lib/src/widget/swipe_action_cell.dart`
- [X] T018 [US1] Implement `_handleDragUpdate` with dead-zone accumulation (`_accumulatedDx += delta.dx`; move only after `abs >= deadZone`), direction lock (check `enabledDirections`; silently abort if direction not enabled), and `applyResistance` pure function using the iOS logarithmic formula (`(1 - 1 / (overflow * factor / maxT + 1)) * maxT`) to compute `_controller.value` in `lib/src/widget/swipe_action_cell.dart`
- [X] T019 [US1] Wire `onProgressChanged` callback inside the `AnimatedBuilder` builder function (fires every frame) and fire `onStateChanged` from `setState` calls; compute `SwipeProgress(direction, ratio, isActivated, rawOffset)` from `_controller.value` each frame in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: US1 complete — cell follows the finger, dead zone works, disabled directions produce no motion.

---

## Phase 4: User Story 2 — Snap-Back on Sub-Threshold Release (Priority: P2)

**Goal**: Releasing a drag below the activation threshold triggers a spring animation back to origin, settling in the `idle` state.

**Independent Test**: Simulate a drag to 25% of max translation and release. Verify `swipeOffsetListenable.value` returns to 0.0 after `pumpAndSettle` with no stuck states.

### Tests for User Story 2 (write to fail first)

- [X] T020 [US2] Write failing widget test for sub-threshold release: drag to 25% of `maxTranslation` (below 40% activation threshold), release, `pumpAndSettle`, verify `swipeOffsetListenable.value == 0.0` and `onStateChanged` received `idle` in `test/widget/swipe_action_cell_test.dart`

### Implementation for User Story 2

- [X] T021 [US2] Implement `_handleDragEnd`: read `primaryVelocity ?? 0.0`, compute `ratio = _controller.value.abs() / effectiveMaxTranslation`, determine `shouldComplete = ratio >= activationThreshold`; for sub-threshold path, transition state to `animatingToClose` and call `_snapBack` in `lib/src/widget/swipe_action_cell.dart`
- [X] T022 [US2] Implement `_snapBack(double fromOffset, double velocity)`: set `_controller.value = fromOffset`, construct `SpringSimulation` from `snapBackSpring` targeting `0.0` with the drag end velocity, call `_controller.animateWith(simulation)` in `lib/src/widget/swipe_action_cell.dart`
- [X] T023 [US2] Add `AnimationController` status listener in `initState`: on `AnimationStatus.completed` while state is `animatingToClose`, transition to `idle` via `setState` and fire `onStateChanged` in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: US2 complete — sub-threshold releases spring cleanly back to origin.

---

## Phase 5: User Story 3 — Completion Animation on Threshold Release (Priority: P2)

**Goal**: Releasing a drag at or above the activation threshold triggers a spring animation to the full extension position, settling in the `revealed` state.

**Independent Test**: Simulate a drag to 60% of max translation and release. Verify `swipeOffsetListenable.value` equals `effectiveMaxTranslation` after `pumpAndSettle` and state is `revealed`.

### Tests for User Story 3 (write to fail first)

- [X] T024 [US3] Write failing widget test for at/above-threshold release: drag to 60% of `maxTranslation` (above 40% activation threshold), release, `pumpAndSettle`, verify `swipeOffsetListenable.value` equals resolved `maxTranslation` and `onStateChanged` received `revealed` in `test/widget/swipe_action_cell_test.dart`

### Implementation for User Story 3

- [X] T025 [US3] Add at/above-threshold branch to `_handleDragEnd`: when `shouldComplete == true`, transition state to `animatingToOpen` and call `_animateToOpen(fromOffset, toOffset: ±effectiveMaxTranslation, velocity)` in `lib/src/widget/swipe_action_cell.dart`
- [X] T026 [US3] Implement `_animateToOpen(double fromOffset, double toOffset, double velocity)`: set `_controller.value = fromOffset`, construct `SpringSimulation` from `completionSpring` targeting `toOffset` with drag end velocity, call `_controller.animateWith(simulation)` in `lib/src/widget/swipe_action_cell.dart`
- [X] T027 [US3] Extend the `AnimationController` status listener to handle `animatingToOpen → revealed` transition: on `AnimationStatus.completed` while state is `animatingToOpen`, transition to `revealed` via `setState` and fire `onStateChanged` in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: US2 + US3 complete — both release outcomes (snap-back and completion) work independently.

---

## Phase 6: User Story 4 — Fling to Completion (Priority: P3)/

**Goal**: A high-velocity release — even at short displacement — triggers the completion animation. Low-velocity short releases still snap back.

**Independent Test**: Simulate a drag to 15% of max translation with `TestGesture` + `pump(16ms)` between moves to generate real velocity above 700 px/s; verify cell reaches `revealed` state.

### Tests for User Story 4 (write to fail first)

- [X] T028 [US4] Write failing widget test for fling completion: drag to ~15% of `maxTranslation` using `TestGesture` (5 moves × 14px with `pump(16ms)` between each), release, `pumpAndSettle`, verify `revealed` state in `test/widget/swipe_action_cell_test.dart`
- [X] T029 [US4] Write failing widget test for low-velocity rejection at same distance: same drag distance via `tester.drag` (zero velocity), release, `pumpAndSettle`, verify `idle` state (snap-back path) in `test/widget/swipe_action_cell_test.dart`

### Implementation for User Story 4

- [X] T030 [US4] Extend `_handleDragEnd` with fling detection: compute `isFling = (velocity.abs() >= velocityThreshold) && (lockedDirection == right ? velocity > 0 : velocity < 0)`; set `shouldComplete = isFling || ratio >= activationThreshold`; velocity direction overrides distance decision in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: US4 complete — flings complete regardless of distance; slow short drags still snap back.

---

## Phase 7: User Story 5 — Mid-Animation Interruption (Priority: P3)

**Goal**: A new drag started during any active animation immediately freezes the animation at its current visual position and resumes direct drag control with no positional jump.

**Independent Test**: Trigger a snap-back animation, then start a new drag after `pump(50ms)`. Read `swipeOffsetListenable.value` just before and just after the new drag start; values must be within 2.0px of each other.

### Tests for User Story 5 (write to fail first)

- [X] T031 [US5] Write failing widget test for mid-`animatingToClose` interruption: release drag (sub-threshold), `pump(50ms)`, start new drag, verify `swipeOffsetListenable.value` before and after new drag start are within 2.0px (`moreOrLessEquals`) in `test/widget/swipe_action_cell_test.dart`
- [X] T032 [US5] Write failing widget test for mid-`animatingToOpen` interruption: release drag (at threshold), `pump(50ms)`, start new drag, verify same seamless positional handoff with no jump in `test/widget/swipe_action_cell_test.dart`

### Implementation for User Story 5

- [X] T033 [US5] Confirm `_handleDragStart` always calls `_controller.stop()` as its first operation (freezing any in-flight animation) and immediately reads `_controller.value` to initialize `_currentOffset` — ensuring drag tracking resumes from the exact frozen pixel position in `lib/src/widget/swipe_action_cell.dart`
- [X] T034 [US5] Handle `revealed → dragging` transition in `_handleDragStart`: the controller already holds `±maxTranslation`; reset direction lock to `SwipeDirection.none` so the next drag gesture re-locks direction, allowing the user to swipe back in from the fully-extended position in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: All 5 user stories complete and independently testable.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Stress tests, parameter validation, dartdoc compliance, and final analysis pass.

- [X] T035 [P] Write widget tests for SC-007: each of the 6 configurable parameters (`deadZone`, `activationThreshold`, `velocityThreshold`, `resistanceFactor`, `snapBackSpring`, `completionSpring`) produces a measurably different observable outcome when changed from its default — one dedicated assertion per parameter in `test/widget/swipe_action_cell_test.dart`
- [X] T036 [P] Write widget test for SC-006: simulate 10 consecutive rapid drag-release cycles; after all cycles verify `swipeOffsetListenable.value == 0.0`, state is `idle`, and no assertion errors were thrown in `test/widget/swipe_action_cell_test.dart`
- [X] T037 [P] Write widget tests for SC-001: `SwipeActionCell` renders child without altering its natural size or layout constraints; assert `tester.getSize(find.byWidget(child))` equals the unconditional child size across at least 5 different child widget types in `test/widget/swipe_action_cell_test.dart`
- [X] T038 Run `flutter analyze` across all modified source and test files and resolve every warning to zero before committing
- [X] T039 Run `flutter test` to confirm all 39 tasks' tests pass; manually verify each item in the `quickstart.md` validation checklist

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundational (Phase 2)**: Depends on Phase 1 — **blocks all user stories**
- **User Stories (Phases 3–7)**: All depend on Phase 2 completion; stories must be implemented sequentially (US1 → US2 → US3 → US4 → US5) because each extends `swipe_action_cell.dart`
- **Polish (Phase 8)**: Depends on all user stories being complete

### User Story Dependencies

- **US1 (P1)**: Depends only on Phase 2 — implements the widget shell; blocks all subsequent stories
- **US2 (P2)**: Depends on US1 — adds the sub-threshold release path to `_handleDragEnd`
- **US3 (P2)**: Depends on US2 — adds the at/above-threshold path to `_handleDragEnd`
- **US4 (P3)**: Depends on US3 — adds the velocity-based fling decision on top of US2/US3 paths
- **US5 (P3)**: Depends on US4 — validates that `_handleDragStart`'s `controller.stop()` creates seamless handoffs from all animation states

### Within Each User Story

1. Write failing tests **before** implementation — confirm tests fail
2. Implement until all tests pass
3. Run `flutter analyze` — fix any warnings before the next story
4. **Checkpoint**: Verify independent test criterion from the story header

### Parallel Opportunities

- **Phase 2 tests (T002–T005)**: All write to different test files — run in parallel
- **Phase 2 implementations (T006–T008)**: Different files — run in parallel; T009 depends on T007; T010 depends on T009
- **Phase 8 test tasks (T035–T037)**: Different test groups in the same file — can be authored concurrently by different developers

---

## Parallel Example: Phase 2

```bash
# Launch all foundational test tasks in parallel (different files):
Task: "Write SwipeProgress tests in test/core/swipe_progress_test.dart"          # T002
Task: "Write SpringConfig tests in test/animation/spring_config_test.dart"        # T003
Task: "Write SwipeGestureConfig tests in test/gesture/swipe_gesture_config_test.dart"  # T004
Task: "Write SwipeAnimationConfig tests in test/animation/swipe_animation_config_test.dart" # T005

# Then launch independent implementations in parallel:
Task: "Update SwipeProgress in lib/src/core/swipe_progress.dart"                  # T006
Task: "Create SpringConfig in lib/src/animation/spring_config.dart"               # T007
Task: "Create SwipeGestureConfig in lib/src/gesture/swipe_gesture_config.dart"    # T008
# T009 starts after T007 completes (SpringConfig reference)
# T010 starts after T008, T009 complete (barrel export)
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1 (Setup — 1 task)
2. Complete Phase 2 (Foundational — 9 tasks)
3. Complete Phase 3 (US1: Live Drag Following — 9 tasks)
4. **STOP and validate**: drag following works, dead zone suppresses motion, disabled directions produce no movement
5. Demo/review if needed

### Incremental Delivery

1. Phase 1 + Phase 2 → config layer complete ✅
2. Phase 3 (US1) → drag following working → MVP demo
3. Phase 4 (US2) → snap-back working → cancel path complete
4. Phase 5 (US3) → completion animation → confirm path complete
5. Phase 6 (US4) → fling working → gesture interaction complete
6. Phase 7 (US5) → mid-animation interruption → "always responsive" property satisfied
7. Phase 8 → stress tests, analysis, validation → production-ready

---

## Notes

- All widget implementation tasks modify the **same file** (`lib/src/widget/swipe_action_cell.dart`); they must be done sequentially
- `applyResistance` is a pure top-level or static function — no allocation, no Flutter dependency
- The `AnimationController` status listener must be added in `initState` and removed in `dispose`
- `pumpAndSettle()` drives spring animations to completion in tests; use `pump(Duration)` when inspecting mid-animation state
- `swipeOffsetListenable` is the primary test observation surface; avoid `RenderObject` matrix inspection
- Dartdoc (`///`) on all public members is required by `analysis_options.yaml` — `flutter analyze` will fail without it

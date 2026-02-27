# Tasks: Consolidated Configuration API & Theme Support

**Input**: Design documents from `/specs/005-config-api/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/config-api.md ✅

**Tests**: Included — Constitution VII mandates test-first. All tests MUST be written to fail
before the implementation code they exercise is written.

**Organization**: Tasks are grouped by user story (US1–US4 from spec.md). US1 and US2 are
parallelizable with each other; US3 requires US1 to be complete; US4 requires both US1 and US2.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no cross-story dependencies)
- **[Story]**: Which user story this task belongs to (US1–US4)
- **File paths are absolute from the repository root**

---

## Phase 1: Setup

**Purpose**: Establish a known-good baseline before any API changes.

- [x] T001 Run `flutter test` to confirm all F001–F004 tests pass before starting; record the baseline count

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: New data types that US3 (SwipeActionCellTheme) and the widget refactor depend on.
US1 config types must exist before the theme and widget can reference them.

> These tasks have no user story label because they are shared infrastructure for all stories.

- [x] T002 [P] Write failing unit tests for `RightSwipeConfig` in `test/config/right_swipe_config_test.dart` (verify `const` constructability, `stepValue ≤ 0` assertion fires, `minValue ≥ maxValue` assertion fires, `copyWith` no-arg equality, `copyWith` with args changes only specified fields)
- [x] T003 [P] Write failing unit tests for `LeftSwipeConfig` in `test/config/left_swipe_config_test.dart` (verify `const` constructability, `actionPanelWidth ≤ 0` assertion fires, reveal-mode with empty `actions` assertion fires with correct message, reveal-mode with non-empty `actions` passes, autoTrigger with empty `actions` passes, `copyWith` equality)
- [x] T004 [P] Write failing unit tests for `SwipeVisualConfig` in `test/config/swipe_visual_config_test.dart` (verify `const` constructability, default `clipBehavior == Clip.hardEdge`, `copyWith` no-arg equality, `copyWith` with `clipBehavior` changes only that field)
- [x] T005 [P] Write failing unit tests for `SwipeController` in `test/controller/swipe_controller_test.dart` (verify constructable, `dispose()` completes without error) ⚠️ **SCOPE NOTE**: Implementation wrote the full F7 controller test suite (~270 lines: command routing, state machine, ChangeNotifier, lifecycle) in this file. The F6 stub test spec was exceeded. This is pre-work for 006-controller-group Phase A.
- [x] T006 [P] Implement `RightSwipeConfig` in `lib/src/config/right_swipe_config.dart` using the signature from `contracts/config-api.md`; identical fields to `ProgressiveSwipeConfig` with improved assertion messages
- [x] T007 [P] Implement `LeftSwipeConfig` in `lib/src/config/left_swipe_config.dart` using the signature from `contracts/config-api.md`; add new reveal-mode empty-actions assertion vs `IntentionalSwipeConfig`
- [x] T008 [P] Implement `SwipeVisualConfig` in `lib/src/config/swipe_visual_config.dart`; `const` constructor, `final` fields, `copyWith`, `==`, `hashCode`
- [x] T009 [P] Implement `SwipeController` stub in `lib/src/controller/swipe_controller.dart`; `extends ChangeNotifier`, dartdoc noting F007 reservation ⚠️ **SCOPE NOTE**: Implementation delivered the full F7 SwipeController (openLeft/openRight/close/resetProgress/setProgress/attach/detach/reportState/reportProgress, state tracking, `_disposed` guard). Additionally, three F7-only files were created ahead of schedule: `swipe_cell_handle.dart`, `swipe_group_controller.dart`, `swipe_controller_provider.dart`. The barrel (T017) also exports the latter two. All code is correct per the 006-controller-group contracts; Phase A of 006 can be treated as pre-completed.

**Checkpoint**: `flutter test test/config/ test/controller/` — all foundational type tests pass

---

## Phase 3: User Story 1 — Consolidated Config API (Priority: P1) 🎯 MVP

**Goal**: Replace the scattered F001–F004 parameter set with the five-config-object API on
`SwipeActionCell`. Consumers can migrate with find-and-replace guided by compile errors alone.

**Independent Test**: Construct a `SwipeActionCell` using all five config objects
(`rightSwipeConfig`, `leftSwipeConfig`, `gestureConfig`, `animationConfig`, `visualConfig`) and
confirm the cell behaves identically to the equivalent F001–F004 API via widget tests.

### Tests for User Story 1

> **Write these tests FIRST — they must FAIL before T016 and T017 are implemented**

- [x] T010 [US1] Write failing widget migration tests in `test/widget/swipe_action_cell_migration_test.dart` covering: (a) `rightSwipeConfig: RightSwipeConfig(...)` fires callbacks identical to old `rightSwipe: ProgressiveSwipeConfig(...)`, (b) `leftSwipeConfig: LeftSwipeConfig(mode: .autoTrigger, ...)` fires `onActionTriggered` identically to old `leftSwipe: IntentionalSwipeConfig(...)`, (c) `leftSwipeConfig: LeftSwipeConfig(mode: .reveal, ...)` opens panel identically to old `leftSwipe`, (d) `visualConfig: SwipeVisualConfig(leftBackground: ...)` renders the builder, (e) `enabled: false` passes through touches, (f) no-config cell renders without error ⚠️ **QA FIX**: Scenarios (c) and (f) were missing from the original implementation. Added by QA review.

### Implementation for User Story 1

- [x] T011 [US1] Update `lib/src/widget/swipe_action_cell.dart` — Step 1: swap imports (remove `progressive_swipe_config.dart`, `intentional_swipe_config.dart`; add `config/right_swipe_config.dart`, `config/left_swipe_config.dart`, `config/swipe_visual_config.dart`, `controller/swipe_controller.dart`)
- [x] T012 [US1] Update `lib/src/widget/swipe_action_cell.dart` — Step 2: replace field declarations and constructor signature per `contracts/config-api.md`; `gestureConfig` and `animationConfig` become nullable with no default; add `rightSwipeConfig`, `leftSwipeConfig`, `visualConfig`, `controller` fields
- [x] T013 [US1] Update `lib/src/widget/swipe_action_cell.dart` — Step 3: replace all internal field references throughout `_SwipeActionCellState` (`widget.gestureConfig` → local variable from resolution cascade, `widget.leftBackground` → `effectiveVisual?.leftBackground`, `widget.rightSwipe` → local `effectiveRight`, `widget.leftSwipe` → local `effectiveLeft`, `widget.clipBehavior` → `effectiveVisual?.clipBehavior ?? Clip.hardEdge`, `widget.borderRadius` → `effectiveVisual?.borderRadius`)
- [x] T014 [US1] Migrate `test/actions/progressive/progressive_swipe_config_test.dart` to `test/config/right_swipe_config_test.dart` (update type names to `RightSwipeConfig`, remove old file)
- [x] T015 [US1] Migrate `test/actions/intentional/intentional_swipe_config_test.dart` to `test/config/left_swipe_config_test.dart` (update type names to `LeftSwipeConfig`, remove old file)
- [x] T016 [US1] Update all existing widget tests in `test/widget/swipe_action_cell_test.dart`, `test/widget/swipe_action_cell_progressive_test.dart`, `test/widget/swipe_action_cell_intentional_test.dart`, and `test/swipe_action_cell_test.dart` to use new parameter names (`rightSwipeConfig`, `leftSwipeConfig`, `visualConfig`)
- [x] T017 [US1] Update barrel `lib/swipe_action_cell.dart` — remove exports for deleted files, add exports for `config/right_swipe_config.dart`, `config/left_swipe_config.dart`, `config/swipe_visual_config.dart`, `controller/swipe_controller.dart`
- [x] T018 [US1] Delete `lib/src/actions/progressive/progressive_swipe_config.dart` and `lib/src/actions/intentional/intentional_swipe_config.dart`
- [x] T019 [US1] Add migration entry to `CHANGELOG.md` documenting every renamed type and parameter per SC-007 requirements ⚠️ **QA FIX**: Original entry documented parameter renames only. Type renames (`ProgressiveSwipeConfig → RightSwipeConfig`, `IntentionalSwipeConfig → LeftSwipeConfig`) were missing, violating SC-007 and FR-013. Added by QA review.
- [x] T020 [US1] Bump `version` in `pubspec.yaml` from `0.0.1` to `0.1.0`

**Checkpoint**: `flutter analyze` zero warnings; `flutter test` all tests pass — US1 complete and independently verifiable

---

## Phase 4: User Story 2 — Preset Constructors (Priority: P2)

**Goal**: Developers can configure gesture feel and animation character with a single named
constructor call. Presets produce perceptibly distinct behavior and satisfy the ≥ 2× rule.

**Independent Test**: Configure a cell with `gestureConfig: SwipeGestureConfig.tight()` and
`animationConfig: SwipeAnimationConfig.snappy()`; verify the cell is functional. Verify the
≥ 2× parameter difference via unit test without running the widget.

### Tests for User Story 2

> **Write these tests FIRST — they must FAIL before T023 and T024 are implemented**

- [x] T021 [P] [US2] Write failing unit tests for `SwipeGestureConfig` presets in `test/gesture/swipe_gesture_config_preset_test.dart`: `tight().deadZone >= 2 * loose().deadZone` (2× rule assertion), `tight().deadZone > 0`, `loose().deadZone > 0`, neither preset equals default instance, presets are not equal to each other, both support `copyWith`
- [x] T022 [P] [US2] Write failing unit tests for `SwipeAnimationConfig` presets in `test/animation/swipe_animation_config_preset_test.dart`: `snappy().completionSpring.stiffness >= 2 * smooth().completionSpring.stiffness` (2× rule assertion), `snappy().activationThreshold < smooth().activationThreshold` (snappy activates earlier), neither preset equals default instance, presets are not equal to each other, both support `copyWith`

### Implementation for User Story 2

- [x] T023 [P] [US2] Add `SwipeGestureConfig.tight()` and `SwipeGestureConfig.loose()` factory constructors to `lib/src/gesture/swipe_gesture_config.dart` per `contracts/config-api.md` (deadZone: 24.0/4.0, velocityThreshold: 1000.0/300.0); add dartdoc to both
- [x] T024 [P] [US2] Add `SwipeAnimationConfig.snappy()` and `SwipeAnimationConfig.smooth()` factory constructors to `lib/src/animation/swipe_animation_config.dart` per `contracts/config-api.md` (stiffness: 700.0/180.0); add dartdoc to both

**Checkpoint**: `flutter test test/gesture/swipe_gesture_config_preset_test.dart test/animation/swipe_animation_config_preset_test.dart` — all preset tests pass including 2× rule assertions

---

## Phase 5: User Story 3 — App-Wide Defaults via `SwipeActionCellTheme` (Priority: P3)

**Goal**: A developer installs `SwipeActionCellTheme` once at the app root and all
`SwipeActionCell` instances inherit the configured defaults without per-cell changes.

**Independent Test**: Install a `SwipeActionCellTheme` with `gestureConfig: SwipeGestureConfig.loose()`. Verify a cell with no local `gestureConfig` uses the loose config. Add a cell with `gestureConfig: SwipeGestureConfig.tight()` and verify only that cell changes.

**Prerequisite**: US1 (Phase 3) must be complete — `RightSwipeConfig` and `LeftSwipeConfig` must exist before `SwipeActionCellTheme` can reference them.

### Tests for User Story 3

> **Write these tests FIRST — they must FAIL before T027 and T028 are implemented**

- [x] T025 [P] [US3] Write failing unit tests for `SwipeActionCellTheme` in `test/config/swipe_action_cell_theme_test.dart`: `const` constructability with no args, `lerp(other, 0.0)` returns `this`, `lerp(other, 0.5)` returns `this`, `lerp(other, 1.0)` returns `other`, `lerp(null, 1.0)` returns `this`, `copyWith` no-arg returns equal instance, `maybeOf(context)` returns `null` when no theme installed
- [x] T026 [P] [US3] Write failing widget tests for theme inheritance in `test/widget/swipe_action_cell_theme_test.dart`: (a) theme-provided `gestureConfig` used when no local override, (b) local `gestureConfig` overrides theme; other theme configs still apply, (c) no theme in tree → package defaults, no crash, (d) theme `visualConfig` applies to cells without local `visualConfig`, (e) local `animationConfig: snappy()` overrides theme `smooth()`; other cells in tree unchanged

### Implementation for User Story 3

- [x] T027 [US3] Implement `SwipeActionCellTheme` in `lib/src/config/swipe_action_cell_theme.dart` per `contracts/config-api.md`: `ThemeExtension<SwipeActionCellTheme>`, five nullable config fields, `maybeOf()` static helper, `copyWith()`, hard-cutover `lerp()`, dartdoc on every member
- [x] T028 [US3] Update `_SwipeActionCellState.build()` in `lib/src/widget/swipe_action_cell.dart` to resolve effective configs via the three-level cascade: `localConfig ?? theme?.config ?? packageDefault` for gesture and animation; `localConfig ?? theme?.config` (no fallback default) for visual, right, and left
- [x] T029 [US3] Add `SwipeActionCellTheme` export to `lib/swipe_action_cell.dart`

**Checkpoint**: `flutter test test/config/swipe_action_cell_theme_test.dart test/widget/swipe_action_cell_theme_test.dart` — all theme tests pass

---

## Phase 6: User Story 4 — Clear, Actionable Validation Errors (Priority: P4)

**Goal**: Each of the four misconfiguration scenarios produces a distinct, readable assertion
message in debug mode. A developer can understand and act on the message within 10 seconds.

**Independent Test**: Provide four intentionally invalid configurations; verify each produces a
distinct message naming the field, provided value, and the valid range or requirement.

**Prerequisite**: US1 (Phase 3) and US2 (Phase 4) must be complete — assertions live inside the
config type constructors already implemented there.

### Tests for User Story 4

> **Write these tests FIRST — they must FAIL before T031 is implemented**

- [x] T030 [US4] Write failing unit/widget tests for all four validation scenarios in `test/widget/swipe_action_cell_validation_test.dart`: (a) `LeftSwipeConfig(mode: .reveal, actions: [])` throws `AssertionError` whose message contains "reveal mode requires at least one action", (b) `SwipeAnimationConfig(activationThreshold: -0.1)` throws `AssertionError` whose message contains "activationThreshold must be between 0.0 and 1.0" and the provided value, (c) `RightSwipeConfig(stepValue: 0.0)` throws `AssertionError` whose message contains "stepValue must be > 0" and the provided value, (d) `LeftSwipeConfig(mode: .autoTrigger, actionPanelWidth: -5.0)` throws `AssertionError` whose message contains "actionPanelWidth must be > 0" and the provided value

### Implementation for User Story 4

- [x] T031 [US4] Add `activationThreshold >= 0.0 && activationThreshold <= 1.0` assertion to `SwipeAnimationConfig` default constructor in `lib/src/animation/swipe_animation_config.dart` with message: `'activationThreshold must be between 0.0 and 1.0, got $activationThreshold'`
- [x] T032 [US4] Verify assertion messages in `lib/src/config/right_swipe_config.dart` and `lib/src/config/left_swipe_config.dart` match FR-009 requirements exactly (each names the invalid field, the provided value via `$variable`, and the requirement)

**Checkpoint**: `flutter test test/widget/swipe_action_cell_validation_test.dart` — all four validation scenarios pass with correct messages

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Final quality verification across all stories.

- [x] T033 [P] Run `flutter analyze` across the entire package; fix all warnings and errors until output is clean
- [x] T034 [P] Run `dart format --set-exit-if-changed .` and fix any formatting issues
- [x] T035 Run `flutter test` to confirm all tests pass (all pre-existing F001–F004 tests + all new tests)
- [x] T036 Manually verify the three quickstart.md migration examples compile and behave as documented
- [x] T037 Run `flutter pub publish --dry-run` to verify the package is publishable with zero issues

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup)         → No dependencies — run immediately
Phase 2 (Foundational)  → Depends on Phase 1 — BLOCKS Phase 3 and Phase 5 (US3 needs types)
Phase 3 (US1)           → Depends on Phase 2 — BLOCKS Phase 5 (US3)
Phase 4 (US2)           → Depends on Phase 2 — parallel with Phase 3
Phase 5 (US3)           → Depends on Phase 3 (needs RightSwipeConfig, LeftSwipeConfig)
Phase 6 (US4)           → Depends on Phase 3 AND Phase 4 (assertions live in US1/US2 types)
Phase 7 (Polish)        → Depends on all phases complete
```

### User Story Dependencies

```
US1 (P1): Depends on Foundational (Phase 2). No other US dependencies.
US2 (P2): Depends on Foundational (Phase 2). Parallel with US1.
US3 (P3): Depends on US1 completion (needs renamed types in SwipeActionCellTheme).
US4 (P4): Depends on US1 + US2 (assertions baked into those types).
```

### Within Each User Story

1. Tests written to FAIL (Red) before implementation begins
2. Implementation makes tests PASS (Green)
3. Refactor only after Green

### Parallel Opportunities

- **Phase 2**: T002, T003, T004, T005 (test writing) can run in parallel; T006, T007, T008, T009 (implementation) can run in parallel after tests are written
- **Phase 3**: T011→T012→T013 are sequential on the same file; T014 and T015 are parallel with each other; T016 can run concurrently with T014/T015
- **Phase 4**: T021 and T022 (tests) are parallel; T023 and T024 (implementation) are parallel
- **Phase 5**: T025 and T026 (tests) are parallel; T027 and T028 are sequential (theme type before widget usage)
- **Phase 7**: T033 and T034 are parallel

---

## Parallel Execution Examples

### Parallel: Phase 2 Tests (Foundational)

```
Launch simultaneously:
  Task: Write failing RightSwipeConfig tests → test/config/right_swipe_config_test.dart
  Task: Write failing LeftSwipeConfig tests  → test/config/left_swipe_config_test.dart
  Task: Write failing SwipeVisualConfig tests → test/config/swipe_visual_config_test.dart
  Task: Write failing SwipeController tests  → test/controller/swipe_controller_test.dart

Then launch simultaneously:
  Task: Implement RightSwipeConfig  → lib/src/config/right_swipe_config.dart
  Task: Implement LeftSwipeConfig   → lib/src/config/left_swipe_config.dart
  Task: Implement SwipeVisualConfig → lib/src/config/swipe_visual_config.dart
  Task: Implement SwipeController   → lib/src/controller/swipe_controller.dart
```

### Parallel: US1 + US2 (after Phase 2)

```
Developer A: Phase 3 (US1) — widget constructor refactor
Developer B: Phase 4 (US2) — preset constructors (different files, independent)
```

### Parallel: Phase 4 Presets

```
Launch simultaneously:
  Task: Preset tests for SwipeGestureConfig  → test/gesture/swipe_gesture_config_preset_test.dart
  Task: Preset tests for SwipeAnimationConfig → test/animation/swipe_animation_config_preset_test.dart

Then launch simultaneously:
  Task: Add tight()/loose() to SwipeGestureConfig    → lib/src/gesture/swipe_gesture_config.dart
  Task: Add snappy()/smooth() to SwipeAnimationConfig → lib/src/animation/swipe_animation_config.dart
```

---

## Implementation Strategy

### MVP First (User Story 1 + Foundational Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002–T009)
3. Complete Phase 3: User Story 1 (T010–T020)
4. **STOP and VALIDATE**: `flutter analyze` + `flutter test` — all clear
5. Ship: Package API is migrated; consumers can adopt immediately

### Incremental Delivery

1. Phase 1 + 2: Config types ready → library compiles with new types
2. + US1 (Phase 3): Widget API migrated → consumers can upgrade with find-and-replace
3. + US2 (Phase 4): Presets available → developers get fast configuration
4. + US3 (Phase 5): Theme support → app-wide consistency possible
5. + US4 (Phase 6): Validation messages → integration error feedback improved

Each increment adds value without breaking the previous state (within the breaking-change release).

---

## Notes

- **Existing test file migration** (T014, T015): The old test files import `ProgressiveSwipeConfig` and `IntentionalSwipeConfig`. After migration they import `RightSwipeConfig` and `LeftSwipeConfig`. Delete the old files after migration to prevent duplicate test IDs.
- **Widget file edit scope** (T011, T012, T013): All three tasks edit `lib/src/widget/swipe_action_cell.dart`. Run them sequentially. T013 (internal reference replacement) is the most invasive — use `replace_all` tooling where possible.
- **`activationThreshold` assert placement** (T031): This assert lives in `SwipeAnimationConfig` default constructor, but its tests are in US4. The assert must be added as part of US4 even though it modifies a US2 file, because the US2 phase only adds preset factories.
- **Version bump** (T020): `0.0.1` → `0.1.0` signals the breaking API change within pre-1.0 conventions.
- **`flutter pub publish --dry-run`** (T037): If this reports issues (missing LICENSE, SDK constraints, etc.), resolve them as additional polish tasks.

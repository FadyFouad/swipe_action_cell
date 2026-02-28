# Tasks: Unified Feedback System

**Input**: Design documents from `specs/010-unified-feedback/`
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/public-api.md ✓

**Tests**: Included — Constitution VII (Test-First) is NON-NEGOTIABLE. All tests written to FAIL before implementation.

**Organization**: Tasks grouped by user story for independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no shared dependencies on incomplete tasks)
- **[Story]**: Which user story this task belongs to (US1–US5)
- Exact file paths included in every description

---

## Phase 1: Setup

**Purpose**: Create new source and test directories for F010 feedback infrastructure.

- [X] T001 Create `lib/src/feedback/` directory (new package module for F010)
- [X] T002 Create `test/feedback/` directory (new test module for F010)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: All public data types and the theme field that every user story depends on. No user story behavior is added here — only the shared types that make subsequent phases compile.

**⚠️ CRITICAL**: All user story phases depend on this phase completing first.

### Tests (write to FAIL before implementing)

- [X] T003 [P] Write failing unit tests for `SwipeFeedbackConfig` (const construction, `copyWith`, equality, master toggles) in `test/feedback/swipe_feedback_config_test.dart`
- [X] T004 [P] Write failing unit tests for `HapticPattern` and `HapticStep` (named factories, zero-step pattern, 8-step limit assert, equality) in `test/feedback/haptic_pattern_test.dart`

### Implementation

- [X] T005 Create `SwipeFeedbackEvent` enum (7 values: `thresholdCrossed`, `actionTriggered`, `progressIncremented`, `panelOpened`, `panelClosed`, `zoneBoundaryCrossed`, `swipeCancelled`) with dartdoc in `lib/src/feedback/swipe_feedback_config.dart`
- [X] T006 Create `HapticType` enum (6 values: `lightImpact`, `mediumImpact`, `heavyImpact`, `successNotification`, `errorNotification`, `selectionTick`) and `SwipeSoundEvent` enum (5 values) with dartdoc in `lib/src/feedback/swipe_feedback_config.dart`
- [X] T007 Create `HapticStep` const immutable class (fields: `type: HapticType`, `delayBeforeNextMs: int = 0`) with `==`, `hashCode`, and dartdoc in `lib/src/feedback/swipe_feedback_config.dart`
- [X] T008 Create `HapticPattern` const immutable class (field: `steps: List<HapticStep>`; assert `steps.length <= 8`; named const values: `light`, `medium`, `heavy`, `tick`, `success`, `error`, `silent`) with `==`, `hashCode`, and dartdoc in `lib/src/feedback/swipe_feedback_config.dart`
- [X] T009 Create `SwipeFeedbackConfig` const immutable class (fields: `enableHaptic: bool = true`, `enableAudio: bool = false`, `hapticOverrides: Map<SwipeFeedbackEvent, HapticPattern>?`, `onShouldPlaySound: void Function(SwipeSoundEvent)?`) with `copyWith`, `==`, `hashCode`, and dartdoc in `lib/src/feedback/swipe_feedback_config.dart`
- [X] T010 Add `feedbackConfig: SwipeFeedbackConfig?` field to `SwipeActionCellTheme` (constructor, `copyWith`, `==`, `hashCode`, `lerp`, dartdoc) in `lib/src/config/swipe_action_cell_theme.dart`
- [X] T011 Add `export 'src/feedback/swipe_feedback_config.dart';` to `lib/swipe_action_cell.dart` (do NOT export `feedback_dispatcher.dart`)

**Checkpoint**: `flutter test test/feedback/swipe_feedback_config_test.dart test/feedback/haptic_pattern_test.dart` — tests should now PASS. `flutter analyze` — zero warnings.

---

## Phase 3: User Story 1 — Developer Replaces Scattered Haptic Calls with a Single Config (Priority: P1) 🎯 MVP

**Goal**: A developer can replace `enableHaptic: true` on direction configs with a single `SwipeFeedbackConfig(enableHaptic: true)` and observe identical haptic behavior. Legacy `enableHaptic` continues to work unchanged when no `SwipeFeedbackConfig` is present.

**Independent Test**: Configure a cell with `SwipeFeedbackConfig(enableHaptic: true)`, perform each swipe event type (threshold, action, progress), inspect the mock haptic channel log, and verify the correct default pattern fires for each. Separately verify `enableHaptic: true` on a direction config (no `SwipeFeedbackConfig`) still fires haptic as before.

### Tests for User Story 1 (write to FAIL before implementing)

- [X] T012 [P] [US1] Write failing unit tests for `FeedbackDispatcher` basic dispatch (default patterns, single-step, `enableHaptic: false` silences all) in `test/feedback/feedback_dispatcher_test.dart`
- [X] T013 [P] [US1] Write failing widget tests for US1 acceptance scenarios (SC-002, SC-003 subset, SC-008) in `test/widget/swipe_action_cell_feedback_test.dart`

### Implementation for User Story 1

- [X] T014 [US1] Create `FeedbackDispatcher` class with `factory FeedbackDispatcher.resolve({SwipeFeedbackConfig? cellConfig, SwipeFeedbackConfig? themeConfig, bool legacyForwardHaptic, bool legacyBackwardHaptic})` in `lib/src/feedback/feedback_dispatcher.dart`
- [X] T015 [US1] Implement `FeedbackDispatcher._fireHapticType(HapticType)` mapping each `HapticType` value to its `HapticFeedback.*` call, wrapped in `try { } catch (Object _) { }` for platform safety, in `lib/src/feedback/feedback_dispatcher.dart`
- [X] T016 [US1] Implement `FeedbackDispatcher.fire(SwipeFeedbackEvent, {bool isForward})` with: (a) legacy mode when `_config == null` (fires `lightImpact` for threshold/zone or `mediumImpact` for action/progress based on direction flags), (b) `enableHaptic` master toggle check, (c) default pattern lookup via `_defaultPatternFor()` switch expression, (d) single-step synchronous dispatch via `_fireHapticType` in `lib/src/feedback/feedback_dispatcher.dart`
- [X] T017 [US1] Add `feedbackConfig: SwipeFeedbackConfig?` parameter with dartdoc to `SwipeActionCell` widget constructor in `lib/src/widget/swipe_action_cell.dart`
- [X] T018 [US1] Add `FeedbackDispatcher? _feedbackDispatcher` field to `_SwipeActionCellState`; create it in `didChangeDependencies()` via `FeedbackDispatcher.resolve(cellConfig: widget.feedbackConfig, themeConfig: SwipeActionCellTheme.maybeOf(context)?.feedbackConfig, legacyForwardHaptic: _resolvedForwardConfig?.enableHaptic ?? false, legacyBackwardHaptic: _resolvedBackwardConfig?.enableHaptic ?? false)` in `lib/src/widget/swipe_action_cell.dart`
- [X] T019 [US1] Replace threshold haptic block (lines 1115–1129: two separate `HapticFeedback.lightImpact()` direction checks) with a single unified check `if (progress.isActivated && !_hapticThresholdFired && !_hasActiveZones()) { _feedbackDispatcher?.fire(SwipeFeedbackEvent.thresholdCrossed, isForward: _dragIsForward); _hapticThresholdFired = true; }` in `lib/src/widget/swipe_action_cell.dart`
- [X] T020 [US1] Replace zone boundary haptic call (line 1097: `_fireZoneHaptic(zones[newZoneIndex].hapticPattern)`) with dispatcher-first logic: `if (_feedbackDispatcher != null) { _feedbackDispatcher!.fire(SwipeFeedbackEvent.zoneBoundaryCrossed, isForward: _dragIsForward); } else { _fireZoneHaptic(zones[newZoneIndex].hapticPattern); }` in `lib/src/widget/swipe_action_cell.dart`
- [X] T021 [US1] Replace `_applyIntentionalAction` haptic calls (lines 497–502: zone path `_fireZoneHaptic(...)` and direct path `if (config.enableHaptic) HapticFeedback.mediumImpact()`) with `_feedbackDispatcher?.fire(SwipeFeedbackEvent.actionTriggered)` (dispatcher handles legacy internally) in `lib/src/widget/swipe_action_cell.dart`
- [X] T022 [US1] Replace `_applyProgressiveIncrement` haptic calls (lines 570–576: zone path `_fireZoneHaptic(...)` and direct path `if (config.enableHaptic) HapticFeedback.mediumImpact()`) with `_feedbackDispatcher?.fire(SwipeFeedbackEvent.progressIncremented)` in `lib/src/widget/swipe_action_cell.dart`
- [X] T023 [US1] Add `panelOpened` fire point: call `_feedbackDispatcher?.fire(SwipeFeedbackEvent.panelOpened)` after `_updateState(SwipeState.revealed)` in the animation-settle handler (reveal mode only) in `lib/src/widget/swipe_action_cell.dart`
- [X] T024 [US1] Add `panelClosed` fire point: call `_feedbackDispatcher?.fire(SwipeFeedbackEvent.panelClosed)` after `_updateState(SwipeState.idle)` when transitioning from `animatingToClose` following a revealed state in `lib/src/widget/swipe_action_cell.dart`
- [X] T025 [US1] Add `swipeCancelled` fire point: call `_feedbackDispatcher?.fire(SwipeFeedbackEvent.swipeCancelled, isForward: _dragIsForward)` in `_handleDragEnd` when the drag is released below the activation threshold in `lib/src/widget/swipe_action_cell.dart`
- [X] T026 [US1] Add `_feedbackDispatcher?.cancelPendingTimers()` call in `_handleDragStart` (immediately before or after `_hapticThresholdFired = false`) and in `dispose()` in `lib/src/widget/swipe_action_cell.dart`
- [X] T027 [US1] Add debug assert for legacy coexistence (FR-019): assert that `!(widget.feedbackConfig != null && (_resolvedForwardConfig?.enableHaptic == true || _resolvedBackwardConfig?.enableHaptic == true))` with message guiding developer to remove `enableHaptic` from direction configs in `lib/src/widget/swipe_action_cell.dart`
- [X] T028 [US1] Add `onFeedbackRequest: VoidCallback?` parameter to `SwipeActionPanel` constructor; in `_handleButtonTap` replace both `if (widget.enableHaptic) HapticFeedback.mediumImpact()` calls with `if (widget.onFeedbackRequest != null) { widget.onFeedbackRequest!(); } else if (widget.enableHaptic) { HapticFeedback.mediumImpact(); }` in `lib/src/actions/intentional/swipe_action_panel.dart`
- [X] T029 [US1] Pass `onFeedbackRequest` to `SwipeActionPanel` instantiation in the widget: `onFeedbackRequest: _feedbackDispatcher != null ? () => _feedbackDispatcher!.fire(SwipeFeedbackEvent.actionTriggered) : null` in `lib/src/widget/swipe_action_cell.dart`

**Checkpoint**: `flutter test test/feedback/feedback_dispatcher_test.dart test/widget/swipe_action_cell_feedback_test.dart` passes for US1 scenarios. `flutter test` — all pre-existing tests still pass (zero regressions).

---

## Phase 4: User Story 2 — Developer Customizes Haptic Patterns Per Event (Priority: P1)

**Goal**: A developer can provide `hapticOverrides: {SwipeFeedbackEvent.thresholdCrossed: HapticPattern.light, SwipeFeedbackEvent.actionTriggered: HapticPattern.heavy}` and each swipe event fires its override pattern. Events without an override use the predefined default. Multi-step patterns (e.g., `[lightImpact, 50ms, lightImpact]`) fire their steps in sequence without blocking gesture processing.

**Independent Test**: Configure `hapticOverrides` with distinct patterns for threshold, action, and progress events; trigger each; inspect the mock channel call log and verify the expected type and sequence for each. Use `FakeAsync` to verify multi-step timing without real delays.

### Tests for User Story 2 (write to FAIL before implementing)

- [X] T030 [P] [US2] Write failing unit tests for `hapticOverrides` lookup (override fires, missing key uses default, empty map uses defaults), multi-step pattern execution with `FakeAsync`, and `cancelPendingTimers()` preventing pending steps in `test/feedback/feedback_dispatcher_test.dart`
- [X] T031 [P] [US2] Write failing widget tests for US2 acceptance scenarios (SC-003 full, SC-004) in `test/widget/swipe_action_cell_feedback_test.dart`

### Implementation for User Story 2

- [X] T032 [US2] Extend `FeedbackDispatcher.fire()` to look up `_config.hapticOverrides?[event]` before calling `_defaultPatternFor(event)`; pass resolved pattern to `_executePattern()` in `lib/src/feedback/feedback_dispatcher.dart`
- [X] T033 [US2] Implement `FeedbackDispatcher._executePattern(HapticPattern pattern)`: fire `steps[0]` immediately via `_fireHapticType`; for each subsequent step `i > 0`, schedule `Timer(Duration(milliseconds: steps[i-1].delayBeforeNextMs), () { _fireHapticType(steps[i].type); _activeTimers.removeWhere((t) => !t.isActive); })` and add timer to `_activeTimers`; skip entirely if `pattern.steps.isEmpty` in `lib/src/feedback/feedback_dispatcher.dart`
- [X] T034 [US2] Implement `FeedbackDispatcher.cancelPendingTimers()`: iterate `_activeTimers`, call `.cancel()` on each, then `.clear()` the list in `lib/src/feedback/feedback_dispatcher.dart`

**Checkpoint**: `flutter test test/feedback/feedback_dispatcher_test.dart` passes for US2 scenarios. Multi-step patterns verified with `FakeAsync`.

---

## Phase 5: User Story 5 — Haptic Degrades Gracefully on Unsupported Platforms (Priority: P1)

**Goal**: On web or devices where the haptic channel throws, `SwipeFeedbackConfig(enableHaptic: true)` produces no exception and all swipe behavior is unaffected. Multi-step patterns on unsupported platforms are silently skipped in their entirety.

**Independent Test**: Mock `SystemChannels.platform` to throw `MissingPluginException` on any haptic method call; trigger a threshold crossing with `enableHaptic: true`; verify no exception propagates and the swipe animation completes.

### Tests for User Story 5 (write to FAIL before implementing)

- [X] T035 [P] [US5] Write failing unit tests: mock haptic channel to throw `MissingPluginException`; call `fire(SwipeFeedbackEvent.thresholdCrossed)`; verify no exception surfaces and `cancelPendingTimers()` works normally after in `test/feedback/feedback_dispatcher_test.dart`
- [X] T036 [P] [US5] Write failing unit tests: mock haptic channel to throw bare `Exception`; verify silent discard for all `HapticType` values in `test/feedback/feedback_dispatcher_test.dart`

### Implementation for User Story 5

- [X] T037 [US5] Review `FeedbackDispatcher._fireHapticType()` (implemented in T015) to confirm the `try { } catch (Object _) { }` block covers `MissingPluginException`, `PlatformException`, and bare `Exception`; add a comment referencing FR-021 in `lib/src/feedback/feedback_dispatcher.dart`

**Checkpoint**: `flutter test test/feedback/feedback_dispatcher_test.dart` passes for all US5 scenarios.

---

## Phase 6: User Story 3 — Developer Receives Audio Hook Callbacks (Priority: P2)

**Goal**: A developer providing `onShouldPlaySound: (event) => recordedEvents.add(event)` and `enableAudio: true` receives the correct `SwipeSoundEvent` for each triggering swipe event. Enabling `enableAudio: false` (default) never calls the callback. A throwing callback does not affect swipe behavior.

**Independent Test**: Configure `onShouldPlaySound` with a recording closure and `enableAudio: true`; trigger each swipe event type; verify `recordedEvents` contains exactly the expected `SwipeSoundEvent` values. Then verify `enableAudio: false` produces zero callback invocations.

### Tests for User Story 3 (write to FAIL before implementing)

- [X] T038 [P] [US3] Write failing unit tests for audio dispatch: `enableAudio: true` + non-null callback fires correct `SwipeSoundEvent` per triggering event; `enableAudio: false` fires nothing; null callback with `enableAudio: true` fires nothing; throwing callback is caught and suppressed (SC-005) in `test/feedback/feedback_dispatcher_test.dart`
- [X] T039 [P] [US3] Write failing widget tests for US3 acceptance scenarios (US3 scenarios 1–5) in `test/widget/swipe_action_cell_feedback_test.dart`

### Implementation for User Story 3

- [X] T040 [US3] Add `_soundEventFor(SwipeFeedbackEvent) → SwipeSoundEvent?` private method mapping the 5 feedback events that have a sound counterpart to their `SwipeSoundEvent` value (returns `null` for `zoneBoundaryCrossed` and `swipeCancelled`) in `lib/src/feedback/feedback_dispatcher.dart`
- [X] T041 [US3] Extend `FeedbackDispatcher.fire()`: after dispatching haptic, if `_config?.enableAudio == true && _config?.onShouldPlaySound != null`, call `_soundEventFor(event)` and if non-null, invoke callback inside `try { _config!.onShouldPlaySound!(soundEvent); } catch (Object _) { }` in `lib/src/feedback/feedback_dispatcher.dart`

**Checkpoint**: `flutter test test/feedback/feedback_dispatcher_test.dart test/widget/swipe_action_cell_feedback_test.dart` passes for all US3 scenarios.

---

## Phase 7: User Story 4 — Developer Configures App-Wide Feedback via Theme (Priority: P2)

**Goal**: A developer adding `SwipeActionCellTheme(feedbackConfig: SwipeFeedbackConfig(enableHaptic: false))` silences haptic across all descendant cells. A cell with its own `SwipeFeedbackConfig(enableHaptic: true)` overrides the theme. Cells without a local config inherit the theme value.

**Independent Test**: Wrap multiple cells in a `SwipeActionCellTheme`; verify theme config is applied to all; verify a cell with its own config uses only its local config.

*Note*: The infrastructure for theme propagation was already wired in Phase 3 (T018 passes `themeConfig` to `FeedbackDispatcher.resolve()`). This phase adds targeted tests to verify the cascade behavior defined in US4's acceptance scenarios.

### Tests for User Story 4 (write to FAIL before implementing)

- [X] T042 [P] [US4] Write failing widget tests for US4 acceptance scenarios: (1) theme `enableHaptic: false` silences all cells; (2) cell-level `enableHaptic: true` overrides theme silence; (3) no theme + no cell config → legacy behavior applies (SC-007) in `test/widget/swipe_action_cell_feedback_test.dart`
- [X] T043 [P] [US4] Write failing unit tests for `SwipeActionCellTheme` with `feedbackConfig`: `copyWith` propagates field, equality includes field, `lerp` includes field in `test/config/swipe_action_cell_theme_test.dart`

### Implementation for User Story 4

- [X] T044 [US4] Verify `FeedbackDispatcher.resolve()` correctly prioritises `cellConfig ?? themeConfig` (cell wins; theme used only when cell is null); add an explicit unit test case if the existing tests in T012 do not cover this cascade in `test/feedback/feedback_dispatcher_test.dart`

**Checkpoint**: `flutter test test/config/swipe_action_cell_theme_test.dart test/widget/swipe_action_cell_feedback_test.dart` passes for all US4 scenarios.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Regression verification, formatting, and documentation.

- [X] T045 [P] Run `flutter test` across the full test suite and confirm zero regressions in all pre-existing test files (F003: `test/widget/swipe_action_cell_progressive_test.dart`, F004: `test/widget/swipe_action_cell_intentional_test.dart`, F009: `test/widget/swipe_action_cell_zones_test.dart`, and all others) — SC-001
- [X] T046 [P] Run `flutter analyze` and resolve all warnings (zero-warning gate per Constitution linting rules)
- [X] T047 Run `dart format .` to auto-format all modified and new Dart files
- [X] T048 Audit dartdoc on all public members in `lib/src/feedback/swipe_feedback_config.dart` and confirm every class, enum, enum value, field, and method has a `///` comment per Constitution VIII

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — **BLOCKS** all user story phases
- **Phase 3 (US1)**: Depends on Phase 2 completion — all haptic dispatch infrastructure
- **Phase 4 (US2)**: Depends on Phase 3 (FeedbackDispatcher must exist before extending)
- **Phase 5 (US5)**: Depends on Phase 3 (`_fireHapticType` must exist to verify try/catch)
- **Phase 6 (US3)**: Depends on Phase 3 (`fire()` method must exist before extending for audio)
- **Phase 7 (US4)**: Depends on Phase 3 (theme wiring is in `didChangeDependencies()`)
- **Phase 8 (Polish)**: Depends on all story phases completing

### User Story Dependencies

- **US1 (P1)**: Requires Foundational complete — no dependencies on other user stories
- **US2 (P1)**: Requires US1 complete (extends `FeedbackDispatcher.fire()`)
- **US5 (P1)**: Requires US1 complete (verifies `_fireHapticType()` from US1)
- **US3 (P2)**: Requires US1 complete (extends `fire()` for audio); US2 can be concurrent
- **US4 (P2)**: Requires US1 complete (theme wiring exists from Phase 3)
- **US4 + US3**: Can proceed in parallel after US1 completes

### Parallel Opportunities Within Each Phase

- **Phase 2**: T003 ∥ T004 (different test files); T005 ∥ T010 ∥ T011 can be staged as T005→T006→T007→T008→T009→T010→T011 (same file, must be sequential within the feedback config file but T010+T011 touch different files)
- **Phase 3**: T012 ∥ T013 (tests in different files); T014→T015→T016 (sequential, same file); T017→…→T029 (sequential, widget file)
- **Phase 4**: T030 ∥ T031 (different files); T032→T033→T034 (sequential, same file)
- **Phase 5**: T035 ∥ T036 (same file, but independent test cases); T037 (review task)
- **Phase 6**: T038 ∥ T039 (different files)
- **Phase 7**: T042 ∥ T043 (different files)
- **Phase 8**: T045 ∥ T046 (independent commands)

---

## Parallel Example: User Story 1 Kickoff

```
# Once Phase 2 completes, start US1 tests in parallel:
Task A: Write failing unit tests for FeedbackDispatcher (T012) in test/feedback/feedback_dispatcher_test.dart
Task B: Write failing widget tests for US1 scenarios (T013) in test/widget/swipe_action_cell_feedback_test.dart

# Then implement sequentially:
T014 → T015 → T016  (FeedbackDispatcher creation, _fireHapticType, fire())
T017 → T018         (SwipeActionCell param + dispatcher creation)
T019 → T020 → T021 → T022 → T023 → T024 → T025  (haptic call replacements)
T026 → T027 → T028 → T029  (timer cancellation, debug assert, panel threading)
```

---

## Implementation Strategy

### MVP First (US1 Only — Minimum Viable Migration)

1. Complete Phase 1: Setup (5 minutes)
2. Complete Phase 2: Foundational (all public types, theme field, barrel export) — test red first
3. Complete Phase 3: US1 (FeedbackDispatcher + widget wiring + backward compat) — test red first
4. **STOP and VALIDATE**: Run `flutter test` — all tests green, all legacy tests pass
5. **Deliverable**: Developer can use `SwipeFeedbackConfig(enableHaptic: true)` in place of direction-level flags; legacy `enableHaptic` still works

### Incremental Delivery After MVP

1. Add Phase 4 (US2) → custom haptic patterns per event → test and validate
2. Add Phase 5 (US5) → platform degradation verification (implementation already done in Phase 3; adds tests)
3. Add Phase 6 (US3) → audio hooks → test and validate
4. Add Phase 7 (US4) → theme-level config → test and validate
5. Complete Phase 8 → regression sweep, format, lint

### Parallel Team Strategy (if applicable)

After Phase 3 (US1) completes:
- Developer A: Phase 4 (US2 — custom patterns)
- Developer B: Phase 6 (US3 — audio hooks)
- Developer C: Phase 7 (US4 — theme)
- Phase 5 (US5) can be done by any developer in parallel (test-only phase)

---

## Notes

- `[P]` tasks touch different files or have no shared incomplete dependencies — safe to launch in parallel
- `[USN]` label maps each task to the user story it directly delivers or tests
- Constitution VII mandates tests FAIL before implementation — do not skip the red phase
- `FeedbackDispatcher` (`feedback_dispatcher.dart`) is internal — do NOT add it to `lib/swipe_action_cell.dart` exports
- The `_fireZoneHaptic(SwipeZoneHaptic?)` helper is preserved for F009 legacy consumers
- `SwipeActionPanel.enableHaptic` remains in place; the new `onFeedbackRequest` is additive only
- Commit after each checkpoint to preserve a working state at each increment

# Tasks: Multi-Zone Swipe (F009)

**Input**: Design documents from `/specs/009-multi-zone-swipe/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/ ✅

**Tests**: Test tasks are included — Constitution VII mandates test-first (NON-NEGOTIABLE). Every implementation task is preceded by a failing-test task.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete prior tasks)
- **[Story]**: Which user story this task belongs to
- Exact file paths in every description

---

## Phase 1: Setup

**Purpose**: Create the new namespaces and empty test/source stubs so all phases can work in parallel without file-creation conflicts.

- [X] T001 Create `lib/src/zones/` directory (will hold `zone_resolver.dart`, `zone_background.dart`)
- [X] T002 [P] Create empty test directory `test/zones/` and empty stub files: `test/core/swipe_zone_test.dart`, `test/zones/zone_resolver_test.dart`, `test/zones/zone_background_test.dart`, `test/widget/swipe_action_cell_zones_test.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core value types and pure-function utilities that ALL user story phases depend on. No user story implementation can begin until this phase is complete.

**⚠️ CRITICAL**: Phases 3–7 are blocked until Phase 2 completes.

- [X] T003 Write failing unit tests for `SwipeZone` (threshold bounds assert, empty semanticLabel assert, copyWith, ==, hashCode), `ZoneTransitionStyle` (3 values), `SwipeZoneHaptic` (3 values) in `test/core/swipe_zone_test.dart` — tests MUST fail before T004
- [X] T004 Implement `SwipeZone` (`@immutable`, `const` constructor, all fields, two asserts), `ZoneTransitionStyle` enum, `SwipeZoneHaptic` enum with `///` dartdoc on every public member in `lib/src/core/swipe_zone.dart` — run tests from T003; all must pass
- [X] T005 Write failing unit tests for `resolveActiveZoneIndex` (empty list, below threshold, at threshold, between zones, above all), `resolveActiveZone` (null when -1, correct zone), and `assertZonesValid` (>4 zones, duplicate thresholds, descending thresholds, missing semanticLabel, progressive missing stepValue) in `test/zones/zone_resolver_test.dart` — tests MUST fail before T006
- [X] T006 Implement `resolveActiveZoneIndex`, `resolveActiveZone`, and `assertZonesValid(List<SwipeZone> zones, {bool progressive = false})` with dartdoc in `lib/src/zones/zone_resolver.dart` — run tests from T005; all must pass
- [X] T007 Add zone-tracking fields (`_lastHapticZoneIndex`, `_currentZoneIndex`, `_activeZoneAtRelease`) and private helpers (`_effectiveForwardZones()`, `_effectiveBackwardZones()`, `_fireZoneHaptic(SwipeZoneHaptic?)`) to `SwipeActionCellState`; reset `_lastHapticZoneIndex = -1`, `_currentZoneIndex = -1`, `_activeZoneAtRelease = null` in `_handleDragStart` in `lib/src/widget/swipe_action_cell.dart`
- [X] T008 Modify `_handleDragEnd` in `lib/src/widget/swipe_action_cell.dart`: compute `resolveActiveZone` for the locked direction when zones are configured; store result in `_activeZoneAtRelease`; update `shouldComplete` to use `_activeZoneAtRelease != null` when zones present, falling through to existing `ratio >= activationThreshold` when no zones

**Checkpoint**: Foundation ready — zone types exist, resolver works, widget has tracking infrastructure. User stories can now proceed.

---

## Phase 3: User Story 1 — Multiple Intentional Zones on Left Swipe (Priority: P1)

**Goal**: Developers can configure 2–4 left-swipe zones with distinct `onActivated` callbacks. On release, only the highest-crossed zone's callback fires. Zones with `onActivated: null` are valid visual-only milestones.

**Independent Test**: Configure a `LeftSwipeConfig` with zones `[{threshold: 0.4, onActivated: archive}, {threshold: 0.8, onActivated: delete}]`. Drag to 50% → only archive fires. Drag to 85% → only delete fires. Drag to 25% → snap back, neither fires.

- [X] T009 Write failing unit tests for `LeftSwipeConfig` zone extension: valid 2-zone config constructs, descending thresholds assert, >4 zones assert, missing semanticLabel assert, 1-entry list is valid (treated as single-threshold), `copyWith(zones:)` returns updated instance, `==` reflects zone list changes in `test/config/left_swipe_config_test.dart` — tests MUST fail before T010
- [X] T010 Extend `LeftSwipeConfig` with `final List<SwipeZone>? zones` (default `null`) and `final ZoneTransitionStyle zoneTransitionStyle` (default `ZoneTransitionStyle.instant`); add `assertZonesValid` guard in constructor; update `copyWith`, `==`, `hashCode`, and dartdoc in `lib/src/config/left_swipe_config.dart` — run T009 tests; all must pass
- [X] T011 Write failing widget tests for intentional zone outcome: two-zone left swipe fires zone[0].onActivated when released at zone[0] threshold, fires zone[1].onActivated when released at zone[1] threshold, fires nothing when below all thresholds; three-zone release picks highest crossed; visual-only zone (`onActivated: null`) fires no callback without error; `postActionBehavior` still applies after zone action in `test/widget/swipe_action_cell_zones_test.dart` — tests MUST fail before T012
- [X] T012 Modify `_applyIntentionalAction` in `lib/src/widget/swipe_action_cell.dart`: when `_activeZoneAtRelease != null` and backward zones are configured, call `_activeZoneAtRelease!.onActivated?.call()` instead of `config.onActionTriggered`; fire `_activeZoneAtRelease!.hapticPattern` via `_fireZoneHaptic` (or fall back to `config.enableHaptic`); clear `_activeZoneAtRelease = null` after consumption — run T011 tests; all must pass
- [X] T013 [P] Write and run regression tests confirming `LeftSwipeConfig` without zones (plain `onActionTriggered`) behaves identically to pre-F009 behavior, covering auto-trigger, reveal mode, requireConfirmation in `test/widget/swipe_action_cell_zones_test.dart`

**Checkpoint**: Left-swipe multi-zone intentional behavior fully functional and independently testable.

---

## Phase 4: User Story 2 — Multiple Progressive Zones on Right Swipe (Priority: P1)

**Goal**: Developers can configure 2–4 right-swipe zones with distinct `stepValue`s. On release, the highest-crossed zone's step value is used for the increment.

**Independent Test**: Configure a `RightSwipeConfig` with zones `[{threshold: 0.3, stepValue: 1}, {threshold: 0.6, stepValue: 5}, {threshold: 0.9, stepValue: 10}]`. Release at 35% → value +1. Release at 65% → value +5. Release at 92% → value +10. Release at 20% → snap back, no change.

**Note**: Phases 3 and 4 can be worked on in parallel by different developers — they touch different config files and different method paths in the widget.

- [X] T014 [P] Write failing unit tests for `RightSwipeConfig` zone extension: valid 2-zone config constructs, descending thresholds assert, >4 zones assert, missing semanticLabel assert, missing `stepValue` assert (progressive: true), 1-entry list valid, `copyWith(zones:)` returns updated instance, `==` reflects changes in `test/config/right_swipe_config_test.dart` — tests MUST fail before T015
- [X] T015 [P] Extend `RightSwipeConfig` with `final List<SwipeZone>? zones` (default `null`) and `final ZoneTransitionStyle zoneTransitionStyle` (default `ZoneTransitionStyle.instant`); add `assertZonesValid(zones!, progressive: true)` guard in constructor; update `copyWith`, `==`, `hashCode`, and dartdoc in `lib/src/config/right_swipe_config.dart` — run T014 tests; all must pass
- [X] T016 [P] Write failing widget tests for progressive zone outcome: three-zone right swipe at 35% → +1, at 65% → +5, at 92% → +10; two-zone release at zone[1] uses zone[1].stepValue; release below all zones snaps back; `overflowBehavior: clamp` still applies with zone stepValue; `onSwipeCompleted` called with final value in `test/widget/swipe_action_cell_zones_test.dart` — tests MUST fail before T017
- [X] T017 [P] Modify `_applyProgressiveIncrement` in `lib/src/widget/swipe_action_cell.dart`: when `_activeZoneAtRelease != null` and forward zones are configured, use `_activeZoneAtRelease!.stepValue!` as the step (pass to `computeNextProgressiveValue` or apply inline); fire `_activeZoneAtRelease!.hapticPattern` via `_fireZoneHaptic` (or fall back to `config.enableHaptic`); clear `_activeZoneAtRelease = null` — run T016 tests; all must pass
- [X] T018 [P] Write and run regression tests confirming `RightSwipeConfig` without zones (plain `stepValue: 1.0`) behaves identically to pre-F009 behavior, covering increment, overflow, onSwipeCompleted in `test/widget/swipe_action_cell_zones_test.dart`

**Checkpoint**: Right-swipe multi-zone progressive behavior fully functional and independently testable.

---

## Phase 5: User Story 3 — Visual Zone Feedback (Priority: P1)

**Goal**: End users see smooth background transitions when dragging through zone boundaries. A 150ms visual click effect (scale bump) occurs at every crossing in both directions. Before the first zone threshold: no zone background (cell default visible).

**Independent Test**: Configure zones with distinct colors. Drag slowly across zone[0] threshold → background transitions to zone[0] color; click effect fires. Cross zone[1] threshold → transitions to zone[1] color; click effect fires. Retreat across zone[1] → click effect fires backward. Drag below zone[0] → cell default background visible.

- [X] T019 Write failing widget tests for `ZoneAwareBackground`: renders `SizedBox.shrink()` when ratio < zone[0].threshold; renders zone[0] color when ratio >= zone[0].threshold; renders zone[1] color when ratio >= zone[1].threshold; `_clickController` fires when zone index changes (forward); `_clickController` fires when zone index changes backward; `transitionStyle: instant` produces no duration in AnimatedSwitcher; `transitionStyle: crossfade` uses FadeTransition; `transitionStyle: slide` uses SlideTransition; reduced motion (`disableAnimations: true`) forces instant + suppresses scale bump in `test/zones/zone_background_test.dart` — tests MUST fail before T020
- [X] T020 Implement `ZoneAwareBackground` (`StatefulWidget` with `TickerProviderStateMixin`) in `lib/src/zones/zone_background.dart`: owns `_clickController` (150ms) and `_transitionController`; detects zone crossings in `didUpdateWidget` by comparing `resolveActiveZoneIndex` against `_previousZoneIndex`; fires `_clickController.forward(from: 0)` on any crossing; renders pre-first-zone as transparent; renders active zone background (color → ColoredBox, icon+label → Column, or custom `background` builder); wraps in `AnimatedSwitcher` for crossfade/slide styles; respects `MediaQuery.disableAnimations` with dartdoc on all public members — run T019 tests; all must pass
- [X] T021 Modify `_buildBackground` in `lib/src/widget/swipe_action_cell.dart`: when `_effectiveForwardZones()` / `_effectiveBackwardZones()` returns a non-empty list for the current drag direction, return `ZoneAwareBackground(zones: zones, progress: progress, transitionStyle: config.zoneTransitionStyle)` instead of the `SwipeVisualConfig` builder; import `lib/src/zones/zone_background.dart` — run T019–T020 tests plus existing visual tests; all must pass

**Checkpoint**: Zone visual transitions and click effects fully functional across all transition styles and reduced-motion mode.

---

## Phase 6: User Story 4 — Haptic Feedback at Zone Boundaries (Priority: P2)

**Goal**: Each forward zone-boundary crossing fires the zone's configured `SwipeZoneHaptic` pattern exactly once. Re-crossing after retreating fires again. Backward crossings do not fire haptic. Zones with `hapticPattern: null` produce no haptic.

**Independent Test**: Configure two zones with `hapticPattern: light` and `hapticPattern: heavy`. Drag forward across zone[0] → light haptic fires. Cross zone[1] → heavy haptic fires. Retreat past zone[1] → no haptic. Re-cross zone[1] forward → heavy haptic fires again.

- [X] T022 Write failing widget tests for zone haptic: crossing zone[0] forward fires `light` haptic via `HapticFeedback.lightImpact`; crossing zone[1] forward fires `medium` haptic; retreating from zone[1] to zone[0] fires no haptic; re-crossing zone[0] forward after retreat fires haptic again; zone with `hapticPattern: null` fires no haptic at that boundary; gated on `_state == SwipeState.dragging` (no haptic during snap-back) in `test/widget/swipe_action_cell_zones_test.dart` — tests MUST fail before T023
- [X] T023 Add zone haptic detection inside the `AnimatedBuilder` builder in `lib/src/widget/swipe_action_cell.dart`: gated on `_state == SwipeState.dragging`; compute `newZoneIndex` via `resolveActiveZoneIndex`; when `newZoneIndex > _lastHapticZoneIndex && newZoneIndex >= 0`, call `_fireZoneHaptic(zones[newZoneIndex].hapticPattern)`; update `_lastHapticZoneIndex = newZoneIndex`; existing single-threshold `_hapticThresholdFired` path remains unchanged for non-zone configs — run T022 tests; all must pass
- [X] T024 [P] Write and run regression tests confirming `enableHaptic: true` single-threshold (no zones) still fires `HapticFeedback.lightImpact` at activation threshold as before in `test/widget/swipe_action_cell_zones_test.dart`

**Checkpoint**: Haptic zone feedback fully functional with correct forward-only firing and re-fire-after-retreat behavior.

---

## Phase 7: User Story 5 — Backward Compatibility (Priority: P1)

**Goal**: All existing single-threshold configurations from F003/F004 compile and behave identically after F009 is introduced. No migration required.

**Independent Test**: Build a cell with existing `LeftSwipeConfig(mode: autoTrigger, onActionTriggered: fn)` and `RightSwipeConfig(stepValue: 1.0)` without `zones`. Verify all existing test scenarios still pass with zero code changes.

- [X] T025 Write backward-compatibility regression tests covering: right-swipe with plain `stepValue: 1.0` increments correctly; left-swipe `autoTrigger` fires `onActionTriggered`; left-swipe `reveal` mode opens panel; `requireConfirmation: true` flow unchanged; `SwipeVisualConfig.rightBackground` / `.leftBackground` builders render when no zones configured; `enableHaptic: true` single-threshold fires haptic in `test/widget/swipe_action_cell_zones_test.dart` — all tests MUST pass without any zone configuration present
- [X] T026 [P] Verify that existing test suites pass unmodified: run `flutter test test/widget/swipe_action_cell_progressive_test.dart test/widget/swipe_action_cell_intentional_test.dart test/config/right_swipe_config_test.dart test/config/left_swipe_config_test.dart` and confirm zero failures

**Checkpoint**: Full backward compatibility confirmed — existing consumers need zero migration.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Accessibility announcements, barrel export, static analysis, and format verification.

- [X] T027 Write failing tests for zone semantic label announcement: dragging into zone[0] announces `zone[0].semanticLabel` via `SemanticsService`; dragging into zone[1] announces `zone[1].semanticLabel`; retreating to zone[0] re-announces zone[0]; retreating below all zones makes no announcement in `test/widget/swipe_action_cell_zones_test.dart`
- [X] T028 Add zone semantic tracking to `SwipeActionCellState` in `lib/src/widget/swipe_action_cell.dart`: compute `newZoneIndex` in `AnimatedBuilder`; when `newZoneIndex != _currentZoneIndex`, update `_currentZoneIndex = newZoneIndex` and call `SemanticsService.announce(zones[newZoneIndex].semanticLabel, textDirection)` when `newZoneIndex >= 0` — run T027 tests; all must pass
- [X] T029 [P] Export new public types from `lib/swipe_action_cell.dart`: add `export 'src/core/swipe_zone.dart'` and `export 'src/zones/zone_background.dart'`; verify all three types (`SwipeZone`, `ZoneTransitionStyle`, `SwipeZoneHaptic`, `ZoneAwareBackground`) are accessible via `package:swipe_action_cell/swipe_action_cell.dart`
- [X] T030 Run `flutter analyze` in repository root and fix all warnings or errors introduced by F009 (zero-warning policy — Constitution Dev Standards)
- [X] T031 [P] Run `dart format --set-exit-if-changed .` in repository root; apply any formatting corrections to all new and modified Dart files
- [X] T032 Run `flutter test` (full suite) and confirm all tests pass with zero failures; verify count of new F009 tests matches plan expectations (≥ 40 test cases across 4 new test files)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Phase 1 (Setup)**: No dependencies — start immediately
- **Phase 2 (Foundational)**: Depends on Phase 1 — **BLOCKS all user story phases**
- **Phase 3 (US1 Intentional)**: Depends on Phase 2 completion
- **Phase 4 (US2 Progressive)**: Depends on Phase 2 completion — **can run in parallel with Phase 3**
- **Phase 5 (US3 Visual)**: Depends on Phase 2, 3, and 4 completion (needs config zones field to test background routing)
- **Phase 6 (US4 Haptic)**: Depends on Phase 2 completion (only needs widget fields from T007)
- **Phase 7 (US5 Backward Compat)**: Depends on Phase 3 and 4 completion
- **Phase 8 (Polish)**: Depends on all story phases completing

### User Story Dependencies

- **US1 (P1)**: Requires Phase 2 complete. No dependency on US2.
- **US2 (P1)**: Requires Phase 2 complete. No dependency on US1. **Can run in parallel with US1.**
- **US3 (P1)**: Requires US1 and US2 complete (needs zone fields on both configs to route background).
- **US4 (P2)**: Requires Phase 2 complete (T007 fields). Independent of US1/US2.
- **US5 (P1)**: Requires US1 and US2 complete (validates both directions).

### Within Each User Story (Mandatory Order)

1. **Write failing tests** (assert they fail before implementation — Constitution VII)
2. **Implement** to make tests pass
3. **Write regression tests** confirming backward compatibility
4. **Checkpoint** — validate story is independently functional

### Parallel Opportunities

- T001 and T002 can run in parallel (different targets)
- T003–T006 are sequential within Foundational (each test file precedes its implementation)
- T007 and T008 can start after T006 completes
- **Phases 3 and 4 can run simultaneously** on different machines / developers (different config files, different widget method paths)
- T013, T018 regression tasks are [P] — can be written alongside the prior implementation task
- T024, T026, T029, T031 are [P] within their phases

---

## Parallel Example: Phases 3 & 4 (US1 + US2)

Once Phase 2 is complete, a team of two can work simultaneously:

```
Developer A (US1 — Intentional / Left):    Developer B (US2 — Progressive / Right):
  T009 LeftSwipeConfig tests                 T014 RightSwipeConfig tests
  T010 LeftSwipeConfig implementation        T015 RightSwipeConfig implementation
  T011 Widget intentional zone tests         T016 Widget progressive zone tests
  T012 _applyIntentionalAction               T017 _applyProgressiveIncrement
  T013 Regression tests                      T018 Regression tests
```

Merge after both checkpoints, then proceed to Phase 5 together.

---

## Implementation Strategy

### MVP First (Deliver US1 + US2 Core)

1. Complete Phase 1 (Setup) + Phase 2 (Foundational)
2. Complete Phase 3 (US1) and Phase 4 (US2) — both P1
3. **STOP and VALIDATE**: Multi-zone actions fire correctly; backward compat confirmed (Phase 7)
4. This is a shippable increment: zone-based action dispatch with all assertions

### Incremental Delivery

1. Setup + Foundational → types and resolver exist ✅
2. US1 + US2 → zone actions dispatch correctly ✅ (MVP)
3. US3 → zones look right as you drag ✅
4. US4 → zones feel right as you drag ✅
5. Polish → clean, analyzed, formatted, fully documented ✅

### TDD Red-Green-Refactor Cycle (per Constitution VII)

For each task pair (T0XX test → T0(XX+1) impl):
1. Write test → run → confirm RED
2. Implement → run → confirm GREEN
3. Refactor if needed → confirm still GREEN
4. Commit the passing cluster before moving to next

---

## Notes

- `[P]` = different files or no blocking dependency on incomplete tasks in the same phase
- `[USn]` = maps to user story n from spec.md for traceability
- Constitution VII is NON-NEGOTIABLE: every test task MUST be run and confirmed failing before its paired implementation task begins
- `assertZonesValid` is called from config constructors — assertion errors appear at widget construction time, not at drag time
- `_activeZoneAtRelease` is set in `_handleDragEnd` and consumed (and cleared) in `_applyProgressiveIncrement` / `_applyIntentionalAction`; these all run on the main isolate with no concurrency concern
- The 150ms click animation (`ZoneAwareBackground._clickController`) is owned by the background widget, not the cell widget — this keeps parent widget's AnimatedBuilder lean
- All new public members (`SwipeZone`, `ZoneTransitionStyle`, `SwipeZoneHaptic`, `ZoneAwareBackground`, new fields on configs) require `///` dartdoc — `public_member_api_docs` lint rule is enforced

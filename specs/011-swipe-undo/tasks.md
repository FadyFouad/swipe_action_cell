# Tasks: Swipe Action Undo/Revert Support (F011)

**Input**: Design documents from `specs/011-swipe-undo/`
**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md ✅ | contracts/public-api.md ✅ | quickstart.md ✅

**Tests**: Included — Constitution VII (Test-First) is NON-NEGOTIABLE. Write tests first; verify they FAIL before each implementation step.

**Organization**: Grouped by user story to enable independent implementation and delivery of each story increment.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies on incomplete tasks in same batch)
- **[Story]**: Which user story this task belongs to (US1–US4 from spec.md)
- Exact file paths in all task descriptions

---

## Phase 1: Setup

**Purpose**: Initialize the new `undo/` source and test directories.

- [x] T001 Create `test/undo/` directory (add `.gitkeep` placeholder so directory is tracked by git)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data types, the undo spring preset, and the controller bridge interface. ALL user stories depend on these; no story work begins until this phase is complete.

**⚠️ CRITICAL**: No user story work can begin until this phase is complete.

> **TDD**: Write T002–T003 (tests) first, confirm they FAIL, then implement T004–T007.

- [x] T002 [P] Write failing tests for `SwipeUndoConfig`, `SwipeUndoOverlayConfig`, and `SwipeUndoOverlayPosition` in `test/undo/swipe_undo_config_test.dart` — cover: const construction, `copyWith` preserves unchanged fields, `==`/`hashCode`, debug assert fires when `duration <= Duration.zero`, debug assert fires when `progressBarHeight < 0`
- [x] T003 [P] Write failing tests for `UndoData` in `test/undo/undo_data_test.dart` — cover: immutability, `oldValue`/`newValue` are `null` for intentional-action snapshots, `revert` VoidCallback field accessible
- [x] T004 Create `lib/src/undo/swipe_undo_config.dart` containing: `SwipeUndoOverlayPosition` enum (`top`, `bottom`); `SwipeUndoOverlayConfig` const-immutable class (fields: `position`, `backgroundColor`, `textColor`, `buttonColor`, `progressBarColor`, `progressBarHeight` default 3.0, `textStyle`, `undoButtonLabel` default `'Undo'`, `actionLabel`; debug assert `progressBarHeight >= 0`; `copyWith`, `==`, `hashCode`); `SwipeUndoConfig` const-immutable class (fields: `duration` default `Duration(seconds: 5)`, `showBuiltInOverlay` default `true`, `overlayConfig`, `onUndoAvailable`, `onUndoTriggered`, `onUndoExpired`; debug assert `duration > Duration.zero`; `copyWith`, `==`, `hashCode`); full `///` dartdoc on all public members
- [x] T005 [P] Create `lib/src/undo/undo_data.dart` containing `UndoData` immutable class (fields: `oldValue: double?`, `newValue: double?`, `remainingDuration: Duration`, `revert: VoidCallback`); dartdoc noting `oldValue`/`newValue` are `null` for intentional actions
- [x] T006 [P] Add `static const SpringConfig undoReveal = SpringConfig(mass: 1.0, stiffness: 300.0, damping: 18.0)` to `lib/src/animation/spring_config.dart` with dartdoc explaining underdamped intent (damping ratio ≈ 0.52, slight bounce, perceptually distinct from snapBack and completion springs)
- [x] T007 [P] Add two abstract methods to `lib/src/controller/swipe_cell_handle.dart`: `void executeUndo()` (called by `SwipeController.undo()`) and `void executeCommitUndo()` (called by `SwipeController.commitPendingUndo()`); full dartdoc on both

**Checkpoint**: Run `flutter test test/undo/` — T002/T003 tests still FAIL (implementations pending). That is expected and correct.

---

## Phase 3: User Story 1 — Reverting a Progressive Action (Priority: P1) 🎯 MVP

**Goal**: After a right-swipe increment, an undo window opens. The built-in overlay appears with a shrinking progress bar and "Undo" button. Tapping "Undo" reverts the value to its pre-increment state and animates the indicator backward.

**Independent Test**: Trigger a right-swipe with `undoConfig` set, verify the overlay appears, tap "Undo", confirm `onUndoTriggered` fires and the progressive value returns to its previous state.

> **TDD**: Write T008–T010 (tests) first, confirm they FAIL, then implement T011–T015.

### Tests for User Story 1

- [x] T008 [P] [US1] Write failing `SwipeController` undo unit tests in `test/controller/swipe_controller_undo_test.dart` — cover: `undo()` returns `false` when `isUndoPending` is `false` (no cell attached); `undo()` returns `false` when cell attached but no pending undo; `isUndoPending` reflects `reportUndoPending()` calls and notifies listeners; `undo()` and `commitPendingUndo()` are graceful no-ops after `dispose()`; `reportUndoPending()` skips notification when value unchanged
- [x] T009 [P] [US1] Write failing `SwipeUndoOverlay` widget tests in `test/undo/swipe_undo_overlay_test.dart` — cover: renders `undoButtonLabel` text; renders `actionLabel` when set; progress bar width is proportional to animation value (pump to 0.5, verify `FractionallySizedBox.widthFactor`); "Undo" button tap fires `onUndo`; `Semantics` button label matches `semanticUndoLabel`; `Semantics(liveRegion: true)` is present on the container; when `position == top`, bar renders above the button row
- [x] T010 [P] [US1] Write failing progressive-undo widget tests in `test/widget/swipe_action_cell_undo_test.dart` — cover: overlay appears after right-swipe with `undoConfig` set (showBuiltInOverlay: true); `onUndoAvailable` fires with non-null `oldValue`/`newValue`; tapping "Undo" button calls `onUndoTriggered`; overlay disappears after tap; controller `isUndoPending` is `true` during window and `false` after; `controller.undo()` returns `true` during window and `false` outside; `undoConfig: null` → no overlay rendered, no timer allocated (use addTearDown leak tracking)

### Implementation for User Story 1

- [x] T011 [US1] Add undo API to `lib/src/controller/swipe_controller.dart`: private field `bool _isUndoPending = false`; getter `bool get isUndoPending`; method `bool undo()` (if `!_isUndoPending || _handle == null` return `false`; else `_handle!.executeUndo(); return true`); method `void commitPendingUndo()` (no-op if not pending or no handle; else `_handle!.executeCommitUndo()`); package-internal method `void reportUndoPending(bool isPending)` (guard disposed + unchanged; set field; notifyListeners); full dartdoc on all new members
- [x] T012 [P] [US1] Create `lib/src/undo/swipe_undo_overlay.dart` (internal — NOT exported from barrel): `SwipeUndoOverlay` StatelessWidget with fields `config: SwipeUndoOverlayConfig`, `progressAnimation: Animation<double>`, `onUndo: VoidCallback`, `semanticUndoLabel: String`; layout: `Stack` or `Column` with a `Row` (actionLabel text + TextButton labeled `config.undoButtonLabel`) and an `AnimatedBuilder`-driven `FractionallySizedBox(widthFactor: animation.value)` progress bar; row-above-bar order when `position == top`, bar-below-row when `position == bottom`; wrap button in `Semantics(button: true, label: semanticUndoLabel)`; wrap entire widget in `Semantics(liveRegion: true)`; colors fall through to `Theme.of(context)` when config fields are null; add package-internal dartdoc
- [x] T013 [US1] Add `undoConfig` parameter to `SwipeActionCell` in `lib/src/widget/swipe_action_cell.dart`: add `final SwipeUndoConfig? undoConfig` field with dartdoc; add internal state fields to `SwipeActionCellState`: `bool _undoPending = false`, `double? _undoOldValue`, `double? _undoNewValue`, `PostActionBehavior? _lastPostActionBehavior`, `Timer? _undoTimer`, `AnimationController? _undoBarController`
- [x] T014 [US1] Add undo lifecycle and core methods to `SwipeActionCellState` in `lib/src/widget/swipe_action_cell.dart`: in `initState()` create `_undoBarController` (vsync: this, value: 1.0, duration: widget.undoConfig?.duration) when `undoConfig != null`; in `dispose()` call `_undoTimer?.cancel()` and `_undoBarController?.dispose()` before `super.dispose()`; implement `_startUndoWindow()` (cancel existing timer/bar, reset bar to 1.0, setState _undoPending = true, reportUndoPending, build UndoData with revert closure, fire onUndoAvailable, start bar reverse only if `!MediaQuery.of(context).disableAnimations`, start Timer(duration, _commitUndo)); implement `_triggerUndo()` (guard if !_undoPending return, cancel timer/bar, setState _undoPending = false, reportUndoPending false, fire onUndoTriggered); implement `_commitUndo()` (guard if !_undoPending return, cancel timer/bar, setState _undoPending = false, reportUndoPending false, fire onUndoExpired); implement `executeUndo()` calling `_triggerUndo()` and `executeCommitUndo()` calling `_commitUndo()` on the State (satisfying SwipeCellHandle interface)
- [x] T015 [US1] Wire progressive undo and overlay into `SwipeActionCellState` in `lib/src/widget/swipe_action_cell.dart`: in `_applyProgressiveIncrement()` capture `_undoOldValue = _currentProgressValue` before increment and `_undoNewValue = _currentProgressValue` after; call `_startUndoWindow()` when `undoConfig != null`; in `build()` add `SwipeUndoOverlay` as a `Positioned` child in the existing `Stack` when `undoConfig != null && undoConfig!.showBuiltInOverlay && _undoPending && _undoBarController != null`, anchored per `overlayConfig?.position ?? SwipeUndoOverlayPosition.bottom`, passing `progressAnimation: _undoBarController!`, `onUndo: _triggerUndo`, `semanticUndoLabel: overlayConfig?.undoButtonLabel ?? 'Undo'`

**Checkpoint**: Run `flutter test test/undo/ test/controller/swipe_controller_undo_test.dart test/widget/swipe_action_cell_undo_test.dart` — T008, T009, T010 US1 cases should now PASS. Overlay visible after right-swipe; "Undo" button reverts value.

---

## Phase 4: User Story 2 — Reverting an Intentional Action (Priority: P1)

**Goal**: After a left-swipe auto-trigger with `animateOut`, the cell slides off-screen and the overlay appears. Tapping "Undo" animates the cell back into view using a bouncy `undoReveal` spring. For `snapBack`/`stay` modes, `onUndoTriggered` fires with no package animation.

**Independent Test**: Trigger an intentional swipe with `postActionBehavior: animateOut` and `undoConfig` set, verify the cell exits and overlay appears, tap "Undo", confirm the cell animates back into view and reaches `idle` state.

> **TDD**: Write T016 (tests) first, confirm they FAIL, then implement T017–T018.

### Tests for User Story 2

- [x] T016 [P] [US2] Write failing intentional-undo widget tests (US2 cases) in `test/widget/swipe_action_cell_undo_test.dart` — cover: overlay appears after intentional autoTrigger action with `undoConfig` set; `onUndoAvailable` fires with `null` `oldValue`/`newValue` for intentional actions; for `animateOut`: after "Undo" tap, cell transitions through `animatingToClose` back to `idle`; for `snapBack`: `onUndoTriggered` fires, no state change beyond `idle`; for `stay`: `onUndoTriggered` fires, cell remains in current position

### Implementation for User Story 2

- [x] T017 [US2] Hook `_applyPostActionBehavior()` in `lib/src/widget/swipe_action_cell.dart`: immediately before calling `_startUndoWindow()`, set `_lastPostActionBehavior = config.postActionBehavior` and set `_undoOldValue = null; _undoNewValue = null`; call `_startUndoWindow()` when `undoConfig != null`
- [x] T018 [US2] Implement `animateOut` reversal in `_triggerUndo()` in `lib/src/widget/swipe_action_cell.dart`: after clearing `_undoPending` and before firing `onUndoTriggered`, check `if (_lastPostActionBehavior == PostActionBehavior.animateOut)` then call `_updateState(SwipeState.animatingToClose)` and `_controller.animateWith(SpringSimulation(SpringDescription(mass: SpringConfig.undoReveal.mass, stiffness: SpringConfig.undoReveal.stiffness, damping: SpringConfig.undoReveal.damping), _controller.value, 0.0, 0.0))` — the existing `_handleAnimationStatusChange` listener handles the `idle` transition when the animation settles

**Checkpoint**: Run `flutter test test/widget/swipe_action_cell_undo_test.dart` — T016 US2 cases should now PASS. Cell animates back in with visible bounce after undo of animateOut action.

---

## Phase 5: User Story 3 — Automatic Commitment on Expiry (Priority: P2)

**Goal**: When the undo window expires without user interaction, `onUndoExpired` fires, the overlay dismisses, and the action is permanently committed. Under `MediaQuery.disableAnimations`, no countdown animation is shown but the timer still fires normally.

**Independent Test**: Trigger an action with `undoConfig` set, advance fake time past `duration`, verify `onUndoExpired` fires and `isUndoPending` becomes `false`.

> **TDD**: Write T019 (tests) first, confirm they FAIL (if any timer paths not yet covered), then the implementation is already complete in T014.

### Tests for User Story 3

- [x] T019 [P] [US3] Write timer expiry and `reduceMotion` widget tests (US3 cases) in `test/widget/swipe_action_cell_undo_test.dart` — cover: after triggering action, fake-advance time by `undoConfig.duration`, verify `onUndoExpired` fires and `_undoPending` becomes false; overlay disappears on expiry; under `MediaQuery(disableAnimations: true)`, overlay is NOT shown (`SwipeUndoOverlay` not in widget tree) but `onUndoExpired` still fires after duration; widget dispose while `_undoPending`: timer is cancelled, no callbacks fire post-dispose (use `addTearDown` leak assertion)

**Checkpoint**: Run `flutter test test/widget/swipe_action_cell_undo_test.dart` — all US3 cases pass. Expiry commits action; dispose cancels timer cleanly.

---

## Phase 6: User Story 4 — Interrupted Undo Window (Priority: P3)

**Goal**: When a new swipe action begins while a previous undo window is open, the first action commits immediately (firing `onUndoExpired`), and the new action's undo window opens.

**Independent Test**: Trigger Action A, wait 1 s, trigger Action B. Verify `onUndoExpired` fires for Action A immediately and a new `onUndoAvailable` fires for Action B.

> **TDD**: Write T020 (tests) first, confirm they FAIL, then implement T021.

### Tests for User Story 4

- [x] T020 [P] [US4] Write failing interrupted-undo-window tests (US4 cases) in `test/widget/swipe_action_cell_undo_test.dart` — cover: trigger Action A (undo window opens), trigger Action B before expiry, verify `onUndoExpired` fires for Action A immediately followed by `onUndoAvailable` for Action B; `isUndoPending` remains `true` during Action B window; rapid sequential triggers do not produce multiple orphaned timers (use fake async + addTearDown)

### Implementation for User Story 4

- [x] T021 [US4] Add `_undoPending` interrupt guard to `_handleDragStart` in `lib/src/widget/swipe_action_cell.dart`: at the very top of `_handleDragStart`, add `if (_undoPending) _commitUndo();` before any other gesture processing — this force-commits the prior action and clears state before the new gesture is handled

**Checkpoint**: Run `flutter test test/widget/swipe_action_cell_undo_test.dart` — all US4 cases pass. New gesture correctly commits prior undo and opens a fresh window.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Barrel exports, regression verification, format/lint compliance.

- [x] T022 Add exports to `lib/swipe_action_cell.dart`: `export 'src/undo/swipe_undo_config.dart';` and `export 'src/undo/undo_data.dart';` — confirm `swipe_undo_overlay.dart` is NOT exported (it is internal)
- [x] T023 Run full regression suite `flutter test` from repository root and confirm zero failures across all F001–F010 test files; pay particular attention to `test/widget/swipe_action_cell_progressive_test.dart`, `test/widget/swipe_action_cell_intentional_test.dart`, `test/controller/`
- [x] T024 Run `flutter analyze` and `dart format --set-exit-if-changed .` from repository root; resolve any warnings or formatting issues introduced by F011 changes

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately
- **Foundation (Phase 2)**: Depends on Phase 1 — BLOCKS all user stories
- **US1 (Phase 3)**: Depends on Phase 2 — can start after Foundation
- **US2 (Phase 4)**: Depends on Phase 3 — requires `_startUndoWindow` + `_triggerUndo` from T014
- **US3 (Phase 5)**: Depends on Phase 3 — timer expiry is part of T014
- **US4 (Phase 6)**: Depends on Phase 3 — gesture guard built on `_commitUndo` from T014
- **Polish (Phase 7)**: Depends on Phases 3–6 all complete

### User Story Dependencies

- **US1 (P1)**: Depends on Foundation only — no cross-story dependencies
- **US2 (P1)**: Depends on US1 — reuses `_startUndoWindow`, `_triggerUndo`, overlay from T013–T015
- **US3 (P2)**: Depends on US1 — timer mechanism is part of `_startUndoWindow` (T014)
- **US4 (P3)**: Depends on US1 — gesture guard calls `_commitUndo` from T014

### Within Each Phase

- Test tasks marked [P] can run in parallel (different test files, no shared state)
- Implementation tasks in `swipe_action_cell.dart` (T013–T015, T017–T018, T021) must run sequentially — same file
- `SwipeController` (T011) and `SwipeUndoOverlay` (T012) are different files → [P] relative to each other
- Barrel export (T022) can run after T004/T005 (types exist), but run it in Polish to avoid import issues during development

### Parallel Opportunities (within phases)

**Phase 2 (Foundation)**:
```
Parallel batch 1 (tests first):
  T002 [swipe_undo_config_test.dart]
  T003 [undo_data_test.dart]

Parallel batch 2 (implementations after tests written):
  T004 [swipe_undo_config.dart]
  T005 [undo_data.dart]
  T006 [spring_config.dart]
  T007 [swipe_cell_handle.dart]
```

**Phase 3 (US1)**:
```
Parallel batch 1 (tests first):
  T008 [swipe_controller_undo_test.dart]
  T009 [swipe_undo_overlay_test.dart]
  T010 [swipe_action_cell_undo_test.dart — US1 cases]

Parallel batch 2 (implementations after tests written):
  T011 [swipe_controller.dart]
  T012 [swipe_undo_overlay.dart]

Sequential (same file, after T011/T012 done):
  T013 → T014 → T015 [swipe_action_cell.dart]
```

---

## Implementation Strategy

### MVP (User Story 1 Only — Progressive Undo)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundation (T002–T007) — CRITICAL, blocks everything
3. Complete Phase 3: US1 (T008–T015)
4. **STOP and VALIDATE**: `flutter test test/undo/ test/controller/swipe_controller_undo_test.dart test/widget/swipe_action_cell_undo_test.dart`
5. Progressive swipe undo is fully functional and independently testable

### Incremental Delivery

1. Foundation → US1 (progressive undo) → **Demo/validate**
2. Add US2 (intentional undo with animateOut bounce) → **Demo/validate**
3. Add US3 tests (expiry verification — implementation already in place) → **Validate**
4. Add US4 (gesture interrupt) → **Validate**
5. Polish → **Ship**

### Full Parallel Strategy

With multiple developers after Foundation completes:

```
Developer A: T008 + T011 + T013 → T014 → T015 (US1 core widget integration)
Developer B: T009 + T012 (SwipeUndoOverlay widget)
Developer C: T010 (US1 widget tests against stubbed types)
```

US2, US3, US4 are sequential after US1 (same widget file) — best done by one developer.

---

## Notes

- `[P]` tasks touch different files with no in-flight dependencies — safe to parallelize
- `[Story]` label maps each task to its user story for traceability
- **TDD is mandatory** (Constitution VII): write test → run (confirm FAIL) → implement → run (confirm PASS)
- `swipe_action_cell.dart` tasks (T013–T015, T017–T018, T021) must run sequentially in order
- `undoConfig: null` path must produce zero overhead — verify with leak tracking in tests (T010)
- The `animateOut` reversal (T018) relies on the existing `_handleAnimationStatusChange` for `idle` transition — do not add extra status handling
- Commit after each checkpoint or logical task group; do not batch all changes into one commit

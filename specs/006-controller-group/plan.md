# Implementation Plan: Programmatic Control & Multi-Cell Coordination

**Branch**: `006-controller-group` | **Date**: 2026-02-27 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/006-controller-group/spec.md`

---

## Summary

Replace the F6 `SwipeController` stub with a full programmatic API and add
`SwipeGroupController` + `SwipeControllerProvider` for accordion coordination in lists.
The bridge between `SwipeController` and `SwipeActionCellState` uses a package-internal
`SwipeCellHandle` abstract class, following the `ScrollController` / `ScrollPosition`
pattern from the Flutter framework. No new states are added to the existing state machine.

---

## Technical Context

**Language/Version**: Dart ≥ 3.4.0 / Flutter ≥ 3.22.0
**Primary Dependencies**: Flutter SDK only (zero external runtime deps — Constitution IV)
**Storage**: N/A (in-memory state only; no persistence)
**Testing**: `flutter test` — unit tests for controller logic, widget tests for integration
**Target Platform**: All Flutter-supported platforms (iOS, Android, web, macOS, Windows, Linux)
**Project Type**: Flutter package (library)
**Performance Goals**: 60 fps during all drag and animation interactions — Constitution X
**Constraints**: `SwipeController` must not allocate any `AnimationController` or `Ticker` — those live in `SwipeActionCellState`
**Scale/Scope**: Designed for `ListView.builder` with hundreds of items; accordion O(N visible) per open event

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-checked post-design below.*

| Principle | Check | Notes |
|-----------|-------|-------|
| I. Composition over Inheritance | ✅ | `SwipeControllerProvider` wraps child; no base-class extension required |
| II. Explicit State Machine | ✅ | Valid transitions defined in data-model.md; invalid calls are no-ops/asserts |
| III. Spring-Based Physics | ✅ | `executeOpenLeft/Right/Close` delegate to existing spring animations in widget state |
| IV. Zero External Runtime Deps | ✅ | Only Flutter SDK |
| V. Controlled/Uncontrolled Pattern | ✅ | Controller is opt-in; widget creates internal controller when none provided |
| VI. Const-Friendly Configuration | ✅ | `SwipeControllerProvider` const constructor; no new config objects are mutable |
| VII. Test-First | ✅ | Four test files written before implementation (see tasks.md) |
| VIII. Dartdoc Everything | ✅ | All public members have `///` docs per contracts |
| IX. Null Config = Feature Disabled | ✅ | `executeOpenLeft()` is no-op when `leftSwipeConfig == null` |
| X. 60 fps Budget | ✅ | Group coordination is O(N) synchronous calls; no frame-deferred work |

**Post-design re-check**: No violations introduced by the design. `SwipeCellHandle` is
package-internal and not exported; it does not pollute the public API surface.

---

## Project Structure

### Documentation (this feature)

```text
specs/006-controller-group/
├── plan.md                    ← this file
├── research.md                ← Phase 0 output
├── data-model.md              ← Phase 1 output
├── quickstart.md              ← Phase 1 output
├── contracts/
│   └── controller-api.md     ← Phase 1 output
└── tasks.md                   ← Phase 2 output (/speckit.tasks)
```

### Source Code

```text
lib/
├── swipe_action_cell.dart                   ← add group controller + provider exports
└── src/
    ├── controller/
    │   ├── swipe_controller.dart             ← REPLACE stub with full implementation
    │   ├── swipe_cell_handle.dart            ← NEW (package-internal, not exported)
    │   ├── swipe_group_controller.dart       ← NEW
    │   └── swipe_controller_provider.dart    ← NEW
    └── widget/
        └── swipe_action_cell.dart            ← ADD handle attach/detach + group sync

test/
├── controller/
│   ├── swipe_controller_test.dart            ← EXPAND (currently 2 stub tests)
│   ├── swipe_group_controller_test.dart      ← NEW
└── widget/
    ├── swipe_action_cell_controller_test.dart ← NEW
    └── swipe_controller_provider_test.dart    ← NEW
```

---

## Complexity Tracking

No Constitution violations. No exceptional complexity justification needed.

---

## Implementation Phases

### Phase A — `SwipeController` Full API (MVP — unblocks everything)

Replaces the stub. Widget integration (`attach`/`detach`/`reportState`) is part of
this phase because the commands cannot be tested end-to-end without it.

**New files**: `lib/src/controller/swipe_cell_handle.dart`
**Modified files**: `lib/src/controller/swipe_controller.dart`, `lib/src/widget/swipe_action_cell.dart`

**Tests (write FIRST)**:
- `test/controller/swipe_controller_test.dart` — unit coverage for all commands, state properties, ChangeNotifier, lifecycle, standalone (no group)
- `test/widget/swipe_action_cell_controller_test.dart` — widget integration: attach/detach, programmatic open/close, state preserved across rebuilds, resetProgress/setProgress

### Phase B — `SwipeGroupController` (accordion, no provider)

Depends on Phase A.

**New file**: `lib/src/controller/swipe_group_controller.dart`

**Tests (write FIRST)**:
- `test/controller/swipe_group_controller_test.dart` — register/unregister, accordion behavior, closeAll, closeAllExcept, rapid register/unregister, no-op edge cases

### Phase C — `SwipeControllerProvider` (zero-boilerplate list coordination)

Depends on Phase B.

**New file**: `lib/src/controller/swipe_controller_provider.dart`
**Modified**: `lib/src/widget/swipe_action_cell.dart` (add `_syncGroupRegistration` in `didChangeDependencies`)

**Tests (write FIRST)**:
- `test/widget/swipe_controller_provider_test.dart` — auto-registration, accordion via gesture, rapid create/dispose in lazy list, explicit groupController injection, cells without controller auto-register

### Phase D — Polish & Exports

- Update `lib/swipe_action_cell.dart` barrel
- `flutter analyze` → zero warnings
- `dart format --set-exit-if-changed .`
- `flutter test` → all pass
- `flutter pub publish --dry-run` → zero issues

---

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Controller→Widget bridge | `SwipeCellHandle` abstract class | Mirrors `ScrollController`/`ScrollPosition`; clean cross-file protocol |
| Widget→Controller state sync | `reportState()` called in `_updateState()` | Widget is authoritative; controller is a projection |
| Accordion trigger | Synchronous before opening animation | No frame with two open cells (SC-002) |
| Provider structure | `StatefulWidget` + `_SwipeControllerScope InheritedWidget` | Standard Flutter pattern; StatefulWidget owns dispose lifecycle |
| Auto-registration hook | `didChangeDependencies()` | Only valid hook for InheritedWidget lookups; not `initState` |
| Internal controller | Created in `initState`; disposed in widget `dispose` | Consumer-provided controller NOT disposed by widget (consumer owns lifecycle) |
| `setProgress` out-of-range | Clamp silently | Matches `OverflowBehavior.clamp`; forgiving for externally-sourced values |
| Dart weak references | Not needed | `unregister()` in `dispose()` is reliable; `Finalizer` adds complexity for no gain |

See [research.md](research.md) for full rationale on each decision.

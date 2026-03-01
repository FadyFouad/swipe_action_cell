# Tasks: Documentation and pub.dev Release (F016)

**Input**: Design documents from `/specs/015-pubdev-release/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/deliverables.md ✅, quickstart.md ✅

**Tests**: Not applicable as standalone test tasks — this feature is documentation + configuration. Correctness is verified by `flutter analyze`, `flutter pub publish --dry-run`, and manual review of the 13 quickstart.md scenarios.

**Organization**: Tasks are grouped by user story (US1–US5). Cluster A (Phase 2, Foundational) MUST complete before any user story work begins. US1–US4 can proceed in parallel after Phase 2.

## Format: `[ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies on in-progress tasks)
- **[Story]**: Which user story this task belongs to (US1–US5)
- Exact file paths specified in each task description

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create directory scaffolding needed by all subsequent tasks.

- [ ] T001 Create `doc/assets/` directory; commit two 1×1 transparent placeholder PNG files as `doc/assets/demo-delete.gif` and `doc/assets/demo-reveal.gif` (binary placeholder images at final asset paths so README image tags resolve immediately)

**Checkpoint**: `doc/assets/demo-delete.gif` and `doc/assets/demo-reveal.gif` exist as valid binary files.

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Package metadata and version must be correct before any publication-facing content is written.

**⚠️ CRITICAL**: No user story work should begin until this phase is complete.

- [ ] T002 Change `version: 0.1.0-beta.1` to `version: 1.0.0` in `pubspec.yaml` (description is already 123 chars — within 60–180 limit; all URLs already present)
- [ ] T003 Prepend a new `## [1.0.0] - 2026-03-01` entry at the top of `CHANGELOG.md` with `### Added` section listing all 15 features (F001–F015) per keepachangelog.com format; preserve existing 0.1.0-beta.1 and 0.0.1 entries below

**Checkpoint**: `pubspec.yaml` shows `version: 1.0.0`; `CHANGELOG.md` has the 1.0.0 entry as its first section with 15 `### Added` bullets.

---

## Phase 3: User Story 1 — Package Discovery and Quick Start (Priority: P1) 🎯 MVP

**Goal**: Deliver a complete, publish-ready `README.md` that gives a developer everything they need to evaluate, install, and get a working swipe cell in 5 minutes.

**Independent Test**: Open `README.md` in a markdown renderer. The first visible screen shows a tagline + at least one image + at least one key capability. Copy the Quick Start code into a blank Flutter app — it compiles and renders a delete cell with no modifications.

### Implementation for User Story 1

- [ ] T004 [US1] Rewrite the top of `README.md` with: pub.dev version badge + MIT license badge, 1–2 sentence hero tagline (mentions asymmetric swipe semantics), two `![...]` image tags pointing to `https://raw.githubusercontent.com/FadyFouad/swipe_action_cell/main/doc/assets/demo-delete.gif` and `demo-reveal.gif`, and an 8-bullet Features list
- [ ] T005 [US1] Add `## Quick Start` section to `README.md` with a compilable 3–5 line `SwipeActionCell.delete(...)` code sample; add `## Installation` section with `flutter pub add swipe_action_cell` command
- [ ] T006 [US1] Add `## Platform Support` table (6 rows: iOS ✅, Android ✅, Web ✅, macOS ✅, Windows ✅, Linux ✅; note minimum Flutter ≥ 3.22.0) and `## Configuration Reference` table covering at minimum `child`, `leftSwipeConfig`, `rightSwipeConfig`, `controller`, `visualConfig` to `README.md`
- [ ] T007 [US1] Add `## swipe_action_cell vs flutter_slidable` comparison table (≥ 5 rows covering: symmetric vs asymmetric swipe, built-in undo, spring physics, prebuilt templates, consumer testing utilities) and `## Documentation & Links` section with pub.dev API reference and GitHub example app links to `README.md`; remove all "beta" or "WIP" language from the file

**Checkpoint**: `README.md` has no "under development" language; all 9 required sections present; both image tags resolve; Quick Start code compiles in a blank Flutter app.

---

## Phase 4: User Story 2 — Interactive Example App Exploration (Priority: P1)

**Goal**: Deliver an 8-screen example app with scrollable `TabBar` navigation that runs without any configuration, API keys, or network access.

**Independent Test**: `cd example/ && flutter pub get && flutter run` — app launches, all 8 tabs visible in the tab bar, every screen responds to gestures. `flutter analyze example/` reports zero issues.

### Implementation for User Story 2

- [ ] T008 [US2] Update `example/lib/main.dart` to use `DefaultTabController(length: 8)` with `TabBar(isScrollable: true)` containing 8 named tabs (Basic, Counter, Reveal, Multi-Zone, Custom, List, RTL, Templates) and a `TabBarView` referencing the 8 screen widgets; create `example/lib/screens/` directory with 8 stub screen files (each a minimal `StatelessWidget` returning a `Center(child: Text('...'))`): `basic_screen.dart`, `counter_screen.dart`, `reveal_actions_screen.dart`, `multi_threshold_screen.dart`, `custom_visuals_screen.dart`, `list_demo_screen.dart`, `rtl_screen.dart`, `templates_screen.dart`
- [ ] T009 [P] [US2] Implement `example/lib/screens/basic_screen.dart` — a single `SwipeActionCell` with `leftSwipeConfig: LeftSwipeConfig(mode: LeftSwipeMode.autoTrigger, ...)` and `rightSwipeConfig: RightSwipeConfig(...)` displaying a visible state change; include `///` comments explaining each config parameter
- [ ] T010 [P] [US2] Implement `example/lib/screens/counter_screen.dart` — a `StatefulWidget` where right-swipe increments a visible integer counter; use `rightBackground` with `LinearProgressIndicator` tied to swipe ratio; comments explain `onSwipeCompleted` callback
- [ ] T011 [P] [US2] Implement `example/lib/screens/reveal_actions_screen.dart` — `LeftSwipeConfig(mode: LeftSwipeMode.reveal, actions: [SwipeAction(icon: Icons.archive, ...), SwipeAction(icon: Icons.delete, ...)])` on a single cell; tapping each action shows a `SnackBar`; comments explain reveal mode vs autoTrigger
- [ ] T012 [P] [US2] Implement `example/lib/screens/multi_threshold_screen.dart` — a cell demonstrating ≥ 2 distinct threshold levels via `RightSwipeConfig` with different visual feedback (color/icon change) at each threshold; comments explain the threshold configuration
- [ ] T013 [P] [US2] Implement `example/lib/screens/custom_visuals_screen.dart` — a cell using `SwipeMorphIcon` in the `rightBackground` builder (morphing between two icons based on swipe ratio) and `SwipeVisualConfig` with custom `borderRadius`; comments explain the painter/visual config options
- [ ] T014 [P] [US2] Implement `example/lib/screens/list_demo_screen.dart` — `ListView.builder` with 50 items; create one `SwipeController` per item via `SwipeGroupController`; use `SwipeActionCell.delete(controller: ..., onDeleted: () => setState(...))` so opening one row closes others (accordion); show undo strip on delete; comments explain `SwipeGroupController` wiring
- [ ] T015 [P] [US2] Implement `example/lib/screens/rtl_screen.dart` — wrap a `ListView` of 5 items in `Directionality(textDirection: TextDirection.rtl)`; use Arabic text labels; left-swipe (physical) triggers the right semantic action; comments explain RTL direction reversal
- [ ] T016 [US2] Implement `example/lib/screens/templates_screen.dart` — a `ListView` of 6 `ListTile`s each wrapped with a different factory template (`SwipeActionCell.delete`, `.archive`, `.favorite`, `.checkbox`, `.counter`, `.standard`); each row has a subtitle label naming its template; comments reference which factory constructor is used

**Checkpoint**: `flutter run` from `example/` launches with all 8 tabs; `flutter analyze example/` → zero issues; every screen responds to gestures; no network calls or API keys.

---

## Phase 5: User Story 3 — Complete API Reference (Priority: P2)

**Goal**: `flutter analyze lib/` with `public_member_api_docs: true` reports zero violations; every primary-workflow class has at least one dartdoc code example.

**Independent Test**: `flutter analyze lib/ --fatal-warnings` exits with code 0. Hover over `SwipeState.revealed`, `SwipeController.openLeft`, and `SwipeTester.swipeLeft` in an IDE — each shows a non-empty tooltip.

### Implementation for User Story 3

- [ ] T017 [US3] Run `flutter analyze lib/` and capture the full list of `Missing documentation for a public member` violations; create a scratch list of all affected symbols to guide T018–T021
- [ ] T018 [P] [US3] Fix all dartdoc violations in `lib/src/core/` — add missing `///` comments to every `SwipeState`, `SwipeDirection`, and `SwipeProgress` enum value, and any undocumented getters on `SwipeProgress`
- [ ] T019 [P] [US3] Fix all dartdoc violations in `lib/src/config/` — add missing `///` comments to every named parameter of `LeftSwipeConfig.copyWith`, `RightSwipeConfig.copyWith`, `SwipeVisualConfig.copyWith`, and `SwipeUndoConfig.copyWith`; document any undocumented fields
- [ ] T020 [P] [US3] Fix all dartdoc violations in `lib/src/controller/swipe_group_controller.dart` and `lib/src/templates/` — document all undocumented public members and every named parameter of the 6 factory constructors (`SwipeActionCell.delete`, `.archive`, `.favorite`, `.checkbox`, `.counter`, `.standard`)
- [ ] T021 [P] [US3] Fix all dartdoc violations in `lib/src/testing/` (`SwipeTester` static methods, `SwipeAssertions` extension methods, `MockSwipeController` getters); verify `lib/testing.dart` has a non-empty library-level `///` doc comment
- [ ] T022 [US3] Add a dartdoc `///` code fence example to `SwipeActionCell` class (main constructor usage) and each of the 6 factory constructors in `lib/src/widget/swipe_action_cell.dart`; add a code example to `SwipeController` in `lib/src/controller/swipe_controller.dart`
- [ ] T023 [P] [US3] Add a dartdoc code example to `SwipeGroupController` in `lib/src/controller/swipe_group_controller.dart` and to `LeftSwipeConfig` in `lib/src/config/left_swipe_config.dart`
- [ ] T024 [P] [US3] Add a dartdoc code example to `RightSwipeConfig` in `lib/src/config/right_swipe_config.dart`; add code examples to `SwipeTestHarness` in `lib/src/testing/swipe_test_harness.dart` and `MockSwipeController` in `lib/src/testing/mock_swipe_controller.dart`

**Checkpoint**: `flutter analyze lib/ --fatal-warnings` exits with code 0 and zero `Missing documentation` warnings.

---

## Phase 6: User Story 4 — Migration from flutter_slidable (Priority: P2)

**Goal**: Deliver `MIGRATION.md` with an API mapping table, behavioral differences, two before/after code examples, and explicit "not available" sections for both packages.

**Independent Test**: Take the `flutter_slidable` "before" code in Example 1. Read only `MIGRATION.md`. Produce working `swipe_action_cell` code. Paste the "after" code into the example app — `flutter analyze example/` shows zero issues.

### Implementation for User Story 4

- [ ] T025 [P] [US4] Create `MIGRATION.md` at repository root with: `# Migrating from flutter_slidable to swipe_action_cell` heading, 2-paragraph Overview, Installation before/after pubspec snippets, and 7-row API Mapping table (`Slidable` → `SwipeActionCell`, `SlidableAction` → `SwipeAction`, `ActionPane(endActionPane)` → `LeftSwipeConfig`, `ActionPane(startActionPane)` → `RightSwipeConfig`, `SlidableController` → `SwipeController`, `SlidableAutoCloseBehavior` → `SwipeGroupController`, `DismissiblePane` → `LeftSwipeConfig(mode: autoTrigger)`)
- [ ] T026 [US4] Add `## Behavioral Differences` section (≥ 5 bullets: symmetric vs asymmetric, undo support, spring physics, group controller pattern, testing utilities) and `## Code Examples — Example 1: Basic Reveal Action` with compilable before (flutter_slidable) and after (swipe_action_cell) code blocks to `MIGRATION.md`
- [ ] T027 [US4] Add `## Code Examples — Example 2: Delete with Undo` with compilable before (`DismissiblePane`) and after (`SwipeActionCell.delete`) code blocks; add `## Features not in swipe_action_cell` (motion types, per-action extentRatio, action-level autoClose) and `## Features not in flutter_slidable` (progressive right-swipe, built-in undo, spring physics, prebuilt templates, testing utilities) sections to `MIGRATION.md`

**Checkpoint**: `MIGRATION.md` exists with all 7 required sections; "after" code blocks compile under `flutter analyze example/` when pasted into a screen file.

---

## Phase 7: User Story 5 — Package Publishing Readiness (Priority: P3)

**Goal**: `flutter pub publish --dry-run` exits with zero errors and zero warnings; `flutter analyze lib/ example/lib/` reports zero issues; `dart format` reports no changes needed.

**Independent Test**: Run `flutter pub publish --dry-run` on a clean checkout — exit code 0, no ERROR/WARNING lines.

### Implementation for User Story 5

- [ ] T028 [US5] Run `flutter analyze lib/ example/lib/` — fix any remaining warnings or errors not addressed in earlier phases; then run `dart format --set-exit-if-changed .` — fix any formatting issues across the full codebase (lib/, test/, example/lib/)
- [ ] T029 [US5] Run `flutter pub publish --dry-run`; if any errors or warnings appear, diagnose and fix the root cause (common issues: missing license header, undocumented public member, formatting error, invalid pubspec field); re-run until exit code is 0 with no warnings

**Checkpoint**: `flutter pub publish --dry-run` exits cleanly. `flutter analyze lib/ example/lib/` → zero issues. `dart format --set-exit-if-changed .` → no changes needed.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Final sanity check across all deliverables.

- [ ] T030 Verify quickstart.md scenarios 1–13 are satisfied: check README renders correctly (Scenario 2), example app launches with all 8 tabs (Scenario 3), dartdoc zero warnings (Scenario 8), MIGRATION.md "after" code compiles (Scenario 9), publish dry-run passes (Scenario 10), pubspec metadata correct (Scenario 11)

**Checkpoint**: All 13 quickstart.md scenarios pass. Package is ready for `flutter pub publish`.

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup, T001): No dependencies — start immediately
Phase 2 (Foundational, T002–T003): Depends on Phase 1 — BLOCKS all user stories
Phase 3 (US1, T004–T007): Depends on Phase 2 — no dependency on US2/US3/US4/US5
Phase 4 (US2, T008–T016): Depends on Phase 2 — no dependency on US1/US3/US4/US5
Phase 5 (US3, T017–T024): Depends on Phase 2 — no dependency on US1/US2/US4/US5
Phase 6 (US4, T025–T027): Depends on Phase 2 — no dependency on US1/US2/US3/US5
Phase 7 (US5, T028–T029): Depends on ALL user story phases (T028 fixes any remaining issues from US1–US4)
Phase 8 (Polish, T030): Depends on Phase 7
```

### Dependency Graph

```
T001
└── T002 → T003
              ├── T004 → T005 → T006 → T007          (US1, sequential within story)
              ├── T008 → T009–T015 [P] → T016         (US2, stubs then parallel screens)
              ├── T017 → T018–T021 [P] → T022–T024 [P] (US3, audit then parallel fix/example)
              └── T025 → T026 → T027                   (US4, sequential in same file)
                                                    ↓
                                            T028 → T029 → T030
```

### Within Each User Story

| Story | Sequential constraint |
|---|---|
| US1 (T004–T007) | Write top-to-bottom (each task adds sections to same README.md) |
| US2 (T008–T016) | T008 creates stubs first; T009–T015 are parallel; T016 last (most complex screen) |
| US3 (T017–T024) | T017 runs first (discovers violations); T018–T021 parallel; T022–T024 parallel |
| US4 (T025–T027) | Sequential (all append to same MIGRATION.md) |
| US5 (T028–T029) | Sequential (analyze/format before dry-run) |

---

## Parallel Execution Examples

### After Phase 2: Launch US1, US2, US3, US4 simultaneously

```
# Agent A (US1 — README):
T004 → T005 → T006 → T007

# Agent B (US2 — Example app):
T008 → [T009, T010, T011, T012, T013, T014, T015 in parallel] → T016

# Agent C (US3 — Dartdoc):
T017 → [T018, T019, T020, T021 in parallel] → [T022, T023, T024 in parallel]

# Agent D (US4 — Migration guide):
T025 → T026 → T027
```

### Parallel screens within US2 (after T008 creates stubs)

```
T009 basic_screen.dart     ─┐
T010 counter_screen.dart    │
T011 reveal_actions.dart    │ All parallel — different files
T012 multi_threshold.dart   │
T013 custom_visuals.dart    │
T014 list_demo_screen.dart  │
T015 rtl_screen.dart       ─┘
         ↓
T016 templates_screen.dart  (last — slightly more complex, 6 templates)
```

---

## Implementation Strategy

### MVP First (US1 + US2 Only)

1. Complete Phase 1: Setup (T001)
2. Complete Phase 2: Foundational (T002–T003)
3. Complete Phase 3: US1 README (T004–T007)
4. **STOP and VALIDATE**: README renders correctly; Quick Start code compiles
5. Complete Phase 4: US2 Example App (T008–T016)
6. **STOP and VALIDATE**: Example app launches, all 8 screens work
7. → At this point the package is demo-ready for early adopters

### Full Release Path

1. Setup + Foundational
2. US1 (README) + US2 (Example) + US3 (Dartdoc) + US4 (Migration) — all in parallel
3. US5 (Publishing) — after all four stories complete
4. Polish — final verification

### Single-Developer Sequential Order

```
T001 → T002 → T003 → T004 → T005 → T006 → T007   (Setup + US1 complete)
→ T008 → T009 → T010 → T011 → T012 → T013 → T014 → T015 → T016   (US2)
→ T017 → T018 → T019 → T020 → T021 → T022 → T023 → T024   (US3)
→ T025 → T026 → T027   (US4)
→ T028 → T029 → T030   (US5 + Polish)
```

---

## Notes

- **No test task files**: This feature is documentation-only; correctness is verified by `flutter analyze`, `flutter pub publish --dry-run`, and the 13 quickstart.md scenarios
- **GIF placeholders (T001)**: The `.gif` extension files contain valid PNG binary data; browsers and pub.dev render them as images; real GIFs replace these in a follow-up commit before the pub.dev announcement
- **US1 tasks are sequential (T004–T007)**: All write to `README.md`; each task adds the next section block
- **US4 tasks are sequential (T025–T027)**: All write to `MIGRATION.md`; each task adds the next section
- **T028 is the final analyze+format sweep**: May catch issues introduced by earlier tasks; treat it as the integration test for the whole feature
- Commit after each US phase completion and after T029 (clean dry-run)

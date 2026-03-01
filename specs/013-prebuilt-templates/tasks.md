# Tasks: Prebuilt Zero-Configuration Templates (F014)

**Input**: Design documents from `specs/013-prebuilt-templates/`
**Prerequisites**: plan.md ✅ | spec.md ✅ | research.md ✅ | data-model.md ✅ | contracts/ ✅ | quickstart.md ✅

**Tests**: Constitution VII (Test-First) is **NON-NEGOTIABLE** — tests MUST be written to fail before any implementation. Test tasks are mandatory for every cluster.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies on in-progress tasks)
- **[Story]**: Which user story this task belongs to (US1–US5)
- Exact file paths included in every task description

---

## Phase 1: Setup

**Purpose**: Create directory structure and stub files so all phases can proceed without file-creation friction.

- [x] T001 [P] Create `lib/src/templates/` directory with empty stub files: `template_style.dart`, `swipe_cell_templates.dart`
- [x] T002 [P] Create `test/templates/` directory with empty stub test files: `template_style_test.dart`, `delete_template_test.dart`, `toggle_template_test.dart`, `counter_template_test.dart`, `standard_template_test.dart`, `platform_adaptation_test.dart`

---

## Phase 2: Foundational — TemplateStyle & Shared Helpers

**Purpose**: Core types and shared helper functions used by ALL templates. MUST be complete before any user story implementation.

**⚠️ CRITICAL**: No factory constructor can be implemented until this phase is complete (all templates depend on `TemplateStyle` and `_resolveStyle` / `_buildVisualConfig`).

> **⚠️ Write tests FIRST (RED), then implement (GREEN)**

- [x] T003 Write failing unit tests for `TemplateStyle` enum (all three values) and `_resolveStyle()` platform mapping (iOS/macOS → cupertino, others → material) in `test/templates/template_style_test.dart`
- [x] T004 Implement `TemplateStyle` enum with dartdoc in `lib/src/templates/template_style.dart`
- [x] T005 Implement `_resolveStyle(TemplateStyle)` and `_buildVisualConfig({resolvedStyle, leftBackground, rightBackground})` private helpers in `lib/src/templates/swipe_cell_templates.dart`; confirm T003 tests pass

**Checkpoint**: `flutter test test/templates/template_style_test.dart` passes. Foundation ready — US1/US2/US3 can now begin in parallel.

---

## Phase 3: User Story 1 — Destructive Action Templates (Priority: P1) 🎯 MVP

**Goal**: Deliver fully functional delete and archive templates. A consumer can add delete/archive with a single line of code and no additional configuration.

**Independent Test**: Use `SwipeActionCell.delete(child: ListTile(...), onDeleted: callback)` in a bare widget test. Drag left, verify animation and undo strip appear. Wait for undo expiry, verify `onDeleted` fires. Repeat for `SwipeActionCell.archive` — verify `onArchived` fires immediately with no undo strip.

> **⚠️ Write tests FIRST (RED), then implement (GREEN)**

- [x] T006 [P] [US1] Write failing widget tests for `SwipeActionCell.delete()`: renders with minimal params, left swipe → cell animates out + undo strip appears, undo tapped → `onDeleted` NOT fired, undo expires → `onDeleted` fires exactly once, right swipe ignored, custom `backgroundColor`/`icon` override applied, `deleteMaterial`/`deleteCupertino` return correct clip/icon in `test/templates/delete_template_test.dart`
- [x] T007 [P] [US1] Write failing widget tests for `SwipeActionCell.archive()`: renders with minimal params, left swipe → `onArchived` fires immediately (no undo strip), right swipe ignored, icon/color defaults correct in `test/templates/delete_template_test.dart`
- [x] T008 [US1] Implement `_deleteAssets(TemplateStyle, Widget?, Color?)` and `_archiveAssets(TemplateStyle, Widget?, Color?)` private helpers in `lib/src/templates/swipe_cell_templates.dart`
- [x] T009 [US1] Implement `SwipeActionCell.delete({child, onDeleted, backgroundColor, icon, semanticLabel, style, controller})` factory constructor in `lib/src/widget/swipe_action_cell.dart`; wire to `LeftSwipeConfig(mode: autoTrigger, postActionBehavior: animateOut)` + `SwipeUndoConfig(onUndoExpired: onDeleted)`
- [x] T010 [US1] Implement `SwipeActionCell.archive({child, onArchived, backgroundColor, icon, semanticLabel, style, controller})` factory constructor in `lib/src/widget/swipe_action_cell.dart`; wire `onArchived` to `LeftSwipeConfig.onSwipeCompleted` (no undo config)
- [x] T011 [US1] Implement `deleteMaterial`, `deleteCupertino`, `archiveMaterial`, `archiveCupertino` static methods in `lib/src/widget/swipe_action_cell.dart`; confirm T006 and T007 tests pass

**Checkpoint**: `flutter test test/templates/delete_template_test.dart` passes. Delete + archive templates are fully functional and independently testable.

---

## Phase 4: User Story 2 — Toggle State Templates (Priority: P1)

**Goal**: Deliver fully functional favorite-toggle and checkbox templates. A consumer can add reversible right-swipe toggle interactions in a single line with icon morphing proportional to swipe progress.

**Independent Test**: Use `SwipeActionCell.favorite(child: ..., isFavorited: false, onToggle: callback)` in a widget test. Simulate a drag at 50% — verify icon is equally blended between outline and filled. Complete the swipe — verify `onToggle(true)` fires. Repeat with `isChecked` for checkbox.

> **⚠️ Write tests FIRST (RED), then implement (GREEN)**

- [x] T012 [P] [US2] Write failing widget tests for `SwipeActionCell.favorite()`: renders with minimal params, right swipe (unfavorited) → `onToggle(true)` fires, right swipe (favorited) → `onToggle(false)` fires, progress at 50% → icon midpoint morph, left swipe ignored, `outlineIcon`/`filledIcon` overrides applied, `favoriteMaterial`/`favoriteCupertino` static methods in `test/templates/toggle_template_test.dart`
- [x] T013 [P] [US2] Write failing widget tests for `SwipeActionCell.checkbox()`: renders with minimal params, right swipe (unchecked) → `onChanged(true)` fires, right swipe (checked) → `onChanged(false)` fires, indicator transitions smoothly, `checkboxMaterial`/`checkboxCupertino` static methods in `test/templates/toggle_template_test.dart`
- [x] T014 [US2] Implement `_favoriteAssets(TemplateStyle, Widget?, Widget?, Color?)` and `_checkboxAssets(TemplateStyle, Widget?, Widget?, Color?)` private helpers in `lib/src/templates/swipe_cell_templates.dart`
- [x] T015 [US2] Implement `SwipeActionCell.favorite({child, isFavorited, onToggle, backgroundColor, outlineIcon, filledIcon, semanticLabel, style, controller})` factory constructor in `lib/src/widget/swipe_action_cell.dart`; use `SwipeMorphIcon` in `SwipeVisualConfig.rightBackground`
- [x] T016 [US2] Implement `SwipeActionCell.checkbox({child, isChecked, onChanged, backgroundColor, uncheckedIcon, checkedIcon, semanticLabel, style, controller})` factory constructor in `lib/src/widget/swipe_action_cell.dart`; use `SwipeMorphIcon` in `SwipeVisualConfig.rightBackground`
- [x] T017 [US2] Implement `favoriteMaterial`, `favoriteCupertino`, `checkboxMaterial`, `checkboxCupertino` static methods in `lib/src/widget/swipe_action_cell.dart`; confirm T012 and T013 tests pass

**Checkpoint**: `flutter test test/templates/toggle_template_test.dart` passes. Favorite and checkbox templates are fully functional and independently testable.

---

## Phase 5: User Story 3 — Counter Template (Priority: P2)

**Goal**: Deliver a right-swipe counter increment template. A consumer can let users increment a numeric value with a single line of code; the current count appears in the swipe background; increments stop at `max`.

**Independent Test**: Use `SwipeActionCell.counter(child: ..., count: 3, onCountChanged: callback, max: 5)`. Swipe right at count 3 → `onCountChanged(4)` fires. Swipe at count 5 → no gesture recognized, callback NOT fired. Remove `max` → counter increments indefinitely.

> **⚠️ Write tests FIRST (RED), then implement (GREEN)**

- [x] T018 [P] [US3] Write failing widget tests for `SwipeActionCell.counter()`: renders with minimal params, right swipe at count < max → `onCountChanged(count + 1)` fires, right swipe at count == max → right swipe completely disabled, max null → unlimited increments, max ≤ 0 treated as unlimited, count value visible in background during drag, `counterMaterial`/`counterCupertino` static methods in `test/templates/counter_template_test.dart`
- [x] T019 [US3] Implement `_counterAssets(TemplateStyle, Widget?, Color?)` private helper in `lib/src/templates/swipe_cell_templates.dart`
- [x] T020 [US3] Implement `SwipeActionCell.counter({child, count, onCountChanged, max, backgroundColor, icon, semanticLabel, style, controller})` factory constructor in `lib/src/widget/swipe_action_cell.dart`; set `rightSwipeConfig: null` when `count >= max` (Constitution IX)
- [x] T021 [US3] Implement `counterMaterial`, `counterCupertino` static methods in `lib/src/widget/swipe_action_cell.dart`; confirm T018 tests pass

**Checkpoint**: `flutter test test/templates/counter_template_test.dart` passes. Counter template is fully functional and independently testable.

---

## Phase 6: User Story 4 — Standard Template (Priority: P2)

**Goal**: Deliver the composite standard template combining a right-swipe favorite toggle and a left-swipe reveal action panel. Either direction can be independently disabled by omitting its parameter.

**Independent Test**: Use `SwipeActionCell.standard(child: ..., onFavorited: callback, actions: [...])`. Right swipe → favorite fires. Left swipe → reveal panel appears. Omit `onFavorited` → right swipe disabled. Omit `actions` → left swipe disabled. Omit both → plain non-interactive wrapper.

> **⚠️ Write tests FIRST (RED), then implement (GREEN)**

> **⚠️ Requires Phase 4 (US2) complete** — standard template reuses `_favoriteAssets()` from the toggle helper module.

- [x] T022 [US4] Write failing widget tests for `SwipeActionCell.standard()`: renders with all params (right + left active), right swipe → `onFavorited` fires with toggled state, left swipe → reveal panel shows all action buttons, `onFavorited: null` → right swipe completely disabled, `actions: []` → left swipe completely disabled, both null/empty → plain wrapper, `standardMaterial`/`standardCupertino` static methods in `test/templates/standard_template_test.dart`
- [x] T023 [US4] Implement `SwipeActionCell.standard({child, onFavorited, isFavorited, actions, style, controller})` factory constructor in `lib/src/widget/swipe_action_cell.dart`; reuse `_favoriteAssets()` for right background; set `rightSwipeConfig: null` when `onFavorited == null`, `leftSwipeConfig: null` when `actions` is null or empty
- [x] T024 [US4] Implement `standardMaterial`, `standardCupertino` static methods in `lib/src/widget/swipe_action_cell.dart`; confirm T022 tests pass

**Checkpoint**: `flutter test test/templates/standard_template_test.dart` passes. Standard template is fully functional and independently testable.

---

## Phase 7: User Story 5 — Platform Style Adaptation (Priority: P3)

**Goal**: Verify that all templates auto-select platform-appropriate icons, clip behavior, and border radius, and that explicit `Material`/`Cupertino` style overrides work on any platform.

**Independent Test**: In tests, mock `defaultTargetPlatform` as iOS → verify Cupertino icon and rounded corners. Mock as Android → verify Material icon and sharp clip. Use `deleteMaterial` on mocked iOS → verify Material style applied regardless of platform.

> **⚠️ Write tests FIRST (RED), then implement (GREEN)**

> **⚠️ Requires all of Phase 3–6 complete** — platform adaptation tests cover all six templates.

- [x] T025 [US5] Write failing widget tests for platform auto-detection: `_resolveStyle(TemplateStyle.auto)` returns cupertino for iOS/macOS, material for Android/web/desktop; all templates use cupertino clip/icon on simulated iOS; all templates use material clip/icon on simulated Android in `test/templates/platform_adaptation_test.dart`
- [x] T026 [US5] Write failing widget tests for explicit style override: `deleteMaterial` on simulated iOS uses `Clip.hardEdge` and `Icons.delete_outline`; `deleteCupertino` on simulated Android uses `Clip.antiAlias` and `CupertinoIcons.trash`; color override + style override coexist correctly (FR-013-007) in `test/templates/platform_adaptation_test.dart`
- [x] T027 [US5] Verify `_resolveStyle()` and all asset helpers produce correct output for both styles; fix any gaps in platform resolution logic in `lib/src/templates/swipe_cell_templates.dart`; confirm T025 and T026 tests pass

**Checkpoint**: `flutter test test/templates/platform_adaptation_test.dart` passes. All six templates adapt correctly to platform context and respect style overrides.

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Barrel exports, static analysis, formatting, and full regression.

- [x] T028 Export `TemplateStyle` from `lib/swipe_action_cell.dart` (add to barrel after existing exports)
- [x] T029 [P] Add `///` dartdoc comments to all public members in `lib/src/templates/template_style.dart` and all factory constructors / static methods added to `lib/src/widget/swipe_action_cell.dart` (Constitution VIII)
- [x] T030 Run `flutter analyze` from repo root; fix all warnings and errors in `lib/src/templates/` and the modified `lib/src/widget/swipe_action_cell.dart`
- [x] T031 Run `dart format .` from repo root; fix any formatting issues
- [x] T032 Run `flutter test` (full suite) from repo root; verify zero failures — all pre-existing tests must continue to pass (SC-013-005)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies — start immediately, both tasks in parallel
- **Foundational (Phase 2)**: Depends on Phase 1 — BLOCKS all factory constructors
- **US1 (Phase 3), US2 (Phase 4), US3 (Phase 5)**: All depend on Phase 2 — can proceed **in parallel** after Phase 2 completes
- **US4 (Phase 6)**: Depends on US2 (Phase 4) complete — reuses `_favoriteAssets()` helper
- **US5 (Phase 7)**: Depends on all of Phase 3–6 complete — platform tests cover all templates
- **Polish (Phase 8)**: Depends on Phase 7 complete

### User Story Dependencies

| Story | Depends On | Can Parallel With |
|---|---|---|
| US1 Delete+Archive | Phase 2 | US2, US3 |
| US2 Favorite+Checkbox | Phase 2 | US1, US3 |
| US3 Counter | Phase 2 | US1, US2 |
| US4 Standard | US2 (needs `_favoriteAssets`) | — |
| US5 Platform | US1, US2, US3, US4 | — |

### Within Each User Story

1. Tests MUST be written (RED) before implementation
2. Asset helpers before factory constructors
3. Factory constructors before static variant methods
4. All GREEN before story marked complete

---

## Parallel Opportunities

### Phase 1 (both tasks in parallel)
```
Task A: Create lib/src/templates/ directory + stubs
Task B: Create test/templates/ directory + stubs
```

### Phase 2 → Phase 3/4/5 can all start after Foundational complete

```
After Phase 2 completes:
  Team A: Phase 3 (US1 Delete + Archive)
  Team B: Phase 4 (US2 Favorite + Checkbox)
  Team C: Phase 5 (US3 Counter)
```

### Within US1 (Phase 3) — test tasks in parallel

```
T006: Write delete template tests
T007: Write archive template tests  ← parallel with T006 (same file, different test groups)
```

### Within US2 (Phase 4) — test tasks in parallel

```
T012: Write favorite template tests
T013: Write checkbox template tests  ← parallel with T012 (same file, different test groups)
```

---

## Implementation Strategy

### MVP First (US1 Only — Delete + Archive)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (TemplateStyle + helpers)
3. Complete Phase 3: US1 (Delete + Archive)
4. **STOP and VALIDATE**: `flutter test test/templates/delete_template_test.dart`
5. Package consumers can already use `SwipeActionCell.delete()` and `SwipeActionCell.archive()`

### Incremental Delivery

1. Setup + Foundational → foundation ready
2. Add US1 (Delete + Archive) → test → **MVP**
3. Add US2 (Favorite + Checkbox) → test independently
4. Add US3 (Counter) → test independently (can happen before/after US2)
5. Add US4 (Standard) → test independently (requires US2)
6. Add US5 (Platform tests) → validates entire template suite
7. Polish → export, analyze, format, regression

### Single-Developer Sequence

```
T001 → T002 (parallel) → T003 → T004 → T005 →
T006 → T007 (parallel) → T008 → T009 → T010 → T011 →  [US1 done]
T012 → T013 (parallel) → T014 → T015 → T016 → T017 →  [US2 done]
T018 → T019 → T020 → T021 →                             [US3 done]
T022 → T023 → T024 →                                     [US4 done]
T025 → T026 → T027 →                                     [US5 done]
T028 → T029 (parallel) → T030 → T031 → T032             [Polish done]
```

---

## Notes

- `[P]` tasks operate on different files or independent test groups — no write conflicts
- Each user story phase is independently testable via its dedicated test file in `test/templates/`
- Constitution VII is NON-NEGOTIABLE: every RED test must fail before implementation begins
- Constitution IX: standard template and counter template use null `rightSwipeConfig`/`leftSwipeConfig` to disable directions — never a boolean flag
- Constitution VI exception: factory constructors are non-const; this is documented in plan.md
- `_buildVisualConfig()` and `_resolveStyle()` are shared by all templates; they live in Phase 2 foundation so all stories can use them without phase ordering conflicts
- Static variant methods (`deleteMaterial`, etc.) are thin wrappers — implement all variants for a template in the same task as the factory constructor's completion task
- Verify quickstart.md scenarios manually after T032 to confirm all 12 scenarios and 47 checkpoints pass

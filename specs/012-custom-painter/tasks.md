# Tasks: Custom Painting & Decoration Hooks (F013)

**Input**: Design documents from `specs/012-custom-painter/`
**Prerequisites**: plan.md ✅, spec.md ✅, research.md ✅, data-model.md ✅, contracts/public-api.md ✅, quickstart.md ✅

**Tests**: Included — Constitution VII (Test-First) is NON-NEGOTIABLE. All test tasks must FAIL before their implementation tasks begin.

**Organization**: Tasks grouped by user story. US1 + US2 are both P1; US2 follows US1 because both modify `swipe_action_cell.dart` sequentially.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no blocking dependencies)
- **[Story]**: User story label (US1–US4)
- Exact file paths included in all descriptions

---

## Phase 1: Setup

**Purpose**: Create the `lib/src/painting/` directory structure per plan.md

- [ ] T001 Create directory `lib/src/painting/` and stub files: `swipe_painting_config.dart`, `particle_config.dart`, `swipe_particle_painter.dart`, `swipe_morph_icon.dart` (each with a single `// TODO` comment) and test directory `test/painting/`

---

## Phase 2: Foundation — Shared Types (Cluster A)

**Purpose**: `SwipePaintingConfig`, `SwipePainterCallback`, and `ParticleConfig` are prerequisites for ALL user stories. No story work can begin until these are complete.

**⚠️ CRITICAL**: Write tests to FAIL (RED) before implementing.

- [ ] T002 Write failing unit tests for `SwipePaintingConfig` + `SwipePainterCallback` typedef: const construction, all-null fields, copyWith, `==`/`hashCode`, null means zero-overhead assertion in `test/painting/swipe_painting_config_test.dart`
- [ ] T003 [P] Write failing unit tests for `ParticleConfig`: const construction, default values (`count=12`, `duration=500ms`, `spreadAngle=360`), copyWith, empty-colors fallback to default palette, `count=0` no-op, `==`/`hashCode` in `test/painting/swipe_painting_config_test.dart`
- [ ] T004 Implement `SwipePainterCallback` typedef and `SwipePaintingConfig` class (const constructor, all fields nullable, copyWith, `==`, `hashCode`, dartdoc on every member) in `lib/src/painting/swipe_painting_config.dart` — run T002 tests to GREEN
- [ ] T005 [P] Implement `ParticleConfig` class (const constructor, default values, copyWith, `==`, `hashCode`, dartdoc on every member) in `lib/src/painting/particle_config.dart` — run T003 tests to GREEN

**Checkpoint**: `flutter test test/painting/swipe_painting_config_test.dart` passes. Foundation ready.

---

## Phase 3: US1 — Custom Painter Hooks (Priority: P1) 🎯 MVP

**Goal**: Consumers can attach `backgroundPainter` and `foregroundPainter` callbacks to `SwipeActionCell`. Painters receive `SwipeProgress` + `SwipeState` every frame during all `SwipeState` phases. Foreground painter does not block hit testing. Zero overhead when both painters are null.

**Independent Test** (from quickstart.md Scenario 1): Attach a background painter drawing a red gradient whose width scales with `progress.ratio`; verify it grows/shrinks with drag. Attach a foreground yellow-border painter; verify it renders above `ListTile` content. Remove `paintingConfig`; verify no artifacts.

- [ ] T006 Write failing widget tests for painter hooks: (a) background painter renders below child content, (b) foreground painter renders above child content, (c) tap on child interactive area with foreground painter active → tap fires, (d) `paintingConfig: null` → Stack has no extra children, (e) painter callback throws in debug → error propagates, (f) painter callback throws in release → layer skipped, no crash — in `test/widget/swipe_action_cell_painting_test.dart`
- [ ] T007 [US1] Add `final SwipePaintingConfig? paintingConfig` field to `SwipeActionCell` constructor (alongside existing `undoConfig`; dartdoc required) in `lib/src/widget/swipe_action_cell.dart`
- [ ] T008 [US1] Capture `_widgetHeight` from `LayoutBuilder` constraints and compute `_burstOrigin = Offset(_widgetWidth / 2, _widgetHeight / 2)` in `SwipeActionCellState.build()` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T009 [US1] Implement `_safePainterCall(SwipePainterCallback, SwipeProgress, SwipeState) → CustomPainter` helper (rethrow in `kDebugMode`; catch + `FlutterError.reportError` + return `_NoOpPainter()` in release) and internal `_NoOpPainter extends CustomPainter` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T010 [US1] Wire background painter as first Stack child: `if (widget.paintingConfig?.backgroundPainter != null) Positioned.fill(child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: _safePainterCall(...)))))` in `SwipeActionCellState.build()` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T011 [US1] Wire foreground painter as Stack child after progress indicator: `if (widget.paintingConfig?.foregroundPainter != null) Positioned.fill(child: IgnorePointer(child: RepaintBoundary(child: CustomPaint(painter: _safePainterCall(...)))))` in `SwipeActionCellState.build()` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T012 [US1] Add barrel export `export 'src/painting/swipe_painting_config.dart';` to `lib/swipe_action_cell.dart` — run T006 tests to GREEN

**Checkpoint**: `flutter test test/widget/swipe_action_cell_painting_test.dart` (US1 tests) passes. Painters visible in isolation.

---

## Phase 4: US2 — Decoration Interpolation (Priority: P1)

**Goal**: Consumers can define `restingDecoration` and `activatedDecoration` on `SwipePaintingConfig`. The cell smoothly interpolates between them proportional to `progress.ratio` during all `SwipeState` phases. Null `activatedDecoration` → resting decoration applied permanently. Incompatible decoration types degrade gracefully.

**Independent Test** (from quickstart.md Scenario 2): Configure grey/rounded resting + pink/sharp activated decoration. At 50% drag the appearance is visually halfway. Release without completing → returns to resting smoothly.

- [ ] T013 [US2] Write failing widget tests for decoration interpolation: (a) both decorations set: `ratio=0.0` → resting applied, `ratio=0.5` → blended, `ratio=1.0` → activated, (b) only `restingDecoration` set → resting always, no crash, (c) `ratio > 1.0` → clamped to activated state, no overflow, (d) `Decoration.lerp` returns null (incompatible types) → fallback to resting, no crash — append to `test/widget/swipe_action_cell_painting_test.dart`
- [ ] T014 [US2] Implement `_buildDecoratedChild(Widget translatedChild, SwipeProgress progress) → Widget` helper: guard on `restingDecoration != null || activatedDecoration != null`; compute `t = progress.ratio.clamp(0.0, 1.0)`; use `Decoration.lerp(resting, activated, t) ?? resting`; wrap in `DecoratedBox` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T015 [US2] Replace bare `translatedChild` reference in `Stack` children with `_buildDecoratedChild(translatedChild, progress)` in `SwipeActionCellState.build()` in `lib/src/widget/swipe_action_cell.dart` — run T013 tests to GREEN

**Checkpoint**: `flutter test test/widget/swipe_action_cell_painting_test.dart` (US1 + US2 tests) passes. Decoration interpolation verified.

---

## Phase 5: US3 — Built-In Morph Icon (Priority: P2)

**Goal**: `SwipeMorphIcon` is a standalone `StatelessWidget` that cross-fades between two `Widget` icons based on a `progress` value [0.0, 1.0]. Usable inside any F002 `SwipeBackgroundBuilder`. No internal `AnimationController` — progress is consumer-driven.

**Independent Test** (from quickstart.md Scenario 3): Place `SwipeMorphIcon` inside `visualConfig.leftBackground`; verify `startIcon` only at `progress=0.0`, equal blend at `0.5`, `endIcon` only at `1.0`.

- [ ] T016 [P] [US3] Write failing widget tests for `SwipeMorphIcon`: (a) `progress=0.0` → only `startIcon` visible (opacity 1.0), endIcon opacity 0.0, (b) `progress=0.5` → both icons at opacity 0.5, (c) `progress=1.0` → only `endIcon` visible, startIcon opacity 0.0, (d) `progress` clamped: values < 0.0 and > 1.0 do not crash in `test/painting/swipe_morph_icon_test.dart`
- [ ] T017 [P] [US3] Implement `SwipeMorphIcon extends StatelessWidget` (const constructor; `required startIcon`, `required endIcon`, `required progress`; optional `size`, `color`; `build()` returns `Stack` with two `Opacity`-wrapped icons; clamp `progress.clamp(0.0, 1.0)`; apply `size`/`color` via `IconTheme`; dartdoc on every member) in `lib/src/painting/swipe_morph_icon.dart` — run T016 tests to GREEN
- [ ] T018 [P] [US3] Add barrel export `export 'src/painting/swipe_morph_icon.dart';` to `lib/swipe_action_cell.dart`

**Checkpoint**: `flutter test test/painting/swipe_morph_icon_test.dart` passes. `SwipeMorphIcon` usable standalone.

---

## Phase 6: US4 — Particle Burst on Action Completion (Priority: P3)

**Goal**: When `paintingConfig.particleConfig` is non-null, an intentional (left-swipe) action completion triggers a particle burst. Particles animate outward and are gone by `duration`. Progressive (right-swipe) actions do NOT trigger a burst. All resources released on widget disposal. `count=0` → no animation.

**Independent Test** (from quickstart.md Scenario 4): Enable `ParticleConfig(count: 12, colors: [...])`. Complete a left-swipe action. Verify 12 particles appear and are gone by 500 ms. Dispose widget mid-animation → no exception, no particles persist.

- [ ] T019 [P] [US4] Write failing unit tests for `SwipeParticlePainter`: (a) `shouldRepaint` returns `true` when `animationValue` changes, `false` when unchanged, (b) `paint()` draws `count` circles on canvas when `animationValue > 0`, (c) no particles drawn when `animationValue == 0.0` in `test/painting/swipe_particle_painter_test.dart`
- [ ] T020 [P] [US4] Write failing widget tests for particle burst integration: (a) intentional left-swipe action completes → `CustomPaint` with `SwipeParticlePainter` added to tree, (b) progressive right-swipe action completes → no particle layer in tree, (c) `particleConfig: null` → no particle layer ever, (d) `count=0` → no particle layer, (e) dispose widget while particles active → no exception — append to `test/widget/swipe_action_cell_painting_test.dart`
- [ ] T021 [P] [US4] Implement internal `_Particle` data class (fields: `angle: double`, `maxDistance: double`, `color: Color`) and `SwipeParticlePainter extends CustomPainter` (fields: `particles`, `animationValue`, `origin`; `paint()` draws fading circles using `opacity = 1.0 - animationValue`, distance = `maxDistance * animationValue`; `shouldRepaint` checks `animationValue` and `origin`) in `lib/src/painting/swipe_particle_painter.dart`
- [ ] T022 [US4] Add particle state fields to `SwipeActionCellState`: `AnimationController? _particleController`, `List<_Particle>? _particles`, `Offset _burstOrigin = Offset.zero`, `double _widgetHeight = 400.0`; initialize `_particleController` in `initState()` when `paintingConfig?.particleConfig != null`; dispose in `dispose()` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T023 [US4] Implement `_startParticleBurst()` method in `SwipeActionCellState`: guard on `particleConfig.count <= 0`; use `dart:math` `Random()` to generate `_particles` list (angle within `spreadAngle` range, random `maxDistance` 20–60 px, color cycling from `particleConfig.colors` with fallback to default palette when empty); set `_particleController.duration`; call `_particleController.forward(from: 0.0).then((_) { if (mounted) setState(() => _particles = null); })` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T024 [US4] Add `if (widget.paintingConfig?.particleConfig != null) _startParticleBurst();` call immediately after intentional action fires in `_applyIntentionalAction()` in `lib/src/widget/swipe_action_cell.dart`
- [ ] T025 [US4] Wire particle burst layer as last Stack child: `if (_particles != null && _particleController != null) Positioned.fill(child: IgnorePointer(child: AnimatedBuilder(animation: _particleController!, builder: (ctx, _) => CustomPaint(painter: SwipeParticlePainter(particles: _particles!, animationValue: _particleController!.value, origin: _burstOrigin)))))` in `SwipeActionCellState.build()` in `lib/src/widget/swipe_action_cell.dart` — run T019 + T020 tests to GREEN
- [ ] T026 [US4] Add barrel export `export 'src/painting/particle_config.dart';` to `lib/swipe_action_cell.dart`

**Checkpoint**: `flutter test test/painting/ test/widget/swipe_action_cell_painting_test.dart` passes. All four user stories independently verified.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Analysis, format, regression, and quickstart validation.

- [ ] T027 Run `flutter analyze` and fix ALL warnings/errors (zero-warning gate — public_member_api_docs enforced on every new public class/method/field)
- [ ] T028 Run `dart format .` and verify `dart format --set-exit-if-changed .` exits 0
- [ ] T029 Run full regression: `flutter test` (all existing tests must continue to pass — no regressions from F001–F012)
- [ ] T030 Manually validate quickstart.md Scenarios 1–7: painter hooks, decoration interpolation, `SwipeMorphIcon`, particle burst, zero-overhead baseline, incompatible decoration types, rapid direction reversal

---

## Dependencies & Execution Order

### Phase Dependencies

```
Phase 1 (Setup)       → no dependencies
Phase 2 (Foundation)  → depends on Phase 1 — BLOCKS all user story phases
Phase 3 (US1)         → depends on Phase 2 completion
Phase 4 (US2)         → depends on Phase 3 completion (both modify same file sequentially)
Phase 5 (US3)         → depends on Phase 2 completion (can parallel with US1/US2)
Phase 6 (US4)         → depends on Phase 2 + Phase 3 completion (needs paintingConfig on widget)
Phase 7 (Polish)      → depends on Phases 3–6 all complete
```

### User Story Dependencies

- **US1 (P1)**: Depends on Foundation (Phase 2) only
- **US2 (P1)**: Depends on US1 — both modify `swipe_action_cell.dart`; US2 extends US1's decorated child wiring
- **US3 (P2)**: Depends on Foundation only — `SwipeMorphIcon` is a standalone widget, no dependency on US1/US2
- **US4 (P3)**: Depends on Foundation + US1 — needs `paintingConfig` parameter on `SwipeActionCell` (T007)

### Within Each Phase (test-first order)

```
Tests (RED) → Implementation (GREEN) → Verify → Next task
```

### Parallel Opportunities

- **Phase 2**: T003 [P] parallel with T002; T005 [P] parallel with T004 (different files)
- **Phase 5**: T016 [P], T017 [P], T018 [P] — all three can run in parallel (no cross-dependencies)
- **Phase 6**: T019 [P] and T020 [P] and T021 [P] can run in parallel before T022–T025

---

## Parallel Example: Phase 6 (US4)

```bash
# Phase 6a — run these three in parallel (different files):
Task T019: "Write failing tests for SwipeParticlePainter in test/painting/swipe_particle_painter_test.dart"
Task T020: "Write failing widget tests for particle burst in test/widget/swipe_action_cell_painting_test.dart"
Task T021: "Implement _Particle + SwipeParticlePainter in lib/src/painting/swipe_particle_painter.dart"

# Phase 6b — sequential (same file, ordered):
Task T022: "Add particle fields + lifecycle to SwipeActionCellState"
Task T023: "Implement _startParticleBurst() method"
Task T024: "Wire _startParticleBurst() call in _applyIntentionalAction()"
Task T025: "Wire particle layer in build()"
Task T026: "Add barrel export for ParticleConfig"
```

---

## Implementation Strategy

### MVP (US1 + US2 only — painter hooks + decoration)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundation (types)
3. Complete Phase 3: US1 (painter hooks)
4. Complete Phase 4: US2 (decoration interpolation)
5. **STOP and VALIDATE**: run `flutter test`, manually test Scenarios 1–2
6. Ship: consumers can use custom painters and decoration interpolation

### Incremental Delivery

1. Setup + Foundation → types published ✓
2. + US1 → painter hooks functional (MVP core) ✓
3. + US2 → decoration interpolation functional ✓
4. + US3 → `SwipeMorphIcon` available for background builders ✓
5. + US4 → particle burst available (opt-in) ✓
6. Polish → production-ready ✓

---

## Notes

- All `[P]` tasks involve different files with no blocking dependencies
- Constitution VII mandates RED before GREEN — never skip test tasks
- `_NoOpPainter` and `SwipeParticlePainter` are internal (no barrel export, no dartdoc public API requirement)
- `SwipePainterCallback` is a typedef — it must be exported from the barrel alongside `SwipePaintingConfig`
- When adding `paintingConfig` to `SwipeActionCell`, verify existing tests in `test/widget/swipe_action_cell_test.dart` still compile (new nullable param has no breaking effect)
- Particle animation uses `dart:math` — add `import 'dart:math' as math;` to `swipe_action_cell.dart`
- Total: **30 tasks** across 7 phases

# Implementation Plan: Custom Painting & Decoration Hooks (F013)

**Branch**: `012-custom-painter` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/012-custom-painter/spec.md`

---

## Summary

Add custom painter hooks (background + foreground), decoration interpolation, `SwipeMorphIcon`, and optional particle burst to `SwipeActionCell`. All features are gated behind `SwipePaintingConfig?` (null = zero overhead, Constitution IX). Painters receive `SwipeProgress` + `SwipeState` every frame via the existing `AnimatedBuilder`. The particle burst fires exclusively on intentional (left-swipe) action completion, driven by a dedicated `AnimationController`. `SwipeMorphIcon` is a pure `StatelessWidget` usable inside F002 background builders.

---

## Technical Context

**Language/Version**: Dart ≥ 3.4.0 < 4.0.0
**Primary Dependencies**: Flutter SDK only — `dart:math` for particle angle computation (stdlib, no external package)
**Storage**: N/A (no persistence)
**Testing**: `flutter test` (widget tests + unit tests)
**Target Platform**: All Flutter-supported platforms (iOS, Android, web, macOS, Windows, Linux)
**Project Type**: Flutter library package
**Performance Goals**: 60 fps with all painting layers active on 2018-era mid-range devices (SC-012-002)
**Constraints**: Zero overhead when `paintingConfig` is null (SC-012-003); particle resources released within 100 ms of completion/disposal (SC-012-004)
**Scale/Scope**: 3 new source files, 1 modified source file, 3 new test files

---

## Constitution Check

*GATE: Must pass before implementation. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| I. Composition over Inheritance | ✅ PASS | `SwipeActionCell` wraps child; `SwipePaintingConfig` is injected, not inherited |
| II. Explicit State Machine | ✅ PASS | No new states added; painters respond to existing `SwipeState` values |
| III. Spring-Based Physics | ⚠️ EXCEPTION | Particle animation uses fixed-duration `AnimationController` — justified (see Complexity Tracking) |
| IV. Zero External Runtime Deps | ✅ PASS | `dart:math` is Dart stdlib, not a third-party package |
| V. Controlled/Uncontrolled Pattern | ✅ PASS | No new controller type; painting is passive visual layer |
| VI. Const-Friendly Configuration | ✅ PASS | `SwipePaintingConfig` and `ParticleConfig` have `const` constructors |
| VII. Test-First | ✅ PASS | Tests written before implementation in every cluster |
| VIII. Dartdoc Everything | ✅ PASS | All public members will carry `///` comments |
| IX. Null Config = Feature Disabled | ✅ PASS | `paintingConfig: null` → zero Stack children added; `particleConfig: null` → no burst |
| X. 60 fps Budget | ✅ PASS | `RepaintBoundary` isolates painter layers; `shouldRepaint` guards canvas work |

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Constitution III: particle animation uses fixed-duration `AnimationController`, not `SpringSimulation` | Particle spread physics cannot be meaningfully modeled as a spring — particles travel outward and disappear; there is no equilibrium position | Forcing a spring would produce wrong-looking physics (oscillating particles) and a meaningless equilibrium point. Particles are decorative eye-candy fired once after action completion, not gesture-driven feedback. |

---

## Project Structure

### Documentation (this feature)

```text
specs/012-custom-painter/
├── plan.md              ← This file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
├── contracts/
│   └── public-api.md    ← Phase 1 output
└── tasks.md             ← Phase 2 output (/speckit.tasks — NOT created by /speckit.plan)
```

### Source Code

```text
lib/
├── swipe_action_cell.dart           ← MODIFIED: add 3 new exports
└── src/
    ├── painting/                    ← NEW directory (F013)
    │   ├── swipe_painting_config.dart   ← SwipePaintingConfig, SwipePainterCallback typedef
    │   ├── particle_config.dart         ← ParticleConfig
    │   ├── swipe_particle_painter.dart  ← internal SwipeParticlePainter, _Particle
    │   └── swipe_morph_icon.dart        ← SwipeMorphIcon widget
    └── widget/
        └── swipe_action_cell.dart   ← MODIFIED: paintingConfig param + layer wiring

test/
└── painting/                        ← NEW test directory
    ├── swipe_painting_config_test.dart  ← Unit tests: config, copyWith, const, ==
    ├── swipe_morph_icon_test.dart       ← Widget tests: opacity at 0.0 / 0.5 / 1.0
    └── swipe_particle_painter_test.dart ← Unit tests: paint cycle, dispose, zero-count
└── widget/
    └── swipe_action_cell_painting_test.dart  ← Integration: painter layers, decoration, particles
```

**Structure Decision**: Single project (library package). New `lib/src/painting/` directory follows the feature-first pattern established by `gesture/`, `animation/`, `undo/`, etc.

---

## Phase 0: Research Output

See [research.md](research.md) for all 10 architectural decisions (D1–D10).

Key decisions summary:
- **D1** `SwipePainterCallback` called inside existing `AnimatedBuilder` — no extra listener
- **D2** `Decoration.lerp` with null fallback to resting
- **D3** Error handling: suppress in release, rethrow in debug (`kDebugMode`)
- **D4** `SwipeMorphIcon` is pure `StatelessWidget` with `Opacity` cross-fade
- **D5** Particle fields inlined in `SwipeActionCellState` (mirrors F011 undo pattern)
- **D6** Constitution III justified exception for particle fixed-duration animation
- **D7** Layer order in Stack: bg painter → F002 bg → reveal → confirm → decorated child → undo → progress → fg painter → particles
- **D8** Zero-overhead guard: all layers gated on `paintingConfig` null checks
- **D9** `SwipePaintingConfig` is per-cell only, not added to `SwipeActionCellTheme`
- **D10** `SwipeMorphIcon` accepts `Widget` not `IconData`

---

## Phase 1: Design Artifacts

- **Data Model**: [data-model.md](data-model.md) — types, fields, constraints, layer order
- **Public API Contract**: [contracts/public-api.md](contracts/public-api.md) — Dart signatures, behavior tables
- **Quickstart**: [quickstart.md](quickstart.md) — 7 test scenarios

---

## Implementation Clusters

```
Cluster A ─────────────────────── Foundation types
  T001: tests for SwipePaintingConfig (RED)
  T002: SwipePaintingConfig + SwipePainterCallback typedef
  T003: tests for ParticleConfig (RED)
  T004: ParticleConfig

Cluster B ─────────────────────── SwipeMorphIcon [parallel with C after A]
  T005: tests for SwipeMorphIcon (RED)
  T006: SwipeMorphIcon widget

Cluster C ─────────────────────── Particle painter [parallel with B after A]
  T007: tests for SwipeParticlePainter (RED)
  T008: SwipeParticlePainter + _Particle (internal)

Cluster D ─────────────────────── Widget integration [after B + C]
  T009: integration tests for painter hooks + decoration + particles (RED)
  T010: add paintingConfig param to SwipeActionCell
  T011: wire background painter layer in build()
  T012: wire decoration interpolation in build()
  T013: wire foreground painter layer in build()
  T014: add particle fields (_particleController, _particles, _burstOrigin)
  T015: wire particle trigger in _applyIntentionalAction()
  T016: wire particle layer in build()

Cluster E ─────────────────────── Exports + polish [after D]
  T017: add barrel exports
  T018: flutter analyze + dart format pass
  T019: regression run (flutter test)
```

**Dependency graph**:
```
A → B [parallel]
A → C [parallel]
B + C → D
D → E
```

---

## Key Implementation Notes

### Painter wiring in `build()`

Inside the `AnimatedBuilder` that already computes `SwipeProgress progress` and `SwipeState _state`:

```dart
// 1. Background painter (lowest, before F002 background)
if (widget.paintingConfig?.backgroundPainter != null)
  Positioned.fill(
    child: IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _safePainterCall(
            widget.paintingConfig!.backgroundPainter!, progress, _state),
        ),
      ),
    ),
  ),

// ... existing F002 background, reveal panel, confirm overlay ...

// 5. Decorated child (replaces bare translatedChild)
_buildDecoratedChild(translatedChild, progress),

// ... existing undo overlay, progress indicator ...

// 8. Foreground painter (above child, below operational overlays)
if (widget.paintingConfig?.foregroundPainter != null)
  Positioned.fill(
    child: IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _safePainterCall(
            widget.paintingConfig!.foregroundPainter!, progress, _state),
        ),
      ),
    ),
  ),

// 9. Particle burst (topmost, IgnorePointer)
if (_particles != null && _particleController != null)
  Positioned.fill(
    child: IgnorePointer(
      child: AnimatedBuilder(
        animation: _particleController!,
        builder: (context, _) => CustomPaint(
          painter: SwipeParticlePainter(
            particles: _particles!,
            animationValue: _particleController!.value,
            origin: _burstOrigin,
          ),
        ),
      ),
    ),
  ),
```

### `_buildDecoratedChild` helper

```dart
Widget _buildDecoratedChild(Widget translatedChild, SwipeProgress progress) {
  final config = widget.paintingConfig;
  if (config?.restingDecoration == null && config?.activatedDecoration == null) {
    return translatedChild;
  }
  final t = progress.ratio.clamp(0.0, 1.0);
  final decoration = (config!.activatedDecoration != null)
      ? (Decoration.lerp(config.restingDecoration, config.activatedDecoration, t)
          ?? config.restingDecoration)
      : config.restingDecoration;
  if (decoration == null) return translatedChild;
  return DecoratedBox(decoration: decoration, child: translatedChild);
}
```

### `_safePainterCall` helper (error handling)

```dart
CustomPainter _safePainterCall(
    SwipePainterCallback callback, SwipeProgress progress, SwipeState state) {
  if (kDebugMode) {
    return callback(progress, state);
  }
  try {
    return callback(progress, state);
  } catch (e, st) {
    FlutterError.reportError(FlutterErrorDetails(exception: e, stack: st));
    return _NoOpPainter();
  }
}

class _NoOpPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {}
  @override
  bool shouldRepaint(_NoOpPainter old) => false;
}
```

### Particle burst trigger

In `_applyIntentionalAction()` (after intentional swipe completion logic fires):

```dart
// F13: trigger particle burst on intentional action
if (widget.paintingConfig?.particleConfig != null) {
  _startParticleBurst();
}
```

```dart
void _startParticleBurst() {
  final config = widget.paintingConfig!.particleConfig!;
  if (config.count <= 0) return;

  final colors = config.colors.isEmpty
      ? [Colors.amber, Colors.orange, Colors.red]
      : config.colors;
  final spreadRad = (config.spreadAngle <= 0 ? 360.0 : config.spreadAngle)
      * (math.pi / 180.0);
  final startAngle = -spreadRad / 2;

  _particles = List.generate(config.count, (i) {
    final angle = startAngle + (spreadRad / config.count) * i
        + (math.Random().nextDouble() - 0.5) * (spreadRad / config.count);
    return _Particle(
      angle: angle,
      maxDistance: 20.0 + math.Random().nextDouble() * 40.0,
      color: colors[i % colors.length],
    );
  });

  _particleController!
    ..duration = config.duration
    ..forward(from: 0.0).then((_) {
      if (mounted) setState(() => _particles = null);
    });

  setState(() {});
}
```

### Particle controller lifecycle

```dart
@override
void initState() {
  super.initState();
  // ... existing init ...
  if (widget.paintingConfig?.particleConfig != null) {
    _particleController = AnimationController(vsync: this);
  }
}

@override
void dispose() {
  _particleController?.dispose();
  // ... existing dispose ...
  super.dispose();
}
```

### `_widgetHeight` capture

In `LayoutBuilder` builder alongside existing `_widgetWidth`:
```dart
final width = constraints.maxWidth;
final height = constraints.maxHeight;
_widgetWidth = width;
_widgetHeight = height;
_burstOrigin = Offset(width / 2, height / 2);
```

---

## Post-Design Constitution Re-Check

All 10 principles confirmed compliant after design. One documented exception (Principle III / particles) is justified and recorded in Complexity Tracking above. No gate violations. Proceed to `/speckit.tasks`.

# Research: Custom Painting & Decoration Hooks (F013)

**Branch**: `012-custom-painter` | **Date**: 2026-03-01

---

## D1 — `SwipePainterCallback` invocation pattern

**Decision**: `typedef SwipePainterCallback = CustomPainter Function(SwipeProgress progress, SwipeState state)` — called inside the existing `AnimatedBuilder` each frame; return value passed directly to `CustomPaint(painter:)`.

**Rationale**: The `AnimatedBuilder` wrapping `_controller` already rebuilds every frame. Reusing the same rebuild cycle avoids an extra listener layer. Returning a fresh `CustomPainter` per rebuild matches Flutter's own `CustomPaint` API contract; `shouldRepaint` on the returned painter short-circuits actual canvas operations when nothing changed.

**Alternatives considered**:
- Stateful painter with `ValueNotifier<SwipeProgress>` as repaint trigger — more complex, requires lifecycle management inside `SwipeActionCellState`; rejected for simplicity.
- `Listenable`-based repaint on the painter itself — works but diverges from the F002 builder pattern the consumer already knows.

---

## D2 — Decoration interpolation strategy

**Decision**: `Decoration.lerp(resting, activated, t)` where `t = progress.ratio.clamp(0.0, 1.0)`. If `Decoration.lerp` returns `null` (incompatible decoration types), fall back silently to `restingDecoration`. Activated decoration `null` → resting applied permanently with no lerp attempt.

**Rationale**: `Decoration.lerp` is the canonical Flutter API for blending decorations. Graceful fallback on `null` result handles mixed-type decorations (e.g., `BoxDecoration` vs `ShapeDecoration`) without crashing. This matches the clarification in `spec.md` (checklist notes, FR-012-006).

**Alternatives considered**:
- Force `BoxDecoration` only and use `BoxDecoration.lerp` — more predictable but narrows consumer API unnecessarily; rejected.
- Throw on incompatible types — violates zero-crash contract; rejected.

---

## D3 — Painter error handling

**Decision**: Wrap `CustomPainter.paint()` invocation in `try`/`catch` inside `SwipeActionCellState._buildPainterLayer()`. In `kDebugMode`: rethrow. In release: skip the paint call for that frame (layer is blank); log via `FlutterError.reportError`.

**Rationale**: Matches Flutter's own pattern for builder callbacks (`ListView.builder`, `AnimatedBuilder`). Prevents production crashes while giving developers immediate, visible failure signals. Using `FlutterError.reportError` ensures the error appears in Flutter DevTools error panels even in profile mode.

**Alternatives considered**:
- Always rethrow — consumer responsibility; rejected because painter errors crash the entire widget tree.
- Always suppress silently — hides bugs during development; rejected.

---

## D4 — `SwipeMorphIcon` implementation

**Decision**: Pure `StatelessWidget` using a `Stack` of two icons with `Opacity` transitions. Icon 1: `opacity = 1.0 - progress`. Icon 2: `opacity = progress`. Uses `IgnorePointer` on both icons to prevent stale tap targets during morph.

**Rationale**: No `AnimationController` needed — progress is driven externally by the consumer. The cross-fade is a direct function of `progress`, so `StatelessWidget` + `Opacity` is the correct Flutter pattern. No separate animation lifecycle to manage.

**Alternatives considered**:
- `AnimatedOpacity` — requires tween interpolation, adds unnecessary internal state; rejected.
- `CrossFade` from Flutter — more complex, manages two child widgets with visibility; rejected for simplicity.

---

## D5 — Particle burst architecture

**Decision**: Inline particle fields into `SwipeActionCellState`:
- `AnimationController? _particleController` — drives burst animation (fixed-duration, NOT spring)
- `List<_Particle>? _particles` — generated at burst start; `_Particle(angle, distance, color)`
- `Offset _burstOrigin` — center of cell (derived from `_widgetWidth / 2, height / 2`)
- `SwipeParticlePainter extends CustomPainter` — internal, draws particles from `_particles` using `_particleController.value`

**Rationale**: Mirrors the F011 undo pattern (inline `Timer` + `AnimationController`). Keeps particle state colocated with the widget state that triggers it. `Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: SwipeParticlePainter(...))))` is the lightest render-layer approach.

**Alternatives considered**:
- Separate `SwipeParticleBurst` widget — cleaner in isolation, but requires parent-to-child communication mechanism; rejected for consistency with undo pattern.
- `TickerProvider`-based standalone widget with internal controller — adds widget depth; rejected.

---

## D6 — Constitution III exception: particle animation uses fixed-duration controller

**Decision**: Particle burst uses `AnimationController` with a fixed `duration` (from `ParticleConfig.duration`), NOT `SpringSimulation`. This is a justified exception to Constitution III.

**Rationale**: Spring physics are mandated for "swipe interaction feedback" (gesture-driven, bidirectional). A particle burst is a one-shot decorative effect that:
1. Cannot be meaningfully modeled as a spring (particles spread outward on a trajectory — there is no equilibrium they snap to)
2. Is not gesture-driven (fires once after action completion)
3. Is explicitly opt-in and visually decorative (disabled by default)

This exception is documented in `plan.md` Complexity Tracking.

**Alternatives considered**:
- Force spring physics on particles — would require an artificial equilibrium point; makes the physics wrong and the visual worse; rejected.

---

## D7 — Layer ordering in `Stack`

**Decision**: New layer insertion points in `SwipeActionCellState.build()`:

```
Stack children (bottom → top):
  1. [NEW] Background painter  →  Positioned.fill(IgnorePointer(CustomPaint(painter: bg)))
  2. [EXISTING] F002 background widget  →  Positioned.fill(_buildBackground(...))
  3. [EXISTING] Reveal panel
  4. [EXISTING] Confirm overlay
  5. [MODIFIED] Translated+decorated child  →  _buildDecoratedChild(translatedChild, progress)
  6. [EXISTING] Undo overlay (F011)
  7. [EXISTING] Progress indicator (F003)
  8. [NEW] Foreground painter  →  Positioned.fill(IgnorePointer(CustomPaint(painter: fg)))
  9. [NEW] Particle burst  →  Positioned.fill(IgnorePointer(CustomPaint(painter: particles)))
```

**Rationale**: Background painter must be below F002 background (spec FR-012-003). Foreground painter must be above all content. Operational overlays (undo, progress indicator) are kept above the foreground painter because they are interactive/informational, not visual decoration. Particles render above the foreground painter to avoid being obscured by it. All new layers use `IgnorePointer` to preserve hit testing (FR-012-004).

**Alternatives considered**:
- Putting particles below foreground painter — particles would be hidden by foreground effects; rejected.
- Not using `IgnorePointer` — breaks hit testing on child; rejected.

---

## D8 — Zero-overhead guard

**Decision**: All new painting layers are guarded with `if` conditions on `paintingConfig` nullability:
```dart
if (widget.paintingConfig?.backgroundPainter != null) ... // background layer
if (widget.paintingConfig?.foregroundPainter != null) ... // foreground layer
if (widget.paintingConfig?.restingDecoration != null || widget.paintingConfig?.activatedDecoration != null) ... // decoration
if (_particles != null) ... // particle layer
```

When `paintingConfig` is null, the guard prevents adding any children to the Stack, incurring zero `CustomPaint` overhead per frame (satisfies FR-012-010 and SC-012-003).

---

## D9 — `SwipePaintingConfig` and `SwipeActionCellTheme` relationship

**Decision**: `SwipePaintingConfig` is NOT added to `SwipeActionCellTheme` in this feature. It is a per-cell parameter only (`SwipeActionCell.paintingConfig`). Theme-level support deferred to F14/F15 if needed.

**Rationale**: `SwipeActionCellTheme` extension already has `rightSwipeConfig`, `leftSwipeConfig`, `gestureConfig`, `animationConfig`, `visualConfig`, `feedbackConfig`. Adding `paintingConfig` to the theme would make painting effects (particle colors, custom painters) apply to every cell in a subtree — a surprising and likely undesired default for decoration-level customizations. Per-cell scope is the safe default.

**Alternatives considered**:
- Add to theme immediately — higher risk of consumer surprise; deferred to polish phase.

---

## D10 — `SwipeMorphIcon` icon type: `Widget` not `IconData`

**Decision**: `startIcon` and `endIcon` accept `Widget`, not `IconData`.

**Rationale**: `Widget` is more flexible — consumers can morph between `Icon`, `SvgPicture`, `Image`, or any other icon-like widget. Using `IconData` would artificially limit the API to material/cupertino icons only. This aligns with the F002 `SwipeBackgroundBuilder` pattern (accepts `Widget icon`).

---

## Integration Points Summary

| Integration point | File | Change |
|---|---|---|
| New `paintingConfig` parameter | `lib/src/widget/swipe_action_cell.dart` | Add `final SwipePaintingConfig? paintingConfig` to `SwipeActionCell` |
| Background painter layer | `build()` in `SwipeActionCellState` | Insert as first Stack child |
| Decoration wrapping | `build()` in `SwipeActionCellState` | Wrap translated child in `DecoratedBox` |
| Foreground painter layer | `build()` in `SwipeActionCellState` | Append as second-to-last Stack child |
| Particle trigger | `_applyIntentionalAction()` in `SwipeActionCellState` | Call `_startParticleBurst()` after action fires |
| Particle layer | `build()` in `SwipeActionCellState` | Append as last Stack child when active |
| Particle init/dispose | `initState()`/`dispose()` | Create/dispose `_particleController` |
| Barrel export | `lib/swipe_action_cell.dart` | Export 3 new public files |

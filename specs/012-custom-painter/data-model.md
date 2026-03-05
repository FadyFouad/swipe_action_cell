# Data Model: Custom Painting & Decoration Hooks (F013)

**Branch**: `012-custom-painter` | **Date**: 2026-03-01

---

## Public Types

### `SwipePainterCallback` (typedef)

**File**: `lib/src/painting/swipe_painting_config.dart`

```dart
/// Signature for custom painter hooks attached to [SwipeActionCell].
///
/// Called every frame during any [SwipeState] phase. The returned
/// [CustomPainter] is passed directly to [CustomPaint]. Return a painter
/// whose [CustomPainter.shouldRepaint] reflects your repaint logic.
///
/// In debug mode, exceptions thrown by this callback propagate immediately.
/// In release mode, exceptions are caught and the paint layer is skipped
/// for that frame.
typedef SwipePainterCallback = CustomPainter Function(
  SwipeProgress progress,
  SwipeState state,
);
```

---

### `SwipePaintingConfig`

**File**: `lib/src/painting/swipe_painting_config.dart`

| Field | Type | Default | Description |
|---|---|---|---|
| `backgroundPainter` | `SwipePainterCallback?` | `null` | Painter rendered below F002 background widget. Null = no layer added. |
| `foregroundPainter` | `SwipePainterCallback?` | `null` | Painter rendered above child widget. Null = no layer added. Hit testing unaffected (IgnorePointer). |
| `restingDecoration` | `Decoration?` | `null` | Decoration applied to the cell at progress 0.0. |
| `activatedDecoration` | `Decoration?` | `null` | Decoration applied to the cell at progress 1.0. Null = resting decoration at all times. |
| `particleConfig` | `ParticleConfig?` | `null` | Particle burst configuration. Null = no particle animation (Constitution IX). |

**Constraints**:
- All fields nullable; all null = zero overhead (FR-012-010)
- Immutable with `const` constructor and `copyWith`
- When `paintingConfig` itself is `null` on `SwipeActionCell`, entire feature is disabled

**Relationships**:
- Lives alongside `SwipeVisualConfig` on `SwipeActionCell`; does not replace or extend it
- `backgroundPainter` renders below `SwipeVisualConfig.leftBackground`/`rightBackground`
- `foregroundPainter` renders above all content except operational overlays (undo, progress indicator)

---

### `ParticleConfig`

**File**: `lib/src/painting/particle_config.dart`

| Field | Type | Default | Description |
|---|---|---|---|
| `count` | `int` | `12` | Number of particles emitted per burst. 0 = no burst. |
| `colors` | `List<Color>` | `[Colors.amber, Colors.orange, Colors.red]` | Color palette. Particles cycle through this list. If empty, uses default palette. |
| `spreadAngle` | `double` | `360.0` | Total spread angle in degrees. 360 = all directions; 90 = cone. |
| `duration` | `Duration` | `Duration(milliseconds: 500)` | Total animation duration. Resources released within 100 ms of completion (SC-012-004). |

**Constraints**:
- `count >= 0` (0 = no animation, no overhead)
- `spreadAngle` in range (0.0, 360.0] — values ≤ 0 treated as 360 (full spread)
- `colors` empty list → fallback to default palette (edge case: no crash)
- Immutable with `const` constructor and `copyWith`

---

### `SwipeMorphIcon`

**File**: `lib/src/painting/swipe_morph_icon.dart`

| Field | Type | Description |
|---|---|---|
| `startIcon` | `Widget` | Icon shown at `progress = 0.0` (fully opaque). Accepts any Widget. |
| `endIcon` | `Widget` | Icon shown at `progress = 1.0` (fully opaque). Accepts any Widget. |
| `progress` | `double` | Blend value in [0.0, 1.0]. 0.0 = only startIcon visible; 1.0 = only endIcon visible; 0.5 = equal blend. |
| `size` | `double?` | Icon size in logical pixels. Applied via `IconTheme` to both icons. |
| `color` | `Color?` | Icon color. Applied via `IconTheme` to both icons. |

**Constraints**:
- `progress` clamped to [0.0, 1.0] internally
- `StatelessWidget` — no internal animation controller; progress is consumer-driven
- Does not require `paintingConfig` — usable standalone inside any F002 `SwipeBackgroundBuilder`
- Both icons use `IgnorePointer` to prevent stale tap targets

**Rendering**:
```
Stack [
  Opacity(opacity: 1.0 - progress, child: startIcon)
  Opacity(opacity: progress, child: endIcon)
]
```

---

## Internal Types (not exported)

### `_Particle`

**File**: `lib/src/painting/swipe_particle_painter.dart` (internal class)

| Field | Type | Description |
|---|---|---|
| `angle` | `double` | Emission angle in radians, random within `spreadAngle` range |
| `maxDistance` | `double` | Max pixel travel distance (random within [20, 60]) |
| `color` | `Color` | Selected from `ParticleConfig.colors` by cycling index |

**Note**: Particles are generated once at burst start, stored in `List<_Particle>?` on `SwipeActionCellState`. Cleared to `null` after `_particleController.dispose()`.

---

### `SwipeParticlePainter extends CustomPainter`

**File**: `lib/src/painting/swipe_particle_painter.dart` (internal)

| Field | Type | Description |
|---|---|---|
| `particles` | `List<_Particle>` | Particle data, set at burst start |
| `animationValue` | `double` | Current animation progress [0.0, 1.0] from `_particleController` |
| `origin` | `Offset` | Burst center point, computed as cell center |

**paint() algorithm**:
1. For each particle:
   - `distance = particle.maxDistance * animationValue`
   - `dx = cos(particle.angle) * distance`
   - `dy = sin(particle.angle) * distance`
   - `opacity = 1.0 - animationValue` (fades out as burst progresses)
   - `canvas.drawCircle(origin + Offset(dx, dy), 3.0, Paint()..color = particle.color.withOpacity(opacity))`

**shouldRepaint**: `animationValue != old.animationValue || origin != old.origin`

---

## State Extensions on `SwipeActionCellState`

| New field | Type | Lifecycle |
|---|---|---|
| `_particleController` | `AnimationController?` | Created in `initState()` if `paintingConfig?.particleConfig != null`; disposed in `dispose()` |
| `_particles` | `List<_Particle>?` | Generated in `_startParticleBurst()`; set to null after animation completes |
| `_burstOrigin` | `Offset` | Updated in `build()` as `Offset(_widgetWidth / 2, _widgetHeight / 2)` |
| `_widgetHeight` | `double` | Captured from `LayoutBuilder` (alongside existing `_widgetWidth`) |

---

## Layer Order (visual z-order in Stack)

```
Bottom
  │  1. Background painter    [NEW]  CustomPaint(painter: bgPainter)     IgnorePointer
  │  2. F002 background       [EXI]  _buildBackground(context, progress)
  │  3. Reveal panel          [EXI]  _buildRevealPanel(width)
  │  4. Confirm overlay       [EXI]  Positioned.fill GestureDetector
  │  5. Decorated child       [MOD]  DecoratedBox(decoration: lerped) wrapping Transform.translate(child)
  │  6. Undo overlay          [EXI]  SwipeUndoOverlay
  │  7. Progress indicator    [EXI]  _buildProgressIndicator()
  │  8. Foreground painter    [NEW]  CustomPaint(painter: fgPainter)     IgnorePointer
  │  9. Particle burst        [NEW]  CustomPaint(painter: particles)     IgnorePointer
Top
```

---

## Modified `SwipeActionCell` Constructor

New parameter added (alongside existing `undoConfig`):

```dart
const SwipeActionCell({
  // ... all existing params ...
  this.undoConfig,          // F011 (existing)
  this.paintingConfig,      // F013 (NEW)
});

final SwipePaintingConfig? paintingConfig;
```

---

## Barrel Export Additions (`lib/swipe_action_cell.dart`)

```dart
export 'src/painting/swipe_painting_config.dart';  // SwipePaintingConfig, SwipePainterCallback
export 'src/painting/particle_config.dart';         // ParticleConfig
export 'src/painting/swipe_morph_icon.dart';        // SwipeMorphIcon
```

`SwipeParticlePainter` and `_Particle` are internal — NOT exported.

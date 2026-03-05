# Public API Contract: Custom Painting & Decoration Hooks (F013)

**Branch**: `012-custom-painter` | **Date**: 2026-03-01

---

## Typedef: `SwipePainterCallback`

```dart
/// Signature for custom painter hooks attached to [SwipeActionCell].
///
/// Called every frame during all [SwipeState] phases (dragging,
/// animatingToOpen, animatingToClose, revealed, animatingOut).
///
/// The returned [CustomPainter] is passed to [CustomPaint]. Implement
/// [CustomPainter.shouldRepaint] to control repaint frequency.
///
/// **Error handling**: Exceptions thrown by this callback propagate
/// immediately in debug mode. In release mode, the paint layer is
/// silently skipped for that frame.
typedef SwipePainterCallback = CustomPainter Function(
  SwipeProgress progress,
  SwipeState state,
);
```

---

## Class: `SwipePaintingConfig`

```dart
/// Configuration for custom painters, decoration interpolation, and
/// particle burst effects on [SwipeActionCell].
///
/// Add to [SwipeActionCell.paintingConfig]. When `null`, the entire
/// feature is disabled with zero rendering overhead per frame.
///
/// See also:
/// - [SwipePainterCallback] for the painter hook signature.
/// - [ParticleConfig] for particle burst settings.
/// - [SwipeMorphIcon] for the built-in progress-driven icon widget.
@immutable
class SwipePaintingConfig {
  /// Creates a painting configuration.
  ///
  /// All parameters are optional. When all are null, [SwipeActionCell]
  /// incurs zero additional rendering overhead.
  const SwipePaintingConfig({
    this.backgroundPainter,
    this.foregroundPainter,
    this.restingDecoration,
    this.activatedDecoration,
    this.particleConfig,
  });

  /// Painter rendered as the lowest visual layer of the cell.
  ///
  /// Positioned below the F002 background widget. When null, no
  /// background paint layer is added to the render tree.
  final SwipePainterCallback? backgroundPainter;

  /// Painter rendered as the highest visual layer of the cell.
  ///
  /// Positioned above the child widget. Hit testing on the child
  /// and its interactive elements is unaffected (uses [IgnorePointer]).
  /// When null, no foreground paint layer is added to the render tree.
  final SwipePainterCallback? foregroundPainter;

  /// Decoration applied to the cell at swipe progress ratio 0.0.
  ///
  /// When [activatedDecoration] is non-null, the cell's decoration
  /// smoothly interpolates from this value toward [activatedDecoration]
  /// as swipe progress increases, across all SwipeState phases.
  final Decoration? restingDecoration;

  /// Decoration applied to the cell at swipe progress ratio 1.0.
  ///
  /// When null, [restingDecoration] is applied permanently without
  /// interpolation (no crash, no visual artifact).
  final Decoration? activatedDecoration;

  /// Configuration for an optional particle burst on intentional
  /// (left-swipe) action completion.
  ///
  /// When null, no particle animation plays and no overhead is incurred
  /// (Constitution IX: null config = feature disabled).
  final ParticleConfig? particleConfig;

  /// Returns a copy of this config with the given fields replaced.
  SwipePaintingConfig copyWith({
    SwipePainterCallback? backgroundPainter,
    SwipePainterCallback? foregroundPainter,
    Decoration? restingDecoration,
    Decoration? activatedDecoration,
    ParticleConfig? particleConfig,
  });

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;
}
```

---

## Class: `ParticleConfig`

```dart
/// Configuration for an optional particle burst effect triggered on
/// intentional (left-swipe) action completion.
///
/// Progressive (right-swipe) actions do NOT trigger the particle burst.
///
/// Provide via [SwipePaintingConfig.particleConfig]. A `null` value
/// on [SwipePaintingConfig] disables the feature entirely.
@immutable
class ParticleConfig {
  /// Creates a particle burst configuration.
  const ParticleConfig({
    this.count = 12,
    this.colors = const [Color(0xFFFFC107), Color(0xFFFF5722), Color(0xFFE91E63)],
    this.spreadAngle = 360.0,
    this.duration = const Duration(milliseconds: 500),
  });

  /// Number of particles emitted per burst.
  ///
  /// Must be ≥ 0. When 0, no animation is started and no overhead
  /// is incurred. Defaults to 12.
  final int count;

  /// Color palette for particles.
  ///
  /// Particles cycle through this list. When empty, a default
  /// palette of amber/orange/pink is used (no crash).
  final List<Color> colors;

  /// Total spread angle in degrees.
  ///
  /// 360.0 = particles spread in all directions.
  /// 90.0 = cone-shaped burst forward.
  /// Values ≤ 0 are treated as 360.0.
  /// Defaults to 360.0.
  final double spreadAngle;

  /// Total animation duration.
  ///
  /// All particle resources are released within 100 ms of this
  /// duration elapsing or widget disposal, whichever comes first.
  /// Defaults to 500 ms.
  final Duration duration;

  /// Returns a copy of this config with the given fields replaced.
  ParticleConfig copyWith({
    int? count,
    List<Color>? colors,
    double? spreadAngle,
    Duration? duration,
  });

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;
}
```

---

## Widget: `SwipeMorphIcon`

```dart
/// A widget that cross-fades between two icons based on a progress value.
///
/// Designed for use inside [SwipeVisualConfig] background builders (F002),
/// but usable as a standalone widget anywhere.
///
/// At [progress] 0.0, only [startIcon] is visible.
/// At [progress] 1.0, only [endIcon] is visible.
/// At [progress] 0.5, both icons are blended at equal weight.
///
/// Example:
/// ```dart
/// SwipeMorphIcon(
///   startIcon: const Icon(Icons.favorite_border),
///   endIcon: const Icon(Icons.favorite),
///   progress: swipeProgress.ratio,
/// )
/// ```
class SwipeMorphIcon extends StatelessWidget {
  /// Creates a [SwipeMorphIcon].
  const SwipeMorphIcon({
    super.key,
    required this.startIcon,
    required this.endIcon,
    required this.progress,
    this.size,
    this.color,
  });

  /// Widget displayed fully at [progress] = 0.0.
  ///
  /// Accepts any widget — [Icon], image, SVG, or custom widget.
  final Widget startIcon;

  /// Widget displayed fully at [progress] = 1.0.
  ///
  /// Accepts any widget — [Icon], image, SVG, or custom widget.
  final Widget endIcon;

  /// Blend value from 0.0 to 1.0. Clamped internally.
  ///
  /// 0.0 → only [startIcon] visible.
  /// 0.5 → both icons at equal opacity.
  /// 1.0 → only [endIcon] visible.
  final double progress;

  /// Icon size in logical pixels applied to both icons via [IconTheme].
  ///
  /// When null, the ambient [IconTheme] size is used.
  final double? size;

  /// Color applied to both icons via [IconTheme].
  ///
  /// When null, the ambient [IconTheme] color is used.
  final Color? color;

  @override
  Widget build(BuildContext context);
}
```

---

## `SwipeActionCell` — New Parameter

```dart
// Added alongside existing `undoConfig` parameter:

/// Configuration for custom painters, decoration interpolation, and
/// particle burst effects.
///
/// When null, the entire painting feature is disabled with zero
/// rendering overhead per frame.
///
/// See [SwipePaintingConfig] for details.
final SwipePaintingConfig? paintingConfig;
```

---

## Behavior Contracts

### Painter lifecycle

| Condition | Behavior |
|---|---|
| `paintingConfig` is null | Zero additional Stack children; zero paint calls |
| `backgroundPainter` is non-null | One extra `CustomPaint` below F002 background, updated every frame |
| `foregroundPainter` is non-null | One extra `CustomPaint` above child, wrapped in `IgnorePointer` |
| Painter callback throws (debug) | Exception propagates; developer sees failure |
| Painter callback throws (release) | Layer skipped for that frame; `FlutterError.reportError` called |

### Decoration interpolation

| Condition | Behavior |
|---|---|
| Both `restingDecoration` and `activatedDecoration` non-null | `Decoration.lerp(resting, activated, ratio.clamp(0,1))` applied every frame |
| Only `restingDecoration` non-null | `restingDecoration` applied permanently |
| `Decoration.lerp` returns null (incompatible types) | Falls back to `restingDecoration` silently |
| `ratio > 1.0` | Clamped to 1.0 before lerp; `activatedDecoration` displayed |

### Particle burst

| Condition | Behavior |
|---|---|
| `particleConfig` is null | No burst, no overhead |
| `particleConfig.count == 0` | No burst, no animation started |
| Intentional (left-swipe) action completes | Burst starts immediately at cell center |
| Progressive (right-swipe) action completes | No burst |
| Animation completes | `_particles` cleared; `_particleController.reset()` |
| Widget disposed during burst | `_particleController.dispose()`; all resources released within 100 ms |
| `particleConfig.colors` is empty | Default palette applied |

### Hit testing

| Condition | Behavior |
|---|---|
| `backgroundPainter` active | Wrapped in `IgnorePointer`; zero impact on child hit testing |
| `foregroundPainter` active | Wrapped in `IgnorePointer`; zero impact on child hit testing |
| Particle burst active | Wrapped in `IgnorePointer`; zero impact on child hit testing |

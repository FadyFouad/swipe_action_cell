# Widget API Contract: Foundational Gesture & Spring Animation

**Feature**: 001-gesture-animation
**Date**: 2026-02-25
**Package**: `swipe_action_cell`
**Public entry point**: `package:swipe_action_cell/swipe_action_cell.dart`

This document defines the complete public API surface introduced by this feature. It is the
contract that tests, consumers, and future features depend on. Implementations MUST conform to
these signatures exactly.

---

## Enums (already scaffolded — verify and supplement)

### `SwipeDirection`

```dart
/// Represents the directional intent of a swipe gesture.
enum SwipeDirection {
  /// Swipe toward the left edge.
  left,
  /// Swipe toward the right edge.
  right,
  /// No direction determined yet (idle or within lock window).
  none,
}
```

**Location**: `lib/src/core/swipe_direction.dart`
**Export**: `lib/swipe_action_cell.dart`
**Status**: Exists — no changes needed.

---

### `SwipeState`

```dart
/// The lifecycle phase of the swipe interaction state machine.
enum SwipeState {
  /// Widget is at rest; no active gesture or animation.
  idle,
  /// User is actively dragging.
  dragging,
  /// Animating toward the fully-extended (revealed) position.
  animatingToOpen,
  /// Animating back to the origin (closed) position.
  animatingToClose,
  /// Settled at the fully-extended position.
  revealed,
}
```

**Location**: `lib/src/core/swipe_state.dart`
**Export**: `lib/swipe_action_cell.dart`
**Status**: Exists — no changes needed.

---

## Data Classes

### `SwipeProgress` *(supplement existing)*

```dart
/// An immutable snapshot of swipe gesture progress at a point in time.
@immutable
class SwipeProgress {
  const SwipeProgress({
    required this.direction,
    required this.ratio,
    required this.isActivated,
    required this.rawOffset,
  });

  /// The locked swipe direction, or [SwipeDirection.none] before direction is determined.
  final SwipeDirection direction;

  /// Progress ratio from 0.0 (origin) to 1.0 (max translation). Always in [0.0, 1.0].
  final double ratio;

  /// Whether the swipe has passed the activation threshold.
  /// When `true`, releasing will trigger the completion animation.
  final bool isActivated;

  /// Signed pixel offset from the origin. Positive = right, negative = left.
  final double rawOffset;

  /// Represents no swipe in progress (idle state).
  static const SwipeProgress zero = SwipeProgress(
    direction: SwipeDirection.none,
    ratio: 0.0,
    isActivated: false,
    rawOffset: 0.0,
  );

  /// Returns a copy of this progress with the given fields replaced.
  SwipeProgress copyWith({
    SwipeDirection? direction,
    double? ratio,
    bool? isActivated,
    double? rawOffset,
  });

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;

  @override
  String toString();
}
```

**Location**: `lib/src/core/swipe_progress.dart`
**Export**: `lib/swipe_action_cell.dart`
**Status**: Exists — add `copyWith`, `==`, `hashCode`, `toString`.

---

### `SpringConfig` *(new)*

```dart
/// Physics parameters for a single spring animation.
///
/// Maps directly to [SpringDescription]. Use [copyWith] to adjust individual
/// parameters without recreating the entire config.
@immutable
class SpringConfig {
  /// Creates a [SpringConfig] with the given spring physics parameters.
  ///
  /// All parameters must be positive.
  const SpringConfig({
    this.mass = 1.0,
    this.stiffness = 500.0,
    this.damping = 28.0,
  });

  /// Simulated mass of the dragged object. Higher mass = slower response.
  /// Must be > 0. Default: 1.0.
  final double mass;

  /// Spring constant (k). Higher stiffness = snappier animation.
  /// Must be > 0. Default: 500.0.
  final double stiffness;

  /// Damping coefficient. Critical damping = 2 * sqrt(mass * stiffness).
  /// Values below critical produce a subtle bounce (underdamped).
  /// Values at or above critical produce a smooth return (overdamped).
  /// Default: 28.0 (slightly underdamped for stiffness=500).
  final double damping;

  /// A preset for snap-back animations: responsive but not jarring.
  /// mass=1.0, stiffness=400.0, damping=25.0
  static const SpringConfig snapBack = SpringConfig(
    stiffness: 400.0,
    damping: 25.0,
  );

  /// A preset for completion animations: snappy and decisive.
  /// mass=1.0, stiffness=600.0, damping=32.0
  static const SpringConfig completion = SpringConfig(
    stiffness: 600.0,
    damping: 32.0,
  );

  /// Returns a copy of this config with the specified fields replaced.
  SpringConfig copyWith({double? mass, double? stiffness, double? damping});

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;
}
```

**Location**: `lib/src/animation/spring_config.dart`
**Export**: `lib/swipe_action_cell.dart`

---

## Configuration Objects

### `SwipeGestureConfig` *(new)*

```dart
/// Configuration for horizontal drag gesture recognition.
///
/// Controls when a gesture is recognized, which directions are active,
/// and the fling velocity threshold.
@immutable
class SwipeGestureConfig {
  /// Creates a gesture configuration.
  ///
  /// All parameters have sensible defaults; passing no arguments produces
  /// the standard swipe behavior.
  const SwipeGestureConfig({
    this.deadZone = 12.0,
    this.enabledDirections = const {SwipeDirection.left, SwipeDirection.right},
    this.velocityThreshold = 700.0,
  });

  /// Minimum horizontal displacement (logical pixels) before a swipe is recognized.
  ///
  /// Prevents accidental triggers from taps. Default: 12.0.
  /// Must be ≥ 0.0. A value of 0.0 removes the dead zone entirely.
  final double deadZone;

  /// The set of swipe directions this cell responds to.
  ///
  /// Removing a direction from this set disables all gesture recognition,
  /// visual motion, and state transitions for that direction.
  /// Default: both left and right are enabled.
  final Set<SwipeDirection> enabledDirections;

  /// Minimum release velocity (logical pixels/second) to trigger completion
  /// via fling, regardless of how far the user dragged.
  ///
  /// Default: 700.0. Must be > 0.0.
  final double velocityThreshold;

  /// Returns a copy of this config with the specified fields replaced.
  SwipeGestureConfig copyWith({
    double? deadZone,
    Set<SwipeDirection>? enabledDirections,
    double? velocityThreshold,
  });

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;
}
```

**Location**: `lib/src/gesture/swipe_gesture_config.dart`
**Export**: `lib/swipe_action_cell.dart`

---

### `SwipeAnimationConfig` *(new)*

```dart
/// Configuration for swipe animation physics and thresholds.
///
/// Controls how the cell moves during drag and which spring is used for
/// each release outcome.
@immutable
class SwipeAnimationConfig {
  /// Creates an animation configuration.
  ///
  /// All parameters have sensible defaults suitable for most use cases.
  const SwipeAnimationConfig({
    this.activationThreshold = 0.4,
    this.snapBackSpring = SpringConfig.snapBack,
    this.completionSpring = SpringConfig.completion,
    this.resistanceFactor = 0.55,
    this.maxTranslationLeft,
    this.maxTranslationRight,
  });

  /// The progress ratio at which a drag release triggers the completion
  /// animation rather than snap-back. Range: (0.0, 1.0). Default: 0.4.
  ///
  /// Example: 0.4 means the user must drag 40% of [maxTranslation] before
  /// release is treated as a confirmed swipe.
  final double activationThreshold;

  /// Spring physics used when the cell snaps back to the origin.
  ///
  /// Applied on drag release below [activationThreshold] (and no fling).
  /// Default: [SpringConfig.snapBack].
  final SpringConfig snapBackSpring;

  /// Spring physics used when the cell animates to the revealed position.
  ///
  /// Applied on drag release at or above [activationThreshold], or on fling.
  /// Default: [SpringConfig.completion].
  final SpringConfig completionSpring;

  /// Controls drag resistance near the maximum translation bound.
  ///
  /// Uses an iOS-style logarithmic rubber-band formula:
  /// - 0.0: hard clamp at [maxTranslation] (no rubber-band effect).
  /// - 0.55: iOS-like feel (recommended default).
  /// - 1.0: maximum resistance (cell barely moves past the bound).
  ///
  /// Default: 0.55.
  final double resistanceFactor;

  /// Maximum drag extent in the left direction (logical pixels).
  ///
  /// When `null`, defaults to 60% of the widget's rendered width after layout.
  /// When `0.0`, the left direction is treated as disabled.
  final double? maxTranslationLeft;

  /// Maximum drag extent in the right direction (logical pixels).
  ///
  /// When `null`, defaults to 60% of the widget's rendered width after layout.
  /// When `0.0`, the right direction is treated as disabled.
  final double? maxTranslationRight;

  /// Returns a copy of this config with the specified fields replaced.
  SwipeAnimationConfig copyWith({
    double? activationThreshold,
    SpringConfig? snapBackSpring,
    SpringConfig? completionSpring,
    double? resistanceFactor,
    double? maxTranslationLeft,
    double? maxTranslationRight,
  });

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;
}
```

**Location**: `lib/src/animation/swipe_animation_config.dart`
**Export**: `lib/swipe_action_cell.dart`

---

## Main Widget

### `SwipeActionCell` *(replace skeleton)*

```dart
/// A widget that wraps any child and provides spring-based horizontal swipe interaction.
///
/// [SwipeActionCell] uses asymmetric swipe semantics:
/// - **Right swipe (forward):** Progressive/incremental action intent.
/// - **Left swipe (backward):** Intentional committed action intent.
///
/// Gesture and animation behavior are fully configurable via [gestureConfig]
/// and [animationConfig]. Both left and right swipe directions can be
/// independently enabled or disabled.
///
/// The widget is uncontrolled by default — internal state manages the swipe
/// lifecycle automatically. Observe state changes via [onStateChanged] and
/// [onProgressChanged], or drive custom visuals via [swipeOffsetListenable].
///
/// Example:
/// ```dart
/// SwipeActionCell(
///   child: ListTile(title: Text('Swipeable item')),
///   onStateChanged: (state) => print('State: $state'),
/// )
/// ```
class SwipeActionCell extends StatefulWidget {
  /// Creates a [SwipeActionCell].
  const SwipeActionCell({
    super.key,
    required this.child,
    this.gestureConfig = const SwipeGestureConfig(),
    this.animationConfig = const SwipeAnimationConfig(),
    this.onStateChanged,
    this.onProgressChanged,
    this.enabled = true,
  });

  /// The widget displayed inside the swipe cell.
  ///
  /// Can be any widget. [SwipeActionCell] imposes no layout constraints on it.
  final Widget child;

  /// Configuration for gesture recognition behavior.
  ///
  /// Controls dead zone, enabled directions, and fling velocity threshold.
  /// Defaults to standard swipe behavior with both directions enabled.
  final SwipeGestureConfig gestureConfig;

  /// Configuration for animation physics.
  ///
  /// Controls spring parameters, activation threshold, resistance, and
  /// maximum translation extents. Defaults to sensible physics presets.
  final SwipeAnimationConfig animationConfig;

  /// Called whenever the swipe state machine transitions to a new state.
  ///
  /// Fired on the frame the state changes. Not called if [enabled] is false.
  final ValueChanged<SwipeState>? onStateChanged;

  /// Called on every frame during a drag with the current swipe progress.
  ///
  /// Use this to drive background visuals or progress indicators.
  /// Not called if [enabled] is false.
  final ValueChanged<SwipeProgress>? onProgressChanged;

  /// Whether swipe interactions are active.
  ///
  /// When `false`, the cell renders [child] without any gesture interception
  /// and ignores all configuration. Defaults to `true`.
  final bool enabled;
}
```

**Location**: `lib/src/widget/swipe_action_cell.dart`
**Export**: `lib/swipe_action_cell.dart`

#### State-accessible listenable (test surface)

The `_SwipeActionCellState` MUST expose a `ValueListenable<double>` that is accessible via a
key for test purposes. This enables `flutter_test` to observe the raw pixel offset without
inspecting `RenderObject` matrices.

```dart
// In _SwipeActionCellState:
/// Read-only observable of the current horizontal pixel offset.
/// Exposed for widget testing via a GlobalKey.
ValueListenable<double> get swipeOffsetListenable => _controller;
```

---

## Barrel Exports

All new public types MUST be added to `lib/swipe_action_cell.dart`:

```dart
// New exports for this feature:
export 'src/animation/spring_config.dart';
export 'src/animation/swipe_animation_config.dart';
export 'src/gesture/swipe_gesture_config.dart';
// Updated (SwipeProgress gains copyWith/==/hashCode, SwipeActionCell gains full implementation):
// Already exported: swipe_direction, swipe_state, swipe_progress, swipe_action_cell
```

---

## Breaking Changes

None. This feature replaces the stub implementation of `SwipeActionCell` with a full
implementation. The existing `enabled` parameter is preserved. New parameters all have defaults,
so existing code that constructs `SwipeActionCell(child: ...)` continues to compile.

The scaffold's `SwipeActionCell` exposes `enabled` — this is preserved and its semantics
are unchanged.

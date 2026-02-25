# Widget API Contract: Right-Swipe Progressive Action

**Feature**: 003-progressive-swipe
**Date**: 2026-02-25
**Package**: `swipe_action_cell`
**Public entry point**: `package:swipe_action_cell/swipe_action_cell.dart`

This document defines the complete public API surface introduced and updated by this feature.
Implementations MUST conform to these signatures. Tests and downstream features depend on them.

---

## New Enum

### `OverflowBehavior`

```dart
/// Determines what happens when a progressive swipe step would push the
/// cumulative value beyond [ProgressiveSwipeConfig.maxValue].
enum OverflowBehavior {
  /// Clamps the value at [ProgressiveSwipeConfig.maxValue].
  ///
  /// Further swipes are accepted visually but produce no value change.
  /// [ProgressiveSwipeConfig.onMaxReached] fires on each clamped swipe.
  clamp,

  /// Resets the value to [ProgressiveSwipeConfig.minValue] when [maxValue]
  /// would be exceeded.
  ///
  /// [ProgressiveSwipeConfig.onMaxReached] fires before the value wraps.
  wrap,

  /// Allows the value to grow without restriction.
  ///
  /// [ProgressiveSwipeConfig.onMaxReached] never fires in this mode.
  ignore,
}
```

**Location**: `lib/src/actions/progressive/overflow_behavior.dart`
**Export**: `lib/swipe_action_cell.dart`

---

## New Configuration Objects

### `ProgressIndicatorConfig`

```dart
/// Appearance configuration for the persistent progress bar rendered on the
/// leading edge of a [SwipeActionCell] when
/// [ProgressiveSwipeConfig.showProgressIndicator] is `true`.
@immutable
class ProgressIndicatorConfig {
  /// Creates a [ProgressIndicatorConfig].
  const ProgressIndicatorConfig({
    this.color = const Color(0xFF4CAF50),
    this.width = 4.0,
    this.backgroundColor,
    this.borderRadius,
  }) : assert(width > 0.0, 'width must be positive');

  /// Fill color of the progress bar. Default: green (0xFF4CAF50).
  final Color color;

  /// Width of the progress bar in logical pixels. Default: 4.0. Must be > 0.
  final double width;

  /// Optional background (track) color rendered at full height behind the fill.
  ///
  /// When `null`, no background is painted.
  final Color? backgroundColor;

  /// Optional corner radius applied to both the fill and background rects.
  final BorderRadius? borderRadius;

  /// Returns a copy with the specified fields replaced.
  ProgressIndicatorConfig copyWith({
    Color? color,
    double? width,
    Color? backgroundColor,
    BorderRadius? borderRadius,
  });

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;
}
```

**Location**: `lib/src/actions/progressive/progress_indicator_config.dart`
**Export**: `lib/swipe_action_cell.dart`

---

### `ProgressiveSwipeConfig`

```dart
/// Configuration for right-swipe progressive (incremental) action behavior.
///
/// Pass as [SwipeActionCell.rightSwipe] to enable progressive right-swipe
/// semantics. When `null`, right-swipe progressive behavior is disabled entirely.
///
/// **Controlled vs uncontrolled mode**:
/// - **Uncontrolled** (default): [value] is `null`. The widget manages its own
///   internal state starting from [initialValue]. No external setup required.
/// - **Controlled**: [value] is non-null. The widget displays the provided value
///   and does NOT self-update. The developer must update [value] in response to
///   [onProgressChanged] callbacks.
///
/// Example — uncontrolled:
/// ```dart
/// SwipeActionCell(
///   child: ListTile(title: Text('Tap to add')),
///   rightSwipe: ProgressiveSwipeConfig(
///     stepValue: 1.0,
///     maxValue: 10.0,
///     overflowBehavior: OverflowBehavior.clamp,
///     onProgressChanged: (newVal, oldVal) => print('Value: $newVal'),
///   ),
/// )
/// ```
///
/// Example — controlled:
/// ```dart
/// SwipeActionCell(
///   child: ListTile(title: Text('Counter: $_count')),
///   rightSwipe: ProgressiveSwipeConfig(
///     value: _count.toDouble(),    // non-null → controlled mode
///     maxValue: 10.0,
///     onProgressChanged: (newVal, _) => setState(() => _count = newVal.toInt()),
///   ),
/// )
/// ```
@immutable
class ProgressiveSwipeConfig {
  /// Creates a [ProgressiveSwipeConfig].
  ///
  /// If [showProgressIndicator] is `true`, [maxValue] must be finite.
  /// If [dynamicStep] is provided, it overrides [stepValue].
  const ProgressiveSwipeConfig({
    this.value,
    this.initialValue = 0.0,
    this.stepValue = 1.0,
    this.maxValue = double.infinity,
    this.minValue = 0.0,
    this.overflowBehavior = OverflowBehavior.clamp,
    this.dynamicStep,
    this.showProgressIndicator = false,
    this.progressIndicatorConfig,
    this.enableHaptic = false,
    this.onProgressChanged,
    this.onMaxReached,
    this.onSwipeStarted,
    this.onSwipeCompleted,
    this.onSwipeCancelled,
  }) : assert(stepValue > 0.0, 'stepValue must be > 0'),
       assert(minValue < maxValue, 'minValue must be < maxValue');

  /// The externally-managed progress value.
  ///
  /// When non-null, activates **controlled mode**: the widget displays this value
  /// and does not maintain its own internal state. The developer is responsible
  /// for updating this value in response to [onProgressChanged].
  ///
  /// When `null`, the widget operates in **uncontrolled mode** and manages its
  /// own state starting from [initialValue].
  final double? value;

  /// The initial cumulative value in uncontrolled mode.
  ///
  /// Silently clamped to `[minValue, maxValue]` on widget initialization.
  /// Ignored in controlled mode (where [value] is the source of truth).
  /// Default: 0.0.
  final double initialValue;

  /// The fixed amount added to the cumulative value on each successful swipe.
  ///
  /// Used when [dynamicStep] is `null`. Must be > 0. Default: 1.0.
  final double stepValue;

  /// The upper bound for the cumulative value.
  ///
  /// When [showProgressIndicator] is `true`, this must be finite.
  /// Default: `double.infinity` (unbounded).
  final double maxValue;

  /// The lower bound and wrap-target for the cumulative value.
  ///
  /// Used as the reset value when [overflowBehavior] is [OverflowBehavior.wrap].
  /// Must be < [maxValue]. Default: 0.0.
  final double minValue;

  /// How to handle a step that would push the value beyond [maxValue].
  ///
  /// Default: [OverflowBehavior.clamp].
  final OverflowBehavior overflowBehavior;

  /// A callback that returns the step size for the next swipe.
  ///
  /// Receives the current cumulative value and returns the step to apply.
  /// When set, overrides [stepValue]. A return value of ≤ 0 is treated as a
  /// no-op for that swipe (value unchanged).
  ///
  /// Example — 10% increment of current value:
  /// ```dart
  /// dynamicStep: (current) => current * 0.1,
  /// ```
  final DynamicStepCallback? dynamicStep;

  /// Whether to render a persistent progress bar on the leading edge of the cell.
  ///
  /// When `true`, [maxValue] must be finite (required for percentage calculation).
  /// The indicator updates whenever the cumulative value changes.
  /// Default: `false`.
  final bool showProgressIndicator;

  /// Appearance configuration for the progress indicator.
  ///
  /// When `null` and [showProgressIndicator] is `true`, default appearance is used.
  final ProgressIndicatorConfig? progressIndicatorConfig;

  /// Whether haptic feedback is triggered at swipe milestones.
  ///
  /// When `true`:
  /// - Light haptic fires once when the drag crosses the activation threshold.
  /// - Medium haptic fires on each successful increment.
  ///
  /// Default: `false`.
  final bool enableHaptic;

  /// Called when the cumulative value changes after a successful swipe.
  ///
  /// Fires with the already-constrained values (overflow policy applied).
  /// In controlled mode, fires but the widget does NOT self-update.
  /// Signature: `void Function(double newValue, double oldValue)`.
  final ProgressChangeCallback? onProgressChanged;

  /// Called when the value reaches or would exceed [maxValue].
  ///
  /// Only fires for [OverflowBehavior.clamp] and [OverflowBehavior.wrap].
  /// Does not fire for [OverflowBehavior.ignore].
  final VoidCallback? onMaxReached;

  /// Called when the right swipe direction is locked during a drag.
  ///
  /// Fires at the earliest point a gesture is confirmed as a right swipe.
  final VoidCallback? onSwipeStarted;

  /// Called after a successful swipe animation settles.
  ///
  /// Receives the new cumulative value (post-overflow-policy).
  /// Fires regardless of whether the value actually changed (e.g., clamped at max).
  final ValueChanged<double>? onSwipeCompleted;

  /// Called when a right swipe is released below the activation threshold.
  ///
  /// No value change occurs when this fires.
  final VoidCallback? onSwipeCancelled;

  /// Returns a copy with the specified fields replaced.
  ProgressiveSwipeConfig copyWith({
    double? value,
    double? initialValue,
    double? stepValue,
    double? maxValue,
    double? minValue,
    OverflowBehavior? overflowBehavior,
    DynamicStepCallback? dynamicStep,
    bool? showProgressIndicator,
    ProgressIndicatorConfig? progressIndicatorConfig,
    bool? enableHaptic,
    ProgressChangeCallback? onProgressChanged,
    VoidCallback? onMaxReached,
    VoidCallback? onSwipeStarted,
    ValueChanged<double>? onSwipeCompleted,
    VoidCallback? onSwipeCancelled,
  });

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;
}
```

**Location**: `lib/src/actions/progressive/progressive_swipe_config.dart`
**Export**: `lib/swipe_action_cell.dart`

---

## New Widget

### `ProgressiveSwipeIndicator`

```dart
/// A progress bar rendered as a filled vertical bar on a cell edge.
///
/// Intended for internal use by [SwipeActionCell] when
/// [ProgressiveSwipeConfig.showProgressIndicator] is `true`.
/// May also be used directly for custom layouts.
///
/// The bar grows from the bottom upward proportionally to [fillRatio].
class ProgressiveSwipeIndicator extends StatelessWidget {
  /// Creates a [ProgressiveSwipeIndicator].
  const ProgressiveSwipeIndicator({
    super.key,
    required this.fillRatio,
    this.config = const ProgressIndicatorConfig(),
  }) : assert(fillRatio >= 0.0 && fillRatio <= 1.0,
            'fillRatio must be in [0.0, 1.0]');

  /// Proportion of the indicator filled. Range: [0.0, 1.0].
  ///
  /// Typically computed as `(currentValue / maxValue).clamp(0.0, 1.0)`.
  final double fillRatio;

  /// Visual appearance configuration.
  final ProgressIndicatorConfig config;
}
```

**Location**: `lib/src/actions/progressive/progressive_swipe_indicator.dart`
**Export**: `lib/swipe_action_cell.dart`

---

## Updated Widget

### `SwipeActionCell` *(additive — no breaking changes)*

One new parameter added. All existing parameters and defaults are unchanged.

```dart
class SwipeActionCell extends StatefulWidget {
  const SwipeActionCell({
    super.key,
    required this.child,
    this.gestureConfig = const SwipeGestureConfig(),
    this.animationConfig = const SwipeAnimationConfig(),
    this.onStateChanged,
    this.onProgressChanged,
    this.enabled = true,
    this.leftBackground,
    this.rightBackground,
    this.clipBehavior = Clip.hardEdge,
    this.borderRadius,
    this.rightSwipe,         // NEW
  });

  // ... existing fields unchanged ...

  /// Configuration for right-swipe progressive (incremental) action behavior.
  ///
  /// When non-null, right swipes past the activation threshold increment the
  /// cumulative progress value according to [ProgressiveSwipeConfig].
  ///
  /// When `null` (default), the progressive feature is disabled entirely and
  /// right-swipe behavior is governed solely by [gestureConfig] and
  /// [animationConfig] as in F001/F002.
  ///
  /// Setting [rightSwipe] to a non-null value changes the right-swipe state
  /// machine path: instead of transitioning to [SwipeState.revealed], the cell
  /// increments its value and snaps back to [SwipeState.idle].
  final ProgressiveSwipeConfig? rightSwipe;
}
```

**Location**: `lib/src/widget/swipe_action_cell.dart`
**Export**: `lib/swipe_action_cell.dart` (already exported)

---

## Updated Typedefs

The following typedefs already exist in `lib/src/core/typedefs.dart` and are used by
`ProgressiveSwipeConfig`. No changes needed — they were pre-defined in F001:

```dart
/// Signature for dynamic step-size calculation.
typedef DynamicStepCallback = double Function(double currentValue);

/// Signature for progress change notifications on progressive (right) swipes.
typedef ProgressChangeCallback = void Function(double newValue, double oldValue);
```

**Status**: Exists — no changes needed.

---

## New Barrel Exports

Add to `lib/swipe_action_cell.dart`:

```dart
// Progressive action (003-progressive-swipe)
export 'src/actions/progressive/overflow_behavior.dart';
export 'src/actions/progressive/progress_indicator_config.dart';
export 'src/actions/progressive/progressive_swipe_config.dart';
export 'src/actions/progressive/progressive_swipe_indicator.dart';
```

---

## Breaking Changes

**None.** The `rightSwipe` parameter defaults to `null`, preserving all existing behavior.
`SwipeActionCell(child: myWidget)` continues to compile and behave exactly as in F001/F002.

# Contract: Consolidated Configuration API (F005)

**Branch**: `005-config-api` | **Date**: 2026-02-26
**Spec**: [spec.md](../spec.md) | **Data Model**: [data-model.md](../data-model.md)

This document defines the complete public Dart API surface for F005. All signatures are
normative — implementation MUST match exactly. Internal helpers are not listed here.

---

## `lib/src/config/right_swipe_config.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../core/typedefs.dart';
import '../actions/progressive/overflow_behavior.dart';
import '../actions/progressive/progress_indicator_config.dart';

/// Configuration for right-swipe progressive (incremental) action behavior.
///
/// Pass as [SwipeActionCell.rightSwipeConfig] to enable progressive right-swipe
/// semantics. When `null`, right-swipe progressive behavior is disabled entirely.
///
/// Renamed from `ProgressiveSwipeConfig` in F005. All fields and semantics are
/// preserved.
@immutable
class RightSwipeConfig {
  /// Creates a [RightSwipeConfig].
  const RightSwipeConfig({
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
  })  : assert(stepValue > 0.0, 'stepValue must be > 0, got $stepValue'),
        assert(
          minValue < maxValue,
          'minValue ($minValue) must be < maxValue ($maxValue)',
        );

  /// The externally-managed progress value (controlled mode).
  final double? value;

  /// The initial cumulative value in uncontrolled mode.
  final double initialValue;

  /// The fixed amount added on each successful swipe. Must be > 0.
  final double stepValue;

  /// The upper bound for the cumulative value.
  final double maxValue;

  /// The lower bound and wrap-target for the cumulative value.
  final double minValue;

  /// How to handle a step that would push the value beyond [maxValue].
  final OverflowBehavior overflowBehavior;

  /// A callback that returns the step size for the next swipe.
  final DynamicStepCallback? dynamicStep;

  /// Whether to render a persistent progress bar.
  final bool showProgressIndicator;

  /// Appearance configuration for the progress indicator.
  final ProgressIndicatorConfig? progressIndicatorConfig;

  /// Whether haptic feedback fires at swipe milestones.
  final bool enableHaptic;

  /// Called when the cumulative value changes.
  final ProgressChangeCallback? onProgressChanged;

  /// Called when the value reaches or would exceed [maxValue].
  final VoidCallback? onMaxReached;

  /// Called when the right-swipe direction is locked.
  final VoidCallback? onSwipeStarted;

  /// Called after a successful swipe animation settles.
  final ValueChanged<double>? onSwipeCompleted;

  /// Called when a right swipe is released below the activation threshold.
  final VoidCallback? onSwipeCancelled;

  /// Returns a copy with the specified fields replaced.
  RightSwipeConfig copyWith({
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
}
```

---

## `lib/src/config/left_swipe_config.dart`

```dart
import 'package:flutter/foundation.dart';
import '../actions/intentional/left_swipe_mode.dart';
import '../actions/intentional/post_action_behavior.dart';
import '../actions/intentional/swipe_action.dart';

/// Configuration for left-swipe intentional (one-shot) action behavior.
///
/// Pass as [SwipeActionCell.leftSwipeConfig] to enable left-swipe intentional
/// semantics. When `null`, left-swipe intentional behavior is disabled entirely.
///
/// Renamed from `IntentionalSwipeConfig` in F005. A new debug assertion has been
/// added for reveal mode with an empty [actions] list.
@immutable
class LeftSwipeConfig {
  /// Creates a [LeftSwipeConfig].
  const LeftSwipeConfig({
    required this.mode,
    this.actions = const [],
    this.actionPanelWidth,
    this.postActionBehavior = PostActionBehavior.snapBack,
    this.requireConfirmation = false,
    this.enableHaptic = false,
    this.onActionTriggered,
    this.onSwipeCancelled,
    this.onPanelOpened,
    this.onPanelClosed,
  })  : assert(
          actionPanelWidth == null || actionPanelWidth > 0,
          'actionPanelWidth must be > 0 when provided, got $actionPanelWidth',
        ),
        assert(
          mode != LeftSwipeMode.reveal || actions.isNotEmpty,
          'LeftSwipeConfig in reveal mode requires at least one action, '
          'but actions is empty.',
        );

  /// The interaction mode: [LeftSwipeMode.autoTrigger] or [LeftSwipeMode.reveal].
  final LeftSwipeMode mode;

  /// The action buttons displayed in the panel. Used only in [LeftSwipeMode.reveal].
  ///
  /// Must contain 1–3 [SwipeAction] items when mode is [LeftSwipeMode.reveal].
  /// More than 3 items: only the first 3 are rendered (debug assertion fired).
  final List<SwipeAction> actions;

  /// The width of the action panel in logical pixels. Used only in
  /// [LeftSwipeMode.reveal]. When `null`, auto-calculated from action count.
  final double? actionPanelWidth;

  /// What the cell does after an auto-trigger action fires.
  /// Used only in [LeftSwipeMode.autoTrigger].
  final PostActionBehavior postActionBehavior;

  /// Whether a second gesture (or background-area tap) is required to confirm
  /// the action. Used only in [LeftSwipeMode.autoTrigger].
  final bool requireConfirmation;

  /// Whether haptic feedback fires at swipe milestones.
  final bool enableHaptic;

  /// Called when an auto-trigger action fires successfully.
  final VoidCallback? onActionTriggered;

  /// Called when a left swipe is released below the activation threshold.
  final VoidCallback? onSwipeCancelled;

  /// Called when the reveal panel opens and the animation settles.
  final VoidCallback? onPanelOpened;

  /// Called when the reveal panel closes (any trigger).
  final VoidCallback? onPanelClosed;

  /// Returns a copy with the specified fields replaced.
  LeftSwipeConfig copyWith({
    LeftSwipeMode? mode,
    List<SwipeAction>? actions,
    double? actionPanelWidth,
    PostActionBehavior? postActionBehavior,
    bool? requireConfirmation,
    bool? enableHaptic,
    VoidCallback? onActionTriggered,
    VoidCallback? onSwipeCancelled,
    VoidCallback? onPanelOpened,
    VoidCallback? onPanelClosed,
  });
}
```

---

## `lib/src/config/swipe_visual_config.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';
import '../core/typedefs.dart';

/// Configuration for the visual presentation of a [SwipeActionCell].
///
/// Consolidates the four individual top-level visual parameters from F001–F004
/// (`leftBackground`, `rightBackground`, `clipBehavior`, `borderRadius`) into
/// a single config object.
///
/// Pass as [SwipeActionCell.visualConfig] or install app-wide via
/// [SwipeActionCellTheme.visualConfig].
@immutable
class SwipeVisualConfig {
  /// Creates a [SwipeVisualConfig].
  const SwipeVisualConfig({
    this.leftBackground,
    this.rightBackground,
    this.clipBehavior = Clip.hardEdge,
    this.borderRadius,
  });

  /// Builder for the background widget revealed during a left swipe.
  final SwipeBackgroundBuilder? leftBackground;

  /// Builder for the background widget revealed during a right swipe.
  final SwipeBackgroundBuilder? rightBackground;

  /// How to clip the background and child stack. Defaults to [Clip.hardEdge].
  final Clip clipBehavior;

  /// Optional rounded corners applied to the clip region.
  final BorderRadius? borderRadius;

  /// Returns a copy with the specified fields replaced.
  SwipeVisualConfig copyWith({
    SwipeBackgroundBuilder? leftBackground,
    SwipeBackgroundBuilder? rightBackground,
    Clip? clipBehavior,
    BorderRadius? borderRadius,
  });
}
```

---

## `lib/src/config/swipe_action_cell_theme.dart`

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../animation/swipe_animation_config.dart';
import '../gesture/swipe_gesture_config.dart';
import 'left_swipe_config.dart';
import 'right_swipe_config.dart';
import 'swipe_visual_config.dart';

/// App-level defaults for all [SwipeActionCell] widgets in the widget tree.
///
/// Install in [ThemeData.extensions] to provide default configurations that
/// every [SwipeActionCell] inherits when no local override is provided:
///
/// ```dart
/// MaterialApp(
///   theme: ThemeData(
///     extensions: [
///       SwipeActionCellTheme(
///         gestureConfig: SwipeGestureConfig.loose(),
///         animationConfig: SwipeAnimationConfig.smooth(),
///       ),
///     ],
///   ),
/// )
/// ```
///
/// Per-widget override: pass a non-null config to the relevant [SwipeActionCell]
/// parameter. The local config fully replaces the theme config for that parameter
/// (no field-level merging). Use `copyWith` on the theme's config to merge fields:
///
/// ```dart
/// SwipeActionCell(
///   gestureConfig: SwipeActionCellTheme.maybeOf(context)
///       ?.gestureConfig
///       ?.copyWith(deadZone: 8.0),
/// )
/// ```
@immutable
class SwipeActionCellTheme extends ThemeExtension<SwipeActionCellTheme> {
  /// Creates a [SwipeActionCellTheme].
  ///
  /// All parameters are optional. A null field means "no theme default for
  /// that parameter" — the widget falls back to its package-level defaults.
  const SwipeActionCellTheme({
    this.rightSwipeConfig,
    this.leftSwipeConfig,
    this.gestureConfig,
    this.animationConfig,
    this.visualConfig,
  });

  /// Default right-swipe configuration applied to all cells in the tree.
  final RightSwipeConfig? rightSwipeConfig;

  /// Default left-swipe configuration applied to all cells in the tree.
  final LeftSwipeConfig? leftSwipeConfig;

  /// Default gesture recognition configuration applied to all cells in the tree.
  final SwipeGestureConfig? gestureConfig;

  /// Default animation physics configuration applied to all cells in the tree.
  final SwipeAnimationConfig? animationConfig;

  /// Default visual presentation configuration applied to all cells in the tree.
  final SwipeVisualConfig? visualConfig;

  /// Returns the nearest [SwipeActionCellTheme] from [context], or `null` if
  /// none is installed in the app theme.
  static SwipeActionCellTheme? maybeOf(BuildContext context) =>
      Theme.of(context).extension<SwipeActionCellTheme>();

  /// Returns a copy with the specified fields replaced.
  @override
  SwipeActionCellTheme copyWith({
    RightSwipeConfig? rightSwipeConfig,
    LeftSwipeConfig? leftSwipeConfig,
    SwipeGestureConfig? gestureConfig,
    SwipeAnimationConfig? animationConfig,
    SwipeVisualConfig? visualConfig,
  });

  /// Hard-cutover lerp: returns [other] when [t] >= 1.0, [this] otherwise.
  ///
  /// Spring stiffness, damping, and gesture thresholds are not numerically
  /// interpolated — a mid-lerp mix would produce undefined physical behavior.
  @override
  SwipeActionCellTheme lerp(
    ThemeExtension<SwipeActionCellTheme>? other,
    double t,
  );
}
```

---

## `lib/src/controller/swipe_controller.dart`

```dart
import 'package:flutter/foundation.dart';

/// Controller for programmatic swipe operations.
///
/// Pass to [SwipeActionCell.controller] to enable external control.
///
/// **Note**: Full programmatic API is reserved for F007. In the current release,
/// [SwipeController] is a no-op placeholder. Constructing, storing, and disposing
/// a controller has no observable effect on cell behavior.
///
/// Usage:
/// ```dart
/// final controller = SwipeController();
///
/// @override
/// void dispose() {
///   controller.dispose();
///   super.dispose();
/// }
/// ```
class SwipeController extends ChangeNotifier {
  // Reserved for F007.
}
```

---

## `lib/src/gesture/swipe_gesture_config.dart` (updated)

Additions only — all existing fields and defaults unchanged.

```dart
/// Returns a gesture config that requires deliberate, longer swipes.
///
/// Suitable for high-precision use cases where accidental swipes must be
/// avoided. [deadZone] and [velocityThreshold] are both at least 2× higher
/// than [loose()].
factory SwipeGestureConfig.tight() => const SwipeGestureConfig(
      deadZone: 24.0,
      velocityThreshold: 1000.0,
    );

/// Returns a gesture config that responds to short, light swipes.
///
/// Suitable for casual or discovery-oriented swipe interactions.
factory SwipeGestureConfig.loose() => const SwipeGestureConfig(
      deadZone: 4.0,
      velocityThreshold: 300.0,
    );
```

---

## `lib/src/animation/swipe_animation_config.dart` (updated)

Additions only — all existing fields unchanged. New assertion added to constructor.

```dart
// New constructor assertion:
assert(
  activationThreshold >= 0.0 && activationThreshold <= 1.0,
  'activationThreshold must be between 0.0 and 1.0, got $activationThreshold',
),

/// Returns an animation config with fast, decisive animations and minimal
/// overshoot. Suitable for delete, archive, or other irreversible actions
/// where crisp feedback signals intent.
factory SwipeAnimationConfig.snappy() => const SwipeAnimationConfig(
      activationThreshold: 0.3,
      snapBackSpring: SpringConfig(stiffness: 550.0, damping: 24.0),
      completionSpring: SpringConfig(stiffness: 700.0, damping: 26.0),
      resistanceFactor: 0.60,
    );

/// Returns an animation config with gradual, soft animations and a gentle
/// settle. Suitable for passive reveal or progress interactions where a
/// relaxed feel is preferred.
factory SwipeAnimationConfig.smooth() => const SwipeAnimationConfig(
      activationThreshold: 0.5,
      snapBackSpring: SpringConfig(stiffness: 160.0, damping: 42.0),
      completionSpring: SpringConfig(stiffness: 180.0, damping: 45.0),
      resistanceFactor: 0.45,
    );
```

---

## `lib/src/widget/swipe_action_cell.dart` (updated constructor)

```dart
/// A widget that wraps any child and provides spring-based horizontal swipe
/// interaction with asymmetric left/right semantics.
class SwipeActionCell extends StatefulWidget {
  /// Creates a [SwipeActionCell].
  ///
  /// Only [child] is required. All config parameters default to `null`,
  /// which either falls through to a [SwipeActionCellTheme] in the widget
  /// tree or to the package's built-in defaults.
  ///
  /// Passing `null` for [rightSwipeConfig] or [leftSwipeConfig] completely
  /// disables that swipe direction — no gesture recognition, no visual
  /// feedback, no callbacks fired.
  const SwipeActionCell({
    super.key,
    required this.child,
    this.rightSwipeConfig,
    this.leftSwipeConfig,
    this.gestureConfig,
    this.animationConfig,
    this.visualConfig,
    this.controller,
    this.enabled = true,
    this.onStateChanged,
    this.onProgressChanged,
  });

  /// The widget displayed inside the swipe cell.
  final Widget child;

  /// Configuration for right-swipe progressive (incremental) action behavior.
  ///
  /// When `null` and no [SwipeActionCellTheme] provides a value, right-swipe
  /// progressive behavior is disabled entirely — zero overhead.
  final RightSwipeConfig? rightSwipeConfig;

  /// Configuration for left-swipe intentional (one-shot or reveal) behavior.
  ///
  /// When `null` and no [SwipeActionCellTheme] provides a value, left-swipe
  /// intentional behavior is disabled entirely — zero overhead.
  final LeftSwipeConfig? leftSwipeConfig;

  /// Configuration for gesture recognition behavior.
  ///
  /// When `null`, uses [SwipeActionCellTheme.gestureConfig] if present,
  /// otherwise falls back to [SwipeGestureConfig] defaults.
  final SwipeGestureConfig? gestureConfig;

  /// Configuration for animation physics.
  ///
  /// When `null`, uses [SwipeActionCellTheme.animationConfig] if present,
  /// otherwise falls back to [SwipeAnimationConfig] defaults.
  final SwipeAnimationConfig? animationConfig;

  /// Configuration for visual presentation (backgrounds, clip, border radius).
  ///
  /// When `null`, uses [SwipeActionCellTheme.visualConfig] if present,
  /// otherwise no backgrounds, hard-edge clip, no border radius.
  final SwipeVisualConfig? visualConfig;

  /// External controller for programmatic swipe operations.
  ///
  /// Accepted and stored but has no effect in this release. Reserved for F007.
  final SwipeController? controller;

  /// Whether swipe interactions are active.
  ///
  /// When `false`, all gesture recognition is bypassed and touch events pass
  /// through to the child unchanged.
  final bool enabled;

  /// Called whenever the swipe state machine transitions to a new state.
  final ValueChanged<SwipeState>? onStateChanged;

  /// Called on every frame during a drag with the current swipe progress.
  final ValueChanged<SwipeProgress>? onProgressChanged;
}
```

---

## `lib/swipe_action_cell.dart` (barrel export changes)

**Removed**:
```dart
// export 'src/actions/progressive/progressive_swipe_config.dart';  // deleted
// export 'src/actions/intentional/intentional_swipe_config.dart';  // deleted
```

**Added**:
```dart
export 'src/config/right_swipe_config.dart';
export 'src/config/left_swipe_config.dart';
export 'src/config/swipe_visual_config.dart';
export 'src/config/swipe_action_cell_theme.dart';
export 'src/controller/swipe_controller.dart';
```

**Unchanged** (all other existing exports remain):
```dart
export 'src/actions/intentional/left_swipe_mode.dart';
export 'src/actions/intentional/post_action_behavior.dart';
export 'src/actions/intentional/swipe_action.dart';
export 'src/actions/intentional/swipe_action_panel.dart';
export 'src/actions/progressive/overflow_behavior.dart';
export 'src/actions/progressive/progress_indicator_config.dart';
export 'src/actions/progressive/progressive_swipe_indicator.dart';
export 'src/animation/spring_config.dart';
export 'src/animation/swipe_animation_config.dart';
export 'src/core/swipe_direction.dart';
export 'src/core/swipe_progress.dart';
export 'src/core/swipe_state.dart';
export 'src/core/typedefs.dart';
export 'src/gesture/swipe_gesture_config.dart';
export 'src/visual/swipe_action_background.dart';
export 'src/widget/swipe_action_cell.dart';
```

import 'package:flutter/foundation.dart';

import '../actions/progressive/overflow_behavior.dart';
import '../actions/progressive/progress_indicator_config.dart';
import '../core/swipe_zone.dart';
import '../core/typedefs.dart';

/// Configuration for right-swipe progressive (incremental) action behavior.
///
/// Pass as [SwipeActionCell.rightSwipeConfig] to enable progressive right-swipe
/// semantics. When `null`, right-swipe progressive behavior is disabled entirely.
///
/// Each successful right swipe adds [stepValue] to the cumulative value and
/// fires [onSwipeCompleted] with the new total:
///
/// ```dart
/// rightSwipeConfig: RightSwipeConfig(
///   stepValue: 1.0,
///   maxValue: 10.0,
///   overflowBehavior: OverflowBehavior.clamp,
///   enableHaptic: true,
///   onSwipeCompleted: (newValue) => setState(() => _count = newValue.toInt()),
/// )
/// ```
///
/// For a progress bar that fills as the cumulative value approaches [maxValue],
/// set [showProgressIndicator] to `true` or drive a custom painter via
/// [SwipeVisualConfig.rightBackground] using [SwipeProgress.ratio].
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
    this.zones,
    this.zoneTransitionStyle = ZoneTransitionStyle.instant,
  })  : assert(stepValue > 0.0, 'stepValue must be > 0, got $stepValue'),
        assert(
          minValue < maxValue,
          'minValue ($minValue) must be < maxValue ($maxValue)',
        ),
        assert(
          zones == null || zones.length <= 4,
          'zones must have at most 4 entries for the right swipe direction.',
        );

  /// The externally-managed progress value (controlled mode).
  final double? value;

  /// When non-null and non-empty, overrides single-threshold behavior.
  final List<SwipeZone>? zones;

  /// Visual transition between zone backgrounds.
  final ZoneTransitionStyle zoneTransitionStyle;

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
    List<SwipeZone>? zones,
    ZoneTransitionStyle? zoneTransitionStyle,
  }) {
    return RightSwipeConfig(
      value: value ?? this.value,
      initialValue: initialValue ?? this.initialValue,
      stepValue: stepValue ?? this.stepValue,
      maxValue: maxValue ?? this.maxValue,
      minValue: minValue ?? this.minValue,
      overflowBehavior: overflowBehavior ?? this.overflowBehavior,
      dynamicStep: dynamicStep ?? this.dynamicStep,
      showProgressIndicator:
          showProgressIndicator ?? this.showProgressIndicator,
      progressIndicatorConfig:
          progressIndicatorConfig ?? this.progressIndicatorConfig,
      enableHaptic: enableHaptic ?? this.enableHaptic,
      onProgressChanged: onProgressChanged ?? this.onProgressChanged,
      onMaxReached: onMaxReached ?? this.onMaxReached,
      onSwipeStarted: onSwipeStarted ?? this.onSwipeStarted,
      onSwipeCompleted: onSwipeCompleted ?? this.onSwipeCompleted,
      onSwipeCancelled: onSwipeCancelled ?? this.onSwipeCancelled,
      zones: zones ?? this.zones,
      zoneTransitionStyle: zoneTransitionStyle ?? this.zoneTransitionStyle,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RightSwipeConfig &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          initialValue == other.initialValue &&
          stepValue == other.stepValue &&
          maxValue == other.maxValue &&
          minValue == other.minValue &&
          overflowBehavior == other.overflowBehavior &&
          dynamicStep == other.dynamicStep &&
          showProgressIndicator == other.showProgressIndicator &&
          progressIndicatorConfig == other.progressIndicatorConfig &&
          enableHaptic == other.enableHaptic &&
          onProgressChanged == other.onProgressChanged &&
          onMaxReached == other.onMaxReached &&
          onSwipeStarted == other.onSwipeStarted &&
          onSwipeCompleted == other.onSwipeCompleted &&
          onSwipeCancelled == other.onSwipeCancelled &&
          listEquals(zones, other.zones) &&
          zoneTransitionStyle == other.zoneTransitionStyle;

  @override
  int get hashCode => Object.hashAll([
        value,
        initialValue,
        stepValue,
        maxValue,
        minValue,
        overflowBehavior,
        dynamicStep,
        showProgressIndicator,
        progressIndicatorConfig,
        enableHaptic,
        onProgressChanged,
        onMaxReached,
        onSwipeStarted,
        onSwipeCompleted,
        onSwipeCancelled,
        zones,
        zoneTransitionStyle,
      ]);
}

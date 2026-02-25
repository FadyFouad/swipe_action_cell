import 'package:flutter/widgets.dart';
import '../../core/typedefs.dart';
import 'overflow_behavior.dart';
import 'progress_indicator_config.dart';

/// Configuration for right-swipe progressive (incremental) action behavior.
///
/// Pass as [SwipeActionCell.rightSwipe] to enable progressive right-swipe
/// semantics. When `null`, right-swipe progressive behavior is disabled entirely.
@immutable
class ProgressiveSwipeConfig {
  /// Creates a [ProgressiveSwipeConfig].
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
  })  : assert(stepValue > 0.0, 'stepValue must be > 0'),
        assert(minValue < maxValue, 'minValue must be < maxValue');

  /// The externally-managed progress value.
  final double? value;

  /// The initial cumulative value in uncontrolled mode.
  final double initialValue;

  /// The fixed amount added on each successful swipe.
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

  /// Whether haptic feedback is triggered.
  final bool enableHaptic;

  /// Called when the cumulative value changes.
  final ProgressChangeCallback? onProgressChanged;

  /// Called when the value reaches or would exceed [maxValue].
  final VoidCallback? onMaxReached;

  /// Called when the right swipe direction is locked.
  final VoidCallback? onSwipeStarted;

  /// Called after a successful swipe animation settles.
  final ValueChanged<double>? onSwipeCompleted;

  /// Called when a right swipe is released below the activation threshold.
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
  }) {
    return ProgressiveSwipeConfig(
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
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProgressiveSwipeConfig &&
        other.value == value &&
        other.initialValue == initialValue &&
        other.stepValue == stepValue &&
        other.maxValue == maxValue &&
        other.minValue == minValue &&
        other.overflowBehavior == overflowBehavior &&
        other.dynamicStep == dynamicStep &&
        other.showProgressIndicator == showProgressIndicator &&
        other.progressIndicatorConfig == progressIndicatorConfig &&
        other.enableHaptic == enableHaptic &&
        other.onProgressChanged == onProgressChanged &&
        other.onMaxReached == onMaxReached &&
        other.onSwipeStarted == onSwipeStarted &&
        other.onSwipeCompleted == onSwipeCompleted &&
        other.onSwipeCancelled == onSwipeCancelled;
  }

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
      ]);
}

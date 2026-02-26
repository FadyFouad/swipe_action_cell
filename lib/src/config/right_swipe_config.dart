import 'package:flutter/foundation.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

/// Configuration for right-swipe progressive action behavior.
@immutable
class RightSwipeConfig {
  /// Creates a configuration for right-swipe progressive actions.
  const RightSwipeConfig({
    required this.stepValue,
    this.minValue = 0.0,
    required this.maxValue,
    this.initialValue,
    this.value,
    this.onSwipeCompleted,
    this.onSwipeStarted,
    this.onSwipeCancelled,
    this.onProgressChanged,
    this.indicatorConfig = const ProgressIndicatorConfig(),
    this.overflowBehavior = OverflowBehavior.clamp,
    this.enableHaptic = true,
  })  : assert(stepValue > 0, 'RightSwipeConfig: stepValue must be > 0, got $stepValue'),
        assert(minValue < maxValue,
            'RightSwipeConfig: minValue must be < maxValue, got minValue=$minValue, maxValue=$maxValue');

  /// The increment value for each step of the swipe.
  final double stepValue;

  /// The minimum value the swipe can reach (default 0.0).
  final double minValue;

  /// The maximum value the swipe can reach.
  final double maxValue;

  /// Optional initial value when first rendered.
  final double? initialValue;

  /// Optional controlled value.
  final double? value;

  /// Callback when the swipe is completed (released past a step).
  final ValueChanged<double>? onSwipeCompleted;

  /// Callback when the swipe starts.
  final VoidCallback? onSwipeStarted;

  /// Callback when the swipe is cancelled (released before a step).
  final VoidCallback? onSwipeCancelled;

  /// Callback when the swipe progress changes.
  final ProgressChangeCallback? onProgressChanged;

  /// Configuration for the visual progress indicator.
  final ProgressIndicatorConfig indicatorConfig;

  /// How the swipe behaves when dragged past [maxValue].
  final OverflowBehavior overflowBehavior;

  /// Whether to trigger haptic feedback at key interaction milestones.
  final bool enableHaptic;

  /// Creates a copy of this configuration with the given fields replaced.
  RightSwipeConfig copyWith({
    double? stepValue,
    double? minValue,
    double? maxValue,
    double? initialValue,
    double? value,
    ValueChanged<double>? onSwipeCompleted,
    VoidCallback? onSwipeStarted,
    VoidCallback? onSwipeCancelled,
    ProgressChangeCallback? onProgressChanged,
    ProgressIndicatorConfig? indicatorConfig,
    OverflowBehavior? overflowBehavior,
    bool? enableHaptic,
  }) {
    return RightSwipeConfig(
      stepValue: stepValue ?? this.stepValue,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      initialValue: initialValue ?? this.initialValue,
      value: value ?? this.value,
      onSwipeCompleted: onSwipeCompleted ?? this.onSwipeCompleted,
      onSwipeStarted: onSwipeStarted ?? this.onSwipeStarted,
      onSwipeCancelled: onSwipeCancelled ?? this.onSwipeCancelled,
      onProgressChanged: onProgressChanged ?? this.onProgressChanged,
      indicatorConfig: indicatorConfig ?? this.indicatorConfig,
      overflowBehavior: overflowBehavior ?? this.overflowBehavior,
      enableHaptic: enableHaptic ?? this.enableHaptic,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RightSwipeConfig &&
          runtimeType == other.runtimeType &&
          stepValue == other.stepValue &&
          minValue == other.minValue &&
          maxValue == other.maxValue &&
          initialValue == other.initialValue &&
          value == other.value &&
          onSwipeCompleted == other.onSwipeCompleted &&
          onSwipeStarted == other.onSwipeStarted &&
          onSwipeCancelled == other.onSwipeCancelled &&
          onProgressChanged == other.onProgressChanged &&
          indicatorConfig == other.indicatorConfig &&
          overflowBehavior == other.overflowBehavior &&
          enableHaptic == other.enableHaptic;

  @override
  int get hashCode =>
      stepValue.hashCode ^
      minValue.hashCode ^
      maxValue.hashCode ^
      initialValue.hashCode ^
      value.hashCode ^
      onSwipeCompleted.hashCode ^
      onSwipeStarted.hashCode ^
      onSwipeCancelled.hashCode ^
      onProgressChanged.hashCode ^
      indicatorConfig.hashCode ^
      overflowBehavior.hashCode ^
      enableHaptic.hashCode;
}

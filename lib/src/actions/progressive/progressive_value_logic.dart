import '../../config/right_swipe_config.dart';
import 'overflow_behavior.dart';

/// Computes the next cumulative value after a successful right swipe.
///
/// Returns a record of the constrained next value and a bool indicating
/// whether [maxValue] was reached or exceeded.
({double nextValue, bool hitMax}) computeNextProgressiveValue({
  required double current,
  required RightSwipeConfig config,
  double? stepOverride,
}) {
  final step = stepOverride ??
      (config.dynamicStep != null
          ? config.dynamicStep!(current)
          : config.stepValue);

  if (step <= 0) return (nextValue: current, hitMax: false);

  final candidate = current + step;

  return switch (config.overflowBehavior) {
    OverflowBehavior.clamp => (
        nextValue: candidate.clamp(config.minValue, config.maxValue),
        hitMax: candidate >= config.maxValue,
      ),
    OverflowBehavior.wrap => candidate > config.maxValue
        ? (nextValue: config.minValue, hitMax: true)
        : (nextValue: candidate, hitMax: false),
    OverflowBehavior.ignore => (nextValue: candidate, hitMax: false),
  };
}

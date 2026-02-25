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

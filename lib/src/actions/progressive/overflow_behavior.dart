/// Determines what happens when a progressive swipe step would push the
/// cumulative value beyond [RightSwipeConfig.maxValue].
enum OverflowBehavior {
  /// Clamps the value at [RightSwipeConfig.maxValue].
  ///
  /// Further swipes are accepted visually but produce no value change.
  /// [RightSwipeConfig.onMaxReached] fires on each clamped swipe.
  clamp,

  /// Resets the value to [RightSwipeConfig.minValue] when [maxValue]
  /// would be exceeded.
  ///
  /// [RightSwipeConfig.onMaxReached] fires before the value wraps.
  wrap,

  /// Allows the value to grow without restriction.
  ///
  /// [RightSwipeConfig.onMaxReached] never fires in this mode.
  ignore,
}

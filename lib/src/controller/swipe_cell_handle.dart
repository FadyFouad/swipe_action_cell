/// Package-internal contract between [SwipeController] and [SwipeActionCellState].
///
/// [SwipeActionCellState] implements this interface and registers itself via
/// [SwipeController.attach]. This file is not exported from the package barrel
/// and is not part of the consumer-facing API.
abstract class SwipeCellHandle {
  /// Triggers the left-swipe completion animation and all associated
  /// post-action behaviour (action trigger, reveal, etc.), exactly as if
  /// the user had dragged past the activation threshold.
  void executeOpenLeft();

  /// Triggers the right-swipe completion animation and progressive increment,
  /// exactly as if the user had dragged past the activation threshold.
  void executeOpenRight();

  /// Triggers the snap-back animation from the current offset to the
  /// closed (origin) position.
  void executeClose();

  /// Sets the progressive value back to [RightSwipeConfig.initialValue].
  void executeResetProgress();

  /// Sets the progressive value to [value], clamped to
  /// [RightSwipeConfig.minValue]..[RightSwipeConfig.maxValue].
  void executeSetProgress(double value);

  /// Triggers undo on the cell if an undo window is currently pending.
  void executeUndo();

  /// Force-commits the pending undo immediately, as if the timer expired.
  void executeCommitUndo();
}

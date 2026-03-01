/// Determines what the cell does after a [LeftSwipeMode.autoTrigger] action fires.
enum PostActionBehavior {
  /// The cell springs back to its resting position (offset 0).
  ///
  /// This is the default behavior.
  snapBack,

  /// The cell slides fully off screen to the left.
  ///
  /// The widget does NOT collapse its own height. The developer is responsible
  /// for removing the item from their list in response to
  /// [LeftSwipeConfig.onActionTriggered].
  animateOut,

  /// The cell remains at the fully-swiped position with the background visible.
  ///
  /// The user can swipe right to return the cell to the idle (resting) position.
  /// This is the only exit from the [stay] state within the widget.
  stay,
}

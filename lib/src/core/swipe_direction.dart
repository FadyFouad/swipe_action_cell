/// Represents the direction of a swipe gesture.
enum SwipeDirection {
  /// Swipe towards the left side of the screen.
  ///
  /// In LTR layouts: backward/intentional action.
  /// In RTL layouts: forward/progressive action.
  left,

  /// Swipe towards the right side of the screen.
  ///
  /// In LTR layouts: forward/progressive action.
  /// In RTL layouts: backward/intentional action.
  right,

  /// No swipe direction has been determined yet.
  none,
}

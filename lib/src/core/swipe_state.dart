/// Represents the current state of the swipe interaction state machine.
///
/// State transitions follow the path:
/// `idle → dragging → animatingToOpen → revealed → animatingToClose → idle`
enum SwipeState {
  /// The widget is at rest with no active interaction.
  idle,

  /// The user is actively dragging the widget.
  dragging,

  /// The widget is animating towards the open/revealed position.
  animatingToOpen,

  /// The widget is animating back to the closed/origin position.
  animatingToClose,

  /// The widget is in the revealed/open position (action panel is visible).
  revealed,
}

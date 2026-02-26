/// Determines the interaction model for a left-swipe on a [SwipeActionCell].
enum LeftSwipeMode {
  /// A swipe past the activation threshold fires a one-shot action immediately
  /// on animation completion. The cell never enters a persistent open state unless
  /// [IntentionalSwipeConfig.postActionBehavior] is [PostActionBehavior.stay].
  autoTrigger,

  /// A swipe past the activation threshold springs open a panel of action buttons.
  /// The panel remains open until a button is tapped, the cell body is tapped,
  /// or the user swipes right.
  reveal,
}

import os

def replace_in_file(file_path, old_text, new_text):
    with open(file_path, 'r') as f:
        content = f.read()
    if old_text not in content:
        print(f"ERROR: Could not find old_text in {file_path}")
        return False
    new_content = content.replace(old_text, new_text)
    with open(file_path, 'w') as f:
        f.write(new_content)
    print(f"SUCCESS: Replaced in {file_path}")
    return True

# T001: Add fullSwipeRatio and designatedActionIndex
file_path = '../lib/src/actions/intentional/swipe_action_panel.dart'
old_text = """  /// Creates a [SwipeActionPanel].
  const SwipeActionPanel({
    super.key,
    required this.actions,
    required this.panelWidth,
    required this.onClose,
    this.enableHaptic = false,
    this.onFeedbackRequest,
  }) : assert(
          actions.length >= 1 && actions.length <= 3,
          'actions must contain 1–3 items',
        );

  /// The action buttons to display. Must be 1–3 items.
  final List<SwipeAction> actions;

  /// Total panel width in logical pixels.
  final double panelWidth;

  /// Called by the panel when any user interaction should close it.
  final VoidCallback onClose;

  /// Whether haptic feedback fires when a button is tapped.
  final bool enableHaptic;

  /// Called when feedback (haptic/audio) is requested by a button tap.
  final VoidCallback? onFeedbackRequest;"""

new_text = """  /// Creates a [SwipeActionPanel].
  const SwipeActionPanel({
    super.key,
    required this.actions,
    required this.panelWidth,
    required this.onClose,
    this.enableHaptic = false,
    this.onFeedbackRequest,
    this.fullSwipeRatio = 0.0,
    this.designatedActionIndex,
  }) : assert(
          actions.length >= 1 && actions.length <= 3,
          'actions must contain 1–3 items',
        );

  /// The action buttons to display. Must be 1–3 items.
  final List<SwipeAction> actions;

  /// Total panel width in logical pixels.
  final double panelWidth;

  /// Called by the panel when any user interaction should close it.
  final VoidCallback onClose;

  /// Whether haptic feedback fires when a button is tapped.
  final bool enableHaptic;

  /// Called when feedback (haptic/audio) is requested by a button tap.
  final VoidCallback? onFeedbackRequest;

  /// Current full-swipe expand progress (0.0 to 1.0).
  final double fullSwipeRatio;

  /// Index of the designated action to expand during full swipe.
  final int? designatedActionIndex;"""

replace_in_file(file_path, old_text, new_text)

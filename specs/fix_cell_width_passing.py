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

file_path = '../lib/src/widget/swipe_action_cell.dart'

old_panel = """  Widget _buildRevealPanel(double widgetWidth) {
    final config = _resolvedBackwardConfig!;
    final panelWidth =
        config.actionPanelWidth ?? 80.0 * config.actions.length.clamp(1, 3);
    final actions = config.actions.take(3).toList();
    final currentWidth = _controller.value.abs().clamp(0.0, panelWidth);

    int? designatedIndex;
    final fsCfg = config.fullSwipeConfig;
    if (fsCfg != null && fsCfg.enabled && fsCfg.expandAnimation) {
      final index = actions.indexOf(fsCfg.action);
      if (index != -1) {
        designatedIndex = index;
      }
    }

    return Positioned(
      top: 0,
      bottom: 0,
      right: 0,
      width: currentWidth,
      child: SwipeActionPanel(
        actions: actions,
        panelWidth: panelWidth,
        enableHaptic: config.enableHaptic,
        onFeedbackRequest: _feedbackDispatcher != null
            ? () => _feedbackDispatcher!
                .fire(SwipeFeedbackEvent.actionTriggered, isForward: false)
            : null,
        onClose: () {
          _updateState(SwipeState.animatingToClose);
          _snapBack(_controller.value, 0.0);
        },
        fullSwipeRatio: _fullSwipeRatio,
        designatedActionIndex: designatedIndex,
      ),
    );
  }"""

new_panel = """  Widget _buildRevealPanel(double widgetWidth) {
    final config = _resolvedBackwardConfig!;
    final revealWidth =
        config.actionPanelWidth ?? 80.0 * config.actions.length.clamp(1, 3);
    final actions = config.actions.take(3).toList();

    // T009: During full swipe, the panel expands to follow the drag offset.
    final bool isExpanding = _fullSwipeRatio > 0 &&
        config.fullSwipeConfig?.expandAnimation == true;
    final double currentWidth = isExpanding
        ? _controller.value.abs()
        : _controller.value.abs().clamp(0.0, revealWidth);

    int? designatedIndex;
    final fsCfg = config.fullSwipeConfig;
    if (fsCfg != null && fsCfg.enabled && fsCfg.expandAnimation) {
      final index = actions.indexOf(fsCfg.action);
      if (index != -1) {
        designatedIndex = index;
      }
    }

    return Positioned(
      top: 0,
      bottom: 0,
      right: 0,
      width: currentWidth,
      child: SwipeActionPanel(
        actions: actions,
        panelWidth: currentWidth, // Pass ACTUAL current width
        enableHaptic: config.enableHaptic,
        onFeedbackRequest: _feedbackDispatcher != null
            ? () => _feedbackDispatcher!
                .fire(SwipeFeedbackEvent.actionTriggered, isForward: false)
            : null,
        onClose: () {
          _updateState(SwipeState.animatingToClose);
          _snapBack(_controller.value, 0.0);
        },
        fullSwipeRatio: _fullSwipeRatio,
        designatedActionIndex: designatedIndex,
      ),
    );
  }"""

replace_in_file(file_path, old_panel, new_panel)

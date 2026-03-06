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

# T011: Remove import
old_import = "import '../actions/full_swipe/full_swipe_expand_overlay.dart';"
replace_in_file(file_path, old_import, "")

# T009: Update _buildRevealPanel
old_panel = """  Widget _buildRevealPanel(double widgetWidth) {
    final config = _resolvedBackwardConfig!;
    final panelWidth =
        config.actionPanelWidth ?? 80.0 * config.actions.length.clamp(1, 3);
    final actions = config.actions.take(3).toList();
    final currentWidth = _controller.value.abs().clamp(0.0, panelWidth);
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
      ),
    );
  }"""

new_panel = """  Widget _buildRevealPanel(double widgetWidth) {
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

replace_in_file(file_path, old_panel, new_panel)

# T010: Remove FullSwipeExpandOverlay from Stack
old_overlay = """                        if (_fullSwipeRatio > 0 &&
                            _resolvedFullSwipeConfig(_lockedDirection)
                                    ?.expandAnimation ==
                                true)
                          FullSwipeExpandOverlay(
                            action: _resolvedFullSwipeConfig(_lockedDirection)!
                                .action,
                            direction: _lockedDirection,
                            ratio: _fullSwipeRatio,
                            panelWidth: _effectiveMaxTranslation(
                                width, _lockedDirection),
                          ),"""
replace_in_file(file_path, old_overlay, "")

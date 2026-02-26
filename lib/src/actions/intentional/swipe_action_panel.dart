import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'swipe_action.dart';

/// The reveal-mode action panel rendered behind a [SwipeActionCell] during a left swipe.
///
/// Intended for internal use by [SwipeActionCell] when
/// [IntentionalSwipeConfig.mode] is [LeftSwipeMode.reveal].
/// May also be used directly for custom layouts.
///
/// Renders a [Row] of action buttons, each sized proportionally to its
/// [SwipeAction.flex] weight. A destructive button expands to [panelWidth]
/// on the first tap and executes on the second tap.
class SwipeActionPanel extends StatefulWidget {
  /// Creates a [SwipeActionPanel].
  const SwipeActionPanel({
    super.key,
    required this.actions,
    required this.panelWidth,
    required this.onClose,
    this.enableHaptic = false,
  }) : assert(
          actions.length >= 1 && actions.length <= 3,
          'actions must contain 1–3 items',
        );

  /// The action buttons to display. Must be 1–3 items.
  final List<SwipeAction> actions;

  /// Total panel width in logical pixels.
  final double panelWidth;

  /// Called by the panel when any user interaction should close it.
  ///
  /// The panel itself does not close; it calls [onClose] and lets the parent
  /// ([SwipeActionCell]) drive the close animation.
  final VoidCallback onClose;

  /// Whether haptic feedback fires when a button is tapped.
  final bool enableHaptic;

  @override
  State<SwipeActionPanel> createState() => _SwipeActionPanelState();
}

class _SwipeActionPanelState extends State<SwipeActionPanel> {
  /// Index of the currently-expanded destructive action, or `null` if none.
  int? _expandedIndex;

  void _handleButtonTap(int index) {
    final action = widget.actions[index];

    if (action.isDestructive) {
      if (_expandedIndex == index) {
        // Second tap on already-expanded destructive button — execute.
        if (widget.enableHaptic) HapticFeedback.mediumImpact();
        action.onTap();
        widget.onClose();
        setState(() => _expandedIndex = null);
      } else {
        // First tap — expand.
        setState(() => _expandedIndex = index);
      }
    } else {
      // Non-destructive — execute immediately.
      if (_expandedIndex != null) {
        // Collapse any expanded destructive button without firing it.
        setState(() => _expandedIndex = null);
      }
      if (widget.enableHaptic) HapticFeedback.mediumImpact();
      action.onTap();
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    // When a destructive button is expanded, it takes the full panel width
    // and other buttons are hidden.
    if (_expandedIndex != null) {
      final expandedAction = widget.actions[_expandedIndex!];
      return AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.panelWidth,
        color: expandedAction.backgroundColor,
        child: GestureDetector(
          onTap: () => _handleButtonTap(_expandedIndex!),
          child: _buildButtonContent(expandedAction),
        ),
      );
    }

    return Row(
      children: [
        for (int i = 0; i < widget.actions.length; i++)
          Expanded(
            flex: widget.actions[i].flex > 0 ? widget.actions[i].flex : 1,
            child: GestureDetector(
              onTap: () => _handleButtonTap(i),
              child: ColoredBox(
                color: widget.actions[i].backgroundColor,
                child: _buildButtonContent(widget.actions[i]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildButtonContent(SwipeAction action) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              action.foregroundColor,
              BlendMode.srcIn,
            ),
            child: action.icon,
          ),
          if (action.label != null) ...[
            const SizedBox(height: 4),
            Text(
              action.label!,
              style: TextStyle(
                color: action.foregroundColor,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

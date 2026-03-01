import 'package:flutter/material.dart';
import 'swipe_undo_config.dart';

/// Internal widget rendering the undo bar overlay.
///
/// Not exported from the package barrel.
class SwipeUndoOverlay extends StatelessWidget {
  /// Resolved display config.
  final SwipeUndoOverlayConfig config;

  /// Animation value 1.0 → 0.0 driving the progress bar width.
  final Animation<double> progressAnimation;

  /// Called when user taps the Undo button.
  final VoidCallback onUndo;

  /// Semantic label for the Undo button (accessibility).
  final String semanticUndoLabel;

  /// Creates a [SwipeUndoOverlay].
  const SwipeUndoOverlay({
    super.key,
    required this.config,
    required this.progressAnimation,
    required this.onUndo,
    required this.semanticUndoLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor =
        config.backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final textColor = config.textColor ?? theme.colorScheme.onSurfaceVariant;
    final buttonColor = config.buttonColor ?? theme.colorScheme.primary;
    final progressBarColor =
        config.progressBarColor ?? theme.colorScheme.primary.withAlpha(128);

    final content = Container(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            if (config.actionLabel != null)
              Expanded(
                child: Text(
                  config.actionLabel!,
                  style: config.textStyle ??
                      theme.textTheme.bodyMedium?.copyWith(color: textColor),
                ),
              ),
            TextButton(
              onPressed: onUndo,
              style: TextButton.styleFrom(foregroundColor: buttonColor),
              child: Text(config.undoButtonLabel,
                  semanticsLabel: semanticUndoLabel),
            ),
          ],
        ),
      ),
    );

    final progressBar = AnimatedBuilder(
      animation: progressAnimation,
      builder: (context, child) {
        if (progressAnimation.value <= 0.0) return const SizedBox.shrink();
        return SizedBox(
          height: config.progressBarHeight,
          width: double.infinity,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: progressAnimation.value,
              child: Container(color: progressBarColor),
            ),
          ),
        );
      },
    );

    return Semantics(
      liveRegion: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.position == SwipeUndoOverlayPosition.top) progressBar,
          content,
          if (config.position == SwipeUndoOverlayPosition.bottom) progressBar,
        ],
      ),
    );
  }
}

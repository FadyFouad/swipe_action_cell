import 'package:flutter/widgets.dart';
import '../../actions/intentional/swipe_action.dart';
import '../../core/swipe_direction.dart';

/// Internal widget that renders the expanding background fill for full-swipe.
class FullSwipeExpandOverlay extends StatelessWidget {
  /// The action being armed.
  final SwipeAction action;

  /// The physical direction of the swipe.
  final SwipeDirection direction;

  /// The interpolation ratio (0.0 to 1.0) between activation and full-swipe thresholds.
  final double ratio;

  /// The current width of the reveal panel (start width for expansion).
  final double panelWidth;

  /// Creates a [FullSwipeExpandOverlay].
  const FullSwipeExpandOverlay({
    super.key,
    required this.action,
    required this.direction,
    required this.ratio,
    required this.panelWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (ratio <= 0.0) return const SizedBox.shrink();

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          
          // Width expands from panelWidth to totalWidth
          final currentWidth = panelWidth + (totalWidth - panelWidth) * ratio;
          
          return Stack(
            children: [
              Positioned(
                top: 0,
                bottom: 0,
                left: direction == SwipeDirection.right ? 0 : null,
                right: direction == SwipeDirection.left ? 0 : null,
                width: currentWidth,
                child: ClipRect(
                  child: Container(
                    color: action.backgroundColor,
                    child: Center(
                      child: Opacity(
                        opacity: ratio.clamp(0.0, 1.0),
                        child: action.icon,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

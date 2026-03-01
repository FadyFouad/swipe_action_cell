import 'package:flutter/widgets.dart';
import '../core/swipe_progress.dart';

/// A built-in background widget for [SwipeActionCell] that provides
/// progress-reactive icon + label display.
class SwipeActionBackground extends StatefulWidget {
  /// Creates a [SwipeActionBackground].
  const SwipeActionBackground({
    super.key,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.progress,
    this.label,
  });

  /// The icon displayed in the center of the background.
  final Widget icon;

  /// Fill color of the background panel.
  final Color backgroundColor;

  /// Color applied to [icon] and [label].
  final Color foregroundColor;

  /// The current swipe state, updated every frame by the parent builder.
  final SwipeProgress progress;

  /// Optional text label displayed below [icon].
  final String? label;

  @override
  State<SwipeActionBackground> createState() => _SwipeActionBackgroundState();
}

class _SwipeActionBackgroundState extends State<SwipeActionBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _bumpController;
  late final Animation<double> _bumpAnimation;
  bool _wasActivated = false;

  @override
  void initState() {
    super.initState();
    _bumpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _bumpAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.3).chain(
          CurveTween(curve: Curves.easeOut),
        ),
        weight: 50.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.3, end: 0.0).chain(
          CurveTween(curve: Curves.easeIn),
        ),
        weight: 50.0,
      ),
    ]).animate(_bumpController);

    _wasActivated = widget.progress.isActivated;
  }

  @override
  void didUpdateWidget(SwipeActionBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.progress.isActivated && !_wasActivated) {
      _bumpController.forward(from: 0.0);
    }
    _wasActivated = widget.progress.isActivated;
  }

  @override
  void dispose() {
    _bumpController.dispose();
    super.dispose();
  }

  Color _intensifiedColor(double ratio) {
    final hsl = HSLColor.fromColor(widget.backgroundColor);
    final darkenAmount = 0.15 * ratio;
    return hsl
        .withLightness((hsl.lightness - darkenAmount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = widget.progress.ratio;

    return AnimatedBuilder(
      animation: _bumpAnimation,
      builder: (context, _) {
        final bump = _bumpAnimation.value;
        final scale = ratio * (1.0 + bump);

        return ColoredBox(
          color: _intensifiedColor(ratio),
          child: Center(
            child: Opacity(
              opacity: ratio,
              child: Transform.scale(
                key: const Key('bg_scale'),
                scale: scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconTheme(
                      data: IconThemeData(
                        color: widget.foregroundColor,
                      ),
                      child: widget.icon,
                    ),
                    if (widget.label != null) ...[
                      const SizedBox(height: 4),
                      DefaultTextStyle(
                        style: TextStyle(
                          color: widget.foregroundColor,
                          fontSize: 12,
                        ),
                        child: Text(widget.label!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

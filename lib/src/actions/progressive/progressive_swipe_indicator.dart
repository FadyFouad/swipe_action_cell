import 'package:flutter/widgets.dart';
import 'progress_indicator_config.dart';

/// A progress bar rendered as a filled vertical bar on a cell edge.
class ProgressiveSwipeIndicator extends StatelessWidget {
  /// Creates a [ProgressiveSwipeIndicator].
  const ProgressiveSwipeIndicator({
    super.key,
    required this.fillRatio,
    this.config = const ProgressIndicatorConfig(),
  }) : assert(fillRatio >= 0.0 && fillRatio <= 1.0,
            'fillRatio must be in `[0.0, 1.0]`');

  /// Proportion of the indicator filled. Range: `[0.0, 1.0]`.
  final double fillRatio;

  /// Visual appearance configuration.
  final ProgressIndicatorConfig config;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ProgressIndicatorPainter(
        fillRatio: fillRatio,
        config: config,
      ),
      size: Size(config.width, double.infinity),
    );
  }
}

class _ProgressIndicatorPainter extends CustomPainter {
  _ProgressIndicatorPainter({
    required this.fillRatio,
    required this.config,
  });

  final double fillRatio;
  final ProgressIndicatorConfig config;

  @override
  void paint(Canvas canvas, Size size) {
    if (config.backgroundColor != null) {
      final bgPaint = Paint()..color = config.backgroundColor!;
      _drawBar(canvas, size, 1.0, bgPaint);
    }

    final fillPaint = Paint()..color = config.color;
    _drawBar(canvas, size, fillRatio, fillPaint);
  }

  void _drawBar(Canvas canvas, Size size, double ratio, Paint paint) {
    if (ratio <= 0) return;

    final fillHeight = size.height * ratio;
    final rect = Rect.fromLTWH(
      0,
      size.height - fillHeight,
      size.width,
      fillHeight,
    );

    if (config.borderRadius != null) {
      canvas.drawRRect(
        config.borderRadius!.toRRect(rect),
        paint,
      );
    } else {
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_ProgressIndicatorPainter oldDelegate) {
    return oldDelegate.fillRatio != fillRatio || oldDelegate.config != config;
  }
}

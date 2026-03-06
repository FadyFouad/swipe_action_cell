import 'package:flutter/material.dart';

/// A stateless widget that smoothly cross-fades between two icons based on progress.
///
/// Designed to be used inside custom background builders where an icon needs
/// to transition its appearance as the swipe progresses.
class SwipeMorphIcon extends StatelessWidget {
  /// Creates a [SwipeMorphIcon].
  const SwipeMorphIcon({
    super.key,
    required this.startIcon,
    required this.endIcon,
    required this.progress,
    this.size,
    this.color,
  });

  /// The widget shown when progress is 0.0.
  final Widget startIcon;

  /// The widget shown when progress is 1.0.
  final Widget endIcon;

  /// The interpolation value, clamped internally to `[0.0, 1.0]`.
  final double progress;

  /// Optional size applied to both icons via [IconTheme].
  final double? size;

  /// Optional color applied to both icons via [IconTheme].
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);

    Widget buildIcon(Widget icon, double opacity) {
      Widget result = IgnorePointer(child: icon);
      if (size != null || color != null) {
        result = IconTheme.merge(
          data: IconThemeData(size: size, color: color),
          child: result,
        );
      }
      return Opacity(
        opacity: opacity,
        child: result,
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        buildIcon(startIcon, 1.0 - t),
        buildIcon(endIcon, t),
      ],
    );
  }
}

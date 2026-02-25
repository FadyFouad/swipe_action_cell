import 'package:flutter/widgets.dart';

/// A widget that wraps a child and will provide swipe interaction capabilities.
///
/// [SwipeActionCell] uses asymmetric swipe semantics:
/// - **Right swipe (forward):** Progressive/incremental action (e.g., increment
///   a counter or increase a progress value).
/// - **Left swipe (backward):** Intentional committed action (e.g., delete,
///   archive, or reveal action buttons).
///
/// Example usage:
/// ```dart
/// SwipeActionCell(
///   child: ListTile(title: Text('Swipeable item')),
/// )
/// ```
///
/// > Note: Swipe behaviour is not yet implemented. This is a widget skeleton.
class SwipeActionCell extends StatefulWidget {
  /// Creates a [SwipeActionCell].
  ///
  /// The [child] argument must not be null.
  const SwipeActionCell({
    super.key,
    required this.child,
    this.enabled = true,
  });

  /// The widget displayed inside the swipe cell.
  final Widget child;

  /// Whether swipe interactions are enabled.
  ///
  /// When `false`, the cell renders [child] without any swipe capability.
  /// Defaults to `true`.
  final bool enabled;

  @override
  State<SwipeActionCell> createState() => _SwipeActionCellState();
}

class _SwipeActionCellState extends State<SwipeActionCell> {
  @override
  Widget build(BuildContext context) {
    // TODO(F1): Add gesture detection and swipe behaviour.
    return widget.child;
  }
}

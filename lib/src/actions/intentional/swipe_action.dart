import 'package:flutter/widgets.dart';

/// Defines a single action button in a reveal-mode [SwipeActionCell] panel.
///
/// Pass a list of 1–3 [SwipeAction] objects to
/// [LeftSwipeConfig.actions]. More than 3 entries: only the first 3
/// are rendered (debug assertion).
///
/// Example:
/// ```dart
/// SwipeAction(
///   icon: const Icon(Icons.delete),
///   label: 'Delete',
///   backgroundColor: const Color(0xFFE53935),
///   foregroundColor: const Color(0xFFFFFFFF),
///   onTap: () => deleteItem(item),
///   isDestructive: true,
/// )
/// ```
@immutable
class SwipeAction {
  /// Creates a [SwipeAction].
  const SwipeAction({
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
    this.label,
    this.isDestructive = false,
    this.flex = 1,
  }) : assert(flex >= 0, 'flex must be >= 0');

  /// The icon displayed in the center of the button. Typically an [Icon] widget.
  final Widget icon;

  /// Optional text label displayed below [icon].
  ///
  /// When `null`, an icon-only button is rendered with no text.
  final String? label;

  /// Fill color of the action button.
  final Color backgroundColor;

  /// Color applied to [icon] and [label].
  final Color foregroundColor;

  /// Called when this button is activated.
  ///
  /// For destructive actions ([isDestructive]: true), this fires on the
  /// second tap (after the confirm-expand), not the first.
  final VoidCallback onTap;

  /// Whether this action requires a two-tap confirm-expand before firing.
  ///
  /// When `true`, the first tap expands this button to the full panel width.
  /// The second tap fires [onTap] and closes the panel. Tapping elsewhere
  /// after the first tap collapses without executing.
  ///
  /// Default: `false`.
  final bool isDestructive;

  /// Relative width weight of this button within the action panel.
  ///
  /// Works like [Expanded.flex]: higher values produce wider buttons.
  /// A value of 0 hides the button. Default: 1.
  final int flex;

  /// Returns a copy with the specified fields replaced.
  SwipeAction copyWith({
    Widget? icon,
    String? label,
    Color? backgroundColor,
    Color? foregroundColor,
    VoidCallback? onTap,
    bool? isDestructive,
    int? flex,
  }) {
    return SwipeAction(
      icon: icon ?? this.icon,
      label: label ?? this.label,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      onTap: onTap ?? this.onTap,
      isDestructive: isDestructive ?? this.isDestructive,
      flex: flex ?? this.flex,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SwipeAction &&
        other.icon == icon &&
        other.label == label &&
        other.backgroundColor == backgroundColor &&
        other.foregroundColor == foregroundColor &&
        other.onTap == onTap &&
        other.isDestructive == isDestructive &&
        other.flex == flex;
  }

  @override
  int get hashCode => Object.hash(
        icon,
        label,
        backgroundColor,
        foregroundColor,
        onTap,
        isDestructive,
        flex,
      );
}

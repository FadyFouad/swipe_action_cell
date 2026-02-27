import 'package:flutter/widgets.dart';

/// A const-constructable holder for a semantic label that is either a
/// static string or a context-aware builder function.
///
/// Used as the field type in [SwipeSemanticConfig] to support both
/// static and locale-resolved labels.
@immutable
class SemanticLabel {
  /// A static label string.
  const SemanticLabel.string(String this._value) : _builder = null;

  /// A builder function that resolves the label from [BuildContext],
  /// enabling locale-aware labels.
  const SemanticLabel.builder(String Function(BuildContext context) this._builder)
      : _value = null;

  final String? _value;
  final String Function(BuildContext)? _builder;

  /// Resolves the label for the given [context].
  ///
  /// For [SemanticLabel.string], returns the static string.
  /// For [SemanticLabel.builder], calls the builder function.
  /// Returns an empty string if the builder returns null or empty.
  String resolve(BuildContext context) {
    if (_value != null) return _value;
    final result = _builder!(context);
    return result;
  }
}

/// Configuration for all accessibility labels and screen reader announcements
/// on a [SwipeActionCell].
///
/// All fields are optional. When null or resolving to an empty string, the
/// widget falls back to direction-adaptive built-in defaults.
@immutable
class SwipeSemanticConfig {
  /// Creates a [SwipeSemanticConfig] with the given label overrides.
  const SwipeSemanticConfig({
    this.cellLabel,
    this.rightSwipeLabel,
    this.leftSwipeLabel,
    this.panelOpenLabel,
    this.progressAnnouncementBuilder,
  });

  /// Semantic label for the whole cell row, announced when the screen reader
  /// focuses the cell. Corresponds to [Semantics.label].
  ///
  /// Defaults to null (no cell-level label unless provided).
  final SemanticLabel? cellLabel;

  /// Label for the right-swipe (forward in LTR / backward in RTL) action as
  /// it appears in the screen reader's custom actions menu.
  ///
  /// Defaults to a direction-adaptive label such as "Swipe right to progress"
  /// (LTR) or "Swipe left to progress" (RTL).
  final SemanticLabel? rightSwipeLabel;

  /// Label for the left-swipe (backward in LTR / forward in RTL) action as
  /// it appears in the screen reader's custom actions menu.
  ///
  /// Defaults to a direction-adaptive label such as "Swipe left for actions"
  /// (LTR) or "Swipe right for actions" (RTL).
  final SemanticLabel? leftSwipeLabel;

  /// Announcement text spoken by the screen reader when the action panel opens.
  ///
  /// Defaults to "Action panel open".
  final SemanticLabel? panelOpenLabel;

  /// Override for the automatic progress announcement.
  ///
  /// When null, the widget generates "Progress incremented to N of M"
  /// automatically from the tracked progressive value. Provide this builder
  /// to customize the announcement format or locale.
  final String Function(double current, double max)?
      progressAnnouncementBuilder;

  /// Returns a copy with the specified fields replaced.
  SwipeSemanticConfig copyWith({
    SemanticLabel? cellLabel,
    SemanticLabel? rightSwipeLabel,
    SemanticLabel? leftSwipeLabel,
    SemanticLabel? panelOpenLabel,
    String Function(double current, double max)? progressAnnouncementBuilder,
  }) {
    return SwipeSemanticConfig(
      cellLabel: cellLabel ?? this.cellLabel,
      rightSwipeLabel: rightSwipeLabel ?? this.rightSwipeLabel,
      leftSwipeLabel: leftSwipeLabel ?? this.leftSwipeLabel,
      panelOpenLabel: panelOpenLabel ?? this.panelOpenLabel,
      progressAnnouncementBuilder:
          progressAnnouncementBuilder ?? this.progressAnnouncementBuilder,
    );
  }
}

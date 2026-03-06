import 'package:flutter/widgets.dart';
import 'undo_data.dart';

/// Enum controlling where the undo bar is anchored within the cell.
enum SwipeUndoOverlayPosition {
  /// Bar appears at the top edge of the cell.
  top,

  /// Bar appears at the bottom edge of the cell.
  bottom,
}

/// Visual and layout configuration for the built-in `SwipeUndoOverlay` bar.
@immutable
class SwipeUndoOverlayConfig {
  /// Whether the bar appears at the top or bottom of the cell.
  final SwipeUndoOverlayPosition position;

  /// Background color of the bar.
  final Color? backgroundColor;

  /// Color of the action description text.
  final Color? textColor;

  /// Color of the "Undo" button label.
  final Color? buttonColor;

  /// Color of the shrinking countdown bar.
  final Color? progressBarColor;

  /// Height of the shrinking countdown progress bar in logical pixels.
  final double progressBarHeight;

  /// Style applied to the action description text.
  final TextStyle? textStyle;

  /// Label for the undo trigger button.
  final String undoButtonLabel;

  /// Optional description shown next to the Undo button (e.g., "Deleted").
  final String? actionLabel;

  /// Creates a [SwipeUndoOverlayConfig].
  const SwipeUndoOverlayConfig({
    this.position = SwipeUndoOverlayPosition.bottom,
    this.backgroundColor,
    this.textColor,
    this.buttonColor,
    this.progressBarColor,
    this.progressBarHeight = 3.0,
    this.textStyle,
    this.undoButtonLabel = 'Undo',
    this.actionLabel,
  }) : assert(progressBarHeight >= 0, 'progressBarHeight must be non-negative');

  /// Creates a copy of this config with the given fields replaced.
  SwipeUndoOverlayConfig copyWith({
    SwipeUndoOverlayPosition? position,
    Color? backgroundColor,
    Color? textColor,
    Color? buttonColor,
    Color? progressBarColor,
    double? progressBarHeight,
    TextStyle? textStyle,
    String? undoButtonLabel,
    String? actionLabel,
  }) {
    return SwipeUndoOverlayConfig(
      position: position ?? this.position,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      buttonColor: buttonColor ?? this.buttonColor,
      progressBarColor: progressBarColor ?? this.progressBarColor,
      progressBarHeight: progressBarHeight ?? this.progressBarHeight,
      textStyle: textStyle ?? this.textStyle,
      undoButtonLabel: undoButtonLabel ?? this.undoButtonLabel,
      actionLabel: actionLabel ?? this.actionLabel,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwipeUndoOverlayConfig &&
          runtimeType == other.runtimeType &&
          position == other.position &&
          backgroundColor == other.backgroundColor &&
          textColor == other.textColor &&
          buttonColor == other.buttonColor &&
          progressBarColor == other.progressBarColor &&
          progressBarHeight == other.progressBarHeight &&
          textStyle == other.textStyle &&
          undoButtonLabel == other.undoButtonLabel &&
          actionLabel == other.actionLabel;

  @override
  int get hashCode =>
      position.hashCode ^
      backgroundColor.hashCode ^
      textColor.hashCode ^
      buttonColor.hashCode ^
      progressBarColor.hashCode ^
      progressBarHeight.hashCode ^
      textStyle.hashCode ^
      undoButtonLabel.hashCode ^
      actionLabel.hashCode;
}

/// Opt-in configuration for the undo mechanism.
@immutable
class SwipeUndoConfig {
  /// Length of the undo window.
  final Duration duration;

  /// Whether to render SwipeUndoOverlay automatically.
  final bool showBuiltInOverlay;

  /// Visual configuration for the built-in overlay.
  final SwipeUndoOverlayConfig? overlayConfig;

  /// Fired when an undo window opens.
  final void Function(UndoData)? onUndoAvailable;

  /// Fired when the user (or code) triggers undo.
  final VoidCallback? onUndoTriggered;

  /// Fired when the undo window expires without revert.
  final VoidCallback? onUndoExpired;

  /// Creates a [SwipeUndoConfig].
  const SwipeUndoConfig({
    this.duration = const Duration(seconds: 5),
    this.showBuiltInOverlay = true,
    this.overlayConfig,
    this.onUndoAvailable,
    this.onUndoTriggered,
    this.onUndoExpired,
  });

  /// Creates a copy of this config with the given fields replaced.
  SwipeUndoConfig copyWith({
    Duration? duration,
    bool? showBuiltInOverlay,
    SwipeUndoOverlayConfig? overlayConfig,
    void Function(UndoData)? onUndoAvailable,
    VoidCallback? onUndoTriggered,
    VoidCallback? onUndoExpired,
  }) {
    return SwipeUndoConfig(
      duration: duration ?? this.duration,
      showBuiltInOverlay: showBuiltInOverlay ?? this.showBuiltInOverlay,
      overlayConfig: overlayConfig ?? this.overlayConfig,
      onUndoAvailable: onUndoAvailable ?? this.onUndoAvailable,
      onUndoTriggered: onUndoTriggered ?? this.onUndoTriggered,
      onUndoExpired: onUndoExpired ?? this.onUndoExpired,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SwipeUndoConfig &&
          runtimeType == other.runtimeType &&
          duration == other.duration &&
          showBuiltInOverlay == other.showBuiltInOverlay &&
          overlayConfig == other.overlayConfig &&
          onUndoAvailable == other.onUndoAvailable &&
          onUndoTriggered == other.onUndoTriggered &&
          onUndoExpired == other.onUndoExpired;

  @override
  int get hashCode =>
      duration.hashCode ^
      showBuiltInOverlay.hashCode ^
      overlayConfig.hashCode ^
      onUndoAvailable.hashCode ^
      onUndoTriggered.hashCode ^
      onUndoExpired.hashCode;
}

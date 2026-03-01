# Public API Contract: Swipe Action Undo/Revert Support (F011)

**Branch**: `011-swipe-undo` | **Date**: 2026-03-01

---

## New Public Types

### `SwipeUndoConfig`

```dart
/// Configuration for the undo/revert mechanism of [SwipeActionCell].
///
/// Pass this to [SwipeActionCell.undoConfig] to enable time-limited undo
/// support. Passing `null` disables undo entirely with zero overhead.
///
/// ```dart
/// SwipeActionCell(
///   undoConfig: SwipeUndoConfig(
///     duration: const Duration(seconds: 5),
///     onUndoExpired: () => _deleteItem(item),
///   ),
///   leftSwipeConfig: LeftSwipeConfig(
///     mode: LeftSwipeMode.autoTrigger,
///     postActionBehavior: PostActionBehavior.animateOut,
///   ),
///   child: ListTile(title: Text(item.title)),
/// )
/// ```
@immutable
class SwipeUndoConfig {
  const SwipeUndoConfig({
    this.duration = const Duration(seconds: 5),
    this.showBuiltInOverlay = true,
    this.overlayConfig,
    this.onUndoAvailable,
    this.onUndoTriggered,
    this.onUndoExpired,
  });

  /// How long the undo window stays open before the action commits permanently.
  final Duration duration;

  /// Whether to show the built-in [SwipeUndoOverlay] bar automatically.
  ///
  /// Set to `false` to use only callbacks and [SwipeController] for custom UI.
  final bool showBuiltInOverlay;

  /// Visual configuration for the built-in overlay.
  ///
  /// When `null`, default colors and layout are used.
  final SwipeUndoOverlayConfig? overlayConfig;

  /// Called when an undo window opens, immediately after an action completes.
  ///
  /// Receives an [UndoData] snapshot containing the old/new values and a
  /// [UndoData.revert] shortcut.
  final void Function(UndoData data)? onUndoAvailable;

  /// Called when undo is triggered (by user tap, [SwipeController.undo],
  /// or [UndoData.revert]).
  final VoidCallback? onUndoTriggered;

  /// Called when the undo window expires without a revert being triggered.
  ///
  /// This is the appropriate place to execute the action's permanent side
  /// effect (e.g., call your delete API).
  final VoidCallback? onUndoExpired;

  SwipeUndoConfig copyWith({...});
}
```

---

### `SwipeUndoOverlayConfig`

```dart
/// Visual and layout configuration for the built-in undo overlay bar.
@immutable
class SwipeUndoOverlayConfig {
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
  });

  /// Where the bar appears within the cell.
  final SwipeUndoOverlayPosition position;

  /// Background color of the bar. Defaults to theme surface-variant.
  final Color? backgroundColor;

  /// Color of the action description text. Defaults to theme on-surface.
  final Color? textColor;

  /// Color of the "Undo" button label. Defaults to theme primary.
  final Color? buttonColor;

  /// Color of the shrinking countdown progress bar.
  final Color? progressBarColor;

  /// Height of the shrinking countdown progress bar in logical pixels.
  final double progressBarHeight;

  /// Text style applied to [actionLabel].
  final TextStyle? textStyle;

  /// Label for the undo trigger button. Defaults to `'Undo'`.
  final String undoButtonLabel;

  /// Optional action description displayed next to the button (e.g., `'Deleted'`).
  final String? actionLabel;

  SwipeUndoOverlayConfig copyWith({...});
}
```

---

### `SwipeUndoOverlayPosition`

```dart
/// Controls where [SwipeUndoOverlay] is anchored within the cell.
enum SwipeUndoOverlayPosition {
  /// The bar appears at the top edge of the cell.
  top,

  /// The bar appears at the bottom edge of the cell.
  bottom,
}
```

---

### `UndoData`

```dart
/// A snapshot of the undo window state, passed to [SwipeUndoConfig.onUndoAvailable].
///
/// [oldValue] and [newValue] are non-null only for progressive (right-swipe)
/// actions. For intentional (left-swipe) actions, both are `null`.
@immutable
class UndoData {
  const UndoData({
    required this.oldValue,
    required this.newValue,
    required this.remainingDuration,
    required this.revert,
  });

  /// The progressive value before the action. `null` for intentional actions.
  final double? oldValue;

  /// The progressive value after the action. `null` for intentional actions.
  final double? newValue;

  /// Approximate time remaining in the undo window at the moment this
  /// [UndoData] was created.
  final Duration remainingDuration;

  /// Triggers undo on the associated cell.
  ///
  /// Equivalent to calling [SwipeController.undo] on the cell's controller.
  /// No-op if the undo window has already closed or been committed.
  final VoidCallback revert;
}
```

---

## Modified Public Types

### `SwipeController` — New Members

```dart
class SwipeController extends ChangeNotifier {
  // ... existing members unchanged ...

  /// Whether an undo window is currently open for the attached cell.
  ///
  /// Returns `false` when no cell is attached or when [SwipeActionCell.undoConfig]
  /// is `null`.
  bool get isUndoPending;

  /// Triggers undo on the attached cell.
  ///
  /// Returns `true` if an undo window was open and the revert was initiated.
  /// Returns `false` (silent no-op) if [isUndoPending] is `false` — callers
  /// are not required to check [isUndoPending] before calling [undo].
  bool undo();

  /// Force-commits the pending undo immediately, as if the window had expired.
  ///
  /// Fires [SwipeUndoConfig.onUndoExpired] and closes the overlay.
  /// No-op if [isUndoPending] is `false`.
  void commitPendingUndo();
}
```

---

### `SwipeActionCell` — New Parameter

```dart
class SwipeActionCell extends StatefulWidget {
  const SwipeActionCell({
    // ... existing parameters unchanged ...

    /// Undo configuration. When non-null, a time-limited undo window opens
    /// after each action completes. When `null` (default), undo is disabled
    /// with zero overhead.
    this.undoConfig,
  });

  final SwipeUndoConfig? undoConfig;
}
```

---

## Accessibility Contract

The built-in `SwipeUndoOverlay` satisfies the following accessibility requirements (F8 integration):

| Requirement | Implementation |
|-------------|----------------|
| "Undo" button reachable via keyboard/switch access | Button wrapped in `Semantics(button: true, label: config.undoButtonLabel)` |
| Screen reader announces undo availability | `Semantics(liveRegion: true)` on the overlay container |
| Countdown animation suppressed under `reduceMotion` | `_undoBarController` is not started when `MediaQuery.disableAnimations` is `true` |
| Timer still runs under `reduceMotion` | `Timer` is independent of `_undoBarController` |

---

## Behavior Contract

### Undo Window Lifecycle

| Event | Internal Action | Callbacks Fired |
|-------|-----------------|-----------------|
| Action completes (progressive or intentional) | `_undoPending = true`; `Timer` starts; bar animates | `onUndoAvailable(UndoData)` |
| User taps "Undo" button | `_triggerUndo()` called | `onUndoTriggered()` |
| `SwipeController.undo()` called | `executeUndo()` → `_triggerUndo()` | `onUndoTriggered()` |
| `UndoData.revert()` called | `_triggerUndo()` | `onUndoTriggered()` |
| `SwipeController.commitPendingUndo()` called | `_commitUndo()` | `onUndoExpired()` |
| Timer expires | `_commitUndo()` | `onUndoExpired()` |
| New swipe action initiated while `_undoPending` | `_commitUndo()` then new window starts | `onUndoExpired()` (for old), then `onUndoAvailable(UndoData)` (for new) |
| Widget disposed while `_undoPending` | Timer cancelled; `_undoPending = false` | None (no callbacks after dispose) |

### Revert Behavior by Post-Action Mode

| `PostActionBehavior` | Undo Visual Effect | Consumer Responsibility |
|----------------------|--------------------|-------------------------|
| `animateOut` | Cell animates back into view using `SpringConfig.undoReveal` (bouncy spring) | Remove item from list only in `onUndoExpired`, not `onActionTriggered` |
| `snapBack` | No package animation (cell already visible) | `onUndoTriggered` callback handles data reversal |
| `stay` | No package animation (cell at revealed position; `close()` not called) | `onUndoTriggered` callback handles data reversal |

### `SwipeController.undo()` Return Values

| Condition | Returns |
|-----------|---------|
| `isUndoPending == true` | `true` (undo initiated) |
| `isUndoPending == false` | `false` (silent no-op) |
| No cell attached | `false` (silent no-op) |

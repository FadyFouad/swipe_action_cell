# Widget API Contract: Left-Swipe Intentional Action

**Feature**: 004-intentional-action
**Date**: 2026-02-26
**Package**: `swipe_action_cell`
**Public entry point**: `package:swipe_action_cell/swipe_action_cell.dart`

This document defines the complete public API surface introduced and updated by this feature.
Implementations MUST conform to these signatures.

---

## New Enums

### `LeftSwipeMode`

```dart
/// Determines the interaction model for a left-swipe on a [SwipeActionCell].
enum LeftSwipeMode {
  /// A swipe past the activation threshold fires a one-shot action immediately
  /// on animation completion. The cell never enters a persistent open state unless
  /// [IntentionalSwipeConfig.postActionBehavior] is [PostActionBehavior.stay].
  autoTrigger,

  /// A swipe past the activation threshold springs open a panel of action buttons.
  /// The panel remains open until a button is tapped, the cell body is tapped,
  /// or the user swipes right.
  reveal,
}
```

**Location**: `lib/src/actions/intentional/left_swipe_mode.dart`
**Export**: `lib/swipe_action_cell.dart`

---

### `PostActionBehavior`

```dart
/// Determines what the cell does after an [LeftSwipeMode.autoTrigger] action fires.
enum PostActionBehavior {
  /// The cell springs back to its resting position (offset 0).
  ///
  /// This is the default behavior.
  snapBack,

  /// The cell slides fully off screen to the left.
  ///
  /// The widget does NOT collapse its own height. The developer is responsible
  /// for removing the item from their list in response to
  /// [IntentionalSwipeConfig.onActionTriggered].
  animateOut,

  /// The cell remains at the fully-swiped position with the background visible.
  ///
  /// The user can swipe right to return the cell to the idle (resting) position.
  /// This is the only exit from the [stay] state within the widget.
  stay,
}
```

**Location**: `lib/src/actions/intentional/post_action_behavior.dart`
**Export**: `lib/swipe_action_cell.dart`

---

## New Data Class

### `SwipeAction`

```dart
/// Defines a single action button in a reveal-mode [SwipeActionCell] panel.
///
/// Pass a list of 1–3 [SwipeAction] objects to
/// [IntentionalSwipeConfig.actions]. More than 3 entries: only the first 3
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
  /// *second* tap (after the confirm-expand), not the first.
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
  });

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;
}
```

**Location**: `lib/src/actions/intentional/swipe_action.dart`
**Export**: `lib/swipe_action_cell.dart`

---

## New Configuration Object

### `IntentionalSwipeConfig`

```dart
/// Configuration for left-swipe intentional (one-shot) action behavior.
///
/// Pass as [SwipeActionCell.leftSwipe] to enable left-swipe intentional
/// semantics. When `null`, left-swipe intentional behavior is disabled entirely.
///
/// Two mutually exclusive modes are supported, set via [mode]:
/// - **[LeftSwipeMode.autoTrigger]**: Swipe fires a one-shot callback.
///   Post-action cell position controlled by [postActionBehavior].
/// - **[LeftSwipeMode.reveal]**: Swipe opens an action panel with 1–3 buttons.
///   Panel stays open until a button is tapped, the cell body is tapped, or
///   the user swipes right to close.
///
/// Example — auto-trigger (delete on swipe):
/// ```dart
/// SwipeActionCell(
///   leftSwipe: IntentionalSwipeConfig(
///     mode: LeftSwipeMode.autoTrigger,
///     postActionBehavior: PostActionBehavior.animateOut,
///     onActionTriggered: () => deleteItem(item),
///   ),
///   child: ListTile(title: Text(item.title)),
/// )
/// ```
///
/// Example — reveal panel:
/// ```dart
/// SwipeActionCell(
///   leftSwipe: IntentionalSwipeConfig(
///     mode: LeftSwipeMode.reveal,
///     actions: [
///       SwipeAction(
///         icon: const Icon(Icons.archive),
///         label: 'Archive',
///         backgroundColor: const Color(0xFF43A047),
///         foregroundColor: Colors.white,
///         onTap: () => archiveItem(item),
///       ),
///       SwipeAction(
///         icon: const Icon(Icons.delete),
///         label: 'Delete',
///         backgroundColor: const Color(0xFFE53935),
///         foregroundColor: Colors.white,
///         onTap: () => deleteItem(item),
///         isDestructive: true,
///       ),
///     ],
///   ),
///   child: ListTile(title: Text(item.title)),
/// )
/// ```
@immutable
class IntentionalSwipeConfig {
  /// Creates an [IntentionalSwipeConfig].
  ///
  /// [mode] is required. All other parameters are optional with sensible defaults.
  const IntentionalSwipeConfig({
    required this.mode,
    this.actions = const [],
    this.actionPanelWidth,
    this.postActionBehavior = PostActionBehavior.snapBack,
    this.requireConfirmation = false,
    this.enableHaptic = false,
    this.onActionTriggered,
    this.onSwipeCancelled,
    this.onPanelOpened,
    this.onPanelClosed,
  }) : assert(
         actionPanelWidth == null || actionPanelWidth > 0,
         'actionPanelWidth must be > 0 when provided',
       );

  /// The interaction mode. [LeftSwipeMode.autoTrigger] or [LeftSwipeMode.reveal].
  final LeftSwipeMode mode;

  /// The action buttons displayed in the panel. Used only in [LeftSwipeMode.reveal].
  ///
  /// Must contain 1–3 [SwipeAction] items. An empty list disables the feature.
  /// More than 3 items: only the first 3 are rendered (debug assertion fired).
  final List<SwipeAction> actions;

  /// The width of the action panel in logical pixels. Used only in [LeftSwipeMode.reveal].
  ///
  /// When `null`, width is auto-calculated from action count and content.
  /// Must be > 0 when provided.
  final double? actionPanelWidth;

  /// What the cell does after an auto-trigger action fires.
  /// Used only in [LeftSwipeMode.autoTrigger]. Default: [PostActionBehavior.snapBack].
  ///
  /// Has no effect in [LeftSwipeMode.reveal].
  final PostActionBehavior postActionBehavior;

  /// Whether a second swipe (or background-area tap) is required to confirm the action.
  /// Used only in [LeftSwipeMode.autoTrigger]. Default: `false`.
  ///
  /// When `true`, the first swipe past threshold holds the cell at the fully-open
  /// position (using the [SwipeActionCell.leftBackground] visual). A second left
  /// swipe past threshold, or a tap on the exposed [SwipeActionCell.leftBackground]
  /// area, fires [onActionTriggered]. A right swipe or cell-body tap cancels.
  ///
  /// Has no effect in [LeftSwipeMode.reveal].
  final bool requireConfirmation;

  /// Whether haptic feedback fires at swipe milestones.
  ///
  /// When `true`:
  /// - Light haptic fires once when the drag crosses the activation threshold.
  /// - Medium haptic fires when an action executes (button tap or auto-trigger fire).
  ///
  /// Default: `false`.
  final bool enableHaptic;

  /// Called when an auto-trigger action fires successfully.
  ///
  /// Fires after the animation settles at the open position (or after the
  /// confirmation is accepted, if [requireConfirmation] is `true`).
  /// Used only in [LeftSwipeMode.autoTrigger].
  final VoidCallback? onActionTriggered;

  /// Called when a left swipe is released below the activation threshold.
  ///
  /// Does NOT fire during the post-action snap-back following a successful trigger.
  /// Used only in [LeftSwipeMode.autoTrigger].
  final VoidCallback? onSwipeCancelled;

  /// Called when the reveal panel opens and the animation settles.
  /// Used only in [LeftSwipeMode.reveal].
  final VoidCallback? onPanelOpened;

  /// Called when the reveal panel closes, regardless of trigger (button tap,
  /// cell body tap, or right swipe). Used only in [LeftSwipeMode.reveal].
  final VoidCallback? onPanelClosed;

  /// Returns a copy with the specified fields replaced.
  IntentionalSwipeConfig copyWith({
    LeftSwipeMode? mode,
    List<SwipeAction>? actions,
    double? actionPanelWidth,
    PostActionBehavior? postActionBehavior,
    bool? requireConfirmation,
    bool? enableHaptic,
    VoidCallback? onActionTriggered,
    VoidCallback? onSwipeCancelled,
    VoidCallback? onPanelOpened,
    VoidCallback? onPanelClosed,
  });

  @override
  bool operator ==(Object other);

  @override
  int get hashCode;
}
```

**Location**: `lib/src/actions/intentional/intentional_swipe_config.dart`
**Export**: `lib/swipe_action_cell.dart`

---

## New Widget

### `SwipeActionPanel`

```dart
/// The reveal-mode action panel rendered behind a [SwipeActionCell] during a left swipe.
///
/// Intended for internal use by [SwipeActionCell] when
/// [IntentionalSwipeConfig.mode] is [LeftSwipeMode.reveal].
/// May also be used directly for custom layouts.
///
/// Renders a [Row] of action buttons, each sized proportionally to its
/// [SwipeAction.flex] weight. A destructive button expands to [panelWidth]
/// on the first tap and executes on the second tap.
class SwipeActionPanel extends StatefulWidget {
  /// Creates a [SwipeActionPanel].
  const SwipeActionPanel({
    super.key,
    required this.actions,
    required this.panelWidth,
    required this.onClose,
  }) : assert(actions.length >= 1 && actions.length <= 3,
             'actions must contain 1–3 items');

  /// The action buttons to display. Must be 1–3 items.
  final List<SwipeAction> actions;

  /// Total panel width in logical pixels.
  final double panelWidth;

  /// Called by the panel when any user interaction should close it.
  ///
  /// The panel itself does not close; it calls [onClose] and lets the parent
  /// ([SwipeActionCell]) drive the close animation.
  final VoidCallback onClose;
}
```

**Location**: `lib/src/actions/intentional/swipe_action_panel.dart`
**Export**: `lib/swipe_action_cell.dart`

---

## Updated Types

### `SwipeState` *(additive)*

One new value added to the existing enum:

```dart
enum SwipeState {
  idle,
  dragging,
  animatingToOpen,
  animatingToClose,
  revealed,
  animatingOut, // NEW: cell sliding fully off-screen after postActionBehavior: animateOut
}
```

**Location**: `lib/src/core/swipe_state.dart` *(update existing)*
**Export**: `lib/swipe_action_cell.dart` *(already exported)*

---

### `SwipeActionCell` *(additive — no breaking changes)*

One new parameter added. All existing parameters and defaults are unchanged.

```dart
class SwipeActionCell extends StatefulWidget {
  const SwipeActionCell({
    super.key,
    required this.child,
    this.gestureConfig = const SwipeGestureConfig(),
    this.animationConfig = const SwipeAnimationConfig(),
    this.onStateChanged,
    this.onProgressChanged,
    this.enabled = true,
    this.leftBackground,
    this.rightBackground,
    this.clipBehavior = Clip.hardEdge,
    this.borderRadius,
    this.rightSwipe,
    this.leftSwipe,         // NEW
  });

  // ... existing fields unchanged ...

  /// Configuration for left-swipe intentional (one-shot) action behavior.
  ///
  /// When non-null, left swipes past the activation threshold trigger either a
  /// one-shot action ([LeftSwipeMode.autoTrigger]) or open an action panel
  /// ([LeftSwipeMode.reveal]) according to [IntentionalSwipeConfig.mode].
  ///
  /// When `null` (default), left-swipe intentional behavior is entirely disabled.
  /// The [leftBackground] builder still applies for visual feedback during drag.
  final IntentionalSwipeConfig? leftSwipe;
}
```

**Location**: `lib/src/widget/swipe_action_cell.dart` *(update existing)*
**Export**: `lib/swipe_action_cell.dart` *(already exported)*

---

## New Barrel Exports

Add to `lib/swipe_action_cell.dart`:

```dart
// Intentional action (004-intentional-action)
export 'src/actions/intentional/left_swipe_mode.dart';
export 'src/actions/intentional/post_action_behavior.dart';
export 'src/actions/intentional/swipe_action.dart';
export 'src/actions/intentional/intentional_swipe_config.dart';
export 'src/actions/intentional/swipe_action_panel.dart';
```

---

## Breaking Changes

**None.** The `leftSwipe` parameter defaults to `null`, preserving all existing behavior.
`SwipeActionCell(child: myWidget)` continues to compile and behave exactly as in F001–F003.
`SwipeState.animatingOut` is additive — existing `switch` statements without a default will
need an exhaustive case added, but this is a compile-time signal, not a silent breakage.

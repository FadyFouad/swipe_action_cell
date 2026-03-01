# Public API Contract: Swipe Background Visual Layer

**Feature**: 002-swipe-background
**Date**: 2026-02-25

This document defines the complete public API surface added or modified by this feature.
All items listed here must be exported from `lib/swipe_action_cell.dart`.

---

## New Typedef (already scaffolded — confirm export)

### `SwipeBackgroundBuilder`

```dart
/// Signature for a background widget builder used with [SwipeActionCell].
///
/// Called on every animation frame while a swipe gesture is in progress or
/// a snap-back animation is running. The returned widget is rendered behind
/// the sliding child, clipped to the cell's bounds.
///
/// The [progress] argument reflects the current drag state, including the
/// direction, normalized ratio (0.0–1.0), activation status, and raw pixel
/// offset.
///
/// **Performance contract**: implementations MUST be lightweight. This
/// function is called up to 60 times per second during an active swipe.
/// Avoid async operations, expensive computation, or allocations in this
/// callback.
typedef SwipeBackgroundBuilder = Widget Function(
  BuildContext context,
  SwipeProgress progress,
);
```

**Location**: `lib/src/core/typedefs.dart` (already exists; verify it is exported)

---

## New Widget

### `SwipeActionBackground`

```dart
/// A built-in background widget for [SwipeActionCell] that provides
/// progress-reactive icon + label display.
///
/// Intended as a zero-configuration default for common swipe action
/// backgrounds (e.g., delete, archive, bookmark). Renders a centered icon
/// with an optional text label below it. All visual properties react to
/// [progress]:
///
/// - **Icon opacity**: fades in from 0.0 to 1.0 as [SwipeProgress.ratio]
///   increases from 0.0 to 1.0.
/// - **Icon scale**: scales from 0.0 to 1.0 proportionally with ratio.
/// - **Threshold bump**: produces a brief scale overshoot (+30%) when
///   [SwipeProgress.isActivated] first becomes `true`.
/// - **Background color**: darkens by up to 15% as ratio approaches 1.0.
///
/// ### Usage
///
/// ```dart
/// SwipeActionCell(
///   leftBackground: (context, progress) => SwipeActionBackground(
///     icon: const Icon(Icons.delete),
///     backgroundColor: Colors.red,
///     foregroundColor: Colors.white,
///     progress: progress,
///     label: 'Delete',
///   ),
///   child: MyListItem(),
/// )
/// ```
class SwipeActionBackground extends StatefulWidget {
  /// Creates a [SwipeActionBackground].
  ///
  /// [icon], [backgroundColor], [foregroundColor], and [progress] are
  /// required.
  const SwipeActionBackground({
    super.key,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.progress,
    this.label,
  });

  /// The icon displayed in the center of the background.
  ///
  /// Scales and fades with [SwipeProgress.ratio]. Receives [foregroundColor]
  /// via an [IconTheme] wrapper.
  final Widget icon;

  /// Fill color of the background panel.
  ///
  /// Darkens slightly (up to 15% lightness reduction) as
  /// [SwipeProgress.ratio] approaches 1.0 to signal proximity to the
  /// activation threshold.
  final Color backgroundColor;

  /// Color applied to [icon] and [label].
  final Color foregroundColor;

  /// The current swipe state, updated every frame by the parent builder.
  ///
  /// Pass the [SwipeProgress] received from [SwipeBackgroundBuilder] directly
  /// to this field.
  final SwipeProgress progress;

  /// Optional text label displayed below [icon] in a column layout.
  ///
  /// When `null`, no label space is reserved. When non-null, rendered as
  /// a 12sp text in [foregroundColor] below the icon with 4px spacing.
  final String? label;
}
```

**Location**: `lib/src/visual/swipe_action_background.dart` (new file)
**Export**: Add `export 'src/visual/swipe_action_background.dart';` to `lib/swipe_action_cell.dart`

---

## Modified Widget

### `SwipeActionCell` — new parameters

The following parameters are added to `SwipeActionCell`'s `const` constructor. All have
defaults and are fully backward-compatible.

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
    // ── New in 002-swipe-background ──────────────────────────────────────
    this.leftBackground,
    this.rightBackground,
    this.clipBehavior = Clip.hardEdge,
    this.borderRadius,
  });

  // ... existing parameters unchanged ...

  /// Builder for the background widget revealed during a left swipe.
  ///
  /// Called on every animation frame while a left swipe is in progress
  /// or a snap-back from a left swipe is running. When `null`, no background
  /// is rendered for left swipes (Principle IX: null = feature disabled).
  ///
  /// The builder MUST be lightweight — it is called up to 60 times per second.
  final SwipeBackgroundBuilder? leftBackground;

  /// Builder for the background widget revealed during a right swipe.
  ///
  /// Called on every animation frame while a right swipe is in progress
  /// or a snap-back from a right swipe is running. When `null`, no background
  /// is rendered for right swipes (Principle IX: null = feature disabled).
  ///
  /// The builder MUST be lightweight — it is called up to 60 times per second.
  final SwipeBackgroundBuilder? rightBackground;

  /// Determines how the background and child are clipped within the cell's
  /// bounding box.
  ///
  /// Defaults to [Clip.hardEdge] for performance (no anti-aliasing). Set to
  /// [Clip.antiAlias] for smoother rounded-corner edges at a small performance
  /// cost. Set to [Clip.none] to disable clipping entirely.
  final Clip clipBehavior;

  /// When non-null, clips the background and child to this rounded rectangle.
  ///
  /// Use this when the containing list item has rounded corners to prevent
  /// the background from bleeding outside the visual bounds. Combined with
  /// [clipBehavior] for clip quality control.
  final BorderRadius? borderRadius;
}
```

---

## Builder Contract Summary

| Invariant | Requirement |
|-----------|-------------|
| Call frequency | Every animation frame while `direction != SwipeDirection.none` |
| Thread | Main (UI) thread only; synchronous |
| Exception handling | Exceptions propagate — no catch by `SwipeActionCell` |
| Return value | Any non-null `Widget`; sized by `Positioned.fill` (cell full bounds) |
| Null builder | `SizedBox.shrink()` rendered; no error or warning |
| At idle | Builder not called; background slot empty |
| During snap-back | Builder called each frame; `ratio` decreases; `direction` stays set |

---

## Barrel Export Diff

Add to `lib/swipe_action_cell.dart`:

```dart
// Visual layer (002-swipe-background)
export 'src/visual/swipe_action_background.dart';
```

`SwipeBackgroundBuilder` is already exported via `src/core/typedefs.dart`. Verify this
export exists; no change needed if it does.

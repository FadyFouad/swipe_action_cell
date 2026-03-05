# Public API Contract: Prebuilt Zero-Configuration Templates (F014)

**Branch**: `013-prebuilt-templates` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)

---

## `TemplateStyle` Enum

```dart
/// Controls the visual style applied by template factory constructors.
///
/// - [TemplateStyle.auto]: Selects Material style on Android/web/desktop,
///   Cupertino style on iOS/macOS, based on [defaultTargetPlatform].
/// - [TemplateStyle.material]: Forces Material Design icons, sharp corners,
///   and [Clip.hardEdge] clipping regardless of the running platform.
/// - [TemplateStyle.cupertino]: Forces Cupertino icons, rounded corners
///   ([BorderRadius.circular(12)]), and [Clip.antiAlias] clipping regardless
///   of the running platform.
enum TemplateStyle {
  /// Automatically selects style based on [defaultTargetPlatform].
  auto,

  /// Forces Material Design visual style.
  material,

  /// Forces Cupertino visual style.
  cupertino,
}
```

**Exported from**: `lib/swipe_action_cell.dart`

---

## Factory Constructor: `SwipeActionCell.delete`

```dart
/// Creates a [SwipeActionCell] preconfigured for a destructive delete action.
///
/// A left swipe animates the cell off-screen and shows a built-in undo strip.
/// [onDeleted] fires only after the undo window expires without cancellation.
/// If the user taps the undo strip, the cell snaps back and [onDeleted] is
/// NOT called.
///
/// All parameters beyond [child] and [onDeleted] are optional overrides.
/// The cell functions correctly with only those two arguments.
///
/// See also:
///  * [SwipeActionCell.archive], for a non-undoable left-swipe removal.
///  * [SwipeActionCell.deleteMaterial], to force Material styling.
///  * [SwipeActionCell.deleteCupertino], to force Cupertino styling.
factory SwipeActionCell.delete({
  required Widget child,
  required VoidCallback onDeleted,
  Color? backgroundColor,
  Widget? icon,
  String? semanticLabel,
  TemplateStyle style = TemplateStyle.auto,
  SwipeController? controller,
})
```

**Behavior contract**:

| Scenario | Outcome |
|---|---|
| Left swipe past threshold | Cell animates off-screen; undo strip appears for 5 seconds |
| Undo strip tapped within 5 s | Cell snaps back; `onDeleted` NOT fired |
| Undo strip expires (5 s) | `onDeleted` fires |
| Right swipe | Ignored (no right config) |
| `backgroundColor` provided | Overrides red default; icon style still platform-adapted |
| `icon` provided | Overrides default trash icon; background color still platform-adapted |
| `style: material` on iOS | Material icon and sharp clip used regardless of platform |
| `style: cupertino` on Android | Cupertino icon and rounded clip used regardless of platform |
| `controller` provided | Controller can programmatically trigger or close the cell |

---

## Factory Constructor: `SwipeActionCell.archive`

```dart
/// Creates a [SwipeActionCell] preconfigured for an archive action.
///
/// A left swipe animates the cell off-screen and immediately calls [onArchived].
/// There is no undo window — the action fires as soon as the animation
/// completes. Use [SwipeActionCell.delete] if undo behavior is required.
///
/// See also:
///  * [SwipeActionCell.delete], for a left-swipe action with undo support.
///  * [SwipeActionCell.archiveMaterial], to force Material styling.
///  * [SwipeActionCell.archiveCupertino], to force Cupertino styling.
factory SwipeActionCell.archive({
  required Widget child,
  required VoidCallback onArchived,
  Color? backgroundColor,
  Widget? icon,
  String? semanticLabel,
  TemplateStyle style = TemplateStyle.auto,
  SwipeController? controller,
})
```

**Behavior contract**:

| Scenario | Outcome |
|---|---|
| Left swipe past threshold | Cell animates off-screen; `onArchived` fires immediately |
| Right swipe | Ignored (no right config) |
| No undo strip shown | Archive has no undo — this is by design |

---

## Factory Constructor: `SwipeActionCell.favorite`

```dart
/// Creates a [SwipeActionCell] preconfigured for a favorite-toggle action.
///
/// A right swipe fires [onToggle] with `!isFavorited`. During the drag,
/// the background icon cross-fades from an outline heart (at 0% progress)
/// to a filled heart (at 100% progress). The morph progress is proportional
/// to swipe progress at every frame.
///
/// Rebuild with the new [isFavorited] value to reflect the toggled state.
///
/// See also:
///  * [SwipeActionCell.checkbox], for a checkmark-style right-swipe toggle.
///  * [SwipeActionCell.favoriteMaterial], to force Material styling.
///  * [SwipeActionCell.favoriteCupertino], to force Cupertino styling.
factory SwipeActionCell.favorite({
  required Widget child,
  required bool isFavorited,
  required ValueChanged<bool> onToggle,
  Color? backgroundColor,
  Widget? outlineIcon,
  Widget? filledIcon,
  String? semanticLabel,
  TemplateStyle style = TemplateStyle.auto,
  SwipeController? controller,
})
```

**Behavior contract**:

| Scenario | Outcome |
|---|---|
| Right swipe (not favorited) | `onToggle(true)` fires; filled heart visible at completion |
| Right swipe (favorited) | `onToggle(false)` fires; outline heart visible at completion |
| Progress at 50% | Icon halfway between outline and filled (equal opacity blend) |
| Left swipe | Ignored (no left config) |
| `outlineIcon` provided | Replaces default outline heart at progress = 0.0 |
| `filledIcon` provided | Replaces default filled heart at progress = 1.0 |

---

## Factory Constructor: `SwipeActionCell.checkbox`

```dart
/// Creates a [SwipeActionCell] preconfigured for a checkbox-completion toggle.
///
/// A right swipe fires [onChanged] with `!isChecked`. During the drag,
/// the background indicator cross-fades from an unchecked state (at 0%)
/// to a checked state (at 100%), proportional to swipe progress.
///
/// Rebuild with the new [isChecked] value to reflect the toggled state.
///
/// See also:
///  * [SwipeActionCell.favorite], for a heart-style right-swipe toggle.
///  * [SwipeActionCell.checkboxMaterial], to force Material styling.
///  * [SwipeActionCell.checkboxCupertino], to force Cupertino styling.
factory SwipeActionCell.checkbox({
  required Widget child,
  required bool isChecked,
  required ValueChanged<bool> onChanged,
  Color? backgroundColor,
  Widget? uncheckedIcon,
  Widget? checkedIcon,
  String? semanticLabel,
  TemplateStyle style = TemplateStyle.auto,
  SwipeController? controller,
})
```

**Behavior contract**:

| Scenario | Outcome |
|---|---|
| Right swipe (unchecked) | `onChanged(true)` fires; checked indicator visible |
| Right swipe (checked) | `onChanged(false)` fires; unchecked indicator visible |
| Progress at 50% | Indicator halfway between unchecked and checked |
| Left swipe | Ignored (no left config) |

---

## Factory Constructor: `SwipeActionCell.counter`

```dart
/// Creates a [SwipeActionCell] preconfigured for a counter-increment action.
///
/// Each right swipe fires [onCountChanged] with `count + 1`. When [count]
/// equals [max] (and [max] is positive), the right swipe gesture is completely
/// disabled — no animation, no callback. Values of [max] that are null, zero,
/// or negative are treated as unlimited.
///
/// The current [count] value is displayed in the swipe background during drag.
///
/// See also:
///  * [SwipeActionCell.counterMaterial], to force Material styling.
///  * [SwipeActionCell.counterCupertino], to force Cupertino styling.
factory SwipeActionCell.counter({
  required Widget child,
  required int count,
  required ValueChanged<int> onCountChanged,
  int? max,
  Color? backgroundColor,
  Widget? icon,
  String? semanticLabel,
  TemplateStyle style = TemplateStyle.auto,
  SwipeController? controller,
})
```

**Behavior contract**:

| Scenario | Outcome |
|---|---|
| Right swipe, `count < max` | `onCountChanged(count + 1)` fires |
| Right swipe, `count == max` (max > 0) | No gesture recognized; `onCountChanged` NOT fired |
| Right swipe, `max == null` | `onCountChanged(count + 1)` fires; no ceiling |
| Right swipe, `max <= 0` | Treated as null (unlimited); `onCountChanged(count + 1)` fires |
| Left swipe | Ignored (no left config) |
| Count shown in background | Visible during active drag |

---

## Factory Constructor: `SwipeActionCell.standard`

```dart
/// Creates a [SwipeActionCell] with a composite configuration combining a
/// right-swipe favorite toggle and a left-swipe reveal action panel.
///
/// Either direction can be independently disabled by omitting the
/// corresponding parameter:
/// - Omit [onFavorited] (or pass `null`) → right swipe completely disabled.
/// - Omit [actions] or pass an empty list → left swipe completely disabled.
/// - Omit both → cell is a plain non-interactive wrapper.
///
/// See also:
///  * [SwipeActionCell.favorite], for a standalone favorite-only template.
///  * [SwipeActionCell.standardMaterial], to force Material styling.
///  * [SwipeActionCell.standardCupertino], to force Cupertino styling.
factory SwipeActionCell.standard({
  required Widget child,
  ValueChanged<bool>? onFavorited,
  bool isFavorited = false,
  List<SwipeAction>? actions,
  TemplateStyle style = TemplateStyle.auto,
  SwipeController? controller,
})
```

**Behavior contract**:

| Scenario | Outcome |
|---|---|
| `onFavorited` non-null, right swipe | `onFavorited` fires with toggled state |
| `onFavorited == null` | Right swipe disabled entirely (null config) |
| `actions` non-empty, left swipe past threshold | Reveal panel slides in with action buttons |
| `actions` null or empty | Left swipe disabled entirely (null config) |
| Both `onFavorited` null and `actions` empty | Cell renders as plain non-interactive wrapper |

---

## Static Variant Methods

All static methods accept the same parameters as the corresponding factory constructor, minus the `style` parameter (it is pre-set).

```dart
// Delete variants
static SwipeActionCell deleteMaterial({
  required Widget child, required VoidCallback onDeleted,
  Color? backgroundColor, Widget? icon, String? semanticLabel,
  SwipeController? controller,
})

static SwipeActionCell deleteCupertino({
  required Widget child, required VoidCallback onDeleted,
  Color? backgroundColor, Widget? icon, String? semanticLabel,
  SwipeController? controller,
})

// Archive variants
static SwipeActionCell archiveMaterial({
  required Widget child, required VoidCallback onArchived,
  Color? backgroundColor, Widget? icon, String? semanticLabel,
  SwipeController? controller,
})

static SwipeActionCell archiveCupertino({
  required Widget child, required VoidCallback onArchived,
  Color? backgroundColor, Widget? icon, String? semanticLabel,
  SwipeController? controller,
})

// Favorite variants
static SwipeActionCell favoriteMaterial({
  required Widget child, required bool isFavorited,
  required ValueChanged<bool> onToggle,
  Color? backgroundColor, Widget? outlineIcon, Widget? filledIcon,
  String? semanticLabel, SwipeController? controller,
})

static SwipeActionCell favoriteCupertino({
  required Widget child, required bool isFavorited,
  required ValueChanged<bool> onToggle,
  Color? backgroundColor, Widget? outlineIcon, Widget? filledIcon,
  String? semanticLabel, SwipeController? controller,
})

// Checkbox variants
static SwipeActionCell checkboxMaterial({
  required Widget child, required bool isChecked,
  required ValueChanged<bool> onChanged,
  Color? backgroundColor, Widget? uncheckedIcon, Widget? checkedIcon,
  String? semanticLabel, SwipeController? controller,
})

static SwipeActionCell checkboxCupertino({
  required Widget child, required bool isChecked,
  required ValueChanged<bool> onChanged,
  Color? backgroundColor, Widget? uncheckedIcon, Widget? checkedIcon,
  String? semanticLabel, SwipeController? controller,
})

// Counter variants
static SwipeActionCell counterMaterial({
  required Widget child, required int count,
  required ValueChanged<int> onCountChanged,
  int? max, Color? backgroundColor, Widget? icon,
  String? semanticLabel, SwipeController? controller,
})

static SwipeActionCell counterCupertino({
  required Widget child, required int count,
  required ValueChanged<int> onCountChanged,
  int? max, Color? backgroundColor, Widget? icon,
  String? semanticLabel, SwipeController? controller,
})

// Standard variants
static SwipeActionCell standardMaterial({
  required Widget child,
  ValueChanged<bool>? onFavorited, bool isFavorited = false,
  List<SwipeAction>? actions, SwipeController? controller,
})

static SwipeActionCell standardCupertino({
  required Widget child,
  ValueChanged<bool>? onFavorited, bool isFavorited = false,
  List<SwipeAction>? actions, SwipeController? controller,
})
```

---

## Internal Helper Functions

Location: `lib/src/templates/swipe_cell_templates.dart` (not exported)

```dart
// Resolves TemplateStyle.auto to material or cupertino based on platform.
TemplateStyle _resolveStyle(TemplateStyle style)

// Builds SwipeVisualConfig with platform-appropriate clip/borderRadius.
SwipeVisualConfig _buildVisualConfig({
  required TemplateStyle resolvedStyle,
  required SwipeBackgroundBuilder? leftBackground,
  required SwipeBackgroundBuilder? rightBackground,
})

// Returns the platform-appropriate icon set for the delete template.
({Widget primaryIcon, Color backgroundColor})
    _deleteAssets(TemplateStyle resolvedStyle, Widget? iconOverride, Color? colorOverride)

// Returns the platform-appropriate icon set for the archive template.
({Widget primaryIcon, Color backgroundColor})
    _archiveAssets(TemplateStyle resolvedStyle, Widget? iconOverride, Color? colorOverride)

// Returns the platform-appropriate icon pair for a morph icon template.
({Widget outlineIcon, Widget filledIcon, Color backgroundColor})
    _favoriteAssets(TemplateStyle resolvedStyle,
        Widget? outlineOverride, Widget? filledOverride, Color? colorOverride)

// Returns the platform-appropriate icon pair for checkbox template.
({Widget uncheckedIcon, Widget checkedIcon, Color backgroundColor})
    _checkboxAssets(TemplateStyle resolvedStyle,
        Widget? uncheckedOverride, Widget? checkedOverride, Color? colorOverride)

// Returns the platform-appropriate icon for counter template.
({Widget icon, Color backgroundColor})
    _counterAssets(TemplateStyle resolvedStyle, Widget? iconOverride, Color? colorOverride)
```

---

## Cross-Cutting Constraints

| Constraint | Source | Applies To |
|---|---|---|
| Factory constructors are NOT `const` | Constitution VI exception (runtime `defaultTargetPlatform`) | All 6 factory constructors |
| Returns standard `SwipeActionCell` | Constitution I | All templates |
| No new widget type in tree | Constitution I | All templates |
| All public members carry `///` docs | Constitution VIII | All factory constructors, static methods, `TemplateStyle` |
| `TemplateStyle` exported from barrel | Development Standards | `lib/swipe_action_cell.dart` |
| `SwipeController` wired transparently | FR-013-010 | All templates |
| Works without `MaterialApp` / `CupertinoApp` | FR-013-012 | All templates |
| No external packages | Constitution IV | All templates |

# Data Model: Prebuilt Zero-Configuration Templates (F014)

**Branch**: `013-prebuilt-templates` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)

---

## Public Types

### `TemplateStyle` (enum — public)

Location: `lib/src/templates/template_style.dart`

| Value | Meaning |
|---|---|
| `auto` | Detect platform at call time via `defaultTargetPlatform`; iOS/macOS → Cupertino; others → Material |
| `material` | Force Material icons, `Clip.hardEdge`, no `borderRadius` |
| `cupertino` | Force Cupertino icons, `Clip.antiAlias`, `BorderRadius.circular(12)` |

**Constraints**:
- Enum is exhaustive (sealed — no other values)
- Exported from `lib/swipe_action_cell.dart`
- No `const` restriction — enum values are always `const`

---

## Modified Type: `SwipeActionCell` (factory constructors + static methods)

Location: `lib/src/widget/swipe_action_cell.dart` (MODIFIED)

Six new factory constructors and twelve new static methods are added to the existing `SwipeActionCell` class. All factory constructors return a fully configured `SwipeActionCell` instance.

### Factory Constructor: `SwipeActionCell.delete`

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `child` | `Widget` | ✅ | — | The cell's content widget |
| `onDeleted` | `VoidCallback` | ✅ | — | Fires after the undo window expires without cancellation |
| `backgroundColor` | `Color?` | — | Red (platform-adapted) | Background color of the swipe area |
| `icon` | `Widget?` | — | Trash icon (platform-adapted) | Icon shown in the swipe background |
| `semanticLabel` | `String?` | — | `"Delete item"` | Accessibility label for the swipe action |
| `style` | `TemplateStyle` | — | `TemplateStyle.auto` | Platform style override |
| `controller` | `SwipeController?` | — | `null` | Optional external controller |

**Wires to**: `LeftSwipeConfig(mode: autoTrigger, postActionBehavior: animateOut)` + `SwipeUndoConfig(onUndoExpired: onDeleted)`

---

### Factory Constructor: `SwipeActionCell.archive`

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `child` | `Widget` | ✅ | — | The cell's content widget |
| `onArchived` | `VoidCallback` | ✅ | — | Fires immediately after swipe animation completes |
| `backgroundColor` | `Color?` | — | Teal (platform-adapted) | Background color of the swipe area |
| `icon` | `Widget?` | — | Archive box icon (platform-adapted) | Icon shown in the swipe background |
| `semanticLabel` | `String?` | — | `"Archive item"` | Accessibility label |
| `style` | `TemplateStyle` | — | `TemplateStyle.auto` | Platform style override |
| `controller` | `SwipeController?` | — | `null` | Optional external controller |

**Wires to**: `LeftSwipeConfig(mode: autoTrigger, postActionBehavior: animateOut, onSwipeCompleted: (_) => onArchived())` (no `SwipeUndoConfig`)

---

### Factory Constructor: `SwipeActionCell.favorite`

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `child` | `Widget` | ✅ | — | The cell's content widget |
| `isFavorited` | `bool` | ✅ | — | Current favorited state (drives icon morph) |
| `onToggle` | `ValueChanged<bool>` | ✅ | — | Fires with toggled state on swipe completion |
| `backgroundColor` | `Color?` | — | Amber/yellow | Background color during right swipe |
| `outlineIcon` | `Widget?` | — | Heart outline (platform-adapted) | Shown at `progress = 0.0` |
| `filledIcon` | `Widget?` | — | Heart filled (platform-adapted) | Shown at `progress = 1.0` |
| `semanticLabel` | `String?` | — | Derived from `isFavorited` state | Accessibility label |
| `style` | `TemplateStyle` | — | `TemplateStyle.auto` | Platform style override |
| `controller` | `SwipeController?` | — | `null` | Optional external controller |

**Wires to**: `RightSwipeConfig(onSwipeCompleted: (_) => onToggle(!isFavorited))` + `SwipeVisualConfig(rightBackground: SwipeMorphIcon(...))` background builder

---

### Factory Constructor: `SwipeActionCell.checkbox`

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `child` | `Widget` | ✅ | — | The cell's content widget |
| `isChecked` | `bool` | ✅ | — | Current checked state (drives indicator transition) |
| `onChanged` | `ValueChanged<bool>` | ✅ | — | Fires with toggled state on swipe completion |
| `backgroundColor` | `Color?` | — | Green | Background color during right swipe |
| `uncheckedIcon` | `Widget?` | — | Empty checkbox (platform-adapted) | Shown at `progress = 0.0` |
| `checkedIcon` | `Widget?` | — | Checked checkbox (platform-adapted) | Shown at `progress = 1.0` |
| `semanticLabel` | `String?` | — | Derived from `isChecked` state | Accessibility label |
| `style` | `TemplateStyle` | — | `TemplateStyle.auto` | Platform style override |
| `controller` | `SwipeController?` | — | `null` | Optional external controller |

**Wires to**: `RightSwipeConfig(onSwipeCompleted: (_) => onChanged(!isChecked))` + `SwipeVisualConfig(rightBackground: SwipeMorphIcon(...))` background builder

---

### Factory Constructor: `SwipeActionCell.counter`

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `child` | `Widget` | ✅ | — | The cell's content widget |
| `count` | `int` | ✅ | — | Current count value (displayed during swipe) |
| `onCountChanged` | `ValueChanged<int>` | ✅ | — | Fires with `count + 1` on swipe completion |
| `max` | `int?` | — | `null` (unlimited) | Maximum allowed count; values ≤ 0 treated as unlimited |
| `backgroundColor` | `Color?` | — | Blue | Background color during right swipe |
| `icon` | `Widget?` | — | Add/plus icon (platform-adapted) | Icon shown alongside count in background |
| `semanticLabel` | `String?` | — | `"Increment"` | Accessibility label |
| `style` | `TemplateStyle` | — | `TemplateStyle.auto` | Platform style override |
| `controller` | `SwipeController?` | — | `null` | Optional external controller |

**Wires to**:
- `rightSwipeConfig: RightSwipeConfig(...)` when `count < max` (or max is null/≤0)
- `rightSwipeConfig: null` when `count >= max` (swipe disabled at max — Constitution IX)

**Background builder**: shows `count` value as text centered in the right swipe area.

---

### Factory Constructor: `SwipeActionCell.standard`

| Parameter | Type | Required | Default | Description |
|---|---|---|---|---|
| `child` | `Widget` | ✅ | — | The cell's content widget |
| `onFavorited` | `ValueChanged<bool>?` | — | `null` | Toggle callback; `null` disables right swipe |
| `isFavorited` | `bool` | — | `false` | Current favorited state for right swipe |
| `actions` | `List<SwipeAction>?` | — | `null` | Reveal panel actions; null/empty disables left swipe |
| `style` | `TemplateStyle` | — | `TemplateStyle.auto` | Platform style override |
| `controller` | `SwipeController?` | — | `null` | Optional external controller |

**Wires to**:
- `rightSwipeConfig`: non-null only when `onFavorited != null` (favorite toggle behavior)
- `leftSwipeConfig`: non-null only when `actions != null && actions!.isNotEmpty` (reveal panel)

---

## Static Variant Methods (12 total)

Location: `lib/src/widget/swipe_action_cell.dart`

Each static method mirrors a factory constructor with `style` pre-set. Same parameters minus `style`.

| Static Method | Equivalent To |
|---|---|
| `SwipeActionCell.deleteMaterial(...)` | `SwipeActionCell.delete(..., style: TemplateStyle.material)` |
| `SwipeActionCell.deleteCupertino(...)` | `SwipeActionCell.delete(..., style: TemplateStyle.cupertino)` |
| `SwipeActionCell.archiveMaterial(...)` | `SwipeActionCell.archive(..., style: TemplateStyle.material)` |
| `SwipeActionCell.archiveCupertino(...)` | `SwipeActionCell.archive(..., style: TemplateStyle.cupertino)` |
| `SwipeActionCell.favoriteMaterial(...)` | `SwipeActionCell.favorite(..., style: TemplateStyle.material)` |
| `SwipeActionCell.favoriteCupertino(...)` | `SwipeActionCell.favorite(..., style: TemplateStyle.cupertino)` |
| `SwipeActionCell.checkboxMaterial(...)` | `SwipeActionCell.checkbox(..., style: TemplateStyle.material)` |
| `SwipeActionCell.checkboxCupertino(...)` | `SwipeActionCell.checkbox(..., style: TemplateStyle.cupertino)` |
| `SwipeActionCell.counterMaterial(...)` | `SwipeActionCell.counter(..., style: TemplateStyle.material)` |
| `SwipeActionCell.counterCupertino(...)` | `SwipeActionCell.counter(..., style: TemplateStyle.cupertino)` |
| `SwipeActionCell.standardMaterial(...)` | `SwipeActionCell.standard(..., style: TemplateStyle.material)` |
| `SwipeActionCell.standardCupertino(...)` | `SwipeActionCell.standard(..., style: TemplateStyle.cupertino)` |

---

## Internal Types

### `_TemplateAssets` (internal record — conceptual)

Not a named class; resolved inline in helper functions. Represents the platform-resolved set of visual assets for a template:

| Field | Type | Description |
|---|---|---|
| `primaryIcon` | `Widget` | Main action icon (delete, archive, add, etc.) |
| `outlineIcon` | `Widget` | Outline/unfilled variant (favorite, checkbox start state) |
| `filledIcon` | `Widget` | Filled variant (favorite, checkbox end state) |
| `backgroundColor` | `Color` | Swipe area background color |
| `clipBehavior` | `Clip` | `Clip.hardEdge` (Material) or `Clip.antiAlias` (Cupertino) |
| `borderRadius` | `BorderRadius?` | `null` (Material) or `BorderRadius.circular(12)` (Cupertino) |

---

## Platform Asset Mapping

| Template | Material Icon | Cupertino Icon | Default BG Color |
|---|---|---|---|
| Delete | `Icons.delete_outline` / `Icons.delete` | `CupertinoIcons.trash` | Red (`Color(0xFFE53935)`) |
| Archive | `Icons.archive_outlined` / `Icons.archive` | `CupertinoIcons.archivebox` | Teal (`Color(0xFF00897B)`) |
| Favorite (outline) | `Icons.favorite_border` | `CupertinoIcons.heart` | Amber (`Color(0xFFFFB300)`) |
| Favorite (filled) | `Icons.favorite` | `CupertinoIcons.heart_fill` | Amber (`Color(0xFFFFB300)`) |
| Checkbox (unchecked) | `Icons.check_box_outline_blank` | `CupertinoIcons.circle` | Green (`Color(0xFF43A047)`) |
| Checkbox (checked) | `Icons.check_box` | `CupertinoIcons.checkmark_circle_fill` | Green (`Color(0xFF43A047)`) |
| Counter | `Icons.add_circle_outline` | `CupertinoIcons.add_circled` | Blue (`Color(0xFF1E88E5)`) |
| Standard (right) | Same as Favorite | Same as Favorite | Amber |
| Standard (left) | Reveal panel (action icons from consumer) | Same | Per action |

**Visual config per style**:

| Field | Material | Cupertino |
|---|---|---|
| `clipBehavior` | `Clip.hardEdge` | `Clip.antiAlias` |
| `borderRadius` | `null` | `BorderRadius.circular(12)` |

---

## New Files

```text
lib/src/templates/
├── template_style.dart         ← TemplateStyle enum (public)
└── swipe_cell_templates.dart   ← Internal helpers (private top-level functions)
```

## Modified Files

```text
lib/src/widget/swipe_action_cell.dart   ← +6 factory constructors, +12 static methods
lib/swipe_action_cell.dart              ← +1 export (TemplateStyle)
```

## New Test Files

```text
test/templates/
├── template_style_test.dart        ← Unit tests: TemplateStyle resolution, platform mapping
├── delete_template_test.dart       ← Widget tests: delete + archive templates (US1)
├── toggle_template_test.dart       ← Widget tests: favorite + checkbox templates (US2)
├── counter_template_test.dart      ← Widget tests: counter template (US3)
├── standard_template_test.dart     ← Widget tests: standard template (US4)
└── platform_adaptation_test.dart   ← Widget tests: platform detection + style overrides (US5)
```

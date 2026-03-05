# Research: Prebuilt Zero-Configuration Templates (F014)

**Branch**: `013-prebuilt-templates` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)

---

## D1: Factory Constructors vs Separate Widget Class

**Decision**: Factory constructors on `SwipeActionCell` itself (not a subclass or separate widget).

**Rationale**: Constitution I (Composition over Inheritance) forbids subclassing. A separate widget class (e.g., `SwipeDeleteCell`) would require consumers to learn a new widget name. Factory constructors produce standard `SwipeActionCell` instances — consumers can inspect, configure, and test them exactly like manually-built cells. No wrapper indirection, no new types in the widget tree.

**Alternatives considered**:
- `SwipeDeleteCell` / `SwipeArchiveCell` etc. — rejected: Constitution I violation; adds confusion; forces consumers to memorize multiple widget names.
- Static top-level functions `deleteCell(...)` — rejected: not idiomatic Flutter; no named constructor discoverability via IDE autocomplete on `SwipeActionCell.`.
- Extension methods — rejected: Dart extensions cannot add constructors; adds a separate import requirement.

---

## D2: Platform Detection Mechanism

**Decision**: `defaultTargetPlatform` from `flutter/foundation.dart`. iOS and macOS map to Cupertino style; all other platforms (Android, web, Windows, Linux) map to Material style.

**Rationale**: `defaultTargetPlatform` is available without a `BuildContext`, which means factory constructors (which have no widget tree access) can resolve the style at call time. `Theme.of(context).platform` requires a context; factory constructors are static and have no context parameter. `Platform.isIOS` from `dart:io` would crash on web.

**Alternatives considered**:
- `Theme.of(context).platform` — rejected: factory constructors have no `BuildContext`; adding one as a required param conflicts with the zero-configuration goal.
- `Platform.isIOS` from `dart:io` — rejected: crashes on web (Constitution IV requires web support).
- Always default to Material, let consumer override — rejected: violates FR-013-008 (auto-detection required).

---

## D3: Style Override API

**Decision**: Static methods on `SwipeActionCell` with a `Material` / `Cupertino` suffix (e.g., `SwipeActionCell.deleteMaterial(...)`, `SwipeActionCell.deleteCupertino(...)`). Each static method delegates to the corresponding factory constructor with `style` pre-set.

**Rationale**: Named factory constructors in Dart cannot share a prefix with an existing factory (e.g., `SwipeActionCell.delete` and `SwipeActionCell.deleteMaterial` would both be valid). Static methods are equally discoverable via IDE and can be documented separately. This is consistent with the hint ("static methods forcing platform styling").

**Alternatives considered**:
- Named constructors `SwipeActionCell.deleteMaterial()` — feasible in Dart; chose static methods because static methods are clearer about returning a pre-configured value without the semantic implication of "this is a different kind of cell."
- `TemplateStyle` parameter only (no convenience variants) — rejected: FR-013-009 requires explicit override; static methods are more ergonomic for the common override case.

---

## D4: Delete Template Undo Wiring

**Decision**: Wire `onDeleted` callback to `SwipeUndoConfig.onUndoExpired`. The undo overlay shows automatically (`showBuiltInOverlay: true`). If the user taps undo, `onUndoTriggered` fires (no deletion). If the window expires, `onUndoExpired` fires and `onDeleted` is called.

**Rationale**: `SwipeUndoConfig` from F011 was designed for exactly this use case. The 5-second default undo window matches the spec assumption. No new mechanism needed.

**Wiring**:
```
LeftSwipeConfig(
  mode: LeftSwipeMode.autoTrigger,
  postActionBehavior: PostActionBehavior.animateOut,
)
SwipeUndoConfig(
  onUndoExpired: onDeleted,    // ← deletion fires here
)
```

**Alternatives considered**:
- Calling `onDeleted` directly from `onSwipeCompleted` — rejected: US1 acceptance scenario 2 requires undo to cancel the deletion; direct firing ignores the undo window.
- Custom timer in the template — rejected: F011 (`SwipeUndoConfig`) already manages the timer; duplicating it violates DRY and could cause race conditions.

---

## D5: Favorite/Checkbox Icon Morphing

**Decision**: Use `SwipeMorphIcon` (from F012) inside the `SwipeVisualConfig.rightBackground` builder. Pass `progress.ratio` as the morph progress. `onSwipeCompleted` fires `onToggle(!currentState)`.

**Rationale**: `SwipeMorphIcon` already provides cross-fade between two icon widgets proportional to a `double` progress value — exactly what US2 acceptance scenario 3 requires ("icon is visually halfway between outline and filled at 50% progress"). Reusing it requires zero new code for the morphing behavior.

**Wiring**:
```
RightSwipeConfig(
  onSwipeCompleted: (_) => onToggle(!isFavorited),
)
SwipeVisualConfig(
  rightBackground: (context, progress) => ColoredBox(
    color: backgroundColor ?? _defaultFavoriteColor,
    child: Center(
      child: SwipeMorphIcon(
        startIcon: outlineIcon ?? _platformOutlineHeart(style),
        endIcon: filledIcon ?? _platformFilledHeart(style),
        progress: progress.ratio,
      ),
    ),
  ),
)
```

**Alternatives considered**:
- Animate icon inside the factory constructor using an internal `AnimationController` — rejected: factory constructors return `StatelessWidget` instances; cannot hold animation state.
- New `SwipeToggleIcon` widget — rejected: `SwipeMorphIcon` already handles this; duplication violates DRY.

---

## D6: Counter Template Controlled Mode

**Decision**: Uncontrolled mode — `RightSwipeConfig.onSwipeCompleted` fires `onCountChanged(count + 1)` (or does nothing when `count >= max`). The current `count` is displayed in the background builder. No controlled-mode wiring via `RightSwipeConfig.value` needed for the template.

**Rationale**: The counter template just needs to fire `onCountChanged` on each completed swipe. The consumer owns the state (Dart `count` param is passed fresh each rebuild). The max check is straightforward: compare `count` against `max` before firing. No need for the controlled `value` field (which is for progress tracking, not discrete counter state).

**Max check wiring**:
```
onSwipeCompleted: (max == null || max <= 0 || count < max)
    ? (_) => onCountChanged(count + 1)
    : null,  // null disables swipe completion callback
```

Wait, actually if `onSwipeCompleted` is null, does that prevent the swipe? No — the swipe still activates. We need to disable the right swipe config entirely when at max. Better:

```
rightSwipeConfig: (max == null || max <= 0 || count < max)
    ? RightSwipeConfig(onSwipeCompleted: (_) => onCountChanged(count + 1), ...)
    : null,  // null config = right swipe disabled at max
```

**Alternatives considered**:
- `RightSwipeConfig.value = count.toDouble()` controlled mode — rejected: doesn't directly prevent action at max; requires more complex wiring.
- Clamp inside `onSwipeCompleted` — rejected: the swipe gesture still completes visually even if no state change; disabling via null config gives cleaner UX (no animation when at max).

---

## D7: Standard Template Null Config Pattern (Constitution IX)

**Decision**: `rightSwipeConfig` is set to `null` when `onFavorited == null`; `leftSwipeConfig` is set to `null` when `actions` is null or empty. Disabling via null config complies with Constitution IX and FR-013-006/US4 acceptance scenarios 3 and 4.

**Rationale**: Constitution IX: "A null value for any optional configuration object MUST completely disable the corresponding feature." The standard template must not recognize gestures in a disabled direction — null config achieves this at zero overhead.

**Wiring**:
```
SwipeActionCell(
  rightSwipeConfig: onFavorited != null
      ? RightSwipeConfig(...) : null,
  leftSwipeConfig: (actions != null && actions!.isNotEmpty)
      ? LeftSwipeConfig(...) : null,
)
```

**Alternatives considered**:
- Check at gesture recognition level — rejected: Constitution IX explicitly mandates null config as the disable mechanism.
- Boolean `enableFavorite` / `enableReveal` flags — rejected: Constitution IX forbids boolean feature flags.

---

## D8: Const-Ability of Factory Constructors

**Decision**: Factory constructors for templates are **not** `const`. This is a documented Constitution VI exception.

**Rationale**: Factory constructors call `defaultTargetPlatform` at runtime when `style == TemplateStyle.auto`. Runtime calls prevent `const` construction. The generated `SwipeActionCell` instances themselves are also non-const (they contain icon widgets built from runtime values). The underlying `LeftSwipeConfig`, `RightSwipeConfig`, etc. config objects remain `const`-friendly when platform style is forced (Material or Cupertino) rather than auto.

**Documented exception**: Constitution VI requires const configs; factory constructors produce `SwipeActionCell` instances (not config objects) and require runtime platform resolution. This is the minimum necessary deviation.

**Alternatives considered**:
- Require consumer to pass `style` explicitly (no auto-detect) — would allow const but eliminates the zero-configuration goal (FR-013-008 requires platform auto-detection).
- Two-step: `const SwipeDeleteConfig()` + `SwipeActionCell.fromConfig(config)` — adds complexity; consumers would still need to know platform variants.

---

## D9: Implementation Helpers Location

**Decision**: Internal helper functions (platform resolution, config builders per template) live in `lib/src/templates/swipe_cell_templates.dart` as private top-level functions. `TemplateStyle` enum lives in `lib/src/templates/template_style.dart` (public, exported).

**Rationale**: The `swipe_action_cell.dart` widget file is already ~1300 lines. Adding 6 factory constructors + 12 static methods + their config-building logic would bloat it significantly. Extracting the config-building helpers to `lib/src/templates/` follows the feature-first pattern established by `gesture/`, `animation/`, `painting/`, etc. The factory constructors in `swipe_action_cell.dart` become thin dispatch functions that call the helpers.

**Alternatives considered**:
- All logic inline in `swipe_action_cell.dart` — rejected: file would exceed 2000 lines; violates the feature-first directory convention.
- Dart `part`/`part of` — feasible but obscure; top-level import with private helpers is simpler.

---

## D10: RTL and Accessibility Inheritance

**Decision**: Templates inherit all RTL and accessibility behavior from the underlying `SwipeActionCell` widget. Templates provide default `semanticConfig` with action-appropriate labels; consumers can override via the `semanticLabel` parameter.

**Rationale**: `SwipeActionCell` from F008 already handles RTL direction reversal — left swipe becomes right swipe in RTL contexts without any additional template logic. Semantic labels flow through `SwipeSemanticConfig` (from F008). Templates only need to provide sensible defaults; the widget handles the rest.

**Default semantic labels** (English, RTL-aware wording is handled by F008):
- Delete: `"Delete item"`
- Archive: `"Archive item"`
- Favorite (unfavorited): `"Add to favorites"` / (favorited): `"Remove from favorites"`
- Checkbox (unchecked): `"Mark as complete"` / (checked): `"Mark as incomplete"`
- Counter: `"Increment"`
- Standard: combines favorite + reveal labels

**Alternatives considered**:
- Generate RTL labels manually in templates — rejected: F008 already handles this; duplication risks inconsistency.
- No default semantic labels — rejected: FR-013-011 mandates default labels.

# Implementation Plan: Prebuilt Zero-Configuration Templates (F014)

**Branch**: `013-prebuilt-templates` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/013-prebuilt-templates/spec.md`

---

## Summary

Add six factory constructors and twelve static variant methods to `SwipeActionCell` for common swipe patterns: delete, archive, favorite, checkbox, counter, and standard. Each constructor returns a fully configured `SwipeActionCell` instance with platform-appropriate defaults (Material or Cupertino). Implementation helpers live in `lib/src/templates/`. A new public `TemplateStyle` enum drives platform override semantics. No new widget types are introduced — all templates are pure `SwipeActionCell` instances (Constitution I).

---

## Technical Context

**Language/Version**: Dart ≥ 3.4.0 < 4.0.0
**Primary Dependencies**: Flutter SDK only — `material` and `cupertino` icon libraries (SDK-bundled, Constitution IV)
**Storage**: N/A (no persistence — templates are stateless config builders)
**Testing**: `flutter test` (widget tests + unit tests)
**Target Platform**: All Flutter-supported platforms (iOS, Android, web, macOS, Windows, Linux)
**Performance Goals**: Zero overhead — templates compose existing widgets; no new rendering layers
**Constraints**: Factory constructors cannot be `const` (runtime `defaultTargetPlatform`); documented Constitution VI exception
**Scale/Scope**: 2 new source files, 2 modified source files, 6 new test files

---

## Constitution Check

*GATE: Must pass before implementation. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| I. Composition over Inheritance | ✅ PASS | All factory constructors return standard `SwipeActionCell` instances — no subclassing |
| II. Explicit State Machine | ✅ PASS | No new states; templates wire into the existing state machine via existing config objects |
| III. Spring-Based Physics | ✅ PASS | Templates add no new animations; all motion is through the existing spring system |
| IV. Zero External Runtime Deps | ✅ PASS | Material and Cupertino icon libraries are part of the Flutter SDK |
| V. Controlled/Uncontrolled Pattern | ✅ PASS | All templates accept optional `SwipeController`; all function without one |
| VI. Const-Friendly Configuration | ⚠️ EXCEPTION | Factory constructors are non-const (require `defaultTargetPlatform` at runtime) — see Complexity Tracking |
| VII. Test-First | ✅ PASS | Tests written before implementation in every cluster (NON-NEGOTIABLE) |
| VIII. Dartdoc Everything | ✅ PASS | All public members carry `///` comments per Development Standards |
| IX. Null Config = Feature Disabled | ✅ PASS | Standard template: null `onFavorited` → null `rightSwipeConfig`; empty `actions` → null `leftSwipeConfig` |
| X. 60 fps Budget | ✅ PASS | Templates add zero rendering overhead — they are configuration-only builders |

---

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| Constitution VI: factory constructors cannot be `const` | `defaultTargetPlatform` is a runtime constant — its value differs between devices and cannot be evaluated at compile time. Icon and color defaults depend on the resolved style. | Forcing consumers to pass `style` explicitly (to enable `const`) eliminates the zero-configuration goal (FR-013-008). A separate const config + factory approach adds complexity and still cannot be `const` at the factory level. |

---

## Project Structure

### Documentation (this feature)

```text
specs/013-prebuilt-templates/
├── plan.md              ← This file
├── research.md          ← Phase 0 output
├── data-model.md        ← Phase 1 output
├── quickstart.md        ← Phase 1 output
├── contracts/
│   └── public-api.md    ← Phase 1 output
└── tasks.md             ← Phase 2 output (/speckit.tasks — NOT created by /speckit.plan)
```

### Source Code

```text
lib/
├── swipe_action_cell.dart           ← MODIFIED: add TemplateStyle export
└── src/
    ├── templates/                   ← NEW directory (F014)
    │   ├── template_style.dart      ← TemplateStyle enum (public)
    │   └── swipe_cell_templates.dart ← Internal helper functions (private)
    └── widget/
        └── swipe_action_cell.dart   ← MODIFIED: +6 factory constructors, +12 static methods

test/
└── templates/                       ← NEW test directory
    ├── template_style_test.dart
    ├── delete_template_test.dart
    ├── toggle_template_test.dart
    ├── counter_template_test.dart
    ├── standard_template_test.dart
    └── platform_adaptation_test.dart
```

**Structure Decision**: Single project (library package). New `lib/src/templates/` directory follows the feature-first pattern established by `gesture/`, `animation/`, `painting/`, etc. Factory constructors live in the existing `swipe_action_cell.dart` class file; their config-building logic is extracted to `lib/src/templates/` to keep the widget file manageable.

---

## Phase 0: Research Output

See [research.md](research.md) for all 10 architectural decisions (D1–D10).

Key decisions summary:
- **D1** Factory constructors on `SwipeActionCell` — not a subclass (Constitution I)
- **D2** Platform detection via `defaultTargetPlatform` — no `BuildContext` required
- **D3** Style overrides via static methods (`deleteMaterial`, `deleteCupertino`, etc.)
- **D4** Delete undo wired to `SwipeUndoConfig.onUndoExpired` (5 s default)
- **D5** Favorite/checkbox use `SwipeMorphIcon` from F012 in background builder
- **D6** Counter uses null `rightSwipeConfig` at max (Constitution IX compliant)
- **D7** Standard template: null callbacks → null configs (Constitution IX)
- **D8** Constitution VI exception — factory constructors non-const (documented)
- **D9** Helpers in `lib/src/templates/` (not inlined in widget file)
- **D10** RTL and accessibility inherited from `SwipeActionCell` (F008 handles)

---

## Phase 1: Design Artifacts

- **Data Model**: [data-model.md](data-model.md) — types, fields, platform asset mapping
- **Public API Contract**: [contracts/public-api.md](contracts/public-api.md) — Dart signatures, behavior tables
- **Quickstart**: [quickstart.md](quickstart.md) — 12 test scenarios, 47 test checkpoints

---

## Implementation Clusters

```
Cluster A ─────────────────────── TemplateStyle (foundation)
  T001: tests for TemplateStyle + _resolveStyle() (RED)
  T002: TemplateStyle enum + template_style.dart
  T003: internal helper module swipe_cell_templates.dart (stubs)

Cluster B ─────────────────────── Delete + Archive [US1, after A]
  T004: tests for delete template (RED)
  T005: tests for archive template (RED)
  T006: _deleteAssets() + _archiveAssets() + _buildVisualConfig() helpers
  T007: SwipeActionCell.delete() factory constructor
  T008: SwipeActionCell.archive() factory constructor
  T009: deleteMaterial, deleteCupertino, archiveMaterial, archiveCupertino static methods

Cluster C ─────────────────────── Favorite + Checkbox [US2, parallel with B after A]
  T010: tests for favorite template (RED)
  T011: tests for checkbox template (RED)
  T012: _favoriteAssets() + _checkboxAssets() helpers
  T013: SwipeActionCell.favorite() factory constructor
  T014: SwipeActionCell.checkbox() factory constructor
  T015: favoriteMaterial, favoriteCupertino, checkboxMaterial, checkboxCupertino static methods

Cluster D ─────────────────────── Counter [US3, parallel with B+C after A]
  T016: tests for counter template (RED)
  T017: _counterAssets() helper
  T018: SwipeActionCell.counter() factory constructor
  T019: counterMaterial, counterCupertino static methods

Cluster E ─────────────────────── Standard [US4, after B+C — reuses favorite builder]
  T020: tests for standard template (RED)
  T021: SwipeActionCell.standard() factory constructor
  T022: standardMaterial, standardCupertino static methods

Cluster F ─────────────────────── Platform adaptation tests [US5, after B+C+D+E]
  T023: platform detection tests (Material default, Cupertino for iOS/macOS) (RED → GREEN)
  T024: color/icon override tests (FR-013-007)

Cluster G ─────────────────────── Exports + polish [after F]
  T025: add TemplateStyle barrel export to lib/swipe_action_cell.dart
  T026: flutter analyze + dart format pass
  T027: regression run (flutter test)
```

**Dependency graph**:
```
A → B [parallel]
A → C [parallel with B]
A → D [parallel with B, C]
B + C → E  (standard reuses _favoriteAssets from C)
B + C + D + E → F
F → G
```

---

## Key Implementation Notes

### `TemplateStyle` Resolution

```dart
// lib/src/templates/swipe_cell_templates.dart

TemplateStyle _resolveStyle(TemplateStyle style) {
  if (style != TemplateStyle.auto) return style;
  return (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS)
      ? TemplateStyle.cupertino
      : TemplateStyle.material;
}
```

### Visual Config Builder

```dart
SwipeVisualConfig _buildVisualConfig({
  required TemplateStyle resolvedStyle,
  SwipeBackgroundBuilder? leftBackground,
  SwipeBackgroundBuilder? rightBackground,
}) {
  return SwipeVisualConfig(
    leftBackground: leftBackground,
    rightBackground: rightBackground,
    clipBehavior: resolvedStyle == TemplateStyle.cupertino
        ? Clip.antiAlias
        : Clip.hardEdge,
    borderRadius: resolvedStyle == TemplateStyle.cupertino
        ? const BorderRadius.all(Radius.circular(12))
        : null,
  );
}
```

### Delete Factory Constructor

```dart
// lib/src/widget/swipe_action_cell.dart

factory SwipeActionCell.delete({
  required Widget child,
  required VoidCallback onDeleted,
  Color? backgroundColor,
  Widget? icon,
  String? semanticLabel,
  TemplateStyle style = TemplateStyle.auto,
  SwipeController? controller,
}) {
  final resolved = _resolveStyle(style);
  final assets = _deleteAssets(resolved, icon, backgroundColor);
  return SwipeActionCell(
    controller: controller,
    leftSwipeConfig: LeftSwipeConfig(
      mode: LeftSwipeMode.autoTrigger,
      postActionBehavior: PostActionBehavior.animateOut,
      enableHaptic: true,
    ),
    undoConfig: SwipeUndoConfig(
      onUndoExpired: onDeleted,
    ),
    visualConfig: _buildVisualConfig(
      resolvedStyle: resolved,
      leftBackground: (context, progress) => ColoredBox(
        color: assets.backgroundColor,
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: assets.primaryIcon,
          ),
        ),
      ),
    ),
    semanticConfig: SwipeSemanticConfig(
      leftActionLabel: semanticLabel ?? 'Delete item',
    ),
    child: child,
  );
}
```

### Archive Factory Constructor

```dart
factory SwipeActionCell.archive({
  required Widget child,
  required VoidCallback onArchived,
  Color? backgroundColor,
  Widget? icon,
  String? semanticLabel,
  TemplateStyle style = TemplateStyle.auto,
  SwipeController? controller,
}) {
  final resolved = _resolveStyle(style);
  final assets = _archiveAssets(resolved, icon, backgroundColor);
  return SwipeActionCell(
    controller: controller,
    leftSwipeConfig: LeftSwipeConfig(
      mode: LeftSwipeMode.autoTrigger,
      postActionBehavior: PostActionBehavior.animateOut,
      onSwipeCompleted: (_) => onArchived(),
      enableHaptic: true,
    ),
    visualConfig: _buildVisualConfig(
      resolvedStyle: resolved,
      leftBackground: (context, progress) => ColoredBox(
        color: assets.backgroundColor,
        child: Align(
          alignment: AlignmentDirectional.centerEnd,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: assets.primaryIcon,
          ),
        ),
      ),
    ),
    semanticConfig: SwipeSemanticConfig(
      leftActionLabel: semanticLabel ?? 'Archive item',
    ),
    child: child,
  );
}
```

### Favorite Factory Constructor

```dart
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
}) {
  final resolved = _resolveStyle(style);
  final assets = _favoriteAssets(resolved, outlineIcon, filledIcon, backgroundColor);
  return SwipeActionCell(
    controller: controller,
    rightSwipeConfig: RightSwipeConfig(
      onSwipeCompleted: (_) => onToggle(!isFavorited),
      enableHaptic: true,
    ),
    visualConfig: _buildVisualConfig(
      resolvedStyle: resolved,
      rightBackground: (context, progress) => ColoredBox(
        color: assets.backgroundColor,
        child: Center(
          child: SwipeMorphIcon(
            startIcon: assets.outlineIcon,
            endIcon: assets.filledIcon,
            progress: progress.ratio,
          ),
        ),
      ),
    ),
    semanticConfig: SwipeSemanticConfig(
      rightActionLabel: semanticLabel ??
          (isFavorited ? 'Remove from favorites' : 'Add to favorites'),
    ),
    child: child,
  );
}
```

### Counter Factory Constructor (max enforcement via null config)

```dart
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
}) {
  final resolved = _resolveStyle(style);
  final assets = _counterAssets(resolved, icon, backgroundColor);
  final atMax = max != null && max > 0 && count >= max;
  return SwipeActionCell(
    controller: controller,
    // Null config when at max → right swipe disabled (Constitution IX)
    rightSwipeConfig: atMax ? null : RightSwipeConfig(
      onSwipeCompleted: (_) => onCountChanged(count + 1),
      enableHaptic: true,
    ),
    visualConfig: _buildVisualConfig(
      resolvedStyle: resolved,
      rightBackground: atMax ? null : (context, progress) => ColoredBox(
        color: assets.backgroundColor,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              assets.primaryIcon,
              const SizedBox(width: 8),
              Text(
                '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    semanticConfig: SwipeSemanticConfig(
      rightActionLabel: semanticLabel ?? 'Increment',
    ),
    child: child,
  );
}
```

### Standard Factory Constructor

```dart
factory SwipeActionCell.standard({
  required Widget child,
  ValueChanged<bool>? onFavorited,
  bool isFavorited = false,
  List<SwipeAction>? actions,
  TemplateStyle style = TemplateStyle.auto,
  SwipeController? controller,
}) {
  final resolved = _resolveStyle(style);
  final favoriteAssets = _favoriteAssets(resolved, null, null, null);
  final hasRight = onFavorited != null;
  final hasLeft = actions != null && actions.isNotEmpty;
  return SwipeActionCell(
    controller: controller,
    rightSwipeConfig: hasRight ? RightSwipeConfig(
      onSwipeCompleted: (_) => onFavorited(!isFavorited),
      enableHaptic: true,
    ) : null,
    leftSwipeConfig: hasLeft ? LeftSwipeConfig(
      mode: LeftSwipeMode.reveal,
      actions: actions,
      enableHaptic: true,
    ) : null,
    visualConfig: _buildVisualConfig(
      resolvedStyle: resolved,
      rightBackground: hasRight ? (context, progress) => ColoredBox(
        color: favoriteAssets.backgroundColor,
        child: Center(
          child: SwipeMorphIcon(
            startIcon: favoriteAssets.outlineIcon,
            endIcon: favoriteAssets.filledIcon,
            progress: progress.ratio,
          ),
        ),
      ) : null,
    ),
    child: child,
  );
}
```

### Static Variant Methods (pattern)

```dart
/// Creates a [SwipeActionCell] delete template with forced Material styling.
static SwipeActionCell deleteMaterial({
  required Widget child,
  required VoidCallback onDeleted,
  Color? backgroundColor,
  Widget? icon,
  String? semanticLabel,
  SwipeController? controller,
}) => SwipeActionCell.delete(
  child: child,
  onDeleted: onDeleted,
  backgroundColor: backgroundColor,
  icon: icon,
  semanticLabel: semanticLabel,
  style: TemplateStyle.material,
  controller: controller,
);

/// Creates a [SwipeActionCell] delete template with forced Cupertino styling.
static SwipeActionCell deleteCupertino({
  required Widget child,
  required VoidCallback onDeleted,
  Color? backgroundColor,
  Widget? icon,
  String? semanticLabel,
  SwipeController? controller,
}) => SwipeActionCell.delete(
  child: child,
  onDeleted: onDeleted,
  backgroundColor: backgroundColor,
  icon: icon,
  semanticLabel: semanticLabel,
  style: TemplateStyle.cupertino,
  controller: controller,
);
// ... (remaining 10 static variants follow same pattern)
```

### Asset Helpers (in `swipe_cell_templates.dart`)

```dart
({Widget primaryIcon, Color backgroundColor})
    _deleteAssets(TemplateStyle style, Widget? iconOverride, Color? colorOverride) {
  final isCupertino = style == TemplateStyle.cupertino;
  return (
    primaryIcon: iconOverride ??
        (isCupertino
            ? const Icon(CupertinoIcons.trash, color: Colors.white, size: 28)
            : const Icon(Icons.delete_outline, color: Colors.white, size: 28)),
    backgroundColor: colorOverride ?? const Color(0xFFE53935),
  );
}

({Widget primaryIcon, Color backgroundColor})
    _archiveAssets(TemplateStyle style, Widget? iconOverride, Color? colorOverride) {
  final isCupertino = style == TemplateStyle.cupertino;
  return (
    primaryIcon: iconOverride ??
        (isCupertino
            ? const Icon(CupertinoIcons.archivebox, color: Colors.white, size: 28)
            : const Icon(Icons.archive_outlined, color: Colors.white, size: 28)),
    backgroundColor: colorOverride ?? const Color(0xFF00897B),
  );
}

({Widget outlineIcon, Widget filledIcon, Color backgroundColor})
    _favoriteAssets(TemplateStyle style,
        Widget? outlineOverride, Widget? filledOverride, Color? colorOverride) {
  final isCupertino = style == TemplateStyle.cupertino;
  return (
    outlineIcon: outlineOverride ??
        (isCupertino
            ? const Icon(CupertinoIcons.heart, color: Colors.white, size: 28)
            : const Icon(Icons.favorite_border, color: Colors.white, size: 28)),
    filledIcon: filledOverride ??
        (isCupertino
            ? const Icon(CupertinoIcons.heart_fill, color: Colors.white, size: 28)
            : const Icon(Icons.favorite, color: Colors.white, size: 28)),
    backgroundColor: colorOverride ?? const Color(0xFFFFB300),
  );
}

({Widget uncheckedIcon, Widget checkedIcon, Color backgroundColor})
    _checkboxAssets(TemplateStyle style,
        Widget? uncheckedOverride, Widget? checkedOverride, Color? colorOverride) {
  final isCupertino = style == TemplateStyle.cupertino;
  return (
    uncheckedIcon: uncheckedOverride ??
        (isCupertino
            ? const Icon(CupertinoIcons.circle, color: Colors.white, size: 28)
            : const Icon(Icons.check_box_outline_blank, color: Colors.white, size: 28)),
    checkedIcon: checkedOverride ??
        (isCupertino
            ? const Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.white, size: 28)
            : const Icon(Icons.check_box, color: Colors.white, size: 28)),
    backgroundColor: colorOverride ?? const Color(0xFF43A047),
  );
}

({Widget primaryIcon, Color backgroundColor})
    _counterAssets(TemplateStyle style, Widget? iconOverride, Color? colorOverride) {
  final isCupertino = style == TemplateStyle.cupertino;
  return (
    primaryIcon: iconOverride ??
        (isCupertino
            ? const Icon(CupertinoIcons.add_circled, color: Colors.white, size: 28)
            : const Icon(Icons.add_circle_outline, color: Colors.white, size: 28)),
    backgroundColor: colorOverride ?? const Color(0xFF1E88E5),
  );
}
```

---

## Post-Design Constitution Re-Check

All 10 principles confirmed compliant after design. One documented exception (Principle VI / factory constructors non-const) is justified and recorded in Complexity Tracking above. No gate violations. Proceed to `/speckit.tasks`.

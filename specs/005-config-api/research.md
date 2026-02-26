# Research: Consolidated Configuration API & Theme Support (F005)

**Branch**: `005-config-api` | **Date**: 2026-02-26

---

## R1 — Config File Placement

**Decision**: New config types (`RightSwipeConfig`, `LeftSwipeConfig`, `SwipeVisualConfig`,
`SwipeActionCellTheme`) live in `lib/src/config/`. Gesture and animation configs stay in their
current directories (`lib/src/gesture/`, `lib/src/animation/`).

**Rationale**: CLAUDE.md pre-declares `lib/src/config/` as the F6 home, keeping the
feature-first directory structure consistent. Moving the two renamed action configs
(`ProgressiveSwipeConfig` → `RightSwipeConfig`, `IntentionalSwipeConfig` → `LeftSwipeConfig`)
into `lib/src/config/` is correct because they are now package-level config objects, not
feature-specific action implementations. Their enums and supporting types (`LeftSwipeMode`,
`PostActionBehavior`, `SwipeAction`, `OverflowBehavior`, etc.) remain in their original
`actions/` subdirectories — they are still behavioural types, not configuration types.

**Alternatives considered**:
- Keep renamed configs in `actions/progressive/` and `actions/intentional/` — rejected: creates
  false impression that the config type is implementation-internal.
- Move all config objects including gesture/animation — rejected: overkill and breaks the clean
  per-feature structure of F1/F2.

---

## R2 — ThemeExtension Lookup

**Decision**: `SwipeActionCellTheme` extends `ThemeExtension<SwipeActionCellTheme>` and is
looked up with `Theme.of(context).extension<SwipeActionCellTheme>()`. A static helper
`SwipeActionCellTheme.maybeOf(context)` wraps this call and returns `null` when absent.

**Rationale**: `ThemeExtension` is the canonical Flutter mechanism for distributing custom
theme data through the widget tree. It integrates with `Theme.copyWith()` and
`ThemeData.extensions` without introducing any `InheritedWidget` boilerplate. The `maybeOf()`
helper follows the `MediaQuery.maybeOf()` / `Navigator.maybeOf()` Flutter convention, signalling
that absence is expected (the widget has no hard dependency on the theme being present).

**Alternatives considered**:
- Custom `InheritedWidget` (`SwipeActionCellThemeScope`) — rejected: `ThemeExtension` already
  provides identical functionality and composes naturally with the host app's `MaterialApp` /
  `CupertinoApp`.
- `of()` that throws if absent — rejected: the spec explicitly requires the widget to work with
  zero configuration; a hard lookup that throws would violate that guarantee.

---

## R3 — Preset Calibration Values

**Decision**:

`SwipeGestureConfig` presets:
- `loose()`: `deadZone = 4.0`, `velocityThreshold = 300.0`
- `tight()`: `deadZone = 24.0`, `velocityThreshold = 1000.0`
- Distinguishing ratio: `tight().deadZone / loose().deadZone = 6.0×` ✓ (≥ 2× required)

`SwipeAnimationConfig` presets:
- `smooth()`: `activationThreshold = 0.5`, `completionSpring = SpringConfig(stiffness: 180.0, damping: 45.0)`, `snapBackSpring = SpringConfig(stiffness: 160.0, damping: 42.0)`, `resistanceFactor = 0.45`
- `snappy()`: `activationThreshold = 0.3`, `completionSpring = SpringConfig(stiffness: 700.0, damping: 26.0)`, `snapBackSpring = SpringConfig(stiffness: 550.0, damping: 24.0)`, `resistanceFactor = 0.60`
- Distinguishing ratio: `snappy().completionSpring.stiffness / smooth().completionSpring.stiffness = 3.89×` ✓ (≥ 2× required)

**Rationale**: Values were chosen to satisfy the ≥ 2× rule from the spec (SC-003, FR-004) while
producing perceptibly distinct behaviour. `tight()` requires a deliberate wrist flick to
register; `loose()` responds to a casual brush. `snappy()` is appropriate for deletion/archive
patterns where the user wants decisive feedback; `smooth()` suits passive reveal or progress
patterns. The default constructor values are unchanged, preserving F001–F004 behaviour (FR-011).

**Alternatives considered**:
- `tight().deadZone = 16.0` (only 4×) — accepted as satisfying the rule but chose 24 for more
  perceivable difference and to leave headroom for `copyWith` tuning.
- `snappy().stiffness = 1200.0` — rejected: overshoots at typical panel widths and feels jarring
  on slow devices; 700 provides snappiness without bounce artifacts.

---

## R4 — Background Builder Typedef Reuse

**Decision**: `SwipeVisualConfig.leftBackground` and `SwipeVisualConfig.rightBackground` use the
existing `SwipeBackgroundBuilder` typedef from `lib/src/core/typedefs.dart`. No new typedef is
introduced.

**Rationale**: The typedef already captures the exact signature required
(`Widget Function(BuildContext, SwipeProgress)`). Reusing it keeps the public API surface DRY
and avoids confusing consumers with two names for the same function shape.

**Alternatives considered**:
- Inline function type in `SwipeVisualConfig` — rejected: anonymous function types in public API
  fields hinder documentation and IDE completion.

---

## R5 — SwipeController Stub

**Decision**: `SwipeController extends ChangeNotifier`. No functional API is exposed in F005.
The class exists to validate the parameter slot and allow consumers to construct/dispose it
safely. A single `///`-documented class body with a `dispose()` override is sufficient.

**Rationale**: Extending `ChangeNotifier` is the least-surprise choice — it is the Flutter
idiomatic base for listenable objects and gives F007 a clean extension point. It also allows
the host to call `controller.dispose()` without branching.

**Alternatives considered**:
- Empty class with no supertype — rejected: F007 will need listeners; changing the base later
  would be a breaking API change.
- Full stub with no-op `open()`/`close()` methods — rejected: spec FR-012 says
  "accepted without crash or warning" only; premature API exposure creates false expectations.

---

## R6 — Breaking Change Strategy

**Decision**: Remove `ProgressiveSwipeConfig` and `IntentionalSwipeConfig` entirely. No
`typedef ProgressiveSwipeConfig = RightSwipeConfig` aliases. Update `CHANGELOG.md` with a
dedicated migration section listing every renamed type and parameter. Bump to next minor version
(e.g., `0.5.0`) signalling a semver-compatible breaking change within pre-1.0.

**Rationale**: FR-013 explicitly forbids deprecation aliases. The package is pre-1.0 so
consumers expect breaking changes. The CHANGELOG migration section (SC-007) provides the
find-and-replace guide that makes the migration mechanical. A minor version bump (not patch) is
appropriate because this changes the public API surface.

**Alternatives considered**:
- `@Deprecated` annotations with a one-release grace period — rejected by FR-013.
- Major version bump to 1.0.0 — out of scope; the spec says "implementation decision" but
  pre-1.0 minor bumps are conventional for breaking changes in Flutter packages.

---

## R7 — Null Gesture/Animation Config Semantics

**Decision**: When `gestureConfig` or `animationConfig` is `null` on `SwipeActionCell`, the
widget falls through first to the theme, then to `const SwipeGestureConfig()` /
`const SwipeAnimationConfig()` as hard defaults. The effective config is resolved in `build()`:

```dart
final effectiveGesture = gestureConfig
    ?? theme?.gestureConfig
    ?? const SwipeGestureConfig();
```

This differs from the current API where `gestureConfig` has a non-null default value in the
constructor. Making it nullable in F005 enables theme-driven defaults (US3) without changing the
observable defaults (FR-011).

**Rationale**: The current default-value approach prevents theme inheritance — if the consumer
omits `gestureConfig`, Dart assigns the constructor default before the widget can consult the
theme. Making the parameter nullable allows the null-check cascade to resolve the theme value
before falling back to the package default.

**Alternatives considered**:
- Keep non-null with default and compare against a sentinel value — rejected: fragile; sentinel
  equality is harder to document and test.
- Use `late final` with `initState()` resolution — rejected: increases complexity; theme lookup
  must happen in `build()` where `context` is available.

---

## R8 — `lerp()` Hard Cutover Implementation

**Decision**: `SwipeActionCellTheme.lerp()` returns `other` when `t >= 1.0`, otherwise returns
`this`. No numeric interpolation of any field.

```dart
@override
SwipeActionCellTheme lerp(ThemeExtension<SwipeActionCellTheme>? other, double t) {
  if (t >= 1.0) return (other as SwipeActionCellTheme?) ?? this;
  return this;
}
```

**Rationale**: Spring stiffness, damping, dead zones, and gesture thresholds are not perceptually
meaningful to interpolate. A mid-lerp mix (e.g., stiffness=425 when blending 850 and 0) would
produce undefined physical behaviour. The hard cutover matches the clarification (Session
2026-02-26, Q2) and is consistent with Flutter's own `ThemeData.lerp()` fallback for types it
cannot interpolate smoothly.

**Alternatives considered**:
- Numeric interpolation of numeric fields — rejected by clarification Q2.
- Delegate lerp to each config object's own `lerp()` — rejected: config objects are
  `@immutable` const classes with no lerp contract; adding one would bloat the API.

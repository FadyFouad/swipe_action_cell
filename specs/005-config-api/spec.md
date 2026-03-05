# Feature Specification: Consolidated Configuration API & Theme Support

**Feature Branch**: `005-config-api`
**Created**: 2026-02-26
**Status**: Draft
**Input**: User description: "Consolidate all configuration for the swipe_action_cell package into a clean, hierarchical API and add theme support."

## Clarifications

### Session 2026-02-26

- Q: Where do `onStateChanged` and `onProgressChanged` callbacks live in the new API? → A: Both stay as top-level `SwipeActionCell` parameters (no change from today).
- Q: How does `SwipeActionCellTheme.lerp()` behave for theme transitions? → A: Hard cutover — returns `other` when `t >= 1.0`, `this` otherwise; no numeric interpolation of spring or gesture values.
- Q: What is the measurable definition of "meaningfully distinct" for preset constructors? → A: The primary distinguishing parameter of each preset must differ by at least 2× from its counterpart (e.g., `tight().deadZone` ≥ 2× `loose().deadZone`; `snappy().completionSpring.stiffness` ≥ 2× `smooth().completionSpring.stiffness`). Verifiable in a unit test.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Adopt the Consolidated Config API (Priority: P1) 🎯 MVP

A developer upgrading from F001–F004 updates their `SwipeActionCell` usage to the new
parameter names and config groupings. Related options are now co-located in named config
objects, making intent immediately clear. The widget behaves identically to before; only
the API surface changes.

**Why this priority**: Config consolidation is the foundational change that all other
stories build on. Without it, presets, theme support, and validation have nowhere to
attach. It also delivers the most immediate ergonomic value: a smaller, cleaner constructor.

**Independent Test**: Construct a `SwipeActionCell` using all five config objects
(`rightSwipeConfig`, `leftSwipeConfig`, `gestureConfig`, `animationConfig`,
`visualConfig`) and verify the cell behaves identically to the equivalent F001–F004 API.

**Acceptance Scenarios**:

1. **Given** a developer migrating from F004, **When** they pass `leftSwipeConfig: LeftSwipeConfig(...)`, **Then** the cell behaves identically to the previous `leftSwipe` parameter.
2. **Given** a developer migrating from F003, **When** they pass `rightSwipeConfig: RightSwipeConfig(...)`, **Then** the cell behaves identically to the previous `rightSwipe` parameter.
3. **Given** a developer configuring visual behavior, **When** they pass `visualConfig: SwipeVisualConfig(leftBackground: ..., clipBehavior: ...)`, **Then** the cell renders identically to using the previous top-level `leftBackground` and `clipBehavior` parameters.
4. **Given** `leftSwipeConfig: null`, **When** the user attempts a left swipe, **Then** no left-swipe behavior occurs — no gesture recognition, no callbacks, no background, zero overhead.
5. **Given** a cell with `enabled: false`, **When** any swipe is attempted, **Then** all gesture recognition is bypassed and touch events pass through to the child unchanged.
6. **Given** a developer who omits `gestureConfig` and `animationConfig`, **When** the cell renders, **Then** sensible built-in defaults apply with no configuration required.

---

### User Story 2 — Rapid Configuration with Preset Constructors (Priority: P2)

A developer wants a working swipe cell without fine-tuning individual spring or gesture
parameters. They pick a named preset that bundles opinionated defaults for a common use
case — `tight` for precise interactions, `loose` for casual swiping, `snappy` for crisp
animations, `smooth` for soft transitions.

**Why this priority**: Presets lower the time-to-working-widget and make the package
accessible to developers unfamiliar with spring physics. They serve as a discovery
mechanism: seeing preset names teaches developers which knobs exist.

**Independent Test**: Configure a cell with `gestureConfig: SwipeGestureConfig.tight()`
and `animationConfig: SwipeAnimationConfig.snappy()`; verify the cell is functional and
that switching to `.loose()` and `.smooth()` produces visually distinct behavior.

**Acceptance Scenarios**:

1. **Given** `SwipeGestureConfig.tight()`, **Then** the cell requires more deliberate, longer swipes before registering direction — larger dead zone and higher velocity threshold than `loose()`.
2. **Given** `SwipeGestureConfig.loose()`, **Then** the cell registers direction from short, light swipes.
3. **Given** `SwipeAnimationConfig.snappy()`, **Then** open and close animations feel fast and crisp with minimal overshoot.
4. **Given** `SwipeAnimationConfig.smooth()`, **Then** open and close animations feel gradual and soft with a gentle settle.
5. **Given** a cell with no preset specified, **When** it renders, **Then** behavior is identical to the defaults from F001–F004 — no regression.
6. **Given** any preset constructor, **When** inspected, **Then** it produces a value that supports `copyWith` for further customisation.

---

### User Story 3 — App-Wide Defaults via `SwipeActionCellTheme` (Priority: P3)

A developer configures swipe behavior once in their app's theme. All `SwipeActionCell`
instances in the tree inherit those defaults without any per-cell code. Where a specific
cell needs different behavior, the developer passes a local config that fully replaces
the theme value for that parameter.

**Why this priority**: App-wide defaults eliminate per-cell repetition and ensure
behavioral consistency. Per-widget overrides retain flexibility for special cases. This is
essential for app-wide branding of swipe interactions (e.g., all cells use the same haptic
pattern and spring feel).

**Independent Test**: Install a `SwipeActionCellTheme` with `gestureConfig:
SwipeGestureConfig.loose()`. Verify a cell with no local `gestureConfig` behaves loosely.
Add a cell with `gestureConfig: SwipeGestureConfig.tight()` and verify only that cell
changes; all others remain loose.

**Acceptance Scenarios**:

1. **Given** a `SwipeActionCellTheme` in the app theme with a `gestureConfig`, **When** a `SwipeActionCell` with no local `gestureConfig` renders, **Then** it uses the theme's gesture config.
2. **Given** a `SwipeActionCellTheme` and a cell with an explicit local `gestureConfig`, **When** the cell renders, **Then** the local config takes full precedence; all other theme-provided configs still apply.
3. **Given** no `SwipeActionCellTheme` in the app theme, **When** any `SwipeActionCell` renders, **Then** the package's built-in defaults are used with no crash or warning.
4. **Given** a `SwipeActionCellTheme` that provides a `visualConfig`, **When** a cell has no local `visualConfig`, **Then** the theme's backgrounds and clip behavior are applied.
5. **Given** a theme `animationConfig: SwipeAnimationConfig.smooth()` and a cell that overrides with `animationConfig: SwipeAnimationConfig.snappy()`, **Then** only that cell snaps; all others remain smooth.

---

### User Story 4 — Clear, Actionable Validation Errors (Priority: P4)

A developer who misconfigures the widget sees a meaningful error message in debug mode
that names exactly what is wrong and how to fix it. In release mode no crash occurs.

**Why this priority**: Validation messages save integration time. Without them, a
developer must read source code to decode a vague assertion failure. A one-sentence
message can reduce the feedback loop from minutes to seconds.

**Independent Test**: Provide three intentionally invalid configurations; verify each
produces a distinct, readable message that identifies the field name, the provided value,
and the valid range or requirement.

**Acceptance Scenarios**:

1. **Given** `leftSwipeConfig` in reveal mode with an empty `actions` list, **When** the widget builds in debug mode, **Then** an assertion message identifies that reveal mode requires at least one action.
2. **Given** an `activationThreshold` outside the 0.0–1.0 range, **When** the widget builds in debug mode, **Then** an assertion message identifies the field name, the provided value, and the valid range.
3. **Given** a `stepValue` of 0 or a negative number in `rightSwipeConfig`, **When** the widget builds in debug mode, **Then** an assertion message identifies that step value must be positive.
4. **Given** an `actionPanelWidth` of 0 or a negative number, **When** the widget builds in debug mode, **Then** an assertion message identifies that panel width must be positive.
5. **Given** any of the above in release mode, **Then** no crash occurs — assertions are debug-only guards.

---

### Edge Cases

- What happens when both `SwipeActionCellTheme` and all local configs are absent? The package's built-in defaults apply; the widget is fully functional with no configuration at all.
- What happens when `visualConfig: null` but a `SwipeActionCellTheme` provides a `visualConfig`? The theme's `visualConfig` is used.
- What happens when `copyWith` is called with no arguments? The config object is returned equal to the original — no mutation.
- What happens when a preset and `copyWith` are combined (e.g., `SwipeGestureConfig.tight().copyWith(deadZone: 5.0)`)? The copy produces a new config with the preset's values except for the overridden field.
- What happens with `controller: null`? The cell is fully self-managed. A non-null value is accepted and stored but has no effect in this release; it is reserved for F007.
- What happens when `leftSwipeConfig` reveal mode has more than 3 actions? The first 3 are rendered; a debug assertion fires (inheriting existing F004 behavior).

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The widget MUST expose exactly these top-level parameters: `child` (required), `rightSwipeConfig`, `leftSwipeConfig`, `gestureConfig`, `animationConfig`, `visualConfig`, `controller`, and `enabled`. All config parameters default to `null`; `enabled` defaults to `true`.
- **FR-002**: Passing `null` for any config parameter MUST completely disable the corresponding feature with zero overhead — no gesture recognition, no visual feedback, no callbacks fired (Constitution IX).
- **FR-003**: All five config objects (`RightSwipeConfig`, `LeftSwipeConfig`, `SwipeGestureConfig`, `SwipeAnimationConfig`, `SwipeVisualConfig`) MUST be constructable with `const`, have all-`final` fields, and provide a `copyWith` method that returns a new instance with only the specified fields replaced.
- **FR-004**: `SwipeGestureConfig` MUST provide named preset constructors `tight()` and `loose()`. `SwipeAnimationConfig` MUST provide named preset constructors `snappy()` and `smooth()`. The primary distinguishing parameter of each preset MUST differ by at least 2× from its counterpart: `tight().deadZone` ≥ 2× `loose().deadZone`; `snappy().completionSpring.stiffness` ≥ 2× `smooth().completionSpring.stiffness`. All four presets MUST produce behavior distinct from the default constructor.
- **FR-005**: `SwipeVisualConfig` MUST consolidate left and right background builders, clip behavior, and corner radius into a single config object, replacing the four individual top-level `SwipeActionCell` parameters.
- **FR-006**: The package MUST provide a `SwipeActionCellTheme` class that holds optional instances of the five config objects and that can be installed as an extension in the app's theme data. Its `lerp()` implementation MUST perform a hard cutover: return `other` when `t >= 1.0`, otherwise return `this`. No numeric interpolation of spring stiffness, damping, or gesture thresholds is performed.
- **FR-007**: When a `SwipeActionCellTheme` is present in the widget tree, a `SwipeActionCell` with no local value for a given config parameter MUST use the theme's value for that parameter.
- **FR-008**: A non-null local config parameter on `SwipeActionCell` MUST fully replace the `SwipeActionCellTheme` value for that parameter. Override is at the config-object level — no field-level merging between the theme and the local config.
- **FR-009**: In debug mode, the widget MUST assert with a human-readable, one-sentence message when: reveal mode has an empty `actions` list; `activationThreshold` is outside 0.0–1.0; `stepValue` is ≤ 0; `actionPanelWidth` is ≤ 0. Each message MUST name the invalid field, the provided value, and the requirement.
- **FR-010**: `onStateChanged` and `onProgressChanged` MUST remain as top-level `SwipeActionCell` parameters, unchanged from F001–F004. All other direction-specific callbacks (e.g., `onActionTriggered`, `onPanelOpened`, `onSwipeCancelled`, `onSwipeCompleted`) MUST remain within their respective config objects (`LeftSwipeConfig`, `RightSwipeConfig`).
- **FR-011**: All gesture, animation, visual, and action behavior from F001–F004 MUST be preserved exactly. This is an API-surface refactor only — no observable widget behavior changes.
- **FR-012**: The `controller` parameter MUST be accepted without crash or warning when non-null; its effect is reserved for F007.
- **FR-013**: The types `ProgressiveSwipeConfig` and `IntentionalSwipeConfig` MUST be removed with no deprecation aliases. The package version MUST be bumped to signal the breaking change, and a CHANGELOG entry MUST document every renamed parameter and type.

### Key Entities

- **`RightSwipeConfig`**: Renamed from `ProgressiveSwipeConfig`. Consolidates all right-swipe progressive behavior — step value, value range, overflow behavior, progress indicator config, haptic flag, and all right-swipe callbacks.
- **`LeftSwipeConfig`**: Renamed from `IntentionalSwipeConfig`. Consolidates all left-swipe intentional behavior — mode, actions list, post-action behavior, confirmation flag, panel width, haptic flag, and all left-swipe callbacks.
- **`SwipeGestureConfig`**: Gesture recognition parameters plus `tight()` and `loose()` preset constructors.
- **`SwipeAnimationConfig`**: Spring physics parameters plus `snappy()` and `smooth()` preset constructors.
- **`SwipeVisualConfig`**: Visual presentation parameters (left/right background builders, clip behavior, border radius).
- **`SwipeActionCellTheme`**: App-level configuration provider. Contains optional instances of the five config objects above. Installable as an extension in the app's theme data. `lerp()` performs a hard cutover (returns `other` at `t >= 1.0`); no numeric interpolation of spring or gesture values occurs during theme transitions.
- **`SwipeController`**: Accepted by the widget in this release; behavior reserved for F007.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A developer can fully configure a `SwipeActionCell` using only inline IDE auto-complete and the dartdoc comments — no source code reading required.
- **SC-002**: A developer can migrate an existing F001–F004 usage to the new API guided only by compile errors and assertion messages — no documentation lookup required. Migration of a typical two-direction cell takes under 5 minutes.
- **SC-003**: A cell configured with only preset constructors (no custom values) is fully functional. The primary distinguishing parameter of each preset pair differs by at least 2× (e.g., `tight().deadZone` ≥ 2× `loose().deadZone`), verifiable by a unit test without running the widget.
- **SC-004**: All existing F001–F004 tests pass after migration. `flutter analyze` reports zero warnings. No behavioral regression in any existing test.
- **SC-005**: A `SwipeActionCellTheme` applied once at the app root changes the default behavior for every cell in the tree without requiring any per-cell change.
- **SC-006**: Each of the four validation scenarios (empty reveal actions, out-of-range threshold, non-positive step value, non-positive panel width) produces a distinct assertion message in debug mode that a developer can understand and act on within 10 seconds.
- **SC-007**: The package CHANGELOG documents every renamed type and parameter; a developer can complete migration with a find-and-replace pass guided by the CHANGELOG alone.

---

## Assumptions

- **Rename-only for config types**: `ProgressiveSwipeConfig` → `RightSwipeConfig` and `IntentionalSwipeConfig` → `LeftSwipeConfig` are clean renames with no field changes. All existing fields and semantics are preserved.
- **`onStateChanged` / `onProgressChanged` placement**: Both stay as top-level `SwipeActionCell` parameters (confirmed in clarification Q1). They are cross-cutting widget-level concerns not tied to any single swipe direction.
- **Override granularity is per config object**: A local `gestureConfig` fully replaces the theme's `gestureConfig`. The developer uses `copyWith` on the theme's config to achieve partial field overrides. Field-level merging between theme and local configs is not supported.
- **`SwipeController` is a no-op**: Accepted and stored, but performs no group-coordination in this release. Full semantics land with F007.
- **Version bump**: A semver bump that signals breaking changes is expected. The exact version number (e.g., `0.5.0` or `1.0.0`) is an implementation decision.
- **SDK constraints unchanged**: Dart ≥ 3.4.0, Flutter ≥ 3.22.0. Zero new runtime dependencies.

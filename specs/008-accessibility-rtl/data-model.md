# Data Model: Accessibility & RTL Layout Support (F8)

## New Entities

---

### `ForceDirection` (enum) — `lib/src/core/swipe_direction_resolver.dart`

Represents the manual override for text direction on a specific cell.

| Value | Meaning |
|-------|---------|
| `ltr` | Force left-to-right regardless of ambient `Directionality` |
| `rtl` | Force right-to-left regardless of ambient `Directionality` |
| `auto` | Read ambient `Directionality.of(context)` (default) |

---

### `SwipeDirectionResolver` (utility class) — `lib/src/core/swipe_direction_resolver.dart`

A stateless helper that encapsulates the direction resolution logic. Not exposed publicly.

| Member | Type | Description |
|--------|------|-------------|
| `resolve(context, forceDirection)` | `bool isRtl` | Returns `true` if the effective direction is RTL |
| `forwardPhysicalDirection(isRtl)` | `SwipeDirection` | Physical direction that triggers the forward (progressive) action |
| `backwardPhysicalDirection(isRtl)` | `SwipeDirection` | Physical direction that triggers the backward (intentional) action |
| `configForPhysical(physical, isRtl, right, left)` | generic | Selects the config object for a given physical drag direction |

**State transitions affected**: None — this is a pure function resolver, no state.

---

### `SemanticLabel` (value wrapper) — `lib/src/accessibility/swipe_semantic_config.dart`

A const-constructable union type carrying either a static string or a context-aware builder.
Internal to `SwipeSemanticConfig`; part of the public API via config fields.

| Constructor | Parameters | Description |
|-------------|-----------|-------------|
| `SemanticLabel.string(value)` | `String value` | Static label |
| `SemanticLabel.builder(fn)` | `String Function(BuildContext)` | Locale-aware builder |

| Method | Return | Description |
|--------|--------|-------------|
| `resolve(context)` | `String` | Returns the label string for the given context |

**Validation**: `resolve()` falls back to `''` if builder returns `null` or empty. This triggers the caller to use its configured default.

---

### `SwipeSemanticConfig` (config object) — `lib/src/accessibility/swipe_semantic_config.dart`

Immutable configuration object for all accessibility label and announcement customization.
Passed as `SwipeActionCell.semanticConfig`.

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `cellLabel` | `SemanticLabel?` | `null` | Identifies the whole cell row to screen readers |
| `rightSwipeLabel` | `SemanticLabel?` | `null` | Label for the right-swipe action in screen reader menu |
| `leftSwipeLabel` | `SemanticLabel?` | `null` | Label for the left-swipe action in screen reader menu |
| `panelOpenLabel` | `SemanticLabel?` | `null` | Announcement when the reveal panel opens |
| `progressAnnouncementBuilder` | `String Function(double current, double max)?` | `null` | Override for auto-generated progress announcement |

**Default resolution**: When any label is `null` or resolves to empty string, the widget falls
back to direction-adaptive defaults (see FR-007).

**Constraints**:
- All fields `final`, `const`-constructable
- Has `copyWith` support
- No `==` / `hashCode` override needed (config equality is identity-based for performance)

---

## Modified Entities

---

### `SwipeActionCell` — new parameters

| New Parameter | Type | Default | Description |
|---------------|------|---------|-------------|
| `semanticConfig` | `SwipeSemanticConfig?` | `null` | Accessibility labels and announcement overrides |
| `forwardSwipeConfig` | `RightSwipeConfig?` | `null` | Semantic alias for `rightSwipeConfig` in LTR, `leftSwipeConfig` in RTL |
| `backwardSwipeConfig` | `LeftSwipeConfig?` | `null` | Semantic alias for `leftSwipeConfig` in LTR, `rightSwipeConfig` in RTL |
| `forceDirection` | `ForceDirection` | `ForceDirection.auto` | Manual direction override |

**Config resolution priority** (highest → lowest):

For the progressive/forward action:
1. `forwardSwipeConfig` (semantic alias, direction-agnostic)
2. `rightSwipeConfig` in LTR; `leftSwipeConfig` in RTL (physical, existing)

For the intentional/backward action:
1. `backwardSwipeConfig` (semantic alias, direction-agnostic)
2. `leftSwipeConfig` in LTR; `rightSwipeConfig` in RTL (physical, existing)

**Backward compatibility**: Existing consumers providing only `leftSwipeConfig` /
`rightSwipeConfig` see identical LTR behavior. RTL behavior is automatic when
`Directionality.of(context)` returns `TextDirection.rtl`.

---

### `SwipeActionCellState` — new state fields

| New Field | Type | Description |
|-----------|------|-------------|
| `_cellFocusNode` | `FocusNode` | Manages keyboard focus for the cell |
| `_isRtl` | `bool` | Cached RTL flag, updated each build from `Directionality.of(context)` |

---

## Unchanged Entities

- `SwipeDirection` — remains physical (left/right/none). RTL semantic mapping is handled by
  `SwipeDirectionResolver`, not by adding new enum values.
- `SwipeState` — no new states. Keyboard actions trigger existing state transitions.
- `SwipeProgress` — no changes. Direction is physical; callers remain unaffected.
- `LeftSwipeConfig`, `RightSwipeConfig` — no changes. Existing fields preserved.
- `SwipeVisualConfig` — no changes. `leftBackground`/`rightBackground` remain physical;
  semantic swapping happens in the widget's `_buildBackground()` method.
- `SwipeGestureConfig` — no changes.

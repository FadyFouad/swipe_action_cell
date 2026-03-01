# Implementation Plan: Accessibility & RTL Layout Support (F8)

**Branch**: `008-accessibility-rtl`
**Spec**: `specs/008-accessibility-rtl/spec.md`
**Status**: Ready for Implementation

---

## Constitution Check

| Principle | Status | Notes |
|-----------|--------|-------|
| I. Composition over Inheritance | ✅ Pass | `semanticConfig`, `forwardSwipeConfig`, `backwardSwipeConfig` are all injected parameters; no base class extension |
| II. Explicit State Machine | ✅ Pass | Keyboard actions trigger existing state transitions (`idle → animatingToOpen → revealed`). No new states added. |
| III. Spring-Based Physics | ✅ Pass | Reduced motion bypasses spring simulation only when `MediaQuery.disableAnimations` is true — constitutionally justified by accessibility compliance |
| IV. Zero External Runtime Deps | ✅ Pass | `flutter/semantics`, `flutter/services`, `flutter/widgets` — all Flutter SDK |
| V. Controlled/Uncontrolled Pattern | ✅ Pass | `semanticConfig` is optional; all new behavior has sensible defaults without requiring config |
| VI. Const-Friendly Configuration | ✅ Pass | `SwipeSemanticConfig`, `SemanticLabel`, `ForceDirection` are all const-constructable and immutable with `copyWith` |
| VII. Test-First (NON-NEGOTIABLE) | ✅ Required | Tests written before implementation in all phases below |
| VIII. Dartdoc Everything | ✅ Required | All new public members need `///` docs |
| IX. Null Config = Feature Disabled | ✅ Pass | `semanticConfig: null` → uses built-in defaults only; `forwardSwipeConfig: null` → falls through to physical config |
| X. Performance Budget: 60 fps | ✅ Pass | Semantics wrapper adds one node; `Focus` wrapper is zero-cost when not focused; RTL flag lookup is O(1) |

---

## Technical Context

### Architecture Overview

```
SwipeActionCell (widget)
├── Focus (keyboard nav wrapper — NEW)
│   └── Semantics (screen reader node — NEW)
│       └── RawGestureDetector (existing)
│           └── AnimatedBuilder (existing)
│               └── Stack
│                   ├── Background (_buildBackground — MODIFIED: RTL-aware)
│                   ├── RevealPanel (_buildRevealPanel — unchanged visually)
│                   ├── ProgressIndicator (_buildProgressIndicator — unchanged)
│                   └── TranslatedChild (Transform.translate — unchanged)
│
lib/src/core/
└── swipe_direction_resolver.dart  (NEW — ForceDirection enum + resolver)

lib/src/accessibility/
└── swipe_semantic_config.dart     (NEW — SemanticLabel + SwipeSemanticConfig)
```

### Key Discoveries from Codebase Survey

1. **`Transform.translate` is already direction-correct**: The raw `_controller.value` offset
   tracks physical drag delta (positive = rightward, negative = leftward). This is unchanged in
   RTL. No offset negation needed.

2. **`Positioned` auto-mirrors in RTL**: `_buildRevealPanel` (anchored `right: 0`) and
   `_buildProgressIndicator` (anchored `left: 0`) will automatically flip to the correct visual
   side in RTL via Flutter's bidi layout — no code changes needed in those methods.

3. **Background builder selection DOES need RTL swapping**: `_buildBackground` currently maps
   `SwipeDirection.right → rightBackground`, `SwipeDirection.left → leftBackground`. In RTL, a
   rightward drag triggers the backward/intentional action, so its background should be
   `leftBackground`. This is the primary visual change for RTL.

4. **Config dispatch DOES need RTL swapping**: `effectiveRightSwipeConfig` and
   `effectiveLeftSwipeConfig` are currently `widget.rightSwipeConfig` and
   `widget.leftSwipeConfig`. In RTL, a rightward drag should activate `effectiveLeftSwipeConfig`
   semantics. A new `_effectiveForwardConfig` / `_effectiveBackwardConfig` pair resolves this.

5. **`SwipeDirection` enum stays physical**: Existing fields and all downstream code reference
   physical directions. The RTL semantic mapping is confined to a new resolver layer.

6. **No existing accessibility infrastructure**: `lib/src/accessibility/` directory exists but
   is empty. This feature is the first to populate it.

---

## Implementation Phases

> **Constitution VII — Test-First is non-negotiable.** Each phase below lists tests before
> implementation. Write all tests in a phase to their failing state, then implement.

---

### Phase 1: Direction Resolver (Core Foundation)

**File**: `lib/src/core/swipe_direction_resolver.dart`

**New exports** (add to `lib/swipe_action_cell.dart`): `ForceDirection`

#### 1.1 — Write Failing Tests

**Test file**: `test/core/swipe_direction_resolver_test.dart`

Tests to write (all must fail before implementation):

```
- ForceDirection.auto + LTR context → isRtl = false
- ForceDirection.auto + RTL context → isRtl = true
- ForceDirection.ltr + RTL context → isRtl = false (override wins)
- ForceDirection.rtl + LTR context → isRtl = true (override wins)
- forwardPhysicalDirection(isRtl: false) → SwipeDirection.right
- forwardPhysicalDirection(isRtl: true) → SwipeDirection.left
- backwardPhysicalDirection(isRtl: false) → SwipeDirection.left
- backwardPhysicalDirection(isRtl: true) → SwipeDirection.right
- configForPhysical(right, isRtl: false, right: configA, left: configB) → configA
- configForPhysical(right, isRtl: true, right: configA, left: configB) → configB
- configForPhysical(left, isRtl: false, right: configA, left: configB) → configB
- configForPhysical(left, isRtl: true, right: configA, left: configB) → configA
```

#### 1.2 — Implement

```dart
// lib/src/core/swipe_direction_resolver.dart

/// Controls how [SwipeActionCell] resolves its effective text direction.
enum ForceDirection { auto, ltr, rtl }

/// Resolves the effective text direction and maps physical drag directions
/// to semantic action roles (forward/backward).
abstract final class SwipeDirectionResolver {
  /// Returns true if the effective direction is RTL.
  static bool isRtl(BuildContext context, ForceDirection force) { ... }

  /// The physical direction that triggers the forward (progressive) action.
  static SwipeDirection forwardPhysical(bool isRtl) =>
      isRtl ? SwipeDirection.left : SwipeDirection.right;

  /// The physical direction that triggers the backward (intentional) action.
  static SwipeDirection backwardPhysical(bool isRtl) =>
      isRtl ? SwipeDirection.right : SwipeDirection.left;

  /// Returns the config for [physical] direction given [isRtl].
  static T? configForPhysical<T>(
    SwipeDirection physical, {
    required bool isRtl,
    required T? rightConfig,
    required T? leftConfig,
  }) { ... }
}
```

#### 1.3 — Barrel Export

Add `ForceDirection` to `lib/swipe_action_cell.dart`.

---

### Phase 2: Semantic Config Model

**File**: `lib/src/accessibility/swipe_semantic_config.dart`

**New exports**: `SemanticLabel`, `SwipeSemanticConfig`

#### 2.1 — Write Failing Tests

**Test file**: `test/accessibility/swipe_semantic_config_test.dart`

```
- SemanticLabel.string('hello').resolve(ctx) → 'hello'
- SemanticLabel.builder((ctx) => 'built').resolve(ctx) → 'built'
- SemanticLabel.builder returning '' → resolve returns ''
- SemanticLabel.builder returning null (via cast) → resolve returns ''
- SwipeSemanticConfig default constructor → all fields null
- SwipeSemanticConfig.copyWith replaces specified fields
- SwipeSemanticConfig const construction (compile-time check)
```

#### 2.2 — Implement

```dart
// lib/src/accessibility/swipe_semantic_config.dart

@immutable
class SemanticLabel {
  const SemanticLabel.string(String this._value) : _builder = null;
  const SemanticLabel.builder(String Function(BuildContext) this._builder)
      : _value = null;

  final String? _value;
  final String Function(BuildContext)? _builder;

  /// Resolves the label. Returns empty string if builder returns null/empty.
  String resolve(BuildContext context) {
    if (_value != null) return _value!;
    return _builder!(context);
  }
}

@immutable
class SwipeSemanticConfig {
  const SwipeSemanticConfig({
    this.cellLabel,
    this.rightSwipeLabel,
    this.leftSwipeLabel,
    this.panelOpenLabel,
    this.progressAnnouncementBuilder,
  });

  final SemanticLabel? cellLabel;
  final SemanticLabel? rightSwipeLabel;
  final SemanticLabel? leftSwipeLabel;
  final SemanticLabel? panelOpenLabel;
  final String Function(double current, double max)? progressAnnouncementBuilder;

  SwipeSemanticConfig copyWith({ ... });
}
```

#### 2.3 — Barrel Export

Add `SemanticLabel`, `SwipeSemanticConfig` to `lib/swipe_action_cell.dart`.

---

### Phase 3: RTL Integration in Widget

**File**: `lib/src/widget/swipe_action_cell.dart`

This phase adds RTL support with zero accessibility changes (Semantics/Focus added in Phase 4).

#### 3.1 — Write Failing Tests

**Test file**: `test/widget/swipe_action_cell_rtl_test.dart`

All tests use `Directionality(textDirection: TextDirection.rtl)` wrapper:

```
LTR baseline (regression guard):
- LTR + rightSwipeConfig: right drag activates progressive action ✓
- LTR + leftSwipeConfig: left drag activates intentional panel ✓
- LTR: rightBackground shown during right drag ✓
- LTR: leftBackground shown during left drag ✓

RTL forward/backward remapping:
- RTL + rightSwipeConfig: left drag activates progressive action
- RTL + leftSwipeConfig: right drag activates intentional panel
- RTL: rightBackground shown during left drag (forward action bg)
- RTL: leftBackground shown during right drag (backward action bg)
- RTL: reveal panel anchored on left side (Positioned auto-mirror)
- RTL: progress indicator anchored on right side (Positioned auto-mirror)

forwardSwipeConfig / backwardSwipeConfig aliases:
- LTR + forwardSwipeConfig: right drag activates it (same as rightSwipeConfig)
- RTL + forwardSwipeConfig: left drag activates it
- LTR + backwardSwipeConfig: left drag activates it
- RTL + backwardSwipeConfig: right drag activates it
- forwardSwipeConfig takes precedence over rightSwipeConfig in LTR
- backwardSwipeConfig takes precedence over leftSwipeConfig in LTR

forceDirection override:
- forceDirection: ltr in RTL context → behaves as LTR
- forceDirection: rtl in LTR context → behaves as RTL
- forceDirection: auto (default) → reads ambient Directionality

Reduced motion:
- MediaQuery.disableAnimations = true: snap-back completes in single frame
- MediaQuery.disableAnimations = true: animate-to-open completes in single frame
- MediaQuery.disableAnimations = false: animations play normally
```

#### 3.2 — Implement

**New parameters on `SwipeActionCell`** constructor:
```dart
this.forwardSwipeConfig,
this.backwardSwipeConfig,
this.forceDirection = ForceDirection.auto,
// semanticConfig added in Phase 4
```

**New getters in `SwipeActionCellState`**:

```dart
bool get _isRtl => SwipeDirectionResolver.isRtl(context, widget.forceDirection);

RightSwipeConfig? get _effectiveForwardConfig =>
    widget.forwardSwipeConfig ??
    SwipeDirectionResolver.configForPhysical<RightSwipeConfig>(
      SwipeDirection.right,
      isRtl: _isRtl,
      rightConfig: widget.rightSwipeConfig,
      leftConfig: null, // LeftSwipeConfig is not RightSwipeConfig
    );
    // Simplified: in LTR → rightSwipeConfig; in RTL → null (left is backward)
```

Actually the resolution logic is:

```dart
// Forward action config (RightSwipeConfig):
//   LTR → forwardSwipeConfig ?? rightSwipeConfig
//   RTL → forwardSwipeConfig ?? rightSwipeConfig  ← same! forwardSwipe IS rightSwipe semantically
// BUT dispatch:
//   LTR right drag → effectiveForwardConfig
//   RTL left drag → effectiveForwardConfig
```

The key insight: `forwardSwipeConfig` and `rightSwipeConfig` are THE SAME type (`RightSwipeConfig`)
and map to THE SAME semantic behavior. The RTL change is only in WHICH PHYSICAL DIRECTION triggers it.

Implementation:
```dart
// Effective config resolution (in state):
RightSwipeConfig? get _resolvedForwardConfig =>
    widget.forwardSwipeConfig ?? widget.rightSwipeConfig;

LeftSwipeConfig? get _resolvedBackwardConfig =>
    widget.backwardSwipeConfig ?? widget.leftSwipeConfig;

// In _handleDragStart, after locking _lockedDirection:
// Replace all `effectiveRightSwipeConfig` usages with:
RightSwipeConfig? get effectiveForwardConfig => _resolvedForwardConfig;
LeftSwipeConfig? get effectiveBackwardConfig => _resolvedBackwardConfig;

// Map physical → semantic:
bool get _dragIsForward => _lockedDirection == SwipeDirectionResolver.forwardPhysical(_isRtl);
bool get _dragIsBackward => _lockedDirection == SwipeDirectionResolver.backwardPhysical(_isRtl);
```

**Changes in `_handleDragUpdate` and `_handleDragEnd`**:
- Replace `_lockedDirection == SwipeDirection.right` with `_dragIsForward`
- Replace `_lockedDirection == SwipeDirection.left` with `_dragIsBackward`
- Replace `effectiveRightSwipeConfig` with `_effectiveForwardConfig` where semantics matter
- Replace `effectiveLeftSwipeConfig` with `_effectiveBackwardConfig` where semantics matter

**Changes in `_buildBackground`**:
```dart
Widget _buildBackground(BuildContext context, SwipeProgress progress) {
  final isForward = progress.direction == SwipeDirectionResolver.forwardPhysical(_isRtl);
  final builder = isForward
      ? effectiveVisualConfig.rightBackground   // forward bg = rightBackground (semantic)
      : effectiveVisualConfig.leftBackground;   // backward bg = leftBackground (semantic)
  ...
}
```

**Changes in `_snapBack` and `_animateToOpen`** (reduced motion):
```dart
void _snapBack(double fromOffset, double velocity) {
  if (MediaQuery.of(context).disableAnimations) {
    _controller.value = 0.0;
    return;
  }
  // ... existing spring simulation
}

void _animateToOpen(double fromOffset, double toOffset, double velocity) {
  if (MediaQuery.of(context).disableAnimations) {
    _controller.value = toOffset;
    return;
  }
  // ... existing spring simulation
}
```

---

### Phase 4: Accessibility Integration in Widget

**File**: `lib/src/widget/swipe_action_cell.dart` (continued)

This phase adds the Semantics wrapper, Focus wrapper, keyboard handler, and announcements.

#### 4.1 — Write Failing Tests

**Test file**: `test/accessibility/swipe_semantics_test.dart`

```
Semantics tree structure:
- Cell has Semantics node with configured cellLabel
- Cell has CustomSemanticsAction for forward action (when forwardConfig ≠ null)
- Cell has CustomSemanticsAction for backward action (when backwardConfig ≠ null)
- No forward action registered when forwardConfig = null
- No backward action registered when backwardConfig = null
- Default label "Swipe right to progress" in LTR when rightSwipeLabel is null
- Default label "Swipe left to progress" in RTL when rightSwipeLabel is null
- Default label "Swipe left for actions" in LTR when leftSwipeLabel is null
- Default label "Swipe right for actions" in RTL when leftSwipeLabel is null
- Custom rightSwipeLabel overrides default
- Custom leftSwipeLabel overrides default
- Builder-based label resolves to returned string
- Null/empty builder result falls back to default

Screen reader action triggers:
- Activating forward CustomSemanticsAction triggers same state change as gesture
- Activating backward CustomSemanticsAction opens panel same as gesture

Announcements:
- After progressive action completes, announces "Progress incremented to N of M"
- After panel opens, announces "Action panel open" (default)
- Custom panelOpenLabel announcement fires when panel opens
- Custom progressAnnouncementBuilder result fires after progressive action
- No announcement fires if action config is null (no action registered)
```

**Test file**: `test/accessibility/swipe_keyboard_nav_test.dart`

```
Focus behavior:
- Cell is focusable via Tab (has FocusNode)
- Cell is not auto-focused on mount

Keyboard triggers (LTR):
- Right arrow on focused cell triggers forward action
- Left arrow on focused cell opens backward panel
- Right/left arrow ignored when animation is in progress

Keyboard triggers (RTL):
- Left arrow on focused cell triggers forward action
- Right arrow on focused cell opens backward panel

Escape / close:
- Escape closes open panel
- Focus returns to cell after Escape close
- Focus returns to cell after SwipeController.close() call

Tab with panel open:
- Tab moves focus to first action button in panel
- Subsequent Tab moves to second action button
- Tab after last button wraps to first (if panel still open) OR exits panel

No-op cases:
- Right arrow when no forward config → no state change, event consumed
- Left arrow when no backward config → no state change, event consumed
- Escape when panel not open → no-op, event NOT consumed (passes through)
```

#### 4.2 — Implement

**New state field**:
```dart
late final FocusNode _cellFocusNode;

@override
void initState() {
  super.initState();
  _cellFocusNode = FocusNode();
  // ... existing initState
}

@override
void dispose() {
  _cellFocusNode.dispose();
  // ... existing dispose
}
```

**New helper — default label resolution**:
```dart
String _defaultForwardLabel(bool isRtl) =>
    isRtl ? 'Swipe left to progress' : 'Swipe right to progress';

String _defaultBackwardLabel(bool isRtl) =>
    isRtl ? 'Swipe right for actions' : 'Swipe left for actions';

String _resolveLabel(SemanticLabel? label, String fallback, BuildContext ctx) {
  if (label == null) return fallback;
  final resolved = label.resolve(ctx);
  return resolved.isEmpty ? fallback : resolved;
}
```

**New helper — announcement**:
```dart
void _announceProgress(double current, double max) {
  final msg = widget.semanticConfig?.progressAnnouncementBuilder?.call(current, max)
      ?? 'Progress incremented to ${current.toStringAsFixed(0)} of ${max.toStringAsFixed(0)}';
  SemanticsService.announce(msg, Directionality.of(context));
}

void _announcePanelOpen() {
  final msg = widget.semanticConfig?.panelOpenLabel?.resolve(context) ?? 'Action panel open';
  SemanticsService.announce(
    msg.isEmpty ? 'Action panel open' : msg,
    Directionality.of(context),
  );
}
```

**Call announcement sites**:
- In `_animateToOpen` completion (when `_state == SwipeState.revealed` settles):
  call `_announcePanelOpen()` when backward action was triggered.
- In progressive action snap-back completion: call `_announceProgress(currentValue, maxValue)`.

**Keyboard handler**:
```dart
KeyEventResult _handleKeyEvent(FocusNode node, RawKeyEvent event) {
  if (event is! RawKeyDownEvent) return KeyEventResult.ignored;
  final isRtl = _isRtl;
  final forwardKey = isRtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight;
  final backwardKey = isRtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft;

  if (event.logicalKey == forwardKey) {
    if (_isAnimating) return KeyEventResult.handled; // drop input
    if (_resolvedForwardConfig != null) _triggerForwardFromKeyboard();
    return KeyEventResult.handled;
  }
  if (event.logicalKey == backwardKey) {
    if (_isAnimating) return KeyEventResult.handled;
    if (_resolvedBackwardConfig != null) _triggerBackwardFromKeyboard();
    return KeyEventResult.handled;
  }
  if (event.logicalKey == LogicalKeyboardKey.escape) {
    if (_state == SwipeState.revealed) {
      executeClose();
      _cellFocusNode.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
  return KeyEventResult.ignored;
}
```

**Screen reader action triggers**:
```dart
void _triggerForwardFromSemantics() {
  if (_isAnimating || _resolvedForwardConfig == null) return;
  _triggerProgressiveActionProgrammatically();
}

void _triggerBackwardFromSemantics() {
  if (_isAnimating || _resolvedBackwardConfig == null) return;
  _triggerIntentionalActionProgrammatically();
}
```

**Focus restoration on `executeClose()`**:
```dart
@override
void executeClose() {
  // ... existing close logic
  // Restore focus after close if cell previously had focus
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && !_cellFocusNode.hasFocus) {
      _cellFocusNode.requestFocus();
    }
  });
}
```

**Build method wrapper** (outermost wrapper, outside `LayoutBuilder`):
```dart
@override
Widget build(BuildContext context) {
  if (!widget.enabled) return widget.child;
  final isRtl = _isRtl;
  final forwardConfig = _resolvedForwardConfig;
  final backwardConfig = _resolvedBackwardConfig;
  final semanticCfg = widget.semanticConfig;

  final Map<CustomSemanticsAction, VoidCallback> customActions = {};
  if (forwardConfig != null) {
    final label = _resolveLabel(
      semanticCfg?.rightSwipeLabel, _defaultForwardLabel(isRtl), context);
    customActions[CustomSemanticsAction(label: label)] = _triggerForwardFromSemantics;
  }
  if (backwardConfig != null) {
    final label = _resolveLabel(
      semanticCfg?.leftSwipeLabel, _defaultBackwardLabel(isRtl), context);
    customActions[CustomSemanticsAction(label: label)] = _triggerBackwardFromSemantics;
  }
  final cellLabel = semanticCfg?.cellLabel?.resolve(context);

  return Focus(
    focusNode: _cellFocusNode,
    onKey: _handleKeyEvent,
    child: Semantics(
      label: (cellLabel != null && cellLabel.isNotEmpty) ? cellLabel : null,
      customSemanticsActions: customActions.isEmpty ? null : customActions,
      child: LayoutBuilder(
        builder: (context, constraints) { ... /* existing LayoutBuilder */ },
      ),
    ),
  );
}
```

---

### Phase 5: Barrel Export & Documentation Pass

#### 5.1 — Barrel Updates

Add to `lib/swipe_action_cell.dart`:
```dart
export 'src/core/swipe_direction_resolver.dart' show ForceDirection;
export 'src/accessibility/swipe_semantic_config.dart'
    show SemanticLabel, SwipeSemanticConfig;
```

#### 5.2 — Dartdoc Pass

All new public members must have `///` documentation:
- `ForceDirection` (enum + each value)
- `SemanticLabel` (class + constructors + `resolve`)
- `SwipeSemanticConfig` (class + each field + `copyWith`)
- `SwipeActionCell.semanticConfig`
- `SwipeActionCell.forwardSwipeConfig`
- `SwipeActionCell.backwardSwipeConfig`
- `SwipeActionCell.forceDirection`

#### 5.3 — `flutter analyze` + `dart format`

Must pass with zero warnings before merge.

---

### Phase 6: Regression & Integration Tests

**Test file**: `test/widget/swipe_action_cell_a11y_regression_test.dart`

```
Full LTR regression (all existing behavior unchanged):
- Run equivalent of existing swipe_action_cell_test.dart scenarios with no new params
- Progressive right swipe: same behavior
- Intentional left swipe: same behavior
- Controller close: same behavior
- Theme inheritance: same behavior

RTL + LTR parity:
- Same onActionTriggered fires in RTL as in LTR (via opposite physical direction)
- Same onPanelOpened fires in RTL as in LTR
- Same onProgressChanged fires in RTL as in LTR

WCAG contrast (static validation):
- Assert default colors meet 3:1 minimum ratio using luminance formula
```

---

## File Change Summary

| File | Change |
|------|--------|
| `lib/src/core/swipe_direction_resolver.dart` | **NEW** — `ForceDirection` + `SwipeDirectionResolver` |
| `lib/src/accessibility/swipe_semantic_config.dart` | **NEW** — `SemanticLabel` + `SwipeSemanticConfig` |
| `lib/src/widget/swipe_action_cell.dart` | **MODIFIED** — new params, RTL dispatch, Focus/Semantics wrapper, reduced motion, announcements |
| `lib/swipe_action_cell.dart` | **MODIFIED** — add 3 new exports |
| `test/core/swipe_direction_resolver_test.dart` | **NEW** |
| `test/accessibility/swipe_semantic_config_test.dart` | **NEW** |
| `test/accessibility/swipe_semantics_test.dart` | **NEW** |
| `test/accessibility/swipe_keyboard_nav_test.dart` | **NEW** |
| `test/widget/swipe_action_cell_rtl_test.dart` | **NEW** |
| `test/widget/swipe_action_cell_a11y_regression_test.dart` | **NEW** |

---

## Dependency Order

```
Phase 1 (swipe_direction_resolver)
    ↓
Phase 2 (swipe_semantic_config)         ← no dependency on Phase 1
    ↓
Phase 3 (RTL in widget)                 ← depends on Phase 1
    ↓
Phase 4 (A11y in widget)                ← depends on Phases 1, 2, 3
    ↓
Phase 5 (exports + dartdoc)             ← depends on all
    ↓
Phase 6 (regression tests)              ← depends on all
```

Phases 1 and 2 can be developed in parallel.

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| `CustomSemanticsAction` labels not rendered by TalkBack/VoiceOver on all versions | Medium | Medium | Manual device testing required; fall back to `Semantics.label` if labels are empty |
| Keyboard `Focus.onKey` conflicts with parent scroll view arrow key handling | Low | Medium | Use `KeyEventResult.handled` only for left/right arrows (not up/down); scroll is unaffected |
| RTL background swap breaks consumer visual layouts that depend on left=intentional | Low | Low | Zero breaking change — consumers using LTR-only are unaffected; RTL consumers opt in via `Directionality` |
| `SemanticsService.announce()` fires during widget disposal | Low | Low | Guard with `if (mounted)` before calling |
| `_cellFocusNode.requestFocus()` called after `dispose()` | Low | Low | Guard all focus restoration with `if (mounted)` |

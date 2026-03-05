# Research: Accessibility & RTL Layout Support (F8)

## Flutter Semantics & Screen Reader API

### Decision
Use `CustomSemanticsAction` (not the bare `SemanticsAction.customAction`) for registering
multiple labeled actions per cell.

### Rationale
`CustomSemanticsAction` accepts a `label: String` and can be registered as many times as needed
in `Semantics.customSemanticsActions: Map<CustomSemanticsAction, VoidCallback>`. This allows
the progressive action and the intentional action to each carry a distinct, user-readable label
that appears in the screen reader's actions menu (VoiceOver on iOS, TalkBack on Android).

`SemanticsAction.customAction` (the enum variant) is a single-slot; registering two callbacks
for the same key silently overwrites the first. Therefore it cannot support two distinct actions
on a single node.

### API

```dart
final forwardAction = CustomSemanticsAction(label: 'Increment counter');
final backwardAction = CustomSemanticsAction(label: 'Delete');

Semantics(
  label: 'Task row',
  customSemanticsActions: {
    forwardAction: _triggerForwardAction,
    backwardAction: _triggerBackwardAction,
  },
  child: ...,
)
```

### Alternatives Considered
- **Single `SemanticsAction.customAction`**: Only one slot per node — cannot express two
  distinct actions. Rejected.
- **Two nested `Semantics` nodes, one per action**: Works but creates a semantics tree that
  screen readers traverse as two separate focusable elements, breaking the "single cell"
  mental model. Rejected.

---

## Live-Region Announcements

### Decision
Use `SemanticsService.announce(message, textDirection)` post-state-change.

### Rationale
`SemanticsService.announce()` posts a live-region message to the platform accessibility
service queue. It fires on both iOS (VoiceOver) and Android (TalkBack) without requiring a
visible Semantics tree update. Called after the state change has been committed.

### API

```dart
SemanticsService.announce(
  'Progress incremented to 4 of 10',
  Directionality.of(context),
);
```

### Notes
- Returns `Future<void>` — no need to await in widget lifecycle; fire-and-forget is fine.
- Messages queue; multiple rapid announcements queue sequentially.
- Must be called after the animation or state commit, not during it.

---

## Keyboard Navigation

### Decision
Use `Focus.onKey` for the cell's keyboard handler. Use a named `FocusNode` for panel-button
focus restoration.

### Rationale
`Focus.onKey` is the current standard for single-widget keyboard handling in Flutter. The
`Shortcuts + Actions` pattern adds indirection that provides value for apps but is unnecessary
overhead in a package widget where the key bindings are fixed and non-configurable. For the
panel buttons, a `FocusNode` is created and stored on the state so that `requestFocus()` can
be called when the panel opens, and focus returned to the cell when the panel closes.

### API

```dart
Focus(
  focusNode: _cellFocusNode,
  onKey: (node, event) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        if (!_isAnimating) _handleKeyboardForward();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        if (!_isAnimating) _handleKeyboardBackward();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (_state == SwipeState.revealed) _handleKeyboardClose();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  },
  child: ...,
)
```

### Alternatives Considered
- **`KeyboardListener`**: Older pattern, does not participate in focus tree correctly. Rejected.
- **`Shortcuts + Actions`**: Adds composability but the key bindings are non-negotiable in this
  package; no benefit. Deferred.

---

## RTL Direction Detection

### Decision
Use `Directionality.of(context)` at build time to resolve the effective text direction.
Override via a new `forceDirection: ForceDirection` parameter. Introduce a lightweight resolver
class in `lib/src/core/`.

### Rationale
`Directionality.of(context)` is the idiomatic Flutter API for ambient text direction. It reads
the nearest `Directionality` ancestor. All existing consumer code that correctly sets
`MaterialApp(locale: ...)` or `Directionality(...)` on an RTL locale will automatically work
with zero configuration.

### Key Findings on Transform.translate in RTL
`Transform.translate(offset: Offset(dx, 0))` does **not** automatically mirror in RTL. Flutter
only auto-mirrors widgets that use `EdgeInsetsDirectional`, `AlignmentDirectional`, or
`Positioned` within a `Stack`. Since `SwipeActionCell` uses `Transform.translate` with a raw
`double` offset from `_controller.value`, the translation direction is **already correct**:
- Right drag: positive controller value → positive dx → content slides right ✓
- Left drag: negative controller value → negative dx → content slides left ✓
- RTL right drag (backward action): positive offset, content slides right ✓
- RTL left drag (forward action): negative offset, content slides left ✓

The translation direction is **geometry-faithful** in both LTR and RTL. No offset negation is
needed.

### Key Findings on Positioned in RTL
`Positioned(right: 0)` for the reveal panel and `Positioned(left: 0)` for the progress
indicator **automatically mirror** in RTL via Flutter's Bidi layout pass:
- LTR: panel anchors right, indicator anchors left ✓
- RTL: panel auto-mirrors to left anchor; indicator auto-mirrors to right anchor ✓

No manual `Positioned` changes are required for visual mirroring.

### What DOES Need to Change for RTL
1. **Config dispatch**: Which config (`rightSwipeConfig` / `leftSwipeConfig`) is activated for
   a given physical drag direction. In RTL, a rightward drag (positive offset) should activate
   `leftSwipeConfig` (backward/intentional) and a leftward drag should activate `rightSwipeConfig`
   (forward/progressive).
2. **Background dispatch**: Same — the background builder shown during a rightward drag should
   flip in RTL.
3. **Default semantic label direction words**: "Swipe right to progress" ↔ "Swipe left to
   progress" based on resolved direction.

---

## Reduced Motion

### Decision
Check `MediaQuery.of(context).disableAnimations` at the start of each animation method
(`_snapBack`, `_animateToOpen`). If true, jump the controller directly to the target value
instead of running a `SpringSimulation`.

### API

```dart
void _snapBack(double fromOffset, double velocity) {
  if (MediaQuery.of(context).disableAnimations) {
    _controller.value = 0.0;
    return;
  }
  // ... existing SpringSimulation code
}
```

### Rationale
Checking `MediaQuery` at animation dispatch time (not at build time) means the widget
correctly responds to a system accessibility preference change at any point without requiring
a rebuild. `AnimationController.value = target` immediately fires all animation listeners in
the same frame, satisfying FR-015.

---

## WCAG AA Color Contrast

### Decision
Add WCAG AA-compliant default colors in `SwipeVisualConfig` defaults: minimum 4.5:1 text
contrast, 3:1 for non-text UI components. No runtime contrast checker injected.

### Rationale
Runtime contrast checking (computing relative luminance of two `Color` values) has negligible
performance cost, but there is no standard flutter_lints or test framework integration for it.
The compliance target for the package defaults is confirmed by static hex code calculation. For
developer-provided custom colors, compliance is their responsibility per the spec Assumptions.

---

## Platform Notes

| Platform | CustomSemanticsAction | Focus.onKey | Directionality |
|---|---|---|---|
| iOS | VoiceOver shows label in Actions rotor | Keyboard supported | Auto from locale |
| Android | TalkBack shows label in Actions menu | Keyboard supported | Auto from locale |
| Web | Browser accessibility tree | Full keyboard support | Auto from locale |
| macOS/Windows/Linux | Accessibility tree | Full keyboard support | Auto from locale |

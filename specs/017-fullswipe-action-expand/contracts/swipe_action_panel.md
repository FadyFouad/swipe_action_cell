# Contract: SwipeActionPanel

## Updated Constructor Signature

```dart
const SwipeActionPanel({
  super.key,
  required this.actions,
  required this.panelWidth,
  required this.onClose,
  this.enableHaptic = false,
  this.onFeedbackRequest,
  this.fullSwipeRatio = 0.0,       // NEW
  this.designatedActionIndex,       // NEW
});
```

## New Parameters

### `fullSwipeRatio` (`double`, default `0.0`)
- Range: 0.0–1.0
- Drives width interpolation between equal-width layout (0.0) and designated-fills-all layout (1.0)
- When 0.0: existing `Expanded(flex: ...)` layout is used (no change)
- When > 0.0: explicit `SizedBox(width: ...)` layout with interpolated widths

### `designatedActionIndex` (`int?`, default `null`)
- Index of the action in `actions` list that should expand during full swipe
- When null: no expand behavior regardless of `fullSwipeRatio`
- Must be valid index (0 to `actions.length - 1`) when non-null

## Width Distribution Contract

When `fullSwipeRatio > 0.0` and `designatedActionIndex != null`:

```
normalWidth[i] = panelWidth * (actions[i].flex / totalFlex)
expandProgress = fullSwipeRatio

For i != designatedActionIndex:
  width[i] = normalWidth[i] * (1.0 - expandProgress)
  opacity[i] = 1.0 - expandProgress

For i == designatedActionIndex:
  width[i] = panelWidth - sum(width[j] for j != i)
  opacity[i] = 1.0
```

**Invariant**: `sum(width[i] for all i) == panelWidth` (within floating point tolerance)

## Widget Tree Contract (constant structure)

During drag, the Row always contains exactly `actions.length` children. The widget tree structure does not change — only width and opacity properties update:

```
Row
  SizedBox(width: w0)
    ClipRect
      Opacity(opacity: o0)
        GestureDetector
          ColoredBox
            Center > Column > [icon, label?]
  SizedBox(width: w1)
    ClipRect
      Opacity(opacity: o1)
        ...
  ...
```

This ensures Element reuse during drag updates (no rebuilds).

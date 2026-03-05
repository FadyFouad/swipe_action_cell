# Research: Full-Swipe Action Expand

**Branch**: `017-fullswipe-action-expand` | **Date**: 2026-03-06

## R1: Current Full-Swipe Visual Architecture

**Decision**: The current implementation uses two independent layers — this must be replaced with a single-layer approach.

**Findings**:
- **FullSwipeExpandOverlay** (`lib/src/actions/full_swipe/full_swipe_expand_overlay.dart`): A separate `StatelessWidget` rendered as its own Stack child. Uses `Positioned.fill()` + `LayoutBuilder` to expand from `panelWidth` to `totalWidth`. Displays the full-swipe action's background color and icon independently of the reveal panel.
- **SwipeActionPanel** (`lib/src/actions/intentional/swipe_action_panel.dart`): The reveal panel that shows action buttons. Uses `Row` with `Expanded(flex: action.flex)` for equal-width layout. Has no knowledge of full-swipe state.
- **Stack z-order** (lines 2184–2278 of `swipe_action_cell.dart`): Reveal panel renders at z-index 3, expand overlay renders at z-index 5 (above confirm overlay, below decorated child). They are independent widgets that don't interact.

**Root cause of visual discontinuity**: The expand overlay appears ON TOP of the reveal panel and grows from panel width outward. The reveal panel buttons remain underneath at their fixed positions. The overlay covers them, creating a "replacement" visual rather than an "expansion" visual.

**Rationale**: Merging the expand behavior INTO the reveal panel (by modifying `SwipeActionPanel` to accept `fullSwipeRatio` and distribute widths) eliminates the overlay entirely. The action buttons themselves change width, producing the iOS Mail effect.

**Alternatives considered**:
- AnimatedCrossFade between reveal panel and full-swipe widget — rejected because crossfades produce opacity blending, not the width-expansion effect needed
- Animating the overlay position to exactly match button positions — rejected because it's fragile and doesn't produce the "same widget expanding" visual

## R2: Layout Approach — Width Distribution vs. Flex

**Decision**: Use explicit width-based layout (SizedBox with calculated widths) instead of flex-based layout.

**Rationale**: `Expanded(flex: N)` distributes space proportionally but cannot express "this child should have width 0" (flex 0 removes it from layout). Explicit widths via `SizedBox(width: calculatedWidth)` allow smooth interpolation from `normalWidth` to `0` for shrinking actions and from `normalWidth` to `totalWidth` for the expanding action.

**Implementation approach**:
- `SwipeActionPanel` receives a new `fullSwipeRatio` parameter (default 0.0)
- `SwipeActionPanel` receives a new `designatedActionIndex` parameter (nullable — null means no full-swipe expand)
- When `fullSwipeRatio > 0`, the `Row` uses explicit `SizedBox(width: ...)` children instead of `Expanded`
- When `fullSwipeRatio == 0`, the existing `Expanded(flex: ...)` layout is unchanged (no behavioral change for non-full-swipe cases)

**Alternatives considered**:
- Custom `MultiChildRenderObject` — rejected because it's over-engineered for width distribution, and `Row` with explicit widths achieves the same result
- `LayoutBuilder` inside each action slot — rejected because it adds unnecessary widget tree depth

## R3: Opacity Strategy for Shrinking Actions

**Decision**: Wrap each non-designated action in `Opacity(opacity: 1.0 - expandProgress)`.

**Rationale**: `Opacity` is the simplest approach and has negligible cost for the small number of action widgets (1-3). `FadeTransition` requires an `Animation<double>`, but the expansion is drag-driven (not animation-driven), so a simple `Opacity` widget with a double value is more direct.

**Alternatives considered**:
- `AnimatedOpacity` — rejected because it introduces its own duration/curve, conflicting with the drag-driven nature
- `FadeTransition` — rejected because there's no `AnimationController` driving the fade
- Conditional rendering (removing widgets when width < threshold) — rejected because it causes widget tree rebuilds

## R4: Clipping Strategy for Shrinking Actions

**Decision**: Wrap each non-designated action's content in `ClipRect` when shrinking, so content doesn't overflow as width decreases.

**Rationale**: Without clipping, icons and labels would overflow horizontally as their SizedBox width shrinks below their intrinsic size. `ClipRect` clips to the widget's bounds, preventing visual overflow. This is lightweight and only needed during the expand transition.

## R5: Activation Threshold Value

**Decision**: Use the existing activation threshold from `_checkFullSwipeThreshold` — hardcoded at 0.4 (40% of widget width).

**Findings**: In `swipe_action_cell.dart` line ~2330, the activation threshold is calculated as part of `_checkFullSwipeThreshold`. The `_fullSwipeRatio` already interpolates between this activation point and `cfg.threshold`. No change needed — `SwipeActionPanel` simply uses the `fullSwipeRatio` value it receives.

## R6: Element Reuse During Drag

**Decision**: The `SwipeActionPanel` must NOT change its widget tree structure during drag — only widget properties (width, opacity) should change.

**Rationale**: If the Row's children count or types change during drag, Flutter tears down and rebuilds Elements, causing frame drops. The fix ensures:
- The Row always has the same number of children
- Each child is always a SizedBox > ClipRect > Opacity > GestureDetector > ColoredBox > content
- Only the `width` and `opacity` properties change during drag updates
- This preserves Element reuse and avoids rebuilds

## R7: Compatibility with Destructive Two-Tap Expansion

**Decision**: The destructive two-tap expansion (where tapping a destructive action expands it to fill the panel) is orthogonal to full-swipe expand and does not need modification.

**Rationale**: The `_expandedIndex` state in `SwipeActionPanel` handles the two-tap destructive flow. This only activates when the user taps a button in the revealed state — it cannot co-occur with a drag (which is what full-swipe expand responds to). The two mechanisms operate in different user interaction modes (tap vs drag) and don't conflict.

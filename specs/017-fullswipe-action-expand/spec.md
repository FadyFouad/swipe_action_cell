# Feature Specification: Full-Swipe Action Expand

**Feature Branch**: `017-fullswipe-action-expand`
**Created**: 2026-03-06
**Status**: Draft
**Input**: Fix the full-swipe visual behavior so the last revealed action expands to fill the swipe area, instead of creating a separate background layer. Implement the iOS Mail pattern where existing revealed actions animate smoothly: earlier actions shrink away and the designated action expands to fill the entire area.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Designated Action Expands During Full Swipe (Priority: P1)

A user swipes left on a list cell that has multiple revealed actions (e.g., Archive, Delete) with full-swipe enabled. As the user drags past the activation threshold, the designated full-swipe action (e.g., Delete) smoothly expands to fill the revealed area, while the other actions (e.g., Archive) shrink toward zero width and fade out. The transition is continuous and drag-driven — no visual jump or widget swap occurs.

**Why this priority**: This is the core visual fix. Without it, the full-swipe interaction has a jarring discontinuity that breaks the user's sense of direct manipulation.

**Independent Test**: Can be fully tested by swiping a cell past the activation threshold and verifying that action widths interpolate smoothly — the designated action's width grows while sibling actions' widths shrink proportionally.

**Acceptance Scenarios**:

1. **Given** a cell with two left-swipe actions [Archive, Delete] and full-swipe enabled on Delete, **When** the user drags left to 50% of cell width (between activation and full-swipe thresholds), **Then** Delete is wider than its normal slot width, Archive is narrower, and both are still visible.
2. **Given** the same cell, **When** the user drags left to the full-swipe threshold (e.g., 75%), **Then** Delete fills 100% of the revealed area and Archive has shrunk to 0 width (invisible).
3. **Given** the same cell, **When** the user drags left below the activation threshold, **Then** all actions display at their normal equal widths — no expand/shrink occurs.
4. **Given** the same cell at full-swipe threshold, **When** the user releases, **Then** the Delete action triggers.

---

### User Story 2 - Reversible Expand on Drag-Back (Priority: P1)

A user swipes past the full-swipe threshold (designated action is fully expanded), then drags back below the threshold. The designated action smoothly shrinks back to its normal slot width, and the sibling actions smoothly grow back to their normal widths. The transition is fully reversible with no hysteresis.

**Why this priority**: Direct manipulation requires that the user can always "undo" their gesture mid-drag. Without reversibility, the interaction feels committed before the user lifts their finger.

**Independent Test**: Can be tested by swiping past the threshold, verifying full expand, then dragging back and verifying all actions return to normal widths.

**Acceptance Scenarios**:

1. **Given** a cell swiped past the full-swipe threshold (Delete fills 100%), **When** the user drags back to 50% (between thresholds), **Then** Delete shrinks and Archive grows back proportionally.
2. **Given** a cell swiped past the full-swipe threshold then dragged back below the activation threshold, **When** the layout is inspected, **Then** all actions are at their normal equal widths — identical to an un-expanded state.

---

### User Story 3 - Shrinking Actions Fade Out (Priority: P2)

As sibling actions shrink toward zero width, they also fade out (opacity decreases from 1.0 to 0.0). This prevents visual clutter from compressed action content (e.g., squished icons or text).

**Why this priority**: Enhances visual polish but the expand/shrink layout (P1) must work first. Opacity is a secondary refinement.

**Independent Test**: Can be tested by swiping to a midpoint and verifying that shrinking actions have opacity less than 1.0, proportional to their remaining width.

**Acceptance Scenarios**:

1. **Given** a cell with 3 actions [Pin, Archive, Delete] swiped to midpoint, **When** expand progress is 0.5, **Then** Pin and Archive have opacity 0.5 and their widths are 50% of normal.
2. **Given** a cell swiped to full-swipe threshold, **When** expand progress is 1.0, **Then** Pin and Archive have opacity 0.0 (fully invisible).

---

### User Story 4 - Single Action Full Swipe (Priority: P2)

A cell has only one revealed action and full-swipe is enabled for that action. As the user swipes past the activation threshold, the single action simply grows from its normal slot width to fill the full revealed area. No sibling shrinking occurs because there are no siblings.

**Why this priority**: Important edge case but the multi-action scenario (P1) covers the main complexity.

**Independent Test**: Can be tested by configuring a single-action cell with full swipe and verifying the action width grows continuously.

**Acceptance Scenarios**:

1. **Given** a cell with one left-swipe action [Delete] and full-swipe enabled, **When** the user drags past the activation threshold, **Then** Delete's width grows continuously from its normal slot width toward the full revealed area width.
2. **Given** the same cell at full-swipe threshold, **When** the layout is inspected, **Then** Delete fills 100% of the revealed area.

---

### User Story 5 - No Separate Full-Swipe Background Layer (Priority: P1)

The separate background layer/widget that currently appears during full swipe is removed. The visual representation of the full-swipe action is the same widget instance already present in the reveal panel — it expands in place. No new widget is created, no crossfade occurs.

**Why this priority**: This is the root cause of the current broken behavior. The separate layer is what creates the visual discontinuity.

**Independent Test**: Can be tested by verifying that during full swipe, the widget tree does not contain a separate full-swipe background widget — only the reveal panel actions exist.

**Acceptance Scenarios**:

1. **Given** a cell with full-swipe enabled, **When** the user swipes past the full-swipe threshold, **Then** no separate full-swipe background widget is present in the widget tree.
2. **Given** the same cell, **When** the user swipes past the threshold, **Then** the designated action button visible in the reveal panel is the same instance that was visible before the threshold — no widget swap.

---

### Edge Cases

- **Designated action is the first action (index 0)**: No actions before it to shrink; only actions after it shrink. Layout math still produces correct widths.
- **Designated action is in the middle of N actions**: Actions on both sides shrink. Total width always equals the available revealed area.
- **4 actions with full swipe on the last**: Three actions shrink simultaneously. Each shrinks proportionally.
- **Very fast swipe past threshold**: The layout responds to each drag update frame — velocity does not cause lag or skip the expand interpolation.
- **Drag exactly at activation threshold boundary**: expandProgress is exactly 0.0; all actions at normal width.
- **Drag exactly at full-swipe threshold boundary**: expandProgress is exactly 1.0; designated action fills everything.
- **Cell width is very narrow**: The math still distributes widths correctly even with small pixel values. Actions with computed width < 1 pixel are effectively hidden.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The reveal panel MUST use continuous width interpolation for each action during full-swipe drag, not a threshold-triggered widget swap.
- **FR-002**: The designated full-swipe action MUST expand from its normal slot width to fill 100% of the available revealed area as the user drags from the activation threshold to the full-swipe threshold.
- **FR-003**: All non-designated actions MUST shrink from their normal slot width to 0 width as the user drags from the activation threshold to the full-swipe threshold.
- **FR-004**: Shrinking actions MUST fade out (opacity 1.0 to 0.0) proportionally to their shrink progress.
- **FR-005**: The expand/shrink interpolation MUST be drag-driven — tied to the current swipe ratio, not to a triggered animation.
- **FR-006**: The expand/shrink MUST be fully reversible — dragging back below the threshold MUST restore all actions to their normal widths and opacities with no hysteresis.
- **FR-007**: The designated action's icon/content MUST remain centered (horizontally and vertically) within its expanding bounds at all times.
- **FR-008**: The sum of all action widths MUST always equal the total available revealed area width, ensuring no gaps or overflow.
- **FR-009**: The separate full-swipe background layer/widget MUST be removed. No new widget is created during full swipe.
- **FR-010**: All existing full-swipe behaviors MUST be preserved: haptic feedback at threshold crossing, action trigger on release, undo integration, programmatic triggerFullSwipe, and FullSwipeConfig API shape.
- **FR-011**: The layout MUST handle any number of actions (1, 2, 3, 4+) with the designated action at any position (first, middle, last).
- **FR-012**: The expand/shrink transition MUST maintain smooth visual performance — no widget tree rebuilds during the drag that would cause frame drops.

### Layout Math

The width distribution during full-swipe expand follows this formula:

- `expandProgress = clamp((revealRatio - activationThreshold) / (fullSwipeThreshold - activationThreshold), 0.0, 1.0)`
- For the designated action at index D among N actions:
  - Non-designated actions get width: `normalWidth * (1.0 - expandProgress)`
  - Designated action gets width: `totalAvailableWidth - sum(nonDesignatedWidths)`
- This ensures widths always sum to the total available area.

### Key Entities

- **Expand Progress**: A 0.0-1.0 value derived from the swipe ratio, representing how far the full-swipe expand has progressed. 0.0 = all actions at normal width; 1.0 = designated action fills everything.
- **Designated Action**: The action specified in FullSwipeConfig.action — the one that expands. Must be present in the reveal actions list.
- **Non-Designated Actions**: All other actions in the reveal panel — they shrink and fade during expand.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users perceive a smooth, continuous transition during full swipe — no visible jump, flicker, or widget swap at any drag position between 0% and 100% of cell width.
- **SC-002**: At expand progress 0.0, all action widths are equal (within 1 pixel). At expand progress 1.0, the designated action width equals the total revealed area width (within 1 pixel) and all other actions have 0 width.
- **SC-003**: At any expand progress value, the sum of all action widths equals the total available revealed area width (within 1 pixel tolerance).
- **SC-004**: The transition is fully reversible — dragging back from expand progress 1.0 to 0.0 restores the exact same layout as never having expanded.
- **SC-005**: All existing full-swipe tests (trigger behavior, haptic feedback, undo, accessibility, programmatic trigger) continue to pass without modification.
- **SC-006**: The interaction maintains smooth visual performance throughout the entire drag gesture.

## Assumptions

- The activation threshold and full-swipe threshold values from the existing FullSwipeConfig are used as-is to define the interpolation range.
- The "locked in" haptic feedback and scale bump behavior at threshold crossing are orthogonal to this visual fix and remain unchanged.
- The FullSwipeConfig API (enabled, threshold, action, postActionBehavior, enableHaptic) does not change — this is a visual/layout fix only.
- Normal action width is computed as `totalAvailableWidth / numberOfActions` (equal distribution) unless the existing reveal panel already uses different sizing, in which case the existing per-action width is used as the baseline.
- The expand behavior applies symmetrically for both left and right swipe directions, depending on which direction has full-swipe configured.

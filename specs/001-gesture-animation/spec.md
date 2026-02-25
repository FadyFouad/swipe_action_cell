# Feature Specification: Foundational Gesture & Spring Animation

**Feature Branch**: `001-gesture-animation`
**Created**: 2026-02-25
**Status**: Draft
**Input**: User description: "Build the foundational gesture and animation layer for a Flutter swipe interaction package called swipe_action_cell."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Live Drag Following (Priority: P1)

An app developer adds `SwipeActionCell` wrapping a list item. When an end user drags the cell
horizontally, the cell visually follows the finger in real time, providing immediate tactile
feedback. The cell does not move until a small initial dead zone is exceeded, preventing
accidental triggers from taps.

**Why this priority**: This is the core visible behavior — without live positional following,
the widget has no observable output. All other user stories depend on this foundation.

**Independent Test**: Place a `SwipeActionCell` wrapping a colored box in a standalone widget
test. Simulate a horizontal drag beyond the dead zone and verify the child's rendered position
updates proportionally to the drag displacement.

**Acceptance Scenarios**:

1. **Given** a cell in the idle state, **When** the user drags horizontally by less than the
   configured dead zone, **Then** the cell does not move and the child receives normal touch
   events.
2. **Given** a cell in the idle state, **When** the user drags horizontally beyond the dead
   zone, **Then** the cell translates horizontally in sync with finger displacement and
   transitions to the dragging state.
3. **Given** a cell in the dragging state with direction locked, **When** minor vertical drift
   occurs during the drag, **Then** the cell continues tracking horizontal displacement only
   and does not drift vertically.
4. **Given** a cell in the dragging state, **When** the user drags toward the maximum
   translation bound, **Then** drag resistance increases progressively and the cell does not
   visually exceed the maximum translation limit.

---

### User Story 2 - Snap-Back on Sub-Threshold Release (Priority: P2)

When an end user releases a drag that did not reach the activation threshold, the cell smoothly
springs back to its original resting position. The motion feels natural — a quick spring
settle, not an abrupt jump.

**Why this priority**: The snap-back is the "cancel" path for every incomplete swipe. A missing
or jarring snap-back breaks the interaction model and creates visual litter in lists.

**Independent Test**: Simulate a drag to 25% of max translation and release. Verify the cell
returns to offset zero within a reasonable timeframe with continuous smooth motion — no jumps,
no stuck positions.

**Acceptance Scenarios**:

1. **Given** a cell dragged to below the activation threshold, **When** the user releases,
   **Then** the cell transitions to animatingToClose and spring-animates back to origin.
2. **Given** a cell in the animatingToClose state, **When** no new drag occurs, **Then** the
   animation completes and the cell settles exactly at origin in the idle state.
3. **Given** a cell that snapped back to origin, **When** the user drags again, **Then** drag
   following begins cleanly from origin with no residual offset.

---

### User Story 3 - Completion Animation on Threshold Release (Priority: P2)

When an end user releases a drag that met or exceeded the activation threshold, the cell
animates out to the fully-extended completion position and holds there (revealed state).

**Why this priority**: This is the "confirm" path — the cell visually commits to a swipe,
signaling that an action would fire (handled by future features). It is equally critical to
snap-back since both are release outcomes the user experiences on every swipe.

**Independent Test**: Simulate a drag to 60% of max translation and release. Verify the cell
animates to max translation and holds there in the revealed state.

**Acceptance Scenarios**:

1. **Given** a cell dragged to at or above the activation threshold, **When** the user
   releases, **Then** the cell transitions to animatingToOpen and spring-animates to the
   maximum translation position.
2. **Given** a cell in the animatingToOpen state, **When** the animation completes, **Then**
   the cell settles at maximum translation in the revealed state.
3. **Given** a cell in the revealed state, **When** no new interaction occurs, **Then** the
   cell holds that position indefinitely.

---

### User Story 4 - Fling to Completion (Priority: P3)

A fast, confident fling gesture — even a short one — animates the cell to completion. The
widget recognizes high-velocity releases and treats them as confirmed swipes regardless of how
far the drag traveled.

**Why this priority**: Flings are a natural mobile gesture. Ignoring velocity would make short
but fast swipes feel unresponsive and inconsistent with platform conventions.

**Independent Test**: Simulate a drag to 15% of max translation with a release velocity above
the configured threshold. Verify the cell animates to the revealed state (not snap-back).

**Acceptance Scenarios**:

1. **Given** a cell dragged to 15% of max translation, **When** released with velocity above
   the velocity threshold, **Then** the cell animates to completion rather than snapping back.
2. **Given** a cell dragged to 15% of max translation, **When** released with velocity below
   the velocity threshold, **Then** the cell snaps back (distance-only rule applies).
3. **Given** a fling in a direction that is disabled, **When** the gesture is initiated,
   **Then** no gesture is recognized and the cell does not move.

---

### User Story 5 - Mid-Animation Interruption (Priority: P3)

A user can grab the cell at any point during a snap-back or completion animation, immediately
cancelling the animation and resuming direct drag control from the cell's current visual
position.

**Why this priority**: Without this, the widget enters states the user cannot escape, breaking
the feeling of direct control. The widget must feel alive and responsive at all times.

**Independent Test**: Start a snap-back animation programmatically, then simulate a new drag
start midway. Verify the cell's rendered position matches the drag position from that moment
forward with no jump or discontinuity.

**Acceptance Scenarios**:

1. **Given** a cell in the animatingToClose state, **When** the user initiates a new drag,
   **Then** the animation stops immediately and drag tracking resumes from the current
   animated position without any positional jump.
2. **Given** a cell in the animatingToOpen state, **When** the user initiates a new drag,
   **Then** the same seamless handoff behavior applies.

---

### Edge Cases

- What if the drag stays below the dead zone for the entire gesture? The cell does not move;
  the child receives all normal pointer events.
- What if a gesture starts as vertical and then shifts horizontal? The nearest vertical scroll
  ancestor retains gesture priority if it has already claimed the gesture.
- What if both swipe directions are disabled? The widget renders the child normally with no
  gesture interception whatsoever.
- What if velocity data is unavailable at release? The decision falls back to distance-only
  threshold comparison.
- What if `maxTranslation` is set to zero for a direction? That direction behaves as disabled.
- What if the user drags far beyond `maxTranslation`? Resistance increases per the resistance
  factor; the cell never visually exceeds `maxTranslation`.
- What if a very gentle spring stiffness is configured? Animation duration extends naturally;
  no artificial time cap is enforced.
- What if 10+ rapid drag-release cycles are performed consecutively? The state machine must
  handle each cycle cleanly with no stuck state or accumulated offset error.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The widget MUST detect horizontal drag start, update, and end events on the
  wrapped child without consuming pointer events when displacement is below the dead zone.
- **FR-002**: The widget MUST lock swipe direction (left or right) within the first 10–20
  logical pixels of movement and MUST NOT alter the locked direction due to subsequent
  vertical drift.
- **FR-003**: No visual displacement or state transition MUST occur until horizontal movement
  exceeds the configured dead zone (default: 12 logical pixels).
- **FR-004**: During an active drag, the child widget MUST translate horizontally proportional
  to the user's displacement beyond the dead zone, subject to resistance near bounds.
- **FR-005**: On drag release with displacement below the activation threshold (default: 40% of
  max translation), the widget MUST animate the cell back to origin using spring motion.
- **FR-006**: On drag release with displacement at or above the activation threshold, the widget
  MUST animate the cell to the maximum translation position using spring motion.
- **FR-007**: On drag release with velocity in the swipe direction exceeding the velocity
  threshold (default: 700 logical pixels/second), the widget MUST animate to completion
  regardless of displacement traveled.
- **FR-008**: A new drag initiated while an animation is active MUST cancel the animation
  immediately and resume drag tracking from the current animated position with no positional
  discontinuity.
- **FR-009**: When used inside a vertical scroll container, the widget MUST yield gesture
  priority to the scroll container when the user's predominant motion is vertical.
- **FR-010**: Drag resistance MUST increase proportionally as the cell approaches its maximum
  translation bound, controlled by a configurable resistance factor (0.0 = no additional
  resistance; 1.0 = maximum resistance).
- **FR-011**: Left and right swipe directions MUST be independently configurable; disabling a
  direction MUST suppress all gesture recognition, visual displacement, and state transitions
  for that direction.
- **FR-012**: The widget MUST expose current swipe state, swipe direction, swipe progress
  (ratio, activation flag, raw offset), and current translation offset as observable values
  accessible to the consuming application.

### Key Entities

- **SwipeDirection**: The directional intent of a gesture — `left`, `right`, or `none`
  (undecided/idle). Locked early in a gesture and held for its duration.
- **SwipeState**: The current lifecycle phase — `idle`, `dragging`, `animatingToOpen`,
  `animatingToClose`, or `revealed`.
- **SwipeProgress**: A point-in-time snapshot of gesture progress containing: direction, ratio
  (0.0 at origin to 1.0 at max translation), `isActivated` flag (ratio ≥ activation
  threshold), and raw offset in logical pixels.
- **SwipeActionCell**: The composable widget that wraps any child and provides the complete
  swipe interaction surface. Accepts gesture and animation configuration objects independently.
- **SwipeGestureConfig**: Groups gesture-detection parameters — dead zone size, enabled
  directions, and velocity threshold.
- **SwipeAnimationConfig**: Groups animation parameters — activation threshold, snap-back
  spring properties, completion spring properties, resistance factor, and maximum translation
  per direction.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The widget renders any child without altering its natural size or layout
  constraints — verified across at minimum 5 different child widget types in widget tests.
- **SC-002**: During active drag, the child's visual position matches the touch position within
  the same rendered frame with no perceptible lag, observable in frame-by-frame test playback.
- **SC-003**: Default-parameter snap-back animation settles at origin within 500ms, with no
  overshoot beyond 5% of the initial displacement.
- **SC-004**: All 5 interaction flows (drag following, snap-back, threshold completion, fling
  completion, mid-animation interrupt) each have at least one passing isolated test covering
  the complete state machine path.
- **SC-005**: Vertical scrolling is uninterrupted in 100% of test cases where the predominant
  gesture direction is vertical, even when the widget is nested inside a scroll container.
- **SC-006**: 10 consecutive rapid drag-release cycles produce no stuck states, accumulated
  offset errors, or rendering artifacts.
- **SC-007**: Each of the 6 configurable parameters (dead zone, activation threshold, velocity
  threshold, resistance factor, snap-back spring, completion spring) produces a measurably
  different observable outcome when changed from its default value — verified by dedicated
  test cases per parameter.

## Assumptions

- The `revealed` state persists until a new user drag is initiated. Auto-close behavior belongs
  to future action features.
- `SwipeProgress.ratio` is clamped to 0.0–1.0. Resistance ensures the cell never visually
  exceeds `maxTranslation`, so the ratio never exceeds 1.0.
- When `maxTranslation` is not explicitly set for a direction, a sensible default derived from
  the widget's rendered width (approximately 60%) is used. Passing `null` for a direction's max
  translation is treated as disabling that direction.
- Fling direction is determined by the release velocity vector. If cumulative displacement
  direction and velocity direction conflict, velocity direction takes precedence.
- This feature does not expose programmatic control (no `SwipeController`) — that belongs to
  a future feature. All observable values are read-only in this feature.
- Snap-back and completion springs are independent configurations, each with their own
  physics properties, applied to the respective animation direction.

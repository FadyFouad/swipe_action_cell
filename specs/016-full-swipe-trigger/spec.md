# Feature Specification: Full-Swipe Auto-Trigger

**Feature Branch**: `016-full-swipe-trigger`
**Created**: 2026-03-02
**Status**: Draft
**Input**: User description: "Add full-swipe auto-trigger to the swipe_action_cell package, where swiping a cell fully across the screen automatically triggers a designated action without needing to tap a revealed button. Configurable independently per direction."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Left Swipe to Delete (iOS Mail Pattern) (Priority: P1)

A user viewing a list of emails (or tasks, notifications, etc.) wants to quickly delete an item without the two-step process of swipe-to-reveal → tap Delete. They swipe left past a full-swipe threshold (75% of cell width) and release. The delete action fires immediately, and the cell animates out. If they drag back before releasing, the panel returns to normal reveal state with no side effects.

**Why this priority**: This is the core iOS Mail "full swipe to act" pattern — the headline feature. Every other story builds on this. Without this, the feature doesn't exist.

**Independent Test**: Configure a `SwipeActionCell` with left swipe in reveal mode and a `FullSwipeConfig` pointing to the Delete action. Drag left beyond 75% width and release. Verify the delete callback fires and the cell exits.

**Acceptance Scenarios**:

1. **Given** a cell with left swipe reveal mode and `FullSwipeConfig(enabled: true, threshold: 0.75, action: deleteAction)`, **When** the user drags left past 75% of cell width and releases, **Then** the delete action fires immediately and `postActionBehavior` animation plays.
2. **Given** the same configuration, **When** the user drags left past 75% then drags back below 75% before releasing, **Then** the expand-to-fill visual reverses smoothly and on release (above reveal threshold) the panel stays open without triggering the action.
3. **Given** the same configuration, **When** the user drags left past 75% then releases, **Then** `onFullSwipeTriggered` callback fires with `direction: left` and the designated action's `onTap` also fires.
4. **Given** the same configuration, **When** the user drags left between 40% and 75% and releases, **Then** normal reveal behavior occurs (panel stays open) and the full-swipe action does NOT fire.
5. **Given** the same configuration, **When** the user drags left less than 40% and releases, **Then** the cell snaps back with no panel reveal and no action trigger.

---

### User Story 2 - Visual Commit Indicator During Full-Swipe (Priority: P1)

As the user's finger crosses the full-swipe threshold, the UI must unambiguously communicate that releasing now will trigger the action. The designated action's background color expands to fill the entire cell area behind the sliding child, its icon scales up to center stage, and other action buttons fade out. Dragging back reverses this animation smoothly so the user always knows exactly what will happen on release.

**Why this priority**: Without clear visual feedback, users will accidentally trigger actions or be confused. This is inseparable from Story 1 in terms of usability.

**Independent Test**: Configure full-swipe with `expandAnimation: true`. Drag to 80% (past threshold) and assert the action icon is centered and scaled, background color matches the action's color, and sibling actions are not visible. Drag back to 60% and assert the layout returns to the normal reveal panel state.

**Acceptance Scenarios**:

1. **Given** `expandAnimation: true` and the drag position crosses the full-swipe threshold, **When** position passes the threshold, **Then** the designated action's background color fills the entire cell behind the child, the icon scales up (centered), and all other action buttons fade out.
2. **Given** the drag position is above the full-swipe threshold, **When** the user drags back below the threshold, **Then** the other action buttons fade back in and the expanded action shrinks back to its panel slot smoothly.
3. **Given** `expandAnimation: false`, **When** the user drags past the threshold, **Then** no expand-to-fill visual plays; the panel stays in normal reveal layout.
4. **Given** the drag position crosses the threshold, **When** the transition completes, **Then** a "locked-in" animation plays on the icon (scale: 1.0 → 1.15 → 1.0 in a brief bounce).

---

### User Story 3 - Right Swipe Full-Trigger (Symmetric with Left) (Priority: P2)

A user working with a task list that uses progressive right swipe (incrementing a counter) can swipe fully right to jump the counter directly to its maximum value — saving multiple incremental swipes. Alternatively, when right swipe is in reveal/intentional mode, a full right swipe works identically to a full left swipe: the designated action fires immediately, the expand-to-fill visual plays, and the action must be in the reveal panel for tap accessibility.

**Why this priority**: Full-swipe is symmetric across directions — the same `FullSwipeConfig` contract applies to both left and right regardless of mode (progressive or intentional). This consistency reduces API surface and consumer confusion.

**Independent Test**: Configure right swipe progressive mode with `maxValue: 10` and `FullSwipeConfig(enabled: true, fullSwipeProgressBehavior: setToMax)`. Drag right past 75%. Verify counter jumps to 10 and `onFullSwipeTriggered` fires. Separately, configure right swipe in reveal mode with `FullSwipeConfig` pointing to one of the reveal actions. Drag right past 75%. Verify that action fires (no `fullSwipeProgressBehavior` needed).

**Acceptance Scenarios**:

1. **Given** right swipe in progressive mode and `FullSwipeConfig` with `fullSwipeProgressBehavior: setToMax`, **When** the user drags right past the full-swipe threshold and releases, **Then** the progress value jumps to `maxValue` immediately.
2. **Given** right swipe in progressive mode and `FullSwipeConfig` with `fullSwipeProgressBehavior: customAction` and a custom action, **When** the user drags right past the full-swipe threshold and releases, **Then** the custom action fires instead of modifying the progress value.
3. **Given** right swipe in reveal/intentional mode and `FullSwipeConfig` pointing to one of the reveal panel actions, **When** the user drags right past the full-swipe threshold and releases, **Then** the designated action fires immediately, identically to left swipe reveal + full-swipe.
4. **Given** right swipe configured for full-swipe (any mode), **When** the user hovers between threshold values, **Then** the same expand-to-fill visual from Story 2 applies symmetrically for right direction.

---

### User Story 4 - Haptic Feedback at Threshold Crossing (Priority: P2)

When the user's finger crosses the full-swipe threshold in either direction (entering or exiting), a distinct haptic pulse fires to confirm the crossing. On release above the threshold (action commits), a second confirming haptic fires. This gives tactile confidence that the action either locked in or was cancelled.

**Why this priority**: Haptic feedback is critical for interaction confidence but is independent of visual feedback — both can be tested separately, and haptic can be disabled per-configuration.

**Independent Test**: Configure `enableHaptic: true`. Drag past threshold and assert `SwipeFeedbackController` receives a `fullSwipeThreshold` event. Release above threshold and assert a `fullSwipeActivation` event fires.

**Acceptance Scenarios**:

1. **Given** `enableHaptic: true`, **When** the drag crosses the full-swipe threshold, **Then** the `fullSwipeThreshold` haptic pattern fires exactly once per crossing.
2. **Given** `enableHaptic: true`, **When** the user releases above the full-swipe threshold, **Then** the `fullSwipeActivation` haptic pattern fires.
3. **Given** `enableHaptic: false`, **When** the drag crosses the threshold or action triggers, **Then** no haptic events are dispatched.
4. **Given** the user crosses the threshold, drags back below it, then crosses it again, **Then** the threshold haptic fires each time the boundary is crossed (both entering and exiting).

---

### User Story 5 - Programmatic Full-Swipe via SwipeController (Priority: P3)

A developer building an onboarding tutorial or an automated test needs to trigger the full-swipe action without simulating a gesture. Calling `controller.triggerFullSwipe(SwipeDirection.left)` programmatically fires the designated action including callbacks, haptic, and post-action animation — identical to a user gesture.

**Why this priority**: Programmatic access enables testing, tutorials, and accessibility fallbacks. It's lower priority than core gesture + visual feedback but necessary for a complete API.

**Independent Test**: Create a `SwipeController`, attach it to a cell with left full-swipe configured. Call `triggerFullSwipe(SwipeDirection.left)`. Verify the action fires and the cell responds identically to a gesture-triggered full-swipe.

**Acceptance Scenarios**:

1. **Given** a `SwipeController` attached to a cell with full-swipe configured, **When** `triggerFullSwipe(SwipeDirection.left)` is called, **Then** the designated action fires, `onFullSwipeTriggered` is called, and post-action behavior plays.
2. **Given** `triggerFullSwipe(SwipeDirection.right)` called when right full-swipe is disabled, **Then** the call is a no-op with no errors or state changes.
3. **Given** full-swipe is not configured for a direction, **When** `triggerFullSwipe` is called for that direction, **Then** the call silently does nothing.

---

### User Story 6 - Accessibility & Keyboard Navigation (Priority: P3)

A user relying on keyboard navigation or a screen reader can trigger the full-swipe action without performing the gesture. `Shift+Arrow` keyboard shortcut fires the full-swipe action for the corresponding direction. The screen reader announces "Swipe fully to [action label]" when focus is on the cell. The full-swipe action is always reachable via the reveal panel tap as a mandatory fallback.

**Why this priority**: Accessibility is a non-negotiable requirement but can be verified independently of gesture interaction. A complete feature must pass accessibility checks.

**Independent Test**: Focus a cell with left full-swipe configured on Delete. Press `Shift+Left Arrow`. Verify delete action fires. Verify semantic label includes "Swipe fully to Delete".

**Acceptance Scenarios**:

1. **Given** a cell with full-swipe configured, **When** the screen reader focuses the cell, **Then** the semantic description includes "Swipe fully to [action label]" for each enabled full-swipe direction.
2. **Given** keyboard focus on a cell with left full-swipe, **When** `Shift+Left Arrow` is pressed, **Then** the full-swipe action fires identically to a gesture release above threshold.
3. **Given** a full-swipe action configured, **Then** that same action MUST also be present as a tappable item in the reveal panel (enforced via assertion during configuration).
4. **Given** RTL layout, **When** `Shift+Right Arrow` is pressed for a semantically "left" (backward) action, **Then** the correct action fires according to semantic direction mapping.

---

### Edge Cases

- What happens when the user releases at exactly the threshold value (boundary condition between reveal and full-swipe)?
- How does the system handle `FullSwipeConfig.threshold` set equal to the reveal threshold? (Must assert threshold is strictly greater.)
- What happens when `FullSwipeConfig` is configured with an action not present in the reveal panel actions list? (Assert with descriptive message.)
- What happens when `FullSwipeConfig.action` has a null or empty label and `enabled: true`? (Assert with descriptive message — non-empty label required for screen reader semantics.)
- Full-swipe trigger in a `SwipeGroupController` group closes any open sibling cells (same accordion contract as normal swipe-open).
- After a full-swipe action fires, the cell locks out new gesture input until the post-action animation completes, preventing double-triggers regardless of whether the action callback is sync or async.
- What happens in auto-trigger left-swipe mode when full-swipe is also configured — two thresholds, two actions on the same direction?
- How does full-swipe threshold interact with multi-threshold zone thresholds if they overlap?
- How does the "locked-in" bounce animation interact with users who have Reduce Motion enabled in accessibility settings?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a `FullSwipeConfig` data class with fields: `enabled` (bool, default false), `threshold` (double 0.0–1.0, default 0.75), `action` (SwipeAction, required when enabled), `postActionBehavior` (PostActionBehavior: snapBack | animateOut | stay, default animateOut — where animateOut slides the cell off-screen in the swipe direction then collapses its height to zero), `expandAnimation` (bool, default true), and `enableHaptic` (bool, default true).
- **FR-002**: `FullSwipeConfig` MUST be an optional field on both `RightSwipeConfig` and `LeftSwipeConfig`; when null, the feature has zero overhead on rendering or gesture handling.
- **FR-003**: When a full-swipe threshold crossing occurs, the system MUST trigger the designated action on gesture release (not on drag) and fire the `onFullSwipeTriggered(SwipeDirection, SwipeAction)` callback.
- **FR-004**: The designated `SwipeAction.onTap` callback MUST also fire when the full-swipe action is triggered (by gesture or programmatically), matching tap behavior.
- **FR-005**: When `expandAnimation` is true and drag exceeds the full-swipe threshold, the system MUST: fill the entire cell background with the designated action's color, center and scale up the designated action's icon, and fade out all other action buttons.
- **FR-006**: The expand-to-fill visual transition MUST be bidirectional — dragging back below the threshold MUST smoothly reverse the expansion and restore the normal reveal panel layout.
- **FR-007**: When the drag crosses the full-swipe threshold (entering or exiting the full-swipe zone), the system MUST fire the `fullSwipeThreshold` haptic pattern if `enableHaptic` is true.
- **FR-008**: On release above the full-swipe threshold, the system MUST fire the `fullSwipeActivation` haptic pattern if `enableHaptic` is true, before executing the action.
- **FR-009**: The system MUST assert (with a descriptive error message) that `FullSwipeConfig.threshold` is strictly greater than the activation threshold of the same direction.
- **FR-010**: The system MUST assert (with a descriptive error message) that `FullSwipeConfig.threshold` is strictly greater than all configured zone thresholds for the same direction.
- **FR-011**: When left swipe mode is `reveal` and full-swipe is enabled, the system MUST assert that `FullSwipeConfig.action` is one of the actions in the reveal panel's action list, ensuring tap-based accessibility is always available.
- **FR-012**: When left swipe mode is `autoTrigger` and full-swipe is also configured, the system MUST support two commitment levels: the auto-trigger threshold fires action A, the full-swipe threshold fires action B (each independently configurable).
- **FR-013**: `FullSwipeConfig` is symmetric across directions — on right swipe in reveal/intentional mode it behaves identically to left swipe (action must be in reveal panel, fires on release, same expand-to-fill visual). For right swipe in progressive mode only, `FullSwipeConfig` additionally supports a `fullSwipeProgressBehavior` field with values `setToMax` (jumps progress to maxValue) and `customAction` (fires a separate designated action); this field is absent from non-progressive right-swipe configs.
- **FR-014**: `SwipeController` MUST expose a `triggerFullSwipe(SwipeDirection direction)` method that programmatically fires the designated action identically to a gesture release above threshold, including callbacks and post-action behavior.
- **FR-015**: Full-swipe MUST work correctly in RTL layouts, following the semantic direction mapping from the scroll integration feature — no extra configuration required by consumers.
- **FR-016**: Full-swipe MUST work correctly alongside `SwipeGroupController` — triggering a full-swipe in one cell MUST close any open sibling cells in the group, identical to accordion close-others behavior triggered by a normal swipe-open gesture.
- **FR-017**: The screen reader semantic description for a cell with full-swipe enabled MUST include "Swipe fully to [action label]" for each enabled full-swipe direction.
- **FR-018**: `Shift+Arrow` keyboard shortcuts MUST trigger the full-swipe action for the corresponding semantic direction.
- **FR-019**: `FullSwipeConfig` MUST be immutable with a `copyWith` method and a `const` constructor.
- **FR-020**: `FullSwipeConfig` MUST be configurable via `SwipeActionCellTheme` for app-wide defaults.
- **FR-021**: Template configurations for delete and archive actions MUST include appropriate `FullSwipeConfig` defaults out-of-the-box.
- **FR-022**: When Reduce Motion accessibility preference is active, the "locked-in" bounce animation MUST be suppressed; the threshold crossing MUST still be indicated via color/icon change only.
- **FR-023**: From the moment a full-swipe action fires until the post-action animation completes, the cell MUST ignore all new gesture input (swipe, tap) — preventing double-triggers whether the action callback is synchronous or asynchronous.
- **FR-024**: The system MUST assert (with a descriptive error message) that `FullSwipeConfig.action` has a non-null, non-empty label when `enabled` is true — ensuring screen readers can announce a meaningful "Swipe fully to [action label]" description.

### Key Entities

- **FullSwipeConfig**: Configuration for full-swipe auto-trigger on one direction. Holds threshold, designated action reference, post-action behavior, visual and haptic toggles.
- **FullSwipeProgressBehavior**: Enum for right-swipe progressive mode: `setToMax` (progress jumps to max) or `customAction` (separate action fires).
- **PostActionBehavior**: Enum for cell behavior after the action fires: `snapBack` (spring back to closed position), `animateOut` (cell slides off-screen in the swipe direction then height collapses to zero — iOS Mail delete pattern, default for full-swipe), or `stay` (cell remains open at the revealed position). Reused from undo feature if already defined there.
- **FullSwipeState**: Internal runtime state tracking whether full-swipe is `idle`, `armed` (drag above threshold), `triggered` (action fired, post-action animation in progress — gestures locked), or `completed` (animation finished). Not part of public API.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Full-swipe action triggers within a single animation frame (≤16ms) of the user's finger lifting above the threshold — no perceptible delay between release and action execution.
- **SC-002**: The expand-to-fill visual animation maintains 60fps with no dropped frames on mid-range devices, measured across at least 100 threshold crossings.
- **SC-003**: Bidirectional threshold hovering (dragging back and forth across the threshold boundary) produces no jitter, flicker, or layout jumps — tested by simulating 10 rapid back-and-forth crossings.
- **SC-004**: When `FullSwipeConfig` is null (disabled), the widget tree contains zero additional nodes compared to a cell without any full-swipe configuration — verified by widget tree inspection.
- **SC-005**: 100% of full-swipe actions are reachable via an alternative non-gesture path (reveal panel tap or keyboard shortcut) — verified by accessibility audit and test coverage.
- **SC-006**: RTL layout produces correct semantic behavior without any RTL-specific consumer configuration — verified by running the full test suite with `TextDirection.rtl`.
- **SC-007**: All three threshold validation assertions fire with descriptive, actionable error messages that identify the misconfiguration — verified by dedicated unit tests for each assert.
- **SC-008**: All existing tests (383 passing) continue to pass after this feature is integrated — full-swipe disabled state is fully backward-compatible.

## Clarifications

### Session 2026-03-02

- Q: When right swipe is in reveal/intentional mode (not progressive), does `FullSwipeConfig` work the same as on left swipe? → A: Yes — symmetric. Right reveal mode + full-swipe behaves identically to left reveal mode + full-swipe. `fullSwipeProgressBehavior` is only applicable when right swipe mode is progressive; it does not appear on non-progressive right-swipe configs.
- Q: What is the visual effect of `PostActionBehavior.animateOut`? → A: Slide then collapse — the cell slides fully off-screen in the swipe direction, then its height collapses to zero (standard iOS Mail delete pattern).
- Q: When a full-swipe action triggers on one cell in a `SwipeGroupController` group, should sibling cells auto-close? → A: Yes — full-swipe trigger closes any open sibling cells in the group, identical to normal swipe-open accordion behavior.
- Q: After a full-swipe action fires, can the user initiate another swipe before the post-action animation completes? → A: No — the cell locks out new gestures from the moment the action fires until the post-action animation finishes, preventing double-triggers.
- Q: Should a non-empty label on `FullSwipeConfig.action` be enforced when full-swipe is enabled? → A: Yes — assert that the action label is non-null and non-empty when `enabled: true`; a clear error message guides the developer. Screen readers require a meaningful label.

## Assumptions

- `PostActionBehavior` enum likely already exists from the undo feature (F12). This feature reuses it rather than creating a new type; if not, it is defined here.
- The haptic event patterns `fullSwipeThreshold` and `fullSwipeActivation` are new named patterns added to `SwipeFeedbackConfig`, consistent with how existing patterns are declared.
- The expand-to-fill visual is implemented by driving the existing `visual/` layer (background builders and action builders) with a new `fullSwipeProgress` animation value — not a separate rendering pipeline.
- "Release at exactly the threshold value" defaults to triggering the full-swipe action (the threshold is inclusive from above).
- The "locked-in" bounce animation fires once when the drag first enters the full-swipe zone; it does not repeat on continued dragging.
- Async action callbacks are the consumer's responsibility — the package does not await action completion before running post-action animation.
- The `onFullSwipeTriggered` callback is added as a new parameter on `SwipeActionCell`, alongside the existing callback parameters.

# Feature Specification: Swipe Background Layer

**Feature Branch**: `002-swipe-background`
**Created**: 2026-02-25
**Status**: Draft
**Input**: User description: "Add a visual feedback layer to the swipe_action_cell package that renders behind the sliding child during swipe interactions."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Custom Background per Direction (Priority: P1)

A developer integrating `SwipeActionCell` into a list view wants to show a meaningful background when the user swipes in either direction. They pass a left-background builder (e.g., showing a red trash icon) and a right-background builder (e.g., showing a green bookmark icon). As the user drags the list item, the appropriate background is revealed behind the sliding child.

**Why this priority**: This is the core capability of the feature — without direction-aware background builders, there is no visual feedback layer at all. Every other story builds on this.

**Independent Test**: Can be fully tested by mounting a `SwipeActionCell` with a `leftBackground` builder and a `rightBackground` builder, then simulating horizontal drag gestures in both directions. The test delivers the primary value of contextual visual feedback.

**Acceptance Scenarios**:

1. **Given** a cell configured with both `leftBackground` and `rightBackground` builders, **When** the user drags the child to the right, **Then** the right-swipe background is rendered behind the child and the left-swipe background is not visible.
2. **Given** a cell configured with both builders, **When** the user drags the child to the left, **Then** the left-swipe background is rendered behind the child and the right-swipe background is not visible.
3. **Given** a cell with only `leftBackground` configured (right is null), **When** the user drags to the right, **Then** no background is rendered.
4. **Given** a cell with only `rightBackground` configured (left is null), **When** the user drags to the left, **Then** no background is rendered.

---

### User Story 2 - Progress-Aware Background Rebuilding (Priority: P2)

A developer wants the background to respond dynamically to swipe progress — for example, animating opacity, scale, or color as the drag travels further. They use the `SwipeProgress` data passed into the builder (containing `ratio`, `isActivated`, and `rawOffset`) to drive visual transitions within the builder function.

**Why this priority**: Progress-aware rebuilding is what makes the background feel alive and responsive. Without it, the background would be a static widget with no tie to the gesture — significantly reducing UX value.

**Independent Test**: Can be tested by mounting a cell with a background builder that reads `progress.ratio` and applies it to an opacity or scale, then asserting the rendered widget's visual properties at different drag offsets.

**Acceptance Scenarios**:

1. **Given** a background builder that maps `progress.ratio` to an `Opacity` widget, **When** the swipe ratio is 0.0 (just started), **Then** the background is fully transparent.
2. **Given** the same cell, **When** the swipe ratio is 1.0 (threshold reached), **Then** the background is fully opaque.
3. **Given** a builder that reads `progress.isActivated`, **When** the drag crosses the activation threshold, **Then** `isActivated` becomes `true` and the builder is called again with the updated value.
4. **Given** a background builder, **When** the user actively drags, **Then** the builder is called on every frame update with the current progress values.

---

### User Story 3 - Built-in Default Background Widget (Priority: P3)

A developer who wants a polished default without custom builders uses the built-in `SwipeActionBackground` widget, configuring it with an icon, an optional label, a background color, and a foreground color. The widget handles its own animation: the icon scales and fades in as the swipe progresses, the background color intensifies near the activation threshold, and a brief scale bump occurs when the threshold is first crossed.

**Why this priority**: Reduces boilerplate for the common case and demonstrates a reference implementation of the progress-reactive pattern. Important for developer experience but not a blocker for the core protocol.

**Independent Test**: Can be tested independently by rendering `SwipeActionBackground` directly with a mock `SwipeProgress` value and verifying the visual output (icon opacity, scale, background color intensity) at different ratio values.

**Acceptance Scenarios**:

1. **Given** a `SwipeActionBackground` with an icon and `ratio = 0.0`, **When** rendered, **Then** the icon is not visible (opacity ≈ 0, scale ≈ 0).
2. **Given** the same widget with `ratio = 0.5`, **When** rendered, **Then** the icon is partially visible and scaled between minimum and maximum values.
3. **Given** the widget with `ratio = 1.0` (activated), **When** rendered, **Then** the icon is fully visible, the background color is at its most intense, and the layout shows a brief scale bump effect.
4. **Given** `SwipeActionBackground` with a non-null `label`, **When** rendered, **Then** the label text is shown below the icon in a column layout.
5. **Given** `SwipeActionBackground` with a null `label`, **When** rendered, **Then** only the icon is displayed, no extra spacing for a label.

---

### User Story 4 - Background Clipping and Border Radius (Priority: P4)

A developer whose list items have rounded corners needs the background to respect the same border radius so it does not bleed outside the cell's visual bounds. They configure `borderRadius` on the `SwipeActionCell` and expect the background to be clipped accordingly.

**Why this priority**: Visual correctness for rounded-corner designs. Not blocking for flat-style lists, but required for many real-world UI patterns.

**Independent Test**: Can be tested by mounting a cell with a non-null `borderRadius`, dragging, and asserting the background is clipped to the specified radius.

**Acceptance Scenarios**:

1. **Given** a cell with `borderRadius: BorderRadius.circular(12)` and a background builder, **When** the user swipes, **Then** the background widget is visually clipped to the rounded rectangle.
2. **Given** a cell with default `clipBehavior: Clip.hardEdge`, **When** the user swipes, **Then** the background does not render outside the cell's bounding box.
3. **Given** `clipBehavior: Clip.none`, **When** the user swipes, **Then** no clipping is applied to the background.

---

### Edge Cases

- If a background builder throws an exception, it propagates normally — the widget provides no silent catch or fallback. Developers see it via Flutter's standard error widget in debug mode, consistent with Flutter's own builder conventions.
- When `ratio` is `0.0` at idle (no swipe in progress), no builder is called and the background slot is empty. During snap-back, the last active direction's builder remains in the widget tree until `ratio` returns to `0.0`, at which point it is removed — preserving animation continuity.
- During snap-back, `ratio` animates continuously from its release value back to `0.0`; the builder is called every frame throughout, giving the background the same smooth reactivity as during drag.
- What happens if the background widget itself has a fixed height taller than the cell — is it clipped or does it expand the cell?
- Background behavior after a full left swipe transitions the cell to "revealed/open" state is out of scope for this feature. Feature F4 (intentional left swipe) owns revealed-state rendering.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The widget MUST render a background widget behind the sliding child, using a `Stack` layout where the background fills the cell's full height and width.
- **FR-002**: The widget MUST call the `rightBackground` builder when the child is being dragged to the right, and the `leftBackground` builder when dragged to the left. During snap-back, the last active direction's builder MUST remain in the widget tree until `ratio` returns to `0.0`, then be removed. When idle (no active swipe), the background slot MUST be empty.
- **FR-003**: The widget MUST pass a `SwipeProgress` value to each background builder on every frame update during a swipe gesture and throughout snap-back animation, including: `direction`, `ratio` (0.0–1.0), `isActivated` (bool), and `rawOffset` (pixels). During snap-back, `ratio` MUST animate continuously from its release value back to `0.0`.
- **FR-004**: When a directional background builder is `null`, the widget MUST render no background for that swipe direction.
- **FR-005**: The background layer MUST NOT affect the layout or intrinsic size of the child widget.
- **FR-006**: The background layer MUST NOT affect gesture detection — all pointer events for the drag gesture MUST be routed through the child's interaction layer, not the background.
- **FR-007**: The background MUST be clipped to the cell's widget bounds using the configured `clipBehavior` (default: `Clip.hardEdge`).
- **FR-008**: When `borderRadius` is non-null, the background MUST be clipped to the specified rounded rectangle.
- **FR-009**: The `SwipeActionBackground` built-in widget MUST scale and fade in its icon from invisible/small to visible/full-size as `ratio` progresses from 0.0 to 1.0.
- **FR-010**: The `SwipeActionBackground` MUST intensify (darken or saturate) its `backgroundColor` as `ratio` approaches 1.0 (activation threshold).
- **FR-011**: The `SwipeActionBackground` MUST produce a brief scale bump on the icon/content when `isActivated` first transitions from `false` to `true`.
- **FR-012**: The `SwipeActionBackground` MUST display the `label` string when provided, and omit label layout when `label` is `null`.
- **FR-013**: Background builders MUST be treated as lightweight and called on every frame; the contract forbids expensive computation inside the builder.
- **FR-014**: Background builder exceptions MUST propagate normally without being caught by the widget. No fallback or silent swallowing is provided, consistent with Flutter's own builder conventions.

### Key Entities

- **SwipeProgress**: A data object representing the current state of an in-progress swipe. Attributes: `direction` (left or right), `ratio` (0.0–1.0 normalized progress toward activation threshold), `isActivated` (whether the threshold has been crossed), `rawOffset` (absolute horizontal offset in pixels).
- **SwipeActionBackground**: A built-in, stateful background widget providing icon + optional label display with progress-reactive animations (scale, fade, color intensity, threshold bump). Configurable via `icon`, `label`, `backgroundColor`, `foregroundColor`. Label is laid out below the icon in a column when provided.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A developer can wire a custom background for either or both swipe directions with no more than one builder parameter per direction, without modifying child widget code.
- **SC-002**: The background widget rebuilds on every drag-frame update, maintaining smooth visual continuity with no perceptible lag behind the child's position.
- **SC-003**: The built-in `SwipeActionBackground` renders correctly across all `ratio` values from 0.0 to 1.0, with the icon fully invisible at 0.0 and fully visible at 1.0.
- **SC-004**: A cell with `borderRadius` configured shows zero background pixel bleed outside the rounded bounds during swipe.
- **SC-005**: Setting a directional builder to `null` results in no background rendered for that direction, with no errors or warnings.
- **SC-006**: The background layer causes no measurable change to the cell's intrinsic height, width, or hit-test area compared to a cell without background builders.

## Assumptions

- `SwipeProgress` is already defined as part of Feature 001 (gesture + animation). This feature consumes it; it does not redefine it.
- Feature 001 already translates the child widget horizontally during swipe. This feature layers a background behind it via `Stack`; it does not change child positioning logic.
- The background builder functions are called synchronously on the UI thread during the frame build; they must remain lightweight (no async work, no heavy computation).
- `SwipeActionBackground` is a stateful widget that observes `isActivated` transitions using previous-value comparison in `didUpdateWidget`, enabling the threshold bump animation without external state.
- The `clipBehavior` default of `Clip.hardEdge` follows Flutter's own convention for clipping containers, prioritizing performance over anti-aliasing.
- The background fills the full available space of the cell (Positioned.fill or Expanded), so its visual size is always determined by the parent, not by its own content size.

## Clarifications

### Session 2026-02-25

- Q: When there is no active swipe (ratio = 0.0, idle), are any builders called and kept in the widget tree, or is the background slot empty? → A: The last active direction's builder stays in the tree until snap-back completes (ratio reaches 0.0), then is removed. At true idle, the background slot is empty.
- Q: During snap-back animation (after user releases without triggering the action), how does `ratio` behave? → A: Ratio animates continuously from its release value back to 0.0; builder is called every frame throughout snap-back.
- Q: In `SwipeActionBackground`, where is the label positioned relative to the icon? → A: Label below icon, column layout (icon on top, label below).
- Q: When a background builder throws an exception at runtime, what does the widget do? → A: Exception propagates normally; no silent catch or fallback provided, consistent with Flutter's own builder conventions.
- Q: After a full left swipe completes and the cell enters a "revealed/open" state (F4), what does the background show? → A: Out of scope for this feature — F4 owns revealed-state rendering. This feature's background contract ends at the snap-back boundary.

## Dependencies

- **Feature 001 (001-gesture-animation)**: `SwipeProgress`, `SwipeDirection`, and the horizontal translation of the child widget must be in place before this layer can be rendered.
- **Feature F4 (intentional left swipe)**: Background behavior in the revealed/open state (post full left swipe) is explicitly deferred to F4. This feature's scope ends at the snap-back boundary.

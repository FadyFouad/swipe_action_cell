# Feature Specification: Multi-Zone Swipe

**Feature Branch**: `009-multi-zone-swipe`
**Created**: 2026-02-28
**Status**: Draft
**Input**: User description: "Add multi-threshold zone support to the swipe_action_cell package, allowing multiple activation zones per swipe direction with different actions or step values at each zone."

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Developer Configures Multiple Intentional Zones on Left Swipe (Priority: P1)

An app developer wants different left-swipe actions at different drag distances. For a mail list item, a moderate drag (40%) archives the message, while a longer drag (80%) deletes it. The developer declares an ordered list of two zones on the left swipe direction. When an end user releases at or past the archive threshold but below the delete threshold, only the archive action fires. When released past the delete threshold, only the delete action fires.

**Why this priority**: This is the primary consumer-facing value proposition — enabling richer intentional-swipe experiences that currently require a completely custom widget. It unblocks the most common multi-action use case (archive vs. delete).

**Independent Test**: Can be fully tested by configuring two left-swipe zones on a list item, performing swipes to each threshold, and verifying that only the highest-crossed zone's action fires each time.

**Acceptance Scenarios**:

1. **Given** a list item with two left-swipe zones (threshold 0.4 → archive, threshold 0.8 → delete), **When** the user drags to 50% and releases, **Then** only the archive action fires and the delete action does not fire.
2. **Given** the same configuration, **When** the user drags to 85% and releases, **Then** only the delete action fires and the archive action does not fire.
3. **Given** the same configuration, **When** the user drags to 30% and releases (below all thresholds), **Then** no action fires and the cell snaps back to idle.
4. **Given** four left-swipe zones defined, **When** the user drags to the third zone and releases, **Then** only the third zone's action fires.

---

### User Story 2 — Developer Configures Multiple Progressive Zones on Right Swipe (Priority: P1)

An app developer wants different increment amounts at different drag distances on a right swipe. A short drag (30%) increments by 1, a medium drag (60%) increments by 5, and a long drag (90%) increments by 10. The released zone's step value is used for the increment.

**Why this priority**: Equal in value to intentional zones — this enables granular progressive interaction that makes the right swipe meaningfully richer than a single fixed step.

**Independent Test**: Can be fully tested by configuring three right-swipe zones with distinct step values, releasing at each zone, and verifying the correct increment is applied each time.

**Acceptance Scenarios**:

1. **Given** a right-swipe cell with zones at 0.3 (step +1), 0.6 (step +5), and 0.9 (step +10), **When** the user drags to 35% and releases, **Then** the value increments by 1.
2. **Given** the same configuration, **When** the user drags to 65% and releases, **Then** the value increments by 5.
3. **Given** the same configuration, **When** the user drags to 92% and releases, **Then** the value increments by 10.
4. **Given** the same configuration, **When** the user drags to 25% and releases (below all thresholds), **Then** no increment occurs and the cell snaps back.

---

### User Story 3 — End User Receives Visual Feedback When Crossing Zone Boundaries (Priority: P1)

As an end user drags a list item, the background smoothly transitions between zone colors and icons so they understand which action will fire upon release. When crossing each zone boundary a brief visual "click" effect (scale bump and color shift) occurs. The current active zone is clearly indicated throughout the drag.

**Why this priority**: Without visual zone feedback, multi-zone behavior is invisible and disorienting. This is critical for the feature to be usable — it directly supports discoverability.

**Independent Test**: Can be fully tested by configuring zones with distinct colors, dragging slowly across each boundary, and verifying smooth background transitions and a visible boundary-crossing effect at each threshold.

**Acceptance Scenarios**:

1. **Given** two zones with different colors, **When** the drag position crosses the first zone's threshold, **Then** the background transitions from the first zone's color to the second zone's color.
2. **Given** the user is dragging and crosses a zone boundary, **Then** a brief scale bump and color shift occur at the boundary crossing.
3. **Given** crossfade transition style is configured, **When** zone threshold is crossed, **Then** zone backgrounds cross-dissolve.
4. **Given** slide transition style is configured, **When** zone threshold is crossed, **Then** zone backgrounds slide in/out.
5. **Given** instant transition style is configured, **When** zone threshold is crossed, **Then** background changes without animation.

---

### User Story 4 — End User Receives Haptic Feedback at Zone Boundaries (Priority: P2)

As an end user drags past each zone boundary, distinct haptic feedback confirms that a new action is now "armed." Each zone may specify its own haptic pattern so that lighter actions (archive) produce a lighter tap and destructive actions (delete) produce a stronger impact.

**Why this priority**: Important for accessibility and feel, but the feature is still usable and valuable without it. Depends on the visual feedback (P1) being in place first.

**Independent Test**: Can be fully tested by configuring two zones with different haptic patterns, slowly dragging through each boundary on a physical device, and verifying distinct haptic outputs at each threshold.

**Acceptance Scenarios**:

1. **Given** two zones each with a configured haptic pattern, **When** the user's drag crosses the first zone boundary, **Then** the first zone's haptic pattern fires.
2. **Given** the same configuration, **When** the user's drag crosses the second zone boundary, **Then** the second zone's haptic pattern fires.
3. **Given** a zone with no haptic configured, **When** the user crosses that zone boundary, **Then** no haptic is produced for that boundary.
4. **Given** the user crosses a boundary and then drags back below it, **When** the user crosses that boundary again in the forward direction, **Then** the haptic fires again.

---

### User Story 5 — Developer Migrates from Single-Threshold Config Without Changes (Priority: P1)

An existing consumer using single-threshold configuration from Features 003 and 004 upgrades the package. Their existing code compiles and behaves identically without any migration effort. If they choose to add zones later, they can do so as an additive change.

**Why this priority**: Backward compatibility is a hard constraint — breaking existing consumers would prevent adoption of this version.

**Independent Test**: Can be fully tested by building a cell using only the existing single-threshold API surface and verifying identical behavior before and after adding this feature to the package.

**Acceptance Scenarios**:

1. **Given** an existing cell configured with a single left-swipe threshold and action, **When** the package is updated to include multi-zone support, **Then** the cell behaves identically with no code changes required.
2. **Given** an existing cell configured with a single right-swipe threshold and step value, **When** the package is updated, **Then** the cell behaves identically.
3. **Given** both a single threshold and a zones list are provided for the same direction, **When** the cell renders, **Then** the zones list takes precedence and the single threshold is ignored.

---

### Edge Cases

- What happens when the user drags past all zones and then drags back below all thresholds? → The cell should return to idle/no-active-zone state; release produces no action.
- What happens when the user drags back from a higher zone to a lower zone? → The active zone updates to the highest currently crossed zone; the visual transitions backward accordingly.
- What happens with an empty zones list? → Treated as if no zones are configured; falls back to single-threshold behavior if present, otherwise no swipe action.
- What happens when two zones share the same threshold? → An assertion fires with a descriptive error message; the list must be strictly ascending.
- What happens when more than 4 zones are provided? → An assertion fires with a message stating the maximum is 4 zones per direction.
- What happens when a progressive zone has no stepValue? → An assertion fires; progressive zones require a stepValue.
- What happens when an intentional zone has no onActivated? → The zone is valid but fires no callback (acts as a visual-only zone); no assertion.
- What happens on a fast fling that crosses multiple zones instantly? → The highest crossed zone determines the outcome; visual/haptic effects for skipped intermediate zones are omitted.
- What happens when the system reduced-motion setting is active? → Background transitions use the instant style regardless of configured style; scale bump effects are suppressed.
- What happens when a zone has no semanticLabel? → An assertion fires; all zones require semanticLabel for accessibility (per F008 contract).

---

## Requirements *(mandatory)*

### Functional Requirements

**Zone Configuration**

- **FR-001**: Consumers MUST be able to define an ordered list of 1 to 4 zones per swipe direction. A single-entry list is valid and silently treated as single-threshold behavior (see FR-014).
- **FR-002**: Each zone MUST carry a threshold ratio in the range 0.0–1.0 (exclusive of both endpoints) that marks when the zone becomes active during a drag.
- **FR-003**: The widget MUST assert that zone thresholds are strictly ascending (no duplicates, no out-of-order entries) and provide a descriptive error message identifying the offending pair.
- **FR-004**: The widget MUST assert that no direction has more than 4 zones and provide a descriptive error message when exceeded.
- **FR-005**: All zones MUST declare a non-null, non-empty semanticLabel for screen reader support.
- **FR-006**: The widget MUST assert that every zone has a semanticLabel and provide a descriptive error message identifying the zone at fault.

**Outcome Resolution**

- **FR-007**: On drag release, the widget MUST identify the highest-threshold zone whose threshold the current drag position meets or exceeds as the "active zone."
- **FR-008**: If no zone threshold is met at release, no zone action fires and the cell snaps back to idle.
- **FR-009**: For intentional (left-swipe) zones, ONLY the active zone's onActivated callback MUST fire on release; lower-threshold zone callbacks MUST NOT fire.
- **FR-010**: For progressive (right-swipe) zones, the active zone's stepValue MUST be used as the increment; no other stepValue is applied.
- **FR-011**: Progressive zones MUST assert that each zone has a stepValue defined and provide a descriptive error message for zones missing it.

**Backward Compatibility**

- **FR-012**: Single-threshold configurations from F003 and F004 MUST continue to function without any API changes.
- **FR-013**: When both a single threshold and a zones list are provided for the same direction, the zones list MUST take precedence and the single threshold MUST be silently ignored.
- **FR-014**: A zones list with exactly one entry MUST behave equivalently to a single-threshold configuration at that threshold.

**Visual Zone Transitions**

- **FR-015**: The background MUST visually reflect the currently active zone throughout the drag. Before the first zone's threshold is crossed (pre-first-zone state), no zone background is shown and the cell's default background remains fully visible.
- **FR-016**: As the drag position crosses a zone threshold in either direction (forward or backward), a 150ms visual "click" effect (scale bump and color/background shift) MUST occur at that boundary. Haptic feedback fires only in the forward direction (see FR-020).
- **FR-017**: The background transition between zones MUST support three configurable styles: crossfade, slide, and instant.
- **FR-018**: Zone backgrounds MUST support any combination of: a flat color, an icon widget, a label string, and a custom builder widget function parameterized by drag progress.
- **FR-019**: When the system's reduced-motion preference is active, all animated background transitions MUST use the instant style, and scale-bump effects MUST be suppressed.

**Haptic Feedback**

- **FR-020**: A distinct haptic event MUST fire when the drag position crosses each zone boundary in the forward direction (increasing drag).
- **FR-021**: If the drag retreats past a zone boundary and re-crosses it in the forward direction, the boundary haptic MUST fire again.
- **FR-022**: Haptic pattern MUST be configurable per zone; zones without a configured haptic pattern MUST produce no haptic output for their boundary.

**Performance**

- **FR-023**: All background transitions and visual effects triggered by zone boundary crossings MUST complete within a single animation frame (≤16ms at 60fps) to avoid dropped frames.

### Key Entities

- **SwipeZone**: Represents a single activation zone within a swipe direction. Carries a threshold (position ratio 0.0–1.0), an optional onActivated callback (for intentional directions), an optional stepValue (for progressive directions), an optional background builder, an optional flat color, an optional icon widget, an optional display label, and a required semanticLabel.
- **ZoneTransitionStyle**: Enumeration of the three zone-crossing visual transition styles: crossfade, slide, instant.
- **ActiveZone**: The runtime concept of the highest zone whose threshold the current drag position meets or exceeds. Null when no threshold is met. Determines both visual state and release outcome.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Developers can configure 2–4 zones per direction with distinct behaviors, verified by automated tests covering every combination of zone count and release position.
- **SC-002**: All existing single-threshold test suites pass without modification after this feature is introduced.
- **SC-003**: A misconfigured zone list (wrong order, too many zones, missing semanticLabel, missing stepValue) produces a descriptive assertion error within one render cycle.
- **SC-004**: Background transitions between zones do not produce visible frame drops; frame rendering time remains under 16ms per frame during any zone-crossing transition at 60fps.
- **SC-005**: Every zone's semanticLabel is discoverable by assistive technologies; verified by automated semantics tree tests.
- **SC-006**: On a device with reduced-motion enabled, no animated background transitions or scale-bump effects occur; only instant style is applied.
- **SC-007**: Haptic patterns fire exactly once per forward zone-boundary crossing and re-fire correctly when the user retreats and re-crosses the same boundary.
- **SC-008**: On a fast fling that crosses all zones, the correct (highest) zone's action fires and no intermediate zone actions fire spuriously.

---

## Clarifications

### Session 2026-02-28

- Q: What is the minimum valid zone count — must a zones list have at least 2 entries, or is 1 allowed? → A: Zones list accepts 1–4 entries; a 1-entry list is silently treated as single-threshold behavior. FR-001 floor updated from 2 to 1.
- Q: What does the background show when drag is above 0% but below the first zone threshold (pre-first-zone state)? → A: No zone background is shown; the cell's default background remains fully visible until the first zone threshold is crossed. FR-015 updated.
- Q: Does the visual click effect (scale bump) fire when the user drags backward across a zone boundary, or only forward? → A: Fires in both directions. Haptic remains forward-only. FR-016 updated.
- Q: What is the exact duration of the visual "click" effect (scale bump) at zone boundary crossings? → A: 150ms. FR-016 updated.

---

## Assumptions

- Haptic patterns follow the same type taxonomy already established by F011 (feedback feature); no new haptic primitive types are introduced by this feature.
- The "instant" transition style is the fallback when no transition style is specified (lowest-complexity default).
- Zones are per-direction only (not per-cell); both directions on the same cell may independently use zones or not.
- Zone thresholds are interpreted as ratios of the cell's full drag distance, consistent with how F003/F004 define their single thresholds.
- When a zone's onActivated is null (intentional direction), the zone still participates in visual and haptic behavior but fires no callback on release — this is intentional to support "visual milestone" zones.
- The "highest crossed zone" is determined at the moment of release, not at peak drag position during the gesture; if the user drags to 80% and retreats to 45% before releasing, the 40%-threshold zone (not the 80%-threshold zone) is active at release.

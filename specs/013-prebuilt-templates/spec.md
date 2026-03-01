# Feature Specification: Prebuilt Zero-Configuration Templates

**Feature Branch**: `013-prebuilt-templates`
**Created**: 2026-03-01
**Status**: Draft
**Input**: User description: "Add prebuilt zero-configuration template constructors to the swipe_action_cell package for common swipe patterns."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Destructive Action Templates (Priority: P1)

As a package consumer, I want ready-made delete and archive swipe cells so that I can add the most common destructive list interactions — removing or archiving an item — in a single line of code without configuring colors, icons, animation sequences, or undo behavior.

**Why this priority**: Delete and archive are the two most universally needed swipe interactions across list-based apps. Eliminating their setup removes the most frequent barrier to adopting the package. Together they demonstrate the template system's core value.

**Independent Test**: Use the delete template with a single child widget and a callback. Drag the cell left, release past the threshold. Verify the cell slides off-screen, an undo strip appears, and the deletion callback fires only after the undo window expires. Repeat with the archive template (no undo strip) and verify the cell slides off-screen immediately after the swipe. No configuration beyond child + callback should be needed.

**Acceptance Scenarios**:

1. **Given** a delete template with a child widget and `onDeleted` callback, **When** the user completes a left swipe, **Then** the cell animates off-screen, an undo strip appears for the default window, and `onDeleted` fires only after the undo expires or is committed.
2. **Given** a delete template, **When** the user taps the undo strip before it expires, **Then** the cell snaps back and `onDeleted` is NOT fired.
3. **Given** an archive template with a child widget and `onArchived` callback, **When** the user completes a left swipe, **Then** the cell animates off-screen and `onArchived` fires immediately with no undo strip.
4. **Given** either template with no additional configuration, **When** rendered, **Then** the cell displays the correct default icon (trash / archive box) and background color (red / teal) without any explicit setup by the consumer.

---

### User Story 2 - Toggle State Templates (Priority: P1)

As a package consumer, I want ready-made favorite-toggle and checkbox swipe cells so that I can add reversible value-toggling interactions in a single line of code without configuring icon morphing, threshold callbacks, or semantic labels.

**Why this priority**: Equal to US1 in priority — favorite-toggling and checkbox-completion are ubiquitous in task managers, music apps, and to-do lists. These patterns require the progressive right-swipe mechanics that distinguish this package.

**Independent Test**: Use the favorite template with `isFavorited = false`. Drag right past the threshold; verify the callback fires with `isFavorited = true` and the icon morphs from outline to filled. Rebuild with `isFavorited = true`; drag right again; verify the callback fires with `isFavorited = false`. Repeat the same sequence with the checkbox template.

**Acceptance Scenarios**:

1. **Given** a favorite template with `isFavorited = false`, **When** the user completes a right swipe, **Then** the `onToggle` callback fires with the value `true` and the heart icon is fully filled at completion.
2. **Given** a favorite template with `isFavorited = true`, **When** the user completes a right swipe, **Then** the `onToggle` callback fires with the value `false` and the icon returns to the outline state.
3. **Given** a favorite template during a drag, **When** the swipe progress is at 50%, **Then** the heart icon is visually halfway between the outline and filled state.
4. **Given** a checkbox template with `isChecked = false`, **When** the user completes a right swipe, **Then** the `onChanged` callback fires with `true` and the checkbox indicator shows the checked state.
5. **Given** a checkbox template with `isChecked = true`, **When** the user completes a right swipe, **Then** the `onChanged` callback fires with `false` and the checkbox indicator shows the unchecked state.

---

### User Story 3 - Counter Template (Priority: P2)

As a package consumer, I want a ready-made counter swipe cell so that I can let users increment a numeric value by swiping right without configuring step values, progress indicators, or overflow behavior.

**Why this priority**: Counter-style right swipes are a distinguishing feature of this package. A ready-made template makes the most compelling demo use-case immediately accessible.

**Independent Test**: Use the counter template with `count = 3`, `max = 10`. Perform right swipes and verify the count increments by 1 each time. Swipe when `count = 10`; verify no further increment occurs. Verify that the current count is visually displayed in the background during the swipe.

**Acceptance Scenarios**:

1. **Given** a counter template at `count = 3`, **When** the user completes a right swipe, **Then** `onCountChanged` fires with `4`.
2. **Given** a counter template at `count = max`, **When** the user completes a right swipe, **Then** `onCountChanged` is NOT fired and the count does not change.
3. **Given** a counter template with `max` unspecified, **When** the user repeatedly swipes right, **Then** the count increments without limit.
4. **Given** a counter template during a drag, **When** swipe progress is active, **Then** the current count value is visible in the background panel.

---

### User Story 4 - Composite Standard Template (Priority: P2)

As a package consumer, I want a "standard" template that combines a right-swipe favorite toggle with a left-swipe reveal panel so that I can implement the most common mail/task-list style interaction in a single line without composing multiple configurations manually.

**Why this priority**: The combined right-favorite + left-reveal pattern appears in virtually every production list UI. A single composite template eliminates the most complex setup scenario.

**Independent Test**: Use the standard template with `onFavorited` callback and a list of two action buttons. Right-swipe to threshold; verify the favorite callback fires. Left-swipe to reveal; verify the action panel shows two buttons, and tapping a button triggers its callback. Omit `onFavorited`; verify right-swipe is disabled. Omit `actions`; verify left-swipe is disabled.

**Acceptance Scenarios**:

1. **Given** a standard template with `onFavorited` and `actions`, **When** the user completes a right swipe, **Then** the `onFavorited` callback fires with the toggled state.
2. **Given** a standard template with `onFavorited` and `actions`, **When** the user drags left past the threshold, **Then** the action panel slides in showing all provided action buttons.
3. **Given** a standard template with `onFavorited = null`, **When** the cell is rendered, **Then** right-swipe is completely disabled.
4. **Given** a standard template with `actions = []` or `actions` omitted, **When** the cell is rendered, **Then** left-swipe is completely disabled.

---

### User Story 5 - Platform Style Adaptation (Priority: P3)

As a package consumer, I want templates to automatically match the visual style of the running platform — Material on Android/web, Cupertino on iOS — while allowing me to explicitly force one style when I need cross-platform consistency.

**Why this priority**: Platform-adaptive defaults prevent templates from looking wrong out of the box. Override support handles apps that use a unified design language across platforms. P3 because auto-detection provides high value with no effort; override is an advanced use case.

**Independent Test**: Run the delete template on an Android device and verify it uses Material-style icon, sharp corners, and standard haptic. Run the same unmodified template on an iOS device and verify it uses Cupertino-style icon, rounded corners, and iOS haptic. Then force Material style on iOS; verify Material appearance is used regardless of platform.

**Acceptance Scenarios**:

1. **Given** any template with no platform override, **When** run on an Android/web context, **Then** the template displays Material-style icons, sharp clipping, and standard Material haptic feedback.
2. **Given** any template with no platform override, **When** run on an iOS context, **Then** the template displays Cupertino-style icons, rounded corners, and iOS haptic feedback.
3. **Given** any template with an explicit Material style override, **When** run on iOS, **Then** Material appearance is used regardless of the detected platform.
4. **Given** any template with an explicit Cupertino style override, **When** run on Android, **Then** Cupertino appearance is used regardless of the detected platform.

---

### Edge Cases

- **Delete template with undo dismissed by new drag**: Starting a new drag during the undo window commits the pending deletion before the drag is processed.
- **`max` set to 0 or negative in counter template**: Treated as unlimited (no ceiling applied).
- **Empty `actions` in standard template**: Left-swipe direction is disabled entirely — no panel renders, no gesture recognized.
- **`isFavorited` / `isChecked` external state change during animation**: The cell completes the current animation; the new external state is reflected on the next build cycle.
- **Template in RTL layout**: All directional semantics reverse — delete/archive triggers on right physical swipe, favorite/counter triggers on left physical swipe; semantic labels automatically use RTL-appropriate language.
- **Template with controller provided**: The controller can programmatically trigger or close the cell; template defaults do not interfere with controller commands.
- **Color override + platform override both provided**: Color override takes effect regardless of platform style; icon and haptic follow the platform style.
- **Standard template with no arguments (`onFavorited: null`, `actions: []`)**: Both swipe directions disabled; the cell renders as a plain non-interactive wrapper.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-013-001**: The system MUST provide a delete template accepting a child widget and a deletion callback, configuring a left-swipe destructive action with a red background, a removal animation (cell slides off-screen), and an automatic undo window — all with no additional consumer configuration.
- **FR-013-002**: The system MUST provide an archive template accepting a child widget and an archive callback, configuring a left-swipe action with a teal background and a removal animation, with no undo window.
- **FR-013-003**: The system MUST provide a favorite-toggle template accepting a child widget, a current favorited state, and a toggle callback, configuring a right-swipe progressive action whose icon smoothly transitions from outline to filled proportional to swipe progress; the callback fires with the toggled boolean value upon completion.
- **FR-013-004**: The system MUST provide a checkbox template accepting a child widget, a current checked state, and a toggle callback, configuring a right-swipe progressive action whose indicator transitions from unchecked to checked proportional to swipe progress; the callback fires with the toggled boolean value upon completion.
- **FR-013-005**: The system MUST provide a counter template accepting a child widget, a current count, an increment callback, and an optional maximum value, configuring a right-swipe progressive action that increments the count by 1 per completion and disables further increments at the maximum (if specified).
- **FR-013-006**: The system MUST provide a standard template accepting a child widget and optional `onFavorited` callback and `actions` list, configuring a right-swipe favorite toggle (FR-013-003 behavior) when `onFavorited` is non-null and a left-swipe reveal panel (displaying `actions`) when `actions` is non-empty.
- **FR-013-007**: Every template MUST accept optional overrides for background color, icon, and semantic label so consumers can adapt default appearance without providing a full configuration object.
- **FR-013-008**: Every template MUST automatically select platform-appropriate icons, corner radius, and haptic pattern based on the ambient platform context, with no required consumer configuration.
- **FR-013-009**: Every template MUST accept an explicit platform style parameter (Material, Cupertino, or auto) that overrides platform auto-detection when provided.
- **FR-013-010**: Every template MUST accept an optional `SwipeController` parameter and wire it through without restricting any controller API.
- **FR-013-011**: Every template MUST include default accessibility semantic labels appropriate for its action type, with RTL-aware wording when the layout direction is right-to-left.
- **FR-013-012**: Every template MUST function correctly without any ambient theme, inherited widget, or state management provider in the widget tree.
- **FR-013-013**: Templates MUST NOT prevent access to the full configuration API — they are convenience entry points, not locked-down wrappers. Any configuration they apply internally must be overridable.

### Key Entities

- **TemplateStyle**: The platform visual style — `auto` (reads ambient platform), `material`, or `cupertino`. Consumer-facing enumeration used to override platform auto-detection.
- **SwipeTemplate**: The common interface contract for all six templates: each accepts a child widget, the minimal required callbacks, optional overrides (color, icon, label, style, controller), and produces a fully configured swipe cell.

---

## Assumptions & Dependencies

- **Dependencies**: All of F001–F012 are complete (gesture, animation, visual, progressive, intentional, config, controller, accessibility, scroll, feedback, undo, painting).
- **Assumption**: Material and Cupertino icon libraries are included in the Flutter SDK (no additional packages needed).
- **Assumption**: The `SwipeAction` type (from F004) is used as-is for the `actions` list in the standard template.
- **Assumption**: The default undo window for the delete template is 5 seconds (the F011 default from `SwipeUndoConfig`).
- **Assumption**: Counter template increments by 1 per swipe (no fractional or configurable step in the template; consumers needing custom step sizes use `SwipeActionCell()` directly).
- **Assumption**: "Platform auto-detection" reads the ambient platform context at build time; no reactive update is needed if the platform changes (not possible in practice on mobile).
- **Assumption**: Template styling (colors, icons) follows common app conventions — red for delete, teal for archive, yellow/amber heart for favorite — but all are overridable.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-013-001**: Every template requires at most 3 consumer-provided arguments (child + 1–2 callbacks) to produce a fully functional, visually correct swipe cell — verified by a usage example for each template.
- **SC-013-002**: All 6 templates render correctly on both Material and Cupertino platforms (correct icon, color, corner radius, haptic) without any additional configuration — verified by platform rendering tests.
- **SC-013-003**: All 6 templates produce passing RTL tests: icon position, gesture direction, and semantic labels are correct in right-to-left locales.
- **SC-013-004**: All 6 templates are compatible with `SwipeController` and `SwipeGroupController` — verified by integration tests triggering templates programmatically.
- **SC-013-005**: All existing `SwipeActionCell()` usages remain unaffected (zero breaking changes) — verified by the full existing test suite passing without modification.
- **SC-013-006**: All 6 templates render and function correctly in a widget tree with no `MaterialApp`, `CupertinoApp`, or provider ancestors — verified by standalone widget tests.

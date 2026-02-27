# Feature Specification: Accessibility & RTL Layout Support

**Feature Branch**: `008-accessibility-rtl`
**Created**: 2026-02-27
**Status**: Draft
**Input**: User description: "Add full accessibility support and RTL layout handling to the swipe_action_cell package."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Screen Reader Action Discovery (Priority: P1)

A visually impaired user using a screen reader (VoiceOver on iOS, TalkBack on Android) navigates to a swipe cell in a list. Without needing to perform a physical swipe gesture, they can discover both available swipe actions through the screen reader's custom action menu. They can activate the progressive action (e.g., increment a counter) or the intentional action (e.g., delete, archive) directly from the screen reader. After triggering either action, an announcement is immediately made describing the outcome.

**Why this priority**: Core accessibility gap — without this, users relying on screen readers cannot access any swipe functionality at all. This is a P1 compliance requirement.

**Independent Test**: Can be verified by enabling VoiceOver/TalkBack on a device with a swipe cell, confirming that both actions appear in the custom actions menu, and that activating each action produces the correct state change and announcement. Delivers a fully accessible swipe cell.

**Acceptance Scenarios**:

1. **Given** a swipe cell with a progressive right-swipe action labeled "Increment" and an intentional left-swipe action labeled "Delete", **When** a screen reader user focuses the cell and opens the custom actions menu, **Then** both "Increment" and "Delete" appear as selectable options.
2. **Given** the screen reader user activates "Increment" from the custom actions menu, **When** the action triggers and the value changes from 3 to 4 out of 10, **Then** the screen reader immediately announces "Progress incremented to 4 of 10".
3. **Given** the screen reader user activates "Delete" from the custom actions menu, **When** the action panel opens, **Then** the screen reader announces "Action panel open".
4. **Given** the developer provides a custom semantic label builder function, **When** the cell renders in a Spanish locale, **Then** the screen reader announces labels in Spanish.

---

### User Story 2 - Keyboard Navigation on Desktop and Web (Priority: P2)

A keyboard-only user on a desktop or web platform is navigating through a list of swipe cells using Tab. When they reach a swipe cell, they can trigger actions using arrow keys, navigate into the revealed action panel using Tab, and dismiss an open panel using Escape. Focus returns to the cell after the panel closes, maintaining a logical focus traversal order.

**Why this priority**: Required for WCAG keyboard accessibility compliance on desktop/web targets. Does not affect mobile at all, but is critical for web deployments.

**Independent Test**: Verified by tabbing to a swipe cell in a browser or desktop app, using arrow keys to trigger actions, Tab to move into action buttons, and Escape to close. Delivers a fully keyboard-operable swipe cell on non-touch platforms.

**Acceptance Scenarios**:

1. **Given** a keyboard user has focused a swipe cell, **When** they press the right arrow key, **Then** the progressive (forward) action triggers — matching the current directionality mapping.
2. **Given** a keyboard user has focused a swipe cell, **When** they press the left arrow key, **Then** the intentional (backward) action panel opens.
3. **Given** the action panel is open and the keyboard user presses Tab, **Then** focus moves sequentially to each action button within the panel.
4. **Given** the action panel is open, **When** the user presses Escape, **Then** the panel closes and focus returns to the swipe cell.
5. **Given** multiple swipe cells in a list, **When** the user presses Tab, **Then** focus traverses cells in document order without entering action panels.

---

### User Story 3 - RTL Layout Auto-Detection (Priority: P2)

An Arabic or Hebrew app consumer wraps their list in a standard `Directionality(textDirection: TextDirection.rtl)` widget (as is standard for RTL apps). Their swipe cells automatically render with the correct visual orientation — the progressive action background appears on the right side of the screen (the "forward" side in RTL), and the intentional action panel reveals from the left side. No additional configuration is required.

**Why this priority**: Required for correct behavior in RTL-language markets. A cell that swipes the wrong way in Arabic is a fundamental UX failure, not an enhancement.

**Independent Test**: Verified by wrapping a swipe cell in `Directionality(textDirection: TextDirection.rtl)` and confirming that dragging right reveals the intentional (backward) panel and dragging left triggers the progressive (forward) action. All visual elements mirror correctly.

**Acceptance Scenarios**:

1. **Given** a swipe cell inside an RTL Directionality widget with no explicit direction configuration, **When** the user drags left, **Then** the progressive (forward) action triggers with its background appearing on the left side.
2. **Given** a swipe cell inside an RTL Directionality widget, **When** the user drags right, **Then** the intentional (backward) action panel reveals from the right side.
3. **Given** a developer uses `forwardSwipeConfig` and `backwardSwipeConfig` aliases, **When** the same configuration is used in both LTR and RTL contexts, **Then** actions map to the correct physical direction in each context.
4. **Given** a developer sets `forceDirection: ltr` on a cell inside an RTL parent, **When** the user swipes, **Then** the cell behaves as LTR regardless of the ambient Directionality.
5. **Given** an existing LTR app using `leftSwipeConfig` and `rightSwipeConfig`, **When** no RTL configuration changes are made, **Then** all behavior is identical to before this feature — zero breaking changes.

---

### User Story 4 - Reduced Motion Compliance (Priority: P3)

A user with a vestibular disorder has enabled "Reduce Motion" in their device accessibility settings. When they interact with a swipe cell, all transitions are instantaneous — no spring animations, no slide-in effects. The cell still functions correctly; it just completes state changes in a single frame.

**Why this priority**: Required for WCAG 2.3 vestibular disorder compliance. A subset of accessibility users but important for full WCAG conformance.

**Independent Test**: Verified by enabling "Reduce Motion" in device settings, performing a swipe gesture, and confirming no animation frame delay occurs between the gesture completing and the final state rendering.

**Acceptance Scenarios**:

1. **Given** `MediaQuery.disableAnimations` is `true`, **When** the user drags to trigger a progressive action and releases, **Then** the cell snaps to its final state in a single frame with no animated transition.
2. **Given** `MediaQuery.disableAnimations` is `true`, **When** an intentional action panel is triggered, **Then** the panel appears immediately without a slide-in animation.
3. **Given** `MediaQuery.disableAnimations` is `false`, **When** actions are triggered, **Then** standard spring-based animations play as normal.

---

### User Story 5 - Localized Semantic Labels (Priority: P3)

A developer building a multi-language app can pass either a static string or a locale-aware builder function for any semantic label. The builder function receives the current `BuildContext` (giving access to locale, theme, etc.) and returns the appropriate translated string. This enables screen readers to announce actions in the user's native language without the developer having to imperatively update labels.

**Why this priority**: Required for non-English accessibility compliance. Without this, screen reader users in non-English locales hear English labels even in fully translated apps.

**Independent Test**: Verified by providing a builder function that returns different strings based on `Localizations.localeOf(context)`, switching the app locale, and confirming the screen reader label changes accordingly.

**Acceptance Scenarios**:

1. **Given** `rightSwipeSemanticLabel: (ctx) => AppLocalizations.of(ctx).incrementAction`, **When** the app locale changes from English to Arabic, **Then** the screen reader announces the Arabic label for the progressive action.
2. **Given** a static string `semanticLabel: "Task row"`, **When** the cell renders, **Then** the screen reader identifies the cell with that label.
3. **Given** no semantic labels are configured in an LTR context, **When** the cell renders, **Then** the screen reader announces "Swipe right to progress" and "Swipe left for actions". In an RTL context the labels auto-adapt to "Swipe left to progress" and "Swipe right for actions".

---

### Edge Cases

- What happens when a screen reader activates an action while an animation is already in progress? → **Resolved: input is silently dropped (FR-007a).**
- How does the system handle keyboard arrow keys when the cell has no configured progressive action (right-swipe only has intentional)?
- What happens when `forceDirection` is set but the cell is inside a `Directionality` widget of a different direction?
- How does focus management work when the action panel closes due to an external `SwipeController.close()` call rather than user input? → **Resolved: focus always returns to the swipe cell (FR-012).**
- What happens when `semanticLabel` returns an empty string or `null` from the builder function? → **Resolved: silent fallback to built-in default label (FR-007).**
- How does RTL mirroring interact with custom background builders that may use absolute positioning?
- What contrast ratio applies when the developer provides entirely custom action colors that fall below WCAG AA?

## Requirements *(mandatory)*

### Functional Requirements

**Semantics & Screen Reader:**

- **FR-001**: The widget MUST expose a top-level Semantics node with a configurable cell-level `semanticLabel` that identifies the row to screen readers.
- **FR-002**: The widget MUST register the progressive (forward) swipe action as a discoverable screen reader custom action with a configurable label (`rightSwipeSemanticLabel` in LTR / `forwardSwipeSemanticLabel` by semantic alias).
- **FR-003**: The widget MUST register the intentional (backward) swipe action as a discoverable screen reader custom action with a configurable label (`leftSwipeSemanticLabel` in LTR / `backwardSwipeSemanticLabel` by semantic alias).
- **FR-004**: When the progressive action is triggered (by gesture or screen reader activation), the widget MUST automatically announce the updated state by reading the current progress value and configured maximum from the existing progressive action's tracked state (e.g., "Progress incremented to 4 of 10"). No additional developer-provided announcement builder is required; the announcement is generated automatically from internal state.
- **FR-005**: When the intentional action panel opens, the widget MUST announce a configurable open-panel label (default: "Action panel open").
- **FR-006**: All semantic label properties MUST accept either a static `String` value or a `String Function(BuildContext)` builder for localization support.
- **FR-007**: When no semantic labels are configured, the widget MUST use direction-specific default labels that auto-adapt to the resolved direction: "Swipe right to progress" / "Swipe left for actions" in LTR; "Swipe left to progress" / "Swipe right for actions" in RTL. When a label builder function returns null or an empty string, the widget MUST fall back silently to these direction-adapted defaults.
- **FR-007a**: When a keyboard or screen-reader action is triggered while a swipe animation is in progress, the widget MUST silently drop the input and allow the current animation to complete normally. No error, warning, or queued execution occurs.

**Keyboard Navigation:**

- **FR-008**: On platforms that support keyboard input (desktop, web), the widget MUST be focusable via Tab key traversal.
- **FR-009**: When the widget has focus and the user presses the arrow key aligned with the forward direction (right in LTR, left in RTL), the progressive action MUST trigger.
- **FR-010**: When the widget has focus and the user presses the arrow key aligned with the backward direction (left in LTR, right in RTL), the intentional action panel MUST open.
- **FR-011**: When the action panel is open, Tab MUST move focus sequentially to each action button within the panel.
- **FR-012**: When the action panel closes for any reason — user pressing Escape, keyboard action, or external `SwipeController.close()` call — focus MUST return to the swipe cell.
- **FR-013**: Tab key traversal of swipe cells in a list MUST move between cells, not enter action panels unless the panel is already open.

**Reduced Motion:**

- **FR-014**: The widget MUST read `MediaQuery.disableAnimations` from the current context.
- **FR-015**: When `MediaQuery.disableAnimations` is `true`, all swipe transitions (snap-back, panel reveal, completion) MUST complete in a single frame with no intermediate animation frames.

**WCAG Contrast:**

- **FR-016**: Default background colors and text colors provided by the package MUST meet WCAG AA contrast ratio requirements (minimum 4.5:1 for text, 3:1 for non-text UI components).

**RTL & Directionality:**

- **FR-017**: The widget MUST automatically read `Directionality.of(context)` and internally remap forward/backward semantics to the correct physical drag directions without any explicit developer configuration.
- **FR-018**: In RTL mode, leftward drag MUST trigger the forward (progressive) action; rightward drag MUST trigger the backward (intentional) action.
- **FR-019**: In RTL mode, all background visual elements, the progress indicator, and the reveal panel MUST render on the semantically correct side (i.e., mirrored from their LTR positions).
- **FR-020**: In RTL mode, animation translation direction MUST invert so that panels and snap-backs animate toward/from the correct edge.
- **FR-021**: The widget API MUST expose `forwardSwipeConfig` and `backwardSwipeConfig` as semantic aliases that work correctly in both LTR and RTL contexts.
- **FR-022**: The existing `leftSwipeConfig` and `rightSwipeConfig` properties MUST remain fully functional with identical behavior to pre-feature in LTR contexts — zero breaking changes.
- **FR-023**: The widget MUST support a `forceDirection` parameter accepting `ltr`, `rtl`, or `auto` (default: `auto`), where `auto` reads ambient Directionality.

### Key Entities

- **SemanticDirection**: An enum or resolved value (`ltr` / `rtl`) representing the effective text direction for a specific widget instance, derived from `Directionality.of(context)` unless overridden by `forceDirection`.
- **SwipeSemanticConfig**: A configuration object grouping all semantic label properties (`semanticLabel`, `forwardSwipeSemanticLabel`, `backwardSwipeSemanticLabel`, and optional state-change announcement builders). Supports both static strings and builder functions.
- **ReducedMotionPolicy**: The resolved flag (from `MediaQuery.disableAnimations`) indicating whether animations should be suppressed for a given widget instance.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All existing widget and unit tests continue to pass without modification when running on the default LTR configuration — zero regressions.
- **SC-002**: A swipe cell in an RTL Directionality context renders with correctly mirrored visuals and correctly mapped gesture directions, verified by automated widget tests asserting hit-test positions and painted widget positions.
- **SC-003**: Every swipe action that can be triggered by gesture can also be discovered and activated via the screen reader custom actions interface, verified by semantics-tree inspection in tests.
- **SC-004**: State-change announcements (progress updates, panel open/close) are present in the semantics tree within the same frame as the state change — no deferred or missed announcements in test assertions.
- **SC-005**: Semantic labels provided as `String Function(BuildContext)` builders resolve correctly when the widget rebuilds under a different locale — verified by locale-swap tests.
- **SC-006**: When `MediaQuery.disableAnimations` is `true`, the animation controller completes its cycle in a single frame as measured by test frame pumping (one `pumpAndSettle` frame call resolves the state).
- **SC-007**: Default package colors pass WCAG AA contrast ratio checks (≥ 4.5:1 text, ≥ 3:1 non-text) as validated by automated contrast-ratio assertions in tests.
- **SC-008**: Keyboard arrow-key interactions on a focused swipe cell produce the same observable state changes as the equivalent touch gestures.

## Clarifications

### Session 2026-02-27

- Q: How should the widget access current value (N) and max (M) for the progress announcement? → A: Auto-source from the progressive action's tracked state; announcement is generated automatically with no new API parameter.
- Q: When keyboard/screen-reader input arrives while a swipe animation is in progress, what should happen? → A: Ignore — input is silently dropped; the current animation completes normally.
- Q: When a label builder function returns null or an empty string, what should the widget do? → A: Fall back silently to the built-in default label — no warning, no crash.
- Q: When the action panel closes via external SwipeController.close(), should keyboard focus return to the swipe cell? → A: Always return focus to the swipe cell, regardless of what triggered the close.
- Q: Should built-in default semantic labels be direction-neutral or direction-specific? → A: Direction-specific and auto-adapting — the widget computes the physical direction from current context and generates the correct label (e.g., "Swipe right to progress" in LTR, "Swipe left to progress" in RTL).

## Assumptions

- The widget already exposes a Semantics node or a GestureDetector that can be wrapped; this feature layers semantic annotations on top of the existing widget tree without restructuring it.
- "Keyboard navigation" targets Flutter desktop (macOS, Windows, Linux) and web only — mobile keyboard accessories are out of scope.
- WCAG AA (not AAA) is the target contrast level for default colors; AAA compliance is a future enhancement.
- The `forwardSwipeConfig` / `backwardSwipeConfig` aliases are additive — they read from the same underlying configuration as `rightSwipeConfig` / `leftSwipeConfig` in LTR and are not new independent configuration trees.
- Default semantic labels will be in English; localization of defaults is the developer's responsibility via the label builder API.
- RTL mirroring applies to the standard built-in backgrounds and indicators; custom background builders that draw with absolute coordinates are the developer's responsibility to mirror.
- Focus management for keyboard navigation is scoped to the widget's own focus node; integration with external `FocusScope` hierarchies follows standard Flutter conventions.

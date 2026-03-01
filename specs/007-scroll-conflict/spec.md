# Feature Specification: Scroll Conflict Resolution & Gesture Arena

**Feature Branch**: `007-scroll-conflict`
**Created**: 2026-02-27
**Status**: Draft
**Input**: User description: "Make the swipe interaction bulletproof inside scrollable lists for the swipe_action_cell package."

## Clarifications

- The three new parameters (`horizontalThresholdRatio`, `closeOnScroll`, `respectEdgeGestures`) extend the existing gesture configuration surface — they do not require a new top-level widget parameter.
- "User-initiated scroll" is defined as a scroll that originates from a pointer event, as opposed to programmatic calls to `ScrollController.animateTo()` or similar.
- "Edge gesture" refers specifically to the platform's native back-navigation swipe from the left edge of the screen (iOS and Android gesture navigation), not horizontal swipes that start near an edge within the widget bounds.

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Swipe and Scroll Coexist in a Flat List (Priority: P1) 🎯 MVP

A developer adds `SwipeActionCell` to an existing `ListView.builder` with no additional configuration.
Users can swipe cells left or right to trigger actions, and can also scroll the list vertically at any
time. Neither gesture interferes with the other. A clearly horizontal gesture swipes; a clearly vertical
gesture scrolls. An ambiguous diagonal gesture resolves cleanly to whichever direction is dominant.

**Why this priority**: This is the baseline usability guarantee for the package. A swipe widget that
breaks ordinary list scrolling is not viable in any production app. All other features are meaningless
if this foundation is broken.

**Independent Test**: Place a `SwipeActionCell` inside a `ListView.builder` with 20 items.
Verify that (a) a rightward swipe increments the progressive counter, (b) a downward scroll moves the
list, and (c) a 45-degree diagonal swipe resolves to its dominant direction without affecting the other
axis.

**Acceptance Scenarios**:

1. **Given** a `SwipeActionCell` inside a vertical `ListView`, **When** the user swipes clearly horizontally, **Then** the swipe gesture is recognized and the scroll list does not move.
2. **Given** a `SwipeActionCell` inside a vertical `ListView`, **When** the user scrolls clearly vertically, **Then** the list scrolls and no swipe action triggers on the cell.
3. **Given** a `SwipeActionCell` inside a vertical `ListView`, **When** the user makes a diagonal gesture where horizontal displacement is more than 1.5× the vertical displacement, **Then** the gesture is treated as a swipe.
4. **Given** a `SwipeActionCell` inside a vertical `ListView`, **When** the user makes a diagonal gesture where vertical displacement is more than 1.5× the horizontal displacement, **Then** the gesture is treated as a scroll and the cell does not activate.
5. **Given** a `SwipeActionCell` with no configuration, **When** it is placed inside any of `ListView`, `GridView`, or `CustomScrollView`, **Then** it behaves identically to scenario 1 and 2 in each container.
6. **Given** a very fast diagonal swipe, **When** the directional velocity is unambiguous, **Then** the gesture resolves to the direction with the higher velocity component within one frame.
7. **Given** the list is in a momentum (fling) or overscroll animation, **When** the pointer touches the screen during that animation, **Then** starting a swipe is not triggered by the momentum — only a deliberate new drag activates the cell.

---

### User Story 2 — Open Panels Close Automatically When the User Scrolls (Priority: P2)

A user has swiped a cell to reveal its action panel (left-swipe reveal mode). They then decide to scroll
the list instead of tapping an action. The open panel closes smoothly as the list begins to scroll,
so the list never has a dangling open cell while the user is browsing other items. This behavior is
configurable — a developer can disable it if their use-case requires panels to stay open during scroll.

**Why this priority**: Without auto-close on scroll, a user can end up with an open action panel
scrolled partially out of view, which is visually broken and confusing. Auto-close is the standard
behavior for every major iOS and Android swipe-list implementation.

**Independent Test**: Open a reveal-mode panel on one cell in a list. Immediately scroll the list
vertically. Verify the panel closes before the cell scrolls out of the visible area.

**Acceptance Scenarios**:

1. **Given** a cell with an open reveal panel, **When** the user initiates vertical scrolling, **Then** the panel closes with its snap-back animation before the scroll motion is perceptible.
2. **Given** `closeOnScroll: false` is configured, **When** the user scrolls while a panel is open, **Then** the panel remains open and the list scrolls normally.
3. **Given** a programmatic `ScrollController.animateTo()` call, **When** the list scrolls due to that call, **Then** no open panel closes — only user-initiated scroll events trigger auto-close.
4. **Given** multiple cells with open panels (possible in a `closeOnScroll: false` configuration), **When** the user starts scrolling, **Then** all open panels in the list close.

---

### User Story 3 — Works Inside Nested Scrollable Containers (Priority: P3)

A developer builds a `PageView` where each page contains a `ListView` of `SwipeActionCell` widgets.
Users can swipe pages horizontally, scroll items vertically within a page, and swipe individual cells.
All three gesture types work without conflicting with each other.

**Why this priority**: `PageView > ListView > SwipeActionCell` is a very common production pattern
(e.g., a tabbed list in a mobile app). Without explicit support, a `PageView` and a swipe cell compete
for the same horizontal drag gesture and one of them loses — typically the cell.

**Independent Test**: Build a `PageView` with two pages, each containing a `ListView` of `SwipeActionCell`
widgets. Verify: (a) a slow horizontal swipe starting inside a cell swipes the cell, not the page;
(b) a fast horizontal swipe from near the center swipes the page when the cell has no pending action;
(c) vertical scroll within a page scrolls only the list, not the page.

**Acceptance Scenarios**:

1. **Given** `PageView > ListView > SwipeActionCell`, **When** the user swipes a cell past the activation threshold, **Then** the cell action triggers and the page does not turn.
2. **Given** `PageView > ListView > SwipeActionCell`, **When** the user makes a slow, deliberate horizontal swipe starting on a cell, **Then** the cell claims the gesture first; the page does not start turning.
3. **Given** `PageView > ListView > SwipeActionCell`, **When** the user makes a fast, full-width swipe that a page-turn would normally handle, **Then** the page turns and the cell does not activate.
4. **Given** `PageView > ListView > SwipeActionCell`, **When** the user scrolls vertically inside a page, **Then** the `ListView` scrolls and neither the page nor any cell activates.

---

### User Story 4 — Platform Back-Navigation Gesture Takes Priority (Priority: P4)

On iOS and Android gesture-navigation devices, the user can swipe from the very left edge of the screen
to trigger the platform's back-navigation. When a `SwipeActionCell` is near that edge (e.g., the first
item in a full-width list), the platform gesture must win — the cell must not intercept it. This behavior
is configurable for developers who need different semantics.

**Why this priority**: Intercepting the platform back-navigation gesture is a critical UX regression.
App Review on iOS can reject apps that break the back swipe. This is a correctness requirement, not a
preference.

**Independent Test**: Place a `SwipeActionCell` as the first item in a list on an iOS device or
simulator. Initiate a back-navigation edge swipe. Verify the app navigates back and the cell does not
activate. Then configure `respectEdgeGestures: false` and verify the cell intercepts the gesture.

**Acceptance Scenarios**:

1. **Given** `respectEdgeGestures: true` (default), **When** a touch begins within the platform-defined edge zone (≤ 20 pt from the left screen edge on iOS), **Then** the cell does not claim the gesture and the platform back navigation proceeds normally.
2. **Given** `respectEdgeGestures: false`, **When** a touch begins near the left screen edge, **Then** the cell processes the gesture normally, same as any other horizontal drag.
3. **Given** a swipe that starts outside the edge zone, **When** the user drags toward the edge, **Then** the cell processes it as a normal swipe regardless of `respectEdgeGestures`.
4. **Given** any platform that does not have edge-based back navigation, **When** `respectEdgeGestures: true` is set, **Then** behavior is identical to `respectEdgeGestures: false` — no gesture is unnecessarily suppressed.

---

### Edge Cases

- What happens when the user lifts and re-places their finger during a momentum scroll? The new touch is a fresh gesture — no carry-over of momentum state; the cell must not interpret the lift-and-re-touch as a swipe.
- What happens when `horizontalThresholdRatio` is set to `1.0`? Any gesture with equal or greater horizontal displacement than vertical is treated as a swipe. This is the minimum discriminating value.
- What happens when a cell is already animating to open when the user starts scrolling? The animation is cancelled and the panel snaps back, then the list scrolls.
- What happens when the `ListView` is horizontal (e.g., a horizontal carousel) and contains a `SwipeActionCell`? The threshold ratio still applies but along the perpendicular axis — this is a non-standard embedding and the behavior should be documented as unsupported rather than guaranteed.
- What happens when the user swipes faster than the threshold but in a zigzag pattern? The first direction that clearly wins the threshold ratio locks in; subsequent direction changes are ignored until the gesture ends.
- What happens when `closeOnScroll` is enabled but the `SwipeController.close()` is called at the same time as a scroll event? The close is idempotent — the cell closes once, regardless of which trigger fires first.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The widget MUST participate in the gesture arena so that horizontal (swipe) and vertical (scroll) gestures are disambiguated before any action is taken.
- **FR-002**: A gesture MUST be classified as a swipe only when the horizontal displacement exceeds the vertical displacement multiplied by `horizontalThresholdRatio`. Default ratio: `1.5`.
- **FR-003**: A gesture MUST be classified as a scroll only when the vertical displacement exceeds the horizontal displacement; at that point, the widget MUST release the gesture so the parent scrollable can claim it.
- **FR-004**: Once a gesture direction (horizontal or vertical) has been decided, the widget MUST lock out the other direction for the remainder of that gesture event sequence.
- **FR-005**: Fast diagonal gestures MUST resolve to the direction with the larger displacement or velocity component within the first frame of movement, without waiting for a threshold delay.
- **FR-006**: Momentum and overscroll animations MUST NOT cause the widget to interpret residual pointer contact as a new swipe gesture.
- **FR-007**: When `closeOnScroll` is `true` (default), the widget MUST close any open action panel when a `ScrollNotification` indicating user-initiated scrolling is received from a parent scrollable.
- **FR-008**: Auto-close via `closeOnScroll` MUST NOT fire in response to programmatic scroll events (e.g., `ScrollController.animateTo`, `ScrollController.jumpTo`).
- **FR-009**: The widget MUST function correctly as a direct or indirect child of `ListView`, `GridView`, `CustomScrollView`, and `PageView`.
- **FR-010**: When nested inside a `PageView` that is itself nested inside or alongside a `ListView`, the widget MUST correctly yield horizontal gestures to the `PageView` when the gesture exceeds the page-turn threshold, and claim horizontal gestures for swipe when the gesture is within cell scope.
- **FR-011**: When `respectEdgeGestures` is `true` (default), the widget MUST NOT claim a horizontal drag that originates within the platform-defined back-navigation edge zone (left screen edge on iOS; equivalent on Android gesture navigation).
- **FR-012**: The three configuration parameters (`horizontalThresholdRatio`, `closeOnScroll`, `respectEdgeGestures`) MUST be settable per cell via the existing gesture configuration object. All three MUST have default values that produce correct behavior with zero explicit configuration.
- **FR-013**: All gesture behavior from Feature 001 MUST be preserved. This is a behavioral upgrade, not a regression. Existing consumers MUST require no code changes to benefit from improved scroll coexistence.

### Key Entities

- **`horizontalThresholdRatio`** (`double`, default `1.5`): The minimum ratio of horizontal-to-vertical displacement required before a gesture is classified as a horizontal swipe. A value of `1.0` means equal displacement suffices; higher values require a more deliberate horizontal motion.
- **`closeOnScroll`** (`bool`, default `true`): When `true`, any open action panel closes when the user initiates a vertical scroll in the containing scrollable. When `false`, open panels remain open during scroll.
- **`respectEdgeGestures`** (`bool`, default `true`): When `true`, gestures originating within the platform's back-navigation edge zone are not claimed by the swipe cell, allowing the system back gesture to function normally.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: A developer can drop `SwipeActionCell` into an existing `ListView.builder` with no configuration changes and both vertical scrolling and horizontal swiping work correctly — zero-config compatibility.
- **SC-002**: In a list with 50 cells, a user can scroll freely (including during a momentum fling) without any cell accidentally activating a swipe action.
- **SC-003**: Diagonal swipe gestures (at 30°–60° from horizontal) resolve to the correct dominant direction in ≥ 95% of repeated attempts, measurable via automated gesture injection tests.
- **SC-004**: In a `PageView > ListView > SwipeActionCell` nesting, all three gesture types (page turn, list scroll, cell swipe) are independently triggerable with no unintended cross-activation.
- **SC-005**: On iOS, the platform back-navigation gesture from the left edge is never intercepted by a swipe cell when `respectEdgeGestures` is enabled. Zero failed back navigations in a 20-tap test sequence.
- **SC-006**: An open action panel closes within one rendered frame of a user-initiated scroll event when `closeOnScroll` is enabled.

---

## Assumptions

- **Horizontal ListViews out of scope**: A `SwipeActionCell` embedded inside a horizontal `ListView` or `PageView` as its direct scrolling axis is a non-standard configuration. The threshold ratio still applies geometrically, but correct behavior in that setup is not guaranteed by this feature.
- **`horizontalThresholdRatio` floor is 1.0**: Values below `1.0` are nonsensical (they would classify vertical gestures as horizontal) and MUST be rejected with a debug assertion.
- **ScrollNotification source detection**: The distinction between user-initiated and programmatic scroll is inferred from whether the notification carries a `DragStartDetails` — no additional API is required from the consumer.
- **Edge zone width**: The platform back-navigation edge zone is assumed to be 20 logical pixels from the left edge on iOS. This value matches the Flutter framework's existing edge-swipe detection heuristic and does not require consumer configuration.
- **No new widget parameter**: The three new parameters are added to the existing gesture configuration surface (`SwipeGestureConfig`) — they do not require a new top-level `SwipeActionCell` constructor parameter.
- **SDK constraints unchanged**: Dart ≥ 3.4.0, Flutter ≥ 3.41.0. Zero new runtime dependencies.

# Feature Specification: Right-Swipe Progressive Action

**Feature Branch**: `003-progressive-swipe`
**Created**: 2026-02-25
**Status**: Draft
**Input**: User description: "Add right-swipe progressive action behavior to the swipe_action_cell package."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Basic Progressive Increment (Priority: P1)

A developer integrates the swipe cell with right-swipe configured as a progressive action. When the end user swipes right past the configured threshold and releases, the tracked value increases by the configured step amount. If the user swipes but does not reach the threshold before releasing, the cell snaps back and the value is unchanged.

**Why this priority**: This is the core identity of the feature. All other behaviors build on this foundation. Without it, the feature has no value.

**Independent Test**: Can be tested by configuring a cell with `stepValue: 1.0`, swiping past the threshold, and verifying the value changes from 0.0 to 1.0. Below-threshold release should leave value unchanged.

**Acceptance Scenarios**:

1. **Given** a swipe cell with `initialValue: 0.0`, `stepValue: 1.0`, **When** the user swipes right past the threshold and releases, **Then** the value becomes `1.0` and `onProgressChanged(1.0, 0.0)` fires.
2. **Given** a swipe cell with `initialValue: 2.0`, **When** the user swipes right but releases before the threshold, **Then** the value remains `2.0`, the cell snaps back, and `onSwipeCancelled()` fires.
3. **Given** a swipe cell, **When** the user begins a right swipe, **Then** `onSwipeStarted()` fires immediately.
4. **Given** a swipe cell, **When** a swipe completes successfully, **Then** `onSwipeCompleted(newValue)` fires with the updated value after the animation settles.

---

### User Story 2 - Overflow Behavior (Priority: P2)

A developer configures an upper bound (`maxValue`) for the progress value and selects how the widget behaves when that bound is reached. Three overflow policies are available: clamp (stop at max), wrap (reset to min), or ignore (no upper limit enforced).

**Why this priority**: Without defined overflow semantics, apps with bounded progress (e.g., a 0–10 rating or a 0–100% bar) cannot safely use the widget. This enables a wide range of real-world use cases.

**Independent Test**: Can be tested by configuring a cell with `maxValue: 3.0`, `stepValue: 1.0`, starting at `initialValue: 3.0`, and verifying that the chosen overflow policy is applied on the next swipe.

**Acceptance Scenarios**:

1. **Given** `overflowBehavior: clamp`, `maxValue: 5.0`, current value `5.0`, **When** the user completes a right swipe, **Then** the value remains `5.0`, `onMaxReached()` fires, and no `onProgressChanged` fires.
2. **Given** `overflowBehavior: wrap`, `maxValue: 5.0`, `minValue: 0.0`, current value `5.0`, **When** the user completes a right swipe, **Then** the value resets to `0.0` and `onProgressChanged(0.0, 5.0)` fires, followed by `onMaxReached()`.
3. **Given** `overflowBehavior: ignore`, `maxValue: 5.0`, current value `5.0`, **When** the user completes a right swipe, **Then** the value increments normally to `6.0` and `onProgressChanged(6.0, 5.0)` fires.
4. **Given** `overflowBehavior: clamp`, current value already at `maxValue`, **When** the user attempts a right swipe, **Then** the swipe is accepted visually (cell moves) but value does not change on release.

---

### User Story 3 - Visual Progress Indicator (Priority: P3)

A developer enables the optional persistent progress indicator, which renders a visual representation of the current cumulative value directly on the cell (e.g., a colored bar on the leading edge whose height grows proportionally to the current value relative to maxValue). The indicator is only valid when a finite `maxValue` is configured.

**Why this priority**: Provides immediate visual feedback to end users about their accumulated progress without requiring custom UI outside the widget.

**Independent Test**: Can be tested by enabling `showProgressIndicator: true` with a finite `maxValue` and verifying the indicator renders and updates proportionally as the value changes.

**Acceptance Scenarios**:

1. **Given** `showProgressIndicator: true`, `maxValue: 10.0`, current value `5.0`, **Then** the indicator visually represents 50% progress.
2. **Given** `showProgressIndicator: false` (default), **Then** no indicator is rendered regardless of the current value.
3. **Given** `showProgressIndicator: true`, **When** a swipe completes and the value changes, **Then** the indicator updates to reflect the new value.
4. **Given** `showProgressIndicator: true` with custom `progressIndicatorConfig` (color, width, position), **Then** the indicator renders according to those configuration values.
5. **Given** `showProgressIndicator: true` but no finite `maxValue` is configured, **Then** an invalid configuration error is reported in development mode and the indicator is silently hidden in production.

---

### User Story 4 - Controlled Mode (Priority: P4)

A developer passes a non-null `value` parameter to the widget, activating controlled mode. The widget displays that value and reports swipe completions via callbacks. The developer's external state (e.g., from a database or server) is the single source of truth. When `value` is omitted (null), the widget manages its own internal state starting from `initialValue` (uncontrolled mode).

**Why this priority**: Many production apps already manage their own state. Controlled mode allows seamless integration without fighting the widget's internal state.

**Independent Test**: Can be tested by passing a non-null `value` and confirming the widget reflects it without maintaining its own copy. Updating the `value` prop should immediately update the widget's displayed state.

**Acceptance Scenarios**:

1. **Given** a non-null `value: 3.0` is provided (controlled mode), **When** the `value` prop changes to `4.0`, **Then** the cell's progress indicator updates to reflect `4.0`.
2. **Given** controlled mode (`value` is non-null), **When** a swipe completes, **Then** `onProgressChanged(newValue, oldValue)` fires with the already-constrained value (overflow policy applied by the widget) but the widget does NOT self-update its displayed value — the developer must update the `value` prop.
3. **Given** controlled mode, **When** the developer does not update the `value` prop after a swipe completion, **Then** the cell reverts to displaying the current `value` prop.
4. **Given** `value` is null (uncontrolled mode), **Then** the widget initializes from `initialValue` and manages its own state thereafter.

---

### User Story 5 - Dynamic Step Size (Priority: P5)

A developer configures a dynamic step callback that receives the current value and returns the step to apply for the next swipe. This enables non-linear progression (e.g., exponential growth, adaptive increments, level-based unlocks).

**Why this priority**: Fixed step sizes don't serve all use cases. Dynamic steps unlock sophisticated patterns like difficulty scaling, bonus multipliers, or accelerating progress curves.

**Independent Test**: Can be tested by providing a `dynamicStep` callback that returns `currentValue + 1` and verifying each swipe doubles the increment compared to the previous swipe.

**Acceptance Scenarios**:

1. **Given** `dynamicStep: (v) => v * 0.1` and current value `10.0`, **When** a swipe completes, **Then** the value increments by `1.0` (10% of current value).
2. **Given** both `stepValue` and `dynamicStep` are configured, **Then** `dynamicStep` takes precedence and `stepValue` is ignored.
3. **Given** `dynamicStep` returns `0.0`, **When** a swipe completes, **Then** the value does not change and `onSwipeCompleted` fires with the unchanged value.

---

### User Story 6 - Haptic Feedback (Priority: P6)

The widget provides haptic feedback at two key moments: when the swipe crosses the threshold during a drag (light) and when a swipe completes successfully (medium). Haptic feedback is configurable on/off.

**Why this priority**: Haptics are a quality-of-life enhancement that reinforces interaction milestones. They are non-blocking and should be low effort to add while being easily disabled for contexts where haptics are unwanted.

**Independent Test**: Can be tested by enabling haptics and verifying the correct patterns fire at threshold crossing and swipe completion. Disabling haptics should produce no vibration at any point.

**Acceptance Scenarios**:

1. **Given** `enableHaptic: true`, **When** the swipe distance crosses the threshold during a drag, **Then** a light haptic fires once per drag interaction.
2. **Given** `enableHaptic: true`, **When** a swipe completes successfully, **Then** a medium haptic fires.
3. **Given** `enableHaptic: false` (default), **When** any swipe event occurs, **Then** no haptics fire.
4. **Given** `enableHaptic: true`, **When** a swipe is cancelled (below-threshold release), **Then** no medium haptic fires (only threshold haptic may have fired during the drag).

---

### Edge Cases

- What happens when `stepValue` is `0.0` or negative? — The widget should treat this as an invalid configuration and report an error during development; production behavior is undefined.
- What happens when `initialValue` is outside `[minValue, maxValue]`? — Clamp to the valid range silently on initialization.
- What happens when `minValue >= maxValue` (invalid range)? — Treat as an invalid configuration and report an error during development.
- How does the widget handle rapid repeated swipes before the previous animation settles? — All new swipe inputs are discarded (not buffered) while an animation is in progress; the cell is fully non-interactive during settlement.
- What happens when `dynamicStep` returns a negative value? — Treat as no-op for that swipe; do not decrement.
- What happens when `overflowBehavior: wrap` and `minValue == maxValue`? — Immediate wrap back to minValue; onMaxReached fires.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The widget MUST maintain a cumulative progress value within the range `[minValue, maxValue]` (or unbounded when `overflowBehavior: ignore`).
- **FR-002**: The widget MUST increment the progress value by the configured step amount when the user releases a right swipe past the threshold.
- **FR-003**: The widget MUST NOT change the progress value when the user releases a right swipe below the threshold.
- **FR-004**: The widget MUST snap back to the idle position when a below-threshold swipe is released.
- **FR-005**: Value changes MUST be synchronized with animation completion — `onProgressChanged` fires only after the snap animation settles.
- **FR-006**: The widget MUST support uncontrolled mode where it manages its own internal state starting from `initialValue`.
- **FR-006b**: Progressive right-swipe behavior MUST be configured via a dedicated direction-specific parameter on the widget; left-swipe behavior is configured independently and the two coexist without conflict.
- **FR-007**: The widget MUST support controlled mode, activated by providing a non-null `value` parameter, where the displayed value is driven entirely by that parameter and the widget does not self-update.
- **FR-008**: When `overflowBehavior` is `clamp`, the widget MUST prevent the value from exceeding `maxValue` and fire `onMaxReached()`. This policy applies in both controlled and uncontrolled modes — callbacks always receive the clamped value.
- **FR-009**: When `overflowBehavior` is `wrap`, the widget MUST reset the value to `minValue` when it would exceed `maxValue` and fire `onMaxReached()`. This policy applies in both controlled and uncontrolled modes — callbacks always receive the wrapped value.
- **FR-010**: When `overflowBehavior` is `ignore`, the widget MUST allow the value to exceed `maxValue` without restriction. This policy applies in both controlled and uncontrolled modes.
- **FR-011**: When `dynamicStep` is configured, the widget MUST use its return value as the step size for each swipe instead of `stepValue`.
- **FR-012**: The widget MUST call `onSwipeStarted()` when a right swipe gesture begins.
- **FR-013**: The widget MUST call `onSwipeCompleted(currentValue)` after a successful swipe animation settles.
- **FR-014**: The widget MUST call `onSwipeCancelled()` when a below-threshold swipe is released.
- **FR-015**: The widget MUST call `onProgressChanged(newValue, oldValue)` whenever the progress value changes.
- **FR-016**: The widget MUST call `onMaxReached()` when the value reaches or would exceed `maxValue` (for clamp and wrap policies).
- **FR-017**: When `showProgressIndicator` is `true` and a finite `maxValue` is configured, the widget MUST render a persistent visual indicator reflecting the current progress value as a proportion of `maxValue`.
- **FR-017b**: When `showProgressIndicator` is `true` but no finite `maxValue` is configured, the widget MUST report an invalid configuration error in development mode and silently hide the indicator in production.
- **FR-018**: When `enableHaptic` is `true`, the widget MUST trigger a light haptic at threshold crossing and a medium haptic on successful increment.
- **FR-019**: The widget MUST ignore and discard all new swipe gestures while an animation from a prior swipe is in progress. No buffering or queuing of pending swipes is supported.
- **FR-020**: `initialValue` outside the valid range MUST be silently clamped to `[minValue, maxValue]` on widget initialization.

### Key Entities

- **Progressive Swipe Configuration**: A self-contained, direction-specific bundle of settings for right-swipe behavior — step size, value bounds, overflow policy, visual indicator appearance, haptic enablement, and all event callbacks. Passed as a dedicated parameter (e.g., `rightSwipe`) on the widget; left-swipe behavior is configured independently. Immutable — changes require providing a new configuration.
- **Progress Value**: The tracked cumulative numeric value representing the user's accumulated swipe progress.
- **Overflow Policy**: Determines what happens when a step would push the value beyond its upper bound — stop at the limit, reset to the lower bound, or allow unlimited growth.
- **Progress Indicator Config**: Controls the appearance and position of the optional persistent visual indicator (color, size, placement).
- **Swipe Event Callbacks**: Notifications sent to the developer at each meaningful swipe milestone: started, completed, cancelled, value changed, maximum reached.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Each right swipe past the threshold reliably produces exactly one value increment and one set of callbacks — no double-fires, no missed increments.
- **SC-002**: Value changes are never observed before the swipe animation settles — the timing between gesture and state change is perceptually instantaneous and consistent.
- **SC-003**: All three overflow behaviors (clamp, wrap, ignore) correctly handle 100% of boundary conditions with no value leakage outside the configured range for bounded modes.
- **SC-004**: Controlled mode maintains referential integrity — the widget never self-mutates a developer-provided value; developers must handle all state updates themselves.
- **SC-005**: The progress indicator accurately reflects the current value at all times — no stale or mismatched visual state after swipe completion.
- **SC-006**: Haptic events fire at the correct swipe milestones with no false positives (haptic on cancel) and no missed events (no haptic on successful increment when enabled).
- **SC-007**: The widget correctly handles rapid swipe attempts — no crashes, no state corruption, and no duplicate increments when gestures arrive during active animations.
- **SC-008**: The progressive swipe feature integrates cleanly with the existing gesture detection and visual feedback systems — no existing swipe cell behavior regresses after this feature is added.

## Clarifications

### Session 2026-02-25

- Q: What is the mechanism that activates controlled mode? → A: Providing a non-null `value` parameter activates controlled mode; omitting it (null) activates uncontrolled mode.
- Q: How should the progress indicator behave when there is no finite upper bound (e.g., `overflowBehavior: ignore` with no `maxValue`)? → A: Invalid configuration — `showProgressIndicator: true` requires a finite `maxValue`; error reported in development, indicator silently hidden in production.
- Q: In controlled mode, does the widget apply the overflow policy before reporting the new value in callbacks, or does the developer receive the raw unconstrained result? → A: The widget always applies the overflow policy first; all callbacks (including in controlled mode) receive the already-constrained value.
- Q: When both left and right swipe behaviors are configured on the same cell, how do they coexist? → A: Independent configuration blocks per direction (e.g., `rightSwipe: ProgressiveSwipeConfig(...)`, `leftSwipe: IntentionalSwipeConfig(...)`); the widget routes gestures automatically by direction.
- Q: Should rapid successive swipes be discarded or buffered during an active animation? → A: Always discarded — no buffering. The cell is fully non-interactive during animation settlement.

## Assumptions

- The right swipe threshold is inherited from the existing gesture configuration established in Feature 001. This feature does not redefine threshold detection.
- The progress indicator's default appearance (a left-edge colored bar) is sufficient for the MVP; advanced custom painters are deferred to a later feature.
- Haptic feedback uses platform-standard light and medium intensity patterns — no third-party haptic library is introduced.
- Animation completion timing used for the "synchronized value change" requirement aligns with the spring animation system from Feature 002.
- `minValue` defaults to `0.0` and `maxValue` defaults to `double.infinity` when not specified, giving unbounded-upward behavior by default.
- `enableHaptic` defaults to `false` to avoid surprising developers who have not configured haptics.
- `showProgressIndicator` defaults to `false` to avoid visual changes on existing integrations.
- Dynamic step returning negative values is treated as a no-op (no decrement) to preserve the "progressive only" semantic of right swipe.
- Decrementing behavior is explicitly out of scope for this feature — that belongs to left-swipe semantics (Feature 004).

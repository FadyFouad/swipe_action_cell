# Feature Specification: Unified Feedback System

**Feature Branch**: `010-unified-feedback`
**Created**: 2026-03-01
**Status**: Draft
**Input**: User description: "Consolidate all haptic feedback in the swipe_action_cell package into a unified feedback system with audio hooks."

## User Scenarios & Testing *(mandatory)*

### User Story 1 — Developer Replaces Scattered Haptic Calls with a Single Config (Priority: P1)

An app developer currently using `enableHaptic: true` on `LeftSwipeConfig` or `RightSwipeConfig` upgrades to the unified feedback system. Instead of per-direction boolean flags, they provide a single `SwipeFeedbackConfig` to the cell or to the theme. All haptic events across intentional swipes, progressive increments, and zone boundary crossings are now controlled from one place. Their old `enableHaptic: true` code continues to work unchanged.

**Why this priority**: This is the migration story — the entire motivation for the feature. Without backward compatibility, adoption is blocked. Without the unified config, the feature delivers no value.

**Independent Test**: Can be fully tested by configuring a cell with `SwipeFeedbackConfig(enableHaptic: true)` replacing `enableHaptic: true` on individual configs, performing each swipe event type, and verifying the correct haptic fires for each.

**Acceptance Scenarios**:

1. **Given** a cell with `SwipeFeedbackConfig(enableHaptic: true)` at cell level, **When** a right swipe reaches the activation threshold, **Then** the threshold haptic fires.
2. **Given** the same config, **When** a left swipe action triggers on release, **Then** the activation haptic fires.
3. **Given** a cell with the old `enableHaptic: true` on `LeftSwipeConfig` (no `SwipeFeedbackConfig`), **When** the package is updated, **Then** behavior is identical — the activation haptic fires as before.
4. **Given** `SwipeFeedbackConfig(enableHaptic: false)` (master toggle off), **When** any swipe event occurs, **Then** no haptic fires regardless of per-event configuration.

---

### User Story 2 — Developer Customizes Haptic Patterns Per Event (Priority: P1)

A developer wants the threshold crossing to feel like a light tap, the delete action to feel like a heavy confirmation bump, and the progressive increment to feel like a soft selection tick. They provide `hapticOverrides` mapping each `SwipeFeedbackEvent` to a `HapticPattern`. Events without an override use the predefined default for that event.

**Why this priority**: Per-event haptic customization is the core UX differentiator of this feature. Without it, the unified config offers no advantage over the existing per-direction booleans.

**Independent Test**: Can be fully tested by configuring `hapticOverrides` with distinct patterns for threshold, activation, and tick events, performing each swipe event, and verifying the correct pattern plays for each.

**Acceptance Scenarios**:

1. **Given** `hapticOverrides: {SwipeFeedbackEvent.thresholdCrossed: HapticPattern.light, SwipeFeedbackEvent.actionTriggered: HapticPattern.heavy}`, **When** the drag crosses a zone threshold, **Then** the light haptic pattern fires.
2. **Given** the same config, **When** the action triggers on release, **Then** the heavy haptic pattern fires.
3. **Given** an event with no override entry, **When** that event occurs, **Then** the predefined default pattern for that event fires.
4. **Given** a custom multi-step pattern `[lightImpact, 50ms, lightImpact]` mapped to `SwipeFeedbackEvent.activation`, **When** the activation event fires, **Then** the first impact, a 50ms pause, then the second impact occur in sequence.

---

### User Story 3 — Developer Receives Audio Hook Callbacks (Priority: P2)

A developer wants to play a sound when an action completes. They provide an `onShouldPlaySound` callback in `SwipeFeedbackConfig`. When a swipe event fires, the callback is invoked with the matching `SwipeSoundEvent` value, and the developer dispatches the playback through their own audio system. The package ships no sounds and has no audio dependency.

**Why this priority**: Audio hooks are additive and valuable but the feature is fully functional and shippable without them. P1 stories deliver the core consolidation and customization value.

**Independent Test**: Can be fully tested by configuring `onShouldPlaySound`, triggering each event type (threshold, action, panel open/close, increment), and verifying the callback receives the correct `SwipeSoundEvent` for each.

**Acceptance Scenarios**:

1. **Given** `onShouldPlaySound: (event) => recordedEvents.add(event)` and `enableAudio: true`, **When** a right-swipe increment completes, **Then** `recordedEvents` contains `SwipeSoundEvent.progressIncremented`.
2. **Given** the same config, **When** a left-swipe action triggers, **Then** `SwipeSoundEvent.actionTriggered` is received.
3. **Given** the same config, **When** the reveal panel opens, **Then** `SwipeSoundEvent.panelOpened` is received.
4. **Given** `enableAudio: false` (master toggle off), **When** any swipe event occurs, **Then** `onShouldPlaySound` is never called.
5. **Given** `onShouldPlaySound: null` and `enableAudio: true`, **Then** no error occurs and no callback fires.

---

### User Story 4 — Developer Configures App-Wide Feedback via Theme (Priority: P2)

A developer wants consistent haptic behavior across all cells in their app without repeating `SwipeFeedbackConfig` on every cell. They add a single `feedbackConfig` to `SwipeActionCellTheme`. Individual cells may override the theme config; cells without a local override inherit the theme config.

**Why this priority**: Theme-level config reduces boilerplate significantly for apps with many cells. Important for production adoption but not required for the feature to be usable.

**Independent Test**: Can be fully tested by wrapping multiple cells in a `SwipeActionCellTheme` with `feedbackConfig`, verifying all cells apply the theme config, and verifying that a cell with its own local `feedbackConfig` overrides the theme value.

**Acceptance Scenarios**:

1. **Given** `SwipeActionCellTheme(feedbackConfig: SwipeFeedbackConfig(enableHaptic: false))` wrapping a cell with no local feedback config, **When** any swipe event fires, **Then** no haptic plays.
2. **Given** the same theme, **When** a cell provides its own `SwipeFeedbackConfig(enableHaptic: true)`, **Then** that cell's haptic fires while other cells under the same theme remain silent.
3. **Given** no theme and no cell-level feedback config, **Then** default behavior applies (haptic enabled with predefined patterns).

---

### User Story 5 — Haptic Degrades Gracefully on Unsupported Platforms (Priority: P1)

A developer deploys their app on web and low-end Android devices where haptic feedback is unavailable. When the feedback system attempts to fire a haptic on an unsupported platform, the call is silently skipped. No exception is thrown and no error is logged. All other swipe behavior is unaffected.

**Why this priority**: Silent degradation is a hard correctness requirement — a crash or exception on web due to a missing haptic channel would be a regression for existing users.

**Independent Test**: Can be fully tested by running a cell on the web target with haptic enabled, triggering swipe events, and confirming no exceptions are thrown and all gesture and action behavior works correctly.

**Acceptance Scenarios**:

1. **Given** `SwipeFeedbackConfig(enableHaptic: true)` running on web, **When** any haptic event fires, **Then** no exception is thrown and the swipe action completes normally.
2. **Given** the same scenario on a device that returns a platform error from the haptic channel, **Then** the error is swallowed silently and the swipe action completes.
3. **Given** a multi-step pattern on an unsupported platform, **When** the pattern fires, **Then** all steps are silently skipped and no partial execution leaves state inconsistency.

---

### Edge Cases

- What happens when `hapticOverrides` maps an event to a pattern with zero steps? → No haptic fires for that event (equivalent to disabling haptic for that event only).
- What happens when a multi-step pattern has a 0ms inter-step delay? → Steps fire back-to-back without any pause, treated as near-simultaneous impacts.
- What happens when `onShouldPlaySound` throws? → The exception is caught and ignored; swipe behavior is unaffected.
- What happens when both cell-level and theme-level `feedbackConfig` are null? → The predefined default config applies (haptic on, audio off, default patterns).
- What happens when legacy `enableHaptic: true` remains on a direction config AND a `SwipeFeedbackConfig` is also provided? → `SwipeFeedbackConfig` takes precedence at runtime. In debug builds, an assert fires with a descriptive migration hint message; in release builds, the direction-level flag is silently ignored.
- What happens when a `SwipeZone` (F009) has `hapticPattern` set AND a `SwipeFeedbackConfig` override maps `zoneBoundaryCrossed`? → `SwipeFeedbackConfig` takes precedence.
- What happens on rapid consecutive zone crossings in the same frame? → Each crossing fires its feedback independently.
- What happens to a multi-step pattern that is mid-execution when a new drag gesture begins? → All pending step timers are cancelled immediately; the new gesture starts fresh with no residual haptic state.
- What happens to a mid-execution multi-step pattern when the cell widget is disposed? → All pending step timers are cancelled immediately; no steps fire after disposal.
- What happens if the OS-level vibration setting is disabled by the user? → The OS silently ignores the haptic call; the package takes no action.

---

## Requirements *(mandatory)*

### Functional Requirements

**Unified Configuration**

- **FR-001**: Consumers MUST be able to provide a single `SwipeFeedbackConfig` at the cell level to control all haptic and audio feedback for that cell across all swipe directions and event types.
- **FR-002**: `SwipeFeedbackConfig` MUST expose `enableHaptic: bool` (default `true`) as a master toggle; when `false`, no haptic fires for that cell under any circumstance.
- **FR-003**: `SwipeFeedbackConfig` MUST expose `enableAudio: bool` (default `false`) as a master toggle; when `false`, `onShouldPlaySound` is never invoked.
- **FR-004**: When no `SwipeFeedbackConfig` is present at cell or theme level, all predefined default haptic patterns MUST apply automatically.

**Predefined Haptic Patterns**

- **FR-005**: The system MUST provide five named predefined haptic event mappings:
  - `SwipeFeedbackEvent.thresholdCrossed` → light impact
  - `SwipeFeedbackEvent.actionTriggered` → medium impact
  - `SwipeFeedbackEvent.progressIncremented` → selection tick
  - `SwipeFeedbackEvent.panelOpened` → selection tick
  - `SwipeFeedbackEvent.panelClosed` → selection tick
  - `SwipeFeedbackEvent.zoneBoundaryCrossed` → light impact
  - `SwipeFeedbackEvent.swipeCancelled` → no haptic (silent by default)

**Custom Haptic Overrides**

- **FR-006**: `SwipeFeedbackConfig` MUST expose `hapticOverrides: Map<SwipeFeedbackEvent, HapticPattern>?`; entries replace the default for their keyed event.
- **FR-007**: `HapticPattern` MUST represent a sequence of one or more `HapticStep` values (maximum 8); each step carries a `HapticType` and an optional `delayBeforeNextMs` (default 0). Constructing a pattern with more than 8 steps MUST assert with a descriptive error message.
- **FR-008**: `HapticType` MUST include: `lightImpact`, `mediumImpact`, `heavyImpact`, `successNotification`, `errorNotification`, `selectionTick`.
- **FR-009**: A pattern with zero steps MUST produce no haptic output for its mapped event.
- **FR-010**: Multi-step patterns MUST fire their first step synchronously on the triggering frame; subsequent steps MUST fire after their configured delay without blocking gesture processing. Any pending step timers MUST be cancelled when a new drag gesture starts or when the cell widget is disposed; steps that have not yet fired at cancellation time are silently dropped.

**Audio Hooks**

- **FR-011**: `SwipeFeedbackConfig` MUST expose `onShouldPlaySound: void Function(SwipeSoundEvent)?`.
- **FR-012**: `SwipeSoundEvent` MUST include: `thresholdCrossed`, `actionTriggered`, `panelOpened`, `panelClosed`, `progressIncremented`.
- **FR-013**: When `enableAudio` is `true` and `onShouldPlaySound` is non-null, the callback MUST be invoked synchronously on the same frame as the triggering event.
- **FR-014**: Any exception thrown by `onShouldPlaySound` MUST be caught and suppressed; the swipe action MUST complete normally.

**Theme Integration**

- **FR-015**: `SwipeActionCellTheme` MUST accept `feedbackConfig: SwipeFeedbackConfig?` following the existing cascade pattern.
- **FR-016**: A cell without a local `feedbackConfig` MUST inherit the ancestor theme's `feedbackConfig`.
- **FR-017**: A cell with a local `feedbackConfig` MUST use it exclusively, overriding any theme value.

**Migration & Backward Compatibility**

- **FR-018**: The `enableHaptic` field on `LeftSwipeConfig` and `RightSwipeConfig` MUST continue to function unchanged when no `SwipeFeedbackConfig` is configured.
- **FR-019**: When `SwipeFeedbackConfig` is present, it MUST take precedence over any `enableHaptic` on direction configs; the direction-level flag is ignored at runtime. In debug builds, the widget MUST assert with a descriptive migration hint message when `enableHaptic: true` is set on a direction config AND a `SwipeFeedbackConfig` is also active, guiding the developer to remove the redundant field.
- **FR-020**: Zone-level `hapticPattern` on `SwipeZone` (F009) MUST be superseded by `SwipeFeedbackConfig` when one is configured; zone patterns apply only in the absence of a `SwipeFeedbackConfig`.

**Platform Degradation**

- **FR-021**: All haptic dispatch calls MUST be wrapped in error handling that catches and silently discards any platform exception.
- **FR-022**: On platforms where haptic is unavailable, cells MUST behave identically in all non-haptic respects — no changed gesture behavior, no changed visual behavior.

### Key Entities

- **SwipeFeedbackConfig**: Immutable configuration. Fields: `enableHaptic` (bool, default true), `enableAudio` (bool, default false), `hapticOverrides` (Map<SwipeFeedbackEvent, HapticPattern>?), `onShouldPlaySound` (void Function(SwipeSoundEvent)?). `const` constructor, `copyWith`, `==`, `hashCode`.
- **SwipeFeedbackEvent**: Enumeration of all feedback trigger points: `thresholdCrossed`, `actionTriggered`, `panelOpened`, `panelClosed`, `progressIncremented`, `zoneBoundaryCrossed`, `swipeCancelled`.
- **HapticPattern**: Immutable sequence of 1–8 `HapticStep` values. Asserts on construction if step count exceeds 8. Supports named factory constructors for predefined single-step patterns (`light`, `medium`, `heavy`, `tick`, `success`, `error`).
- **HapticStep**: Immutable pair of `HapticType` and `delayBeforeNextMs` (int, default 0).
- **HapticType**: Enumeration: `lightImpact`, `mediumImpact`, `heavyImpact`, `successNotification`, `errorNotification`, `selectionTick`.
- **SwipeSoundEvent**: Enumeration: `thresholdCrossed`, `actionTriggered`, `panelOpened`, `panelClosed`, `progressIncremented`.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: All existing haptic-related test cases from F003, F004, and F009 pass without modification after migration — zero test regressions.
- **SC-002**: A developer can remove all `enableHaptic: true` flags from direction configs, replace them with a single `SwipeFeedbackConfig(enableHaptic: true)`, and observe identical haptic behavior verified by automated tests.
- **SC-003**: Five distinct swipe events each produce their correct predefined haptic output, verified by inspecting the haptic channel call log in automated tests.
- **SC-004**: A `hapticOverrides` map with custom patterns produces verifiably different haptic channel call sequences than the defaults, verified by automated tests.
- **SC-005**: The `onShouldPlaySound` callback is invoked exactly once per triggering event when `enableAudio: true`, verified by counting callback invocations in automated tests.
- **SC-006**: Zero exceptions surface when haptic events fire on a web platform target, verified by running the test suite on web with haptic enabled.
- **SC-007**: A theme-level `feedbackConfig` propagates to all descendant cells; a local cell override takes exclusive precedence — verified by automated widget tests.
- **SC-008**: Setting `enableHaptic: false` on `SwipeFeedbackConfig` produces zero haptic channel calls across all event types, verified by automated tests.

---

## Clarifications

### Session 2026-03-01

- Q: Should multi-step pattern timers be cancelled when a new drag starts or the cell disposes, or should they always complete? → A: Cancel on both new drag start and widget dispose; unfired steps are silently dropped. FR-010 updated.
- Q: Should there be a maximum number of steps per HapticPattern, and if so what is it? → A: Maximum 8 steps; constructing a pattern with more asserts with a descriptive error message. FR-007 and HapticPattern entity updated.
- Q: When `enableHaptic: true` on a direction config coexists with an active `SwipeFeedbackConfig`, should it be a silent ignore or trigger a debug-mode warning? → A: Assert in debug builds with a migration hint message; silent ignore in release builds. FR-019 updated.

---

## Assumptions

- "SwipeFeedbackController" in the original description is renamed `SwipeFeedbackConfig` for naming consistency with the package's existing config convention (Constitution VI).
- "Platform-aware iOS CoreHaptics" is deferred as a future enhancement; this feature uses only `HapticFeedback` service calls.
- The inter-step delay in multi-step patterns uses a non-blocking timer; gesture processing is never paused.
- `SwipeFeedbackEvent.swipeCancelled` defaults to no haptic; consumers may override via `hapticOverrides`.
- `SwipeSoundEvent` and `SwipeFeedbackEvent` are separate enumerations — audio events are a subset of feedback events; not every feedback event has an audio counterpart.
- When `hapticOverrides` is null (not provided), all events use their predefined defaults. When `hapticOverrides` is an empty map, all events also use their predefined defaults.
- The `feedbackConfig` field added to `SwipeActionCell` widget follows the same null-means-use-theme pattern as `gestureConfig`, `animationConfig`, and `visualConfig`.

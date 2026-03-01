# Feature Specification: Custom Painting & Decoration Hooks

**Feature Branch**: `012-custom-painter`
**Created**: 2026-03-01
**Status**: Draft
**Input**: User description: "Add custom painting and decoration hooks to the swipe_action_cell package for advanced visual effects tied to swipe progress."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Custom Painter Hooks (Priority: P1)

As a package consumer, I want to attach my own drawing logic to the swipe cell — both behind the content and in front of it — so that I can produce signature visual effects (gradient trails, animated borders, glow effects) that respond in real time to the user's swipe gesture.

**Why this priority**: Custom painters are the most powerful and open-ended customization primitive. Unlocking them enables effects that the built-in background builders (F002) cannot express — arbitrary vector art, per-pixel effects, progress-driven geometry. This is the core value of the feature.

**Independent Test**: Attach a background painter that draws a red gradient strip whose width scales with swipe progress. Verify the strip grows and shrinks as the user drags and releases, with no visible lag. Attach a foreground painter that draws a yellow border; verify it renders above the child content. Remove both painters and verify no visual artifacts remain.

**Acceptance Scenarios**:

1. **Given** a cell with a background painter configured, **When** the user drags the cell, **Then** the painter receives the current swipe progress and state on every frame and its output is visible below the child content.
2. **Given** a cell with a foreground painter configured, **When** the user drags the cell, **Then** the painter's output is visible above the child content and does not block taps on the child.
3. **Given** a cell with both painters set to null, **When** the cell is rendered, **Then** no additional rendering work is performed (zero overhead guarantee).
4. **Given** a cell with a foreground painter active, **When** the user taps the child widget's interactive elements, **Then** all taps are received correctly by the child (hit testing is unaffected).

---

### User Story 2 - Decoration Interpolation (Priority: P1)

As a package consumer, I want to define a resting appearance and a threshold-activated appearance for the cell, so that the cell visually morphs between the two states as the user's swipe progresses — for example, corners rounding, background color intensifying, or border widening — without writing custom drawing code.

**Why this priority**: Decoration interpolation delivers high-value visual polish with minimal consumer effort. It is the easiest way to communicate swipe intent without requiring custom drawing knowledge. Equal priority to painter hooks as it serves a distinct, simpler use case.

**Independent Test**: Configure a cell with a resting decoration (light grey background, rounded corners) and an activated decoration (red background, sharp corners). Drag the cell and verify the background and corners smoothly transition proportionally to drag distance. Release without crossing the threshold and verify the cell returns to the resting appearance.

**Acceptance Scenarios**:

1. **Given** a cell with a resting and activated decoration, **When** the user drags to 50% of the threshold, **Then** the cell's appearance is visually halfway between the two decoration states.
2. **Given** a cell with only a resting decoration (no activated decoration), **When** the user drags, **Then** the resting decoration is applied permanently with no crash or visual artifact.
3. **Given** a cell dragged past the threshold (ratio > 1.0), **When** the decorations are interpolated, **Then** the cell holds the fully-activated decoration appearance without visual glitches.

---

### User Story 3 - Built-In Morph Icon (Priority: P2)

As a package consumer, I want a ready-made widget that smoothly transitions between two icons as swipe progress increases, so that I can place an expressive icon inside my background builder (F002) without implementing custom animation.

**Why this priority**: Morph icons are the most commonly needed progress-driven UI element inside background builders. A built-in widget removes the majority of integration effort for real-world use cases. Priority P2 as it depends on F002's background builder pattern being familiar to consumers.

**Independent Test**: Place a `SwipeMorphIcon` inside a background builder with an outline icon at progress 0.0 and a filled icon at progress 1.0. Drag the cell and verify the icon cross-fades between the two states proportional to progress. At progress 0.0 only the first icon is visible; at progress 1.0 only the second.

**Acceptance Scenarios**:

1. **Given** a `SwipeMorphIcon` with a progress value of 0.0, **When** rendered, **Then** only the starting icon is visible.
2. **Given** a `SwipeMorphIcon` with a progress value of 0.5, **When** rendered, **Then** both icons are blended at equal weight with no single icon dominating.
3. **Given** a `SwipeMorphIcon` with a progress value of 1.0, **When** rendered, **Then** only the ending icon is visible.

---

### User Story 4 - Particle Burst on Action Completion (Priority: P3)

As a package consumer, I want an optional particle burst to play when an intentional (left-swipe) action is completed, so that I can add celebratory micro-animation to committed actions without building a custom particle system.

**Why this priority**: Particle effects are opt-in visual flourish. They add delight but are not required for core painting value. Self-contained and independently disableable; lowest priority.

**Independent Test**: Enable particle effects with 12 particles and a red color palette. Trigger an intentional (left-swipe) action. Verify 12 particles appear, animate outward, and are gone by 500 ms. Trigger a progressive (right-swipe) action and verify no particles appear. Dispose the widget mid-animation and verify no particles persist.

**Acceptance Scenarios**:

1. **Given** a cell with `particleConfig` set, **When** an intentional (left-swipe) action completes, **Then** the configured number of particles appears at the action origin and animates outward.
1a. **Given** a cell with `particleConfig` set, **When** a progressive (right-swipe) action completes, **Then** no particle animation plays.
2. **Given** a particle burst in progress, **When** the configured duration elapses, **Then** all particles have disappeared and no rendering overhead remains.
3. **Given** a cell disposed while particles are active, **When** disposal occurs, **Then** all particle resources are released immediately.
4. **Given** a cell with `particleConfig` set to null (default), **When** a swipe action completes, **Then** no particle animation plays and no overhead is incurred.

---

### Edge Cases

- **Painter and F002 background widget both active**: Both render simultaneously; the painter is below the F002 background widget, preserving the defined layer order.
- **Swipe ratio exceeding 1.0**: Decoration interpolation clamps at the fully-activated state; no crash or visual overflow.
- **Particle config with no colors**: System applies a default color palette rather than crashing or rendering invisible particles.
- **Particle count of zero**: No particles are rendered and no animation is started.
- **Rapid swipe direction reversal**: Painters and decorations handle reversals gracefully with no stale frame artifacts.
- **Null activated decoration with active drag**: Resting decoration persists unchanged; no interpolation attempted.
- **Painter callback throws at runtime**: In release mode, the exception is caught and that paint layer is skipped for the affected frame (no crash, no visual artifact from prior frame). In debug mode, the exception is rethrown immediately so developers receive visible failure feedback.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-012-001**: System MUST accept a background painter hook (a function receiving current swipe progress and swipe state, providing drawing instructions per frame) and render its output as the lowest visual layer of the cell. The painter receives updates during all SwipeState phases: dragging, animatingToOpen, animatingToClose, revealed, and animatingOut.
- **FR-012-002**: System MUST accept a foreground painter hook with the same signature as FR-012-001 and render its output as the highest visual layer, above all other cell content. The painter receives updates during all SwipeState phases identical to FR-012-001.
- **FR-012-003**: System MUST enforce this strict visual layer order, bottom to top: (1) background painter, (2) F002 background widget, (3) decoration layer, (4) child widget, (5) foreground painter.
- **FR-012-004**: System MUST NOT impair hit testing on the child widget or any interactive element within it when foreground or background painters are active.
- **FR-012-005**: System MUST accept a resting decoration and an activated decoration; the system MUST interpolate between the two proportionally to the swipe progress ratio, clamped to [0.0, 1.0], during all SwipeState phases (dragging, animatingToOpen, animatingToClose, revealed, animatingOut) — enabling smooth visual return-to-rest on snap-back.
- **FR-012-006**: When only a resting decoration is provided (no activated decoration), the system MUST apply the resting decoration at all times without error or visual artifact.
- **FR-012-007**: System MUST provide a built-in morph icon widget accepting a start icon, an end icon, and a progress value (0.0–1.0), rendering a smooth visual blend between the two proportional to progress.
- **FR-012-008**: System MUST provide an optional particle burst triggered exclusively on intentional (left-swipe) action completion: when `particleConfig` is non-null, the configured number of particles (default 12) animate outward within the configured spread angle and disappear by the configured duration (default 500 ms). Progressive (right-swipe) actions do NOT trigger a particle burst. When `particleConfig` is null, no particle animation plays and no overhead is incurred.
- **FR-012-009**: The particle system MUST release all resources immediately on widget disposal, regardless of animation state.
- **FR-012-010**: When all painting parameters (background painter, foreground painter, resting decoration, activated decoration) are null and `particleConfig` is null, the system MUST incur zero additional rendering overhead per frame.
- **FR-012-011**: `SwipePaintingConfig` MUST be a new, standalone parameter on `SwipeActionCell` independent of the existing `SwipeVisualConfig` (F005). No existing `SwipeVisualConfig` fields, defaults, or consumers are affected by this feature.

### Key Entities

- **SwipePainterCallback**: A painter hook — a function receiving swipe progress and swipe state per frame, returning drawing instructions for one visual layer.
- **SwipePaintingConfig**: A new standalone configuration object added to `SwipeActionCell` alongside the existing `SwipeVisualConfig`. Contains: resting decoration, activated decoration, background painter callback, foreground painter callback, and `particleConfig: ParticleConfig?`. When `SwipePaintingConfig` itself is `null`, the feature is entirely disabled with zero overhead (Constitution IX). When `particleConfig` within it is `null`, particle effects are disabled (Constitution IX null-config pattern — no `enableParticles` boolean).
- **SwipeMorphIcon**: A standalone widget that blends between a start icon and an end icon based on a progress value from 0.0 to 1.0.
- **ParticleConfig**: Configuration for the optional particle burst: particle count, color palette, spread angle in degrees, and total animation duration.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-012-001**: Custom painters receive updated progress values with no more than one frame of lag behind actual gesture position on mid-range devices (equivalent to 2018-era hardware).
- **SC-012-002**: All active painting layers combined (background painter + decoration + foreground painter) produce no measurable frame-rate drop below 60 fps on mid-range devices.
- **SC-012-003**: Zero additional rendering passes occur per frame when all painting parameters are null — verified by confirming paint call count matches a baseline cell with no painting configuration.
- **SC-012-004**: 100% of particle resources are released within 100 ms of animation completion or widget disposal.
- **SC-012-005**: Decoration transitions across the full swipe range (0.0 to 1.0) are visually continuous with no jumps or artifacts.
- **SC-012-006**: `SwipeMorphIcon` renders only the start icon at progress 0.0, a balanced blend at 0.5, and only the end icon at 1.0 — verified with no intermediate artifact frames.

---

## Clarifications

### Session 2026-03-01

- Q: How does `SwipePaintingConfig` relate to the existing `SwipeVisualConfig` from F005? → A: New standalone parameter on `SwipeActionCell` alongside `SwipeVisualConfig` — clean separation, zero breaking change to F005.
- Q: How should particle effects be enabled — `enableParticles: bool` + `particleConfig` or `particleConfig: ParticleConfig?` null pattern? → A: `particleConfig: ParticleConfig?` null pattern only — no `enableParticles` boolean (Constitution IX compliant).
- Q: During which lifecycle phases do painters and decoration interpolation receive updates — drag only, or all SwipeState phases? → A: All SwipeState phases (dragging, animatingToOpen, animatingToClose, revealed, animatingOut) — smooth animation through snap-back and completion.
- Q: What should happen if a painter callback throws an exception at runtime? → A: Suppress in release mode (skip paint layer for that frame, no crash); rethrow/assert in debug mode for immediate developer visibility — matching Flutter's own builder callback convention.
- Q: Which swipe action completions trigger the particle burst — intentional only, progressive too, or consumer-controlled? → A: Intentional (left-swipe) completions only — progressive incremental actions do not trigger a burst.

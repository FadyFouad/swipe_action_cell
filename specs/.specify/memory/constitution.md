<!-- SYNC IMPACT REPORT
Version change: N/A → 1.0.0 (initial constitution; was uninitialized template)
Modified principles: N/A — all principles are new
Added sections:
  - Core Principles (10 principles)
  - SDK & Platform Constraints
  - Development Standards
  - Governance
Removed sections: N/A (template placeholders replaced)
Templates reviewed:
  - .specify/templates/plan-template.md    ✅ Constitution Check section is dynamically filled by /speckit.plan; no updates needed
  - .specify/templates/spec-template.md    ✅ Generic structure aligns with principles; no updates needed
  - .specify/templates/tasks-template.md   ✅ Test-first phase ordering (tests before implementation) aligns with Principle VII; no updates needed
  - .specify/templates/checklist-template.md  ✅ Generic; no constitution references; no updates needed
  - .specify/templates/agent-file-template.md ✅ Generic; no constitution references; no updates needed
Follow-up TODOs: None — all placeholders resolved
-->

# swipe_action_cell Constitution

## Core Principles

### I. Composition over Inheritance

`SwipeActionCell` MUST wrap any child widget via a constructor parameter. No feature
implementation may require consumers to extend a base class. All extension points are expressed
through callbacks, configuration objects, and controller injection.

**Rationale**: Composable widgets integrate cleanly into any widget tree and impose no class
hierarchy constraints on consumers, maximizing compatibility and flexibility.

### II. Explicit State Machine

Every interaction MUST be modeled as a formal state machine with clearly defined states and
transitions. The canonical lifecycle is:
`idle → dragging → animatingToOpen → revealed → animatingToClose → idle`.
Transitions not enumerated in the state machine are forbidden; any new state MUST be formally
added to the machine before use.

**Rationale**: An explicit state machine eliminates ambiguous intermediate states, simplifies
debugging, and makes behavior fully predictable and testable.

### III. Spring-Based Physics

All animated transitions MUST use `AnimationController` combined with `SpringSimulation`.
Tween-only linear or eased animations are not permitted for swipe interaction feedback. Spring
parameters (stiffness, damping, mass) MUST be configurable per feature direction.

**Rationale**: Spring physics produce naturally-feeling interactions that match platform motion
conventions and user expectations better than fixed-duration ease curves.

### IV. Zero External Runtime Dependencies

The package MUST depend solely on the Flutter SDK at runtime. No third-party packages may be
listed under `dependencies` in `pubspec.yaml`. Dev dependencies (testing, linting tools) are
permitted under `dev_dependencies`.

**Rationale**: Zero runtime dependencies minimize consumer dependency conflicts, reduce
supply-chain risk, and keep the package lean and auditable.

### V. Controlled/Uncontrolled Pattern

Every stateful behavior MUST support both modes:

- **Uncontrolled** (default): state managed internally with sensible defaults, no setup required.
- **Controlled**: state driven by an external `SwipeController` instance.

A widget MUST NOT require a controller to function — providing one is strictly opt-in.

**Rationale**: This pattern mirrors Flutter's `TextField`/`TextEditingController` convention and
allows the package to integrate with any state management approach without coupling.

### VI. Const-Friendly Configuration

All configuration objects (e.g., `LeftSwipeConfig`, `RightSwipeConfig`) MUST be:

- Constructable as `const`.
- Fully immutable (all fields `final`).
- Equipped with a `copyWith` method supporting incremental overrides.

Mutable configuration objects are forbidden.

**Rationale**: Const configs enable widget-rebuild optimizations and predictable value semantics,
preventing subtle mutation bugs in long-lived widget trees.

### VII. Test-First (NON-NEGOTIABLE)

Every public API surface MUST have widget and/or unit tests before the implementation is
considered complete. The Red-Green-Refactor cycle is mandatory: tests MUST be written to fail
before the code under test is written. A feature MUST NOT be merged without passing tests.

**Rationale**: Test-first ensures APIs are designed for testability and regressions are caught
immediately. It is the primary quality gate for every feature.

### VIII. Dartdoc Everything

Every public class, method, property, typedef, and enum value MUST carry a `///` documentation
comment. The `public_member_api_docs` lint rule is enforced. A PR that introduces undocumented
public members MUST NOT be merged.

**Rationale**: A Flutter package is a public API surface. Without comprehensive dartdoc,
consumers cannot understand usage without reading source code.

### IX. Null Config = Feature Disabled

A `null` value for any optional configuration object (e.g., `leftSwipeConfig: null`) MUST
completely disable the corresponding feature — no gesture recognition, no visual feedback, no
callbacks fired. The feature MUST behave as if that swipe direction does not exist.

**Rationale**: This convention provides a single, unambiguous toggle mechanism that is explicit,
tree-shaker friendly, and requires no separate boolean flags.

### X. Performance Budget: 60 fps

All drag and animation interactions MUST maintain 60 fps on mid-range devices (equivalent to a
2018-era Android device or iPhone 8). Frame drops during active swipe gestures are treated as
bugs. Render performance MUST be verified with Flutter DevTools before any feature is marked
complete.

**Rationale**: A swipe interaction widget's primary value is tactile responsiveness. Any jank
directly degrades the experience it exists to provide.

## SDK & Platform Constraints

- **Dart SDK**: `>=3.4.0 <4.0.0`
- **Flutter SDK**: `>=3.22.0`

These constraints are intentionally modern and MUST NOT be lowered without a MAJOR version bump
and documented justification. They enable current Gesture Arena APIs, `SpringSimulation`, and
Dart 3 language features (patterns, records, sealed classes).

**Supported platforms**: All Flutter-supported platforms (iOS, Android, web, macOS, Windows,
Linux). Platform-specific behavior differences MUST be documented per feature, not papered over.

## Development Standards

- **Linting**: `analysis_options.yaml` extends `flutter_lints/flutter.yaml` with strict
  additional rules. All code MUST pass `flutter analyze` with zero warnings or errors.
- **Formatting**: All Dart code MUST be formatted with `dart format`. CI enforces this via
  `dart format --set-exit-if-changed .`.
- **Barrel exports**: New public API MUST be exported from `lib/swipe_action_cell.dart`. Test
  utilities MUST be exported from `lib/testing.dart` only, never from the main barrel.
- **No `Dismissible`**: This package is a replacement for `Dismissible`-style interactions.
  Internal use of `Dismissible` is forbidden.
- **Feature flags via null config**: Optional features are disabled by passing `null` to the
  relevant config parameter (see Principle IX). Boolean feature-flag fields are not permitted.

## Governance

This constitution supersedes all other practices documented in the repository. When a conflict
arises between this document and other guidelines (README, inline comments, past decisions),
this constitution takes precedence.

**Amendment procedure**:

1. Propose the change in a PR with a clear rationale and the version bump type (MAJOR/MINOR/PATCH).
2. Update `LAST_AMENDED_DATE` and `CONSTITUTION_VERSION` following semantic versioning:
   - **MAJOR**: Removing or redefining a principle in a backward-incompatible way.
   - **MINOR**: Adding a new principle or materially expanding existing guidance.
   - **PATCH**: Clarifications, wording improvements, typo fixes.
3. Propagate changes to dependent templates (`plan-template.md`, `spec-template.md`,
   `tasks-template.md`) as required and note them in the Sync Impact Report.

**Compliance review**: Every PR MUST verify compliance with the Constitution Check section in
`plan.md`. The reviewer is responsible for flagging violations before merge.

**Runtime guidance**: See `.specify/memory/CLAUDE.md` (auto-generated from feature plans) for
per-session development guidance derived from active feature plans.

---

**Version**: 1.0.0 | **Ratified**: 2026-02-25 | **Last Amended**: 2026-02-25

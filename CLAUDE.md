# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`swipe_action_cell` is a reusable Flutter package that provides a custom swipe interaction widget for list items. Left and right swipes have different semantic meanings:

- **Right swipe (forward):** Progressive/incremental action (e.g., increment counter, increase progress)
- **Left swipe (backward):** Intentional committed action (e.g., delete, archive, reveal action buttons)

The package is inspired by `flutter_slidable` but with asymmetric swipe semantics as its core identity.

## Commands

```bash
# Install dependencies
flutter pub get

# Run all tests
flutter test

# Run a single test file
flutter test test/core/swipe_direction_test.dart

# Run linting/static analysis
flutter analyze

# Check formatting
dart format --set-exit-if-changed .

# Auto-format code
dart format .

# Publish to pub.dev (dry run first)
flutter pub publish --dry-run
```

## Architecture

The package follows a feature-first directory structure under `lib/src/`:

```
lib/
├── swipe_action_cell.dart          # Barrel export — all public API exported here
├── testing.dart                    # Test utilities export (separate entry point)
└── src/
    ├── core/                       # Enums, data classes, typedefs
    ├── gesture/                    # F1: Horizontal drag detection & direction discrimination
    ├── animation/                  # F2: Spring-based animation & snap-back/completion
    ├── visual/                     # F5: Background builders & progress-linked transitions
    ├── actions/
    │   ├── progressive/            # F3: Right swipe incremental value tracking
    │   └── intentional/            # F4: Left swipe auto-trigger & reveal modes
    ├── config/                     # F6: Consolidated configuration API
    ├── controller/                 # F7: SwipeController & group coordination
    ├── accessibility/              # F8: Semantics, keyboard nav, motion sensitivity
    ├── scroll/                     # F9: Gesture arena & scroll conflict resolution
    ├── feedback/                   # F11: Haptic patterns & audio hooks
    ├── undo/                       # F12: Undo lifecycle & revert support
    ├── painting/                   # F13: Custom painter & decoration hooks
    ├── templates/                  # F14: Prebuilt zero-config templates
    └── widget/                     # Main SwipeActionCell widget
```

**Key architectural decisions:**

- **Composition over inheritance:** `SwipeActionCell(child: YourWidget())` — wraps any child
- **Explicit state machine:** `idle → dragging → animatingToOpen → revealed → animatingToClose → idle`
- **Spring-based physics:** `AnimationController` + `SpringSimulation`, not just `Tween`
- **Controlled/uncontrolled pattern:** State managed internally or via external `SwipeController`
- **No external state management dependency:** Works with Provider, Riverpod, Bloc, or none

## SDK Constraints

- **Dart:** `>=3.4.0 <4.0.0`
- **Flutter:** `>=3.41.0`

These are intentionally modern — the package uses APIs from recent Flutter versions (gesture arena improvements, SpringSimulation, etc.). Do not lower these constraints.

## Linting

`analysis_options.yaml` extends `flutter_lints/flutter.yaml` with strict additional rules. All code must pass `flutter analyze` with zero warnings. The `public_member_api_docs` rule is enforced — every public class, method, and property needs dartdoc comments.

## Spec-Driven Development Workflow

The `specs/` directory contains a speckit system for structured feature development. Custom slash commands are in `specs/.claude/commands/`:

| Command | Purpose |
|---|---|
| `/speckit.specify` | Create a feature spec from a natural-language description |
| `/speckit.clarify` | Clarify ambiguous spec requirements |
| `/speckit.plan` | Generate a technical implementation plan from a spec |
| `/speckit.implement` | Implement a planned feature |
| `/speckit.checklist` | Validate spec or plan quality |
| `/speckit.tasks` | Generate task breakdowns |

Each feature gets a numbered branch (`###-feature-name`) and a directory under `specs/` containing the spec, plan, tasks, and checklists. The workflow is: **specify → clarify → plan → tasks → implement**.

## Feature Implementation Order

Features are implemented sequentially following this dependency chain:

```
Phase 1 (Core):     F1 → F2 → F5 → F3 → F4
Phase 2 (Prod):     F6 → F9 → F7 → F8
Phase 3 (Advanced): F10 → F11 → F12 → F13
Phase 4 (Polish):   F14 → F15 → F16 → F17
```

## Development Rules

- **Barrel exports:** When adding new public widgets or classes, always export them from `lib/swipe_action_cell.dart`. Test utilities go in `lib/testing.dart`.
- **Const constructors:** Use `const` wherever possible — config objects, data classes, default values.
- **Immutable config:** All configuration objects must be immutable with `copyWith` support.
- **Tests required:** Every public API surface needs widget/unit tests. Run `flutter test` before committing.
- **No external runtime deps:** The package depends only on Flutter SDK. Dev dependencies are fine.
- **Dartdoc everything:** All public members need `///` documentation comments.

## Active Technologies
- Dart >=3.4.0 + Flutter SDK only (zero external runtime deps — Constitution IV) (001-gesture-animation)
- N/A (in-memory value only; persistence is consumer responsibility) (003-progressive-swipe)
- N/A (stateless config; no persistence) (004-intentional-action)
- Dart >=3.4.0 <4.0.0 + Flutter SDK only (zero external runtime deps — Constitution IV) (005-config-api)
- N/A (stateless config objects) (005-config-api)
- Dart ≥ 3.4.0 / Flutter ≥ 3.22.0 + Flutter SDK only (zero external runtime deps — Constitution IV) (006-controller-group)
- N/A (in-memory state only; no persistence) (006-controller-group)
- Dart >=3.4.0 <4.0.0 + Flutter >=3.22.0 + Flutter SDK only (zero external runtime deps — Constitution IV) (010-unified-feedback)

## Recent Changes
- 001-gesture-animation: Added Dart >=3.4.0 + Flutter SDK only (zero external runtime deps — Constitution IV)

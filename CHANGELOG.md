# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.0.0] - 2026-03-01

### Added

- F001: Horizontal drag detection and direction discrimination with gesture arena integration
- F002: Spring-based animation system with snap-back and completion physics (`SpringSimulation`)
- F003: Progressive right-swipe with real-time value tracking, step increments, and threshold callbacks
- F004: Intentional left-swipe with auto-trigger and reveal modes (`LeftSwipeMode`)
- F005: Consolidated configuration API (`LeftSwipeConfig`, `RightSwipeConfig`, `SwipeVisualConfig`)
- F006: `SwipeController` for programmatic open, close, undo, and progress reset
- F007: `SwipeGroupController` for accordion behavior across multiple cells
- F008: Accessibility and RTL support with semantic labels and direction-adaptive swipe semantics
- F009: Scroll-conflict resolution via custom gesture recognizer and gesture arena participation
- F010: Unified haptic and audio feedback system (`SwipeFeedbackConfig`)
- F011: Undo lifecycle with configurable window and revert callbacks (`SwipeUndoConfig`)
- F012: Custom painter and decoration hooks (`SwipePaintingConfig`, `SwipeMorphIcon`, `SwipeParticlePainter`)
- F013: Multi-zone swipe with per-zone backgrounds, thresholds, and transition styles (`SwipeZone`)
- F014: Prebuilt zero-config templates: `SwipeActionCell.delete`, `.archive`, `.favorite`, `.checkbox`, `.counter`, `.standard`
- F015: Consumer testing utilities: `SwipeTester`, `SwipeAssertions`, `MockSwipeController`, `SwipeTestHarness`

## [0.1.0-beta.1]

- **Breaking Change**: Consolidated SwipeActionCell configuration into dedicated configuration objects.

  **Parameter renames** (widget constructor):
  - `rightSwipe: ProgressiveSwipeConfig(...)` → `rightSwipeConfig: RightSwipeConfig(...)`
  - `leftSwipe: IntentionalSwipeConfig(...)` → `leftSwipeConfig: LeftSwipeConfig(...)`
  - `leftBackground`, `rightBackground`, `clipBehavior`, `borderRadius` → `visualConfig: SwipeVisualConfig(...)`

  **Type renames** (find-and-replace in your codebase):
  - `ProgressiveSwipeConfig` → `RightSwipeConfig`
  - `IntentionalSwipeConfig` → `LeftSwipeConfig`

- **New Feature**: Added `SwipeActionCellTheme` as a `ThemeExtension` for app-wide default configurations.
- **New Feature**: Added `SwipeController` for future programmatic interaction (behavior reserved for next release).
- **New Feature**: Added preset constructors for tuning gesture feel and animation character:
  - `SwipeGestureConfig.tight()` and `SwipeGestureConfig.loose()`
  - `SwipeAnimationConfig.snappy()` and `SwipeAnimationConfig.smooth()`
- Improved haptic feedback integration for both left and right swipes.

## [0.0.1]

- Initial project setup
- Core data models: `SwipeDirection`, `SwipeState`, `SwipeProgress`
- Widget skeleton: `SwipeActionCell` (no swipe behavior yet)

## 0.0.1

- Initial project setup
- Core data models: `SwipeDirection`, `SwipeState`, `SwipeProgress`
- Widget skeleton: `SwipeActionCell` (no swipe behavior yet)

## 0.1.0

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

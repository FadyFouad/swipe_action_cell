## 0.0.1

- Initial project setup
- Core data models: `SwipeDirection`, `SwipeState`, `SwipeProgress`
- Widget skeleton: `SwipeActionCell` (no swipe behavior yet)

## 0.1.0

- **Breaking Change**: Consolidated SwipeActionCell configuration into dedicated configuration objects.
  - leftSwipe -> leftSwipeConfig (type LeftSwipeConfig)
  - rightSwipe -> rightSwipeConfig (type RightSwipeConfig)
  - leftBackground, rightBackground, clipBehavior, borderRadius -> visualConfig (type SwipeVisualConfig)
- **New Feature**: Added SwipeActionCellTheme inherited widget for providing default configurations across the widget tree.
- **New Feature**: Added SwipeController for future programmatic interaction.
- **New Feature**: Added presets for configuration types:
  - SwipeGestureConfig.tight() and SwipeGestureConfig.loose()
  - SwipeAnimationConfig.snappy() and SwipeAnimationConfig.smooth()
- Improved haptic feedback integration for both left and right swipes.

# swipe_action_cell

> 🚧 **Under Development** — not yet published to pub.dev

A highly configurable Flutter swipe interaction widget with asymmetric left/right semantics:

- **Right swipe (forward):** Progressive/incremental action (e.g., increment a counter, increase progress)
- **Left swipe (backward):** Intentional committed action (e.g., delete, archive, reveal action buttons)

## Feature Roadmap

### Phase 1 — Core

- [ ] F1: Horizontal drag detection & direction discrimination
- [ ] F2: Spring-based animation & snap-back/completion
- [ ] F5: Background builders & progress-linked transitions
- [ ] F3: Right swipe — incremental value tracking (progressive)
- [ ] F4: Left swipe — auto-trigger & reveal modes (intentional)

### Phase 2 — Production Ready

- [ ] F6: Consolidated configuration API
- [ ] F9: Gesture arena & scroll conflict resolution
- [ ] F7: `SwipeController` & group coordination
- [ ] F8: Accessibility (semantics, keyboard nav, motion sensitivity)

### Phase 3 — Advanced

- [ ] F10: Performance optimisations & large-list support
- [ ] F11: Haptic patterns & audio hooks
- [ ] F12: Undo lifecycle & revert support
- [ ] F13: Custom painter & decoration hooks

### Phase 4 — Polish

- [ ] F14: Prebuilt zero-config templates
- [ ] F15: RTL & localisation support
- [ ] F16: Theme integration
- [ ] F17: Migration guide & stable API

## Installation

```yaml
# Not yet published — add via path dependency for local development:
dependencies:
  swipe_action_cell:
    path: ../swipe_action_cell
```

## Usage

```dart
// TODO: Usage examples will be added when swipe behaviour is implemented (F1+).
SwipeActionCell(
  child: ListTile(title: Text('Swipeable item')),
)
```

## License

MIT

# Quickstart: Consolidated Configuration API & Theme Support (F005)

**Branch**: `005-config-api` | **Package**: `swipe_action_cell`

---

## Migration from F001–F004

F005 is a **breaking API refactor**. Two types are renamed, four top-level widget parameters move
into a config object, and `gestureConfig`/`animationConfig` become nullable. Follow this guide to
update existing usage.

### Step 1 — Rename config types

| Old name | New name |
|----------|----------|
| `ProgressiveSwipeConfig` | `RightSwipeConfig` |
| `IntentionalSwipeConfig` | `LeftSwipeConfig` |

Find-and-replace across your project. All fields inside these types are identical.

### Step 2 — Rename widget parameters

| Old parameter | New parameter |
|---------------|---------------|
| `rightSwipe:` | `rightSwipeConfig:` |
| `leftSwipe:` | `leftSwipeConfig:` |
| `gestureConfig:` (non-null) | `gestureConfig:` (nullable — same effect) |
| `animationConfig:` (non-null) | `animationConfig:` (nullable — same effect) |

### Step 3 — Move visual parameters into `SwipeVisualConfig`

```dart
// Before (F001–F004)
SwipeActionCell(
  leftBackground: (ctx, p) => ColoredBox(color: Colors.red),
  rightBackground: (ctx, p) => ColoredBox(color: Colors.green),
  clipBehavior: Clip.antiAlias,
  borderRadius: BorderRadius.circular(8),
  child: MyListTile(),
)

// After (F005)
SwipeActionCell(
  visualConfig: SwipeVisualConfig(
    leftBackground: (ctx, p) => ColoredBox(color: Colors.red),
    rightBackground: (ctx, p) => ColoredBox(color: Colors.green),
    clipBehavior: Clip.antiAlias,
    borderRadius: BorderRadius.circular(8),
  ),
  child: MyListTile(),
)
```

---

## Minimal Examples

### Zero-configuration (all defaults)

```dart
SwipeActionCell(
  rightSwipeConfig: RightSwipeConfig(
    onSwipeCompleted: (value, previous) => print('Value: $value'),
  ),
  child: ListTile(title: Text('Swipe right')),
)
```

### Left swipe — auto-trigger delete

```dart
SwipeActionCell(
  visualConfig: SwipeVisualConfig(
    leftBackground: (ctx, progress) => ColoredBox(
      color: Colors.red,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.only(right: 16),
          child: Icon(Icons.delete, color: Colors.white),
        ),
      ),
    ),
  ),
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.autoTrigger,
    postActionBehavior: PostActionBehavior.animateOut,
    enableHaptic: true,
    onActionTriggered: () => deleteItem(item),
  ),
  child: ListTile(title: Text(item.title)),
)
```

### Left swipe — reveal action panel

```dart
SwipeActionCell(
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.reveal,
    actions: [
      SwipeAction(
        icon: const Icon(Icons.archive),
        label: 'Archive',
        backgroundColor: const Color(0xFF43A047),
        foregroundColor: Colors.white,
        onTap: () => archiveItem(item),
      ),
      SwipeAction(
        icon: const Icon(Icons.delete),
        label: 'Delete',
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        onTap: () => deleteItem(item),
        isDestructive: true,
      ),
    ],
  ),
  child: ListTile(title: Text(item.title)),
)
```

### Bidirectional with both directions

```dart
SwipeActionCell(
  rightSwipeConfig: RightSwipeConfig(
    onSwipeCompleted: (value, previous) => print('Incremented to $value'),
  ),
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.autoTrigger,
    onActionTriggered: () => print('Left action fired'),
  ),
  child: ListTile(title: Text('Both directions')),
)
```

---

## Preset Constructors

Use presets when you want a sensible configuration without tuning individual values.

### Gesture presets

```dart
// loose() — responds to short, light swipes (low dead zone)
SwipeActionCell(
  gestureConfig: SwipeGestureConfig.loose(),
  rightSwipeConfig: RightSwipeConfig(...),
  child: MyListTile(),
)

// tight() — requires deliberate, longer swipes (high dead zone)
SwipeActionCell(
  gestureConfig: SwipeGestureConfig.tight(),
  leftSwipeConfig: LeftSwipeConfig(mode: LeftSwipeMode.autoTrigger, ...),
  child: MyListTile(),
)
```

### Animation presets

```dart
// snappy() — fast, decisive animations (delete/archive feel)
SwipeActionCell(
  animationConfig: SwipeAnimationConfig.snappy(),
  leftSwipeConfig: LeftSwipeConfig(mode: LeftSwipeMode.autoTrigger, ...),
  child: MyListTile(),
)

// smooth() — gradual, soft animations (progress/reveal feel)
SwipeActionCell(
  animationConfig: SwipeAnimationConfig.smooth(),
  rightSwipeConfig: RightSwipeConfig(...),
  child: MyListTile(),
)
```

### Combining preset + custom value

```dart
SwipeActionCell(
  gestureConfig: SwipeGestureConfig.tight().copyWith(deadZone: 30.0),
  child: MyListTile(),
)
```

---

## App-Wide Defaults via `SwipeActionCellTheme`

Install once at the app root. Every `SwipeActionCell` in the tree inherits the configured
defaults without any per-cell code.

```dart
MaterialApp(
  theme: ThemeData(
    extensions: [
      SwipeActionCellTheme(
        gestureConfig: SwipeGestureConfig.loose(),
        animationConfig: SwipeAnimationConfig.smooth(),
        visualConfig: SwipeVisualConfig(
          clipBehavior: Clip.antiAlias,
        ),
      ),
    ],
  ),
  home: MyListScreen(),
)
```

### Per-cell override (replaces the theme config entirely for that parameter)

```dart
// All cells use SwipeGestureConfig.loose() from the theme above,
// except this one which uses tight():
SwipeActionCell(
  gestureConfig: SwipeGestureConfig.tight(),  // overrides theme
  rightSwipeConfig: RightSwipeConfig(...),
  child: MyListTile(),
)
```

### Partial override via `copyWith`

```dart
SwipeActionCell(
  gestureConfig: SwipeActionCellTheme.maybeOf(context)
      ?.gestureConfig
      ?.copyWith(deadZone: 8.0),  // inherits velocity threshold from theme
  child: MyListTile(),
)
```

---

## Disabling a Swipe Direction

Pass `null` (or omit) to disable a direction with zero overhead:

```dart
SwipeActionCell(
  rightSwipeConfig: null,  // no right-swipe behavior
  leftSwipeConfig: LeftSwipeConfig(
    mode: LeftSwipeMode.autoTrigger,
    onActionTriggered: () => deleteItem(item),
  ),
  child: MyListTile(),
)
```

---

## API Summary

| Type | Role |
|------|------|
| `RightSwipeConfig` | Right-swipe progressive behavior (renamed from `ProgressiveSwipeConfig`) |
| `LeftSwipeConfig` | Left-swipe intentional behavior (renamed from `IntentionalSwipeConfig`) |
| `SwipeGestureConfig` | Gesture recognition parameters + `tight()`/`loose()` presets |
| `SwipeAnimationConfig` | Spring physics parameters + `snappy()`/`smooth()` presets |
| `SwipeVisualConfig` | Background builders, clip behavior, border radius |
| `SwipeActionCellTheme` | App-level defaults via `ThemeData.extensions` |
| `SwipeController` | Reserved for F007; currently no-op |

---

## See Also

- `spec.md` — Full feature specification and user scenarios
- `data-model.md` — Entity definitions and field reference
- `contracts/config-api.md` — Complete Dart API signatures
- `research.md` — Technical decisions and rationale

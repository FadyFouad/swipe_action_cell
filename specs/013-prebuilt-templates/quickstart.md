# Quickstart: Prebuilt Zero-Configuration Templates (F014)

**Branch**: `013-prebuilt-templates` | **Date**: 2026-03-01

These test scenarios map directly to the acceptance criteria in `spec.md` and the user hint.

---

## Scenario 1 — Delete Template: Undo Flow (US1)

### Widget
```dart
// Minimal usage — only required params
SwipeActionCell.delete(
  child: const ListTile(title: Text('Delete me')),
  onDeleted: () => print('Item deleted!'),
)
```

### What to verify
- [ ] **T001**: Left swipe past threshold → cell animates off-screen, undo strip appears
- [ ] **T002**: Undo strip tap within 5 s → cell snaps back, `onDeleted` NOT called
- [ ] **T003**: Undo strip expires (5 s without interaction) → `onDeleted` fires exactly once
- [ ] **T004**: Right swipe → completely ignored (no gesture recognized)
- [ ] **T005**: No additional configuration required — renders with red background and trash icon

---

## Scenario 2 — Archive Template: Immediate Fire (US1)

### Widget
```dart
SwipeActionCell.archive(
  child: const ListTile(title: Text('Archive me')),
  onArchived: () => print('Item archived!'),
)
```

### What to verify
- [ ] **T006**: Left swipe past threshold → cell animates off-screen, `onArchived` fires immediately
- [ ] **T007**: No undo strip appears — archive has no undo by design
- [ ] **T008**: Right swipe → completely ignored
- [ ] **T009**: Renders with teal background and archive icon out of the box

---

## Scenario 3 — Favorite Template: Icon Morphing (US2)

### Widget
```dart
// Start unfavorited
SwipeActionCell.favorite(
  child: const ListTile(title: Text('Favorite me')),
  isFavorited: false,
  onToggle: (newState) => print('Favorited: $newState'),
)
```

### What to verify
- [ ] **T010**: Right swipe (unfavorited) → `onToggle(true)` fires; filled heart visible at completion
- [ ] **T011**: Right swipe (favorited, rebuilt with `isFavorited: true`) → `onToggle(false)` fires
- [ ] **T012**: At 50% drag progress → heart icon is visually halfway between outline and filled (equal opacity)
- [ ] **T013**: At 0% progress → only outline heart visible; at 100% → only filled heart visible
- [ ] **T014**: Left swipe → completely ignored

---

## Scenario 4 — Checkbox Template: Toggle Complete (US2)

### Widget
```dart
SwipeActionCell.checkbox(
  child: const ListTile(title: Text('Task item')),
  isChecked: false,
  onChanged: (newState) => print('Checked: $newState'),
)
```

### What to verify
- [ ] **T015**: Right swipe (unchecked) → `onChanged(true)` fires; checked indicator visible
- [ ] **T016**: Right swipe (checked) → `onChanged(false)` fires; unchecked indicator visible
- [ ] **T017**: Indicator transitions smoothly proportional to progress (not a jump)

---

## Scenario 5 — Counter Template: Max Value Enforcement (US3)

### Widget
```dart
// Counter with max
SwipeActionCell.counter(
  child: const ListTile(title: Text('Count: 3')),
  count: 3,
  onCountChanged: (newCount) => print('New count: $newCount'),
  max: 5,
)
```

### What to verify
- [ ] **T018**: Right swipe at `count = 3` → `onCountChanged(4)` fires
- [ ] **T019**: Right swipe at `count = 4` → `onCountChanged(5)` fires
- [ ] **T020**: Right swipe at `count = 5` (== max) → NO gesture recognized, `onCountChanged` NOT fired
- [ ] **T021**: Current count value visible in background during active drag
- [ ] **T022**: `max: null` → counter increments indefinitely

---

## Scenario 6 — Standard Template: Composite Behavior (US4)

### Widget
```dart
SwipeActionCell.standard(
  child: const ListTile(title: Text('Mail item')),
  onFavorited: (isFav) => print('Favorited: $isFav'),
  isFavorited: false,
  actions: [
    SwipeAction(
      icon: const Icon(Icons.reply, color: Colors.white),
      label: 'Reply',
      backgroundColor: Colors.blue,
      onTap: () => print('Reply tapped'),
    ),
    SwipeAction(
      icon: const Icon(Icons.more_horiz, color: Colors.white),
      label: 'More',
      backgroundColor: Colors.grey,
      onTap: () => print('More tapped'),
    ),
  ],
)
```

### What to verify
- [ ] **T023**: Right swipe → `onFavorited` fires with toggled state
- [ ] **T024**: Left swipe past threshold → reveal panel slides in with both action buttons
- [ ] **T025**: Tap action button → its `onTap` fires
- [ ] **T026**: `onFavorited: null` → right swipe completely disabled
- [ ] **T027**: `actions: []` or `actions: null` → left swipe completely disabled
- [ ] **T028**: Both null/empty → plain non-interactive wrapper (no gestures)

---

## Scenario 7 — Platform Detection (US5)

### Widget (same for both sub-scenarios)
```dart
// No style override — auto-detect
SwipeActionCell.delete(
  child: const ListTile(title: Text('Platform auto')),
  onDeleted: () {},
)
```

### What to verify
- [ ] **T029**: On Android/web/desktop → Material icons (`Icons.delete_outline`), sharp clip (`Clip.hardEdge`), no border radius
- [ ] **T030**: On iOS/macOS → Cupertino icons (`CupertinoIcons.trash`), antiAlias clip, rounded corners (`BorderRadius.circular(12)`)
- [ ] **T031**: Same unmodified widget used in both cases — no parameter change needed

---

## Scenario 8 — Style Override (US5)

### Widgets
```dart
// Force Material on iOS
SwipeActionCell.deleteMaterial(
  child: const ListTile(title: Text('Force Material')),
  onDeleted: () {},
)

// Force Cupertino on Android
SwipeActionCell.deleteCupertino(
  child: const ListTile(title: Text('Force Cupertino')),
  onDeleted: () {},
)

// Equivalent using style param
SwipeActionCell.delete(
  child: const ListTile(title: Text('Force Cupertino (style param)')),
  onDeleted: () {},
  style: TemplateStyle.cupertino,
)
```

### What to verify
- [ ] **T032**: `deleteMaterial` on iOS → Material icon (`Icons.delete_outline`), sharp clip
- [ ] **T033**: `deleteCupertino` on Android → Cupertino icon (`CupertinoIcons.trash`), rounded clip
- [ ] **T034**: `style: TemplateStyle.cupertino` is equivalent to `deleteCupertino`

---

## Scenario 9 — Templates Return Standard `SwipeActionCell` (SC-013-005)

### Test (unit/type check)
```dart
final cell = SwipeActionCell.delete(
  child: const SizedBox(),
  onDeleted: () {},
);
assert(cell is SwipeActionCell); // Must be true, not a subtype
assert(cell.runtimeType == SwipeActionCell); // Must be exactly SwipeActionCell
```

### What to verify
- [ ] **T035**: `cell is SwipeActionCell` → `true`
- [ ] **T036**: `cell.runtimeType == SwipeActionCell` → `true` (no subclass)
- [ ] **T037**: Cell can be assigned to `SwipeActionCell` typed variable without cast

---

## Scenario 10 — Color + Icon Override (FR-013-007)

### Widget
```dart
SwipeActionCell.delete(
  child: const ListTile(title: Text('Custom color/icon')),
  onDeleted: () {},
  backgroundColor: Colors.purple,
  icon: const Icon(Icons.block, color: Colors.white),
  semanticLabel: 'Block item',
)
```

### What to verify
- [ ] **T038**: Background is purple (not red) — color override takes effect
- [ ] **T039**: Block icon shown (not trash) — icon override takes effect
- [ ] **T040**: `semanticLabel` reads as "Block item" in accessibility tree
- [ ] **T041**: No crash with custom color + default platform icon (partial override)

---

## Scenario 11 — Semantic Labels + RTL (FR-013-011, SC-013-003)

### Widget
```dart
// Wrap in RTL directionality
Directionality(
  textDirection: TextDirection.rtl,
  child: SwipeActionCell.delete(
    child: const ListTile(title: Text('RTL item')),
    onDeleted: () {},
  ),
)
```

### What to verify
- [ ] **T042**: Default semantic label present in accessibility tree (`"Delete item"`)
- [ ] **T043**: In RTL: left physical swipe direction maps to the delete action (direction semantics reversed)
- [ ] **T044**: No crash, no visual artifacts in RTL layout

---

## Scenario 12 — Works Without Theme Ancestors (SC-013-006)

### Widget (no MaterialApp / CupertinoApp wrapper)
```dart
// Bare widget test — no MaterialApp, no CupertinoApp, no providers
await tester.pumpWidget(
  Directionality(
    textDirection: TextDirection.ltr,
    child: SwipeActionCell.delete(
      child: const SizedBox(height: 56, child: Text('No theme')),
      onDeleted: () {},
    ),
  ),
);
```

### What to verify
- [ ] **T045**: Widget renders without exception in a bare `Directionality` wrapper
- [ ] **T046**: Swipe gesture recognizes and fires `onDeleted` correctly with no theme ancestor
- [ ] **T047**: No `Theme.of(context)` call fails — platform detection uses `defaultTargetPlatform` only

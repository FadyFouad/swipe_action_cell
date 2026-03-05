# Quickstart: Documentation and pub.dev Release (F016)

**Branch**: `015-pubdev-release` | **Date**: 2026-03-01

These scenarios map directly to the acceptance criteria in `spec.md`. Each scenario can be verified independently.

---

## Scenario 1 — Quick Start in README (US1, SC-015-001)

### What to verify

Copy the Quick Start code sample from `README.md` into a blank Flutter app's `main.dart`. Run it.

```dart
// The README quick start code must compile and render in this minimal scaffold:
import 'package:flutter/material.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() => runApp(MaterialApp(
  home: Scaffold(
    body: SwipeActionCell.delete(
      child: const ListTile(title: Text('Swipe me left to delete')),
      onDeleted: () => debugPrint('Deleted!'),
    ),
  ),
));
```

- [ ] Compiles with zero errors
- [ ] Renders a visible `ListTile` on screen
- [ ] Left swipe triggers the undo strip
- [ ] After undo window expires, `onDeleted` is called

---

## Scenario 2 — README renders correctly on pub.dev (US1)

### What to verify

Open `README.md` in a markdown renderer (GitHub preview or pub.dev preview).

- [ ] Both image tags render images (even if they are tiny placeholder PNGs)
- [ ] All code blocks are syntax-highlighted
- [ ] The platform support table shows 6 rows with checkmarks
- [ ] The comparison table shows ≥ 5 rows with content in both columns
- [ ] No "beta" or "WIP" language is visible

---

## Scenario 3 — Example App Launches (US2, SC-015-002)

### What to verify

```bash
cd example/
flutter pub get
flutter run
```

- [ ] App launches in under 10 seconds (first run)
- [ ] `TabBar` is visible with 8 tabs
- [ ] Scrolling the tab bar reveals tabs beyond the visible screen width
- [ ] Tapping each tab navigates to the corresponding screen
- [ ] No "No MediaQuery ancestor" or "No Material ancestor" errors in console

---

## Scenario 4 — Basic Screen (US2)

On the Basic screen:

- [ ] A single `SwipeActionCell` is visible
- [ ] Right drag shows progressive feedback (color change or icon morph)
- [ ] Left drag triggers delete or auto-trigger action
- [ ] Comments in `basic_screen.dart` explain the `leftSwipeConfig` and `rightSwipeConfig` setup

---

## Scenario 5 — List Demo Screen: Group Controller (US2)

On the List Demo screen:

- [ ] ≥ 50 list items are visible (scrollable list)
- [ ] Swiping item #1 to reveal its panel — then swiping item #2 — causes item #1 to close automatically
- [ ] A `SwipeGroupController` is used (visible in `list_demo_screen.dart` source)
- [ ] Swipe-to-delete shows the undo strip for 5 seconds before firing the delete callback

---

## Scenario 6 — RTL Screen (US2)

On the RTL screen:

- [ ] Arabic text is displayed in a list
- [ ] A physical LEFT swipe on an item triggers the RIGHT semantic action (e.g., progressive increment)
- [ ] A physical RIGHT swipe triggers the LEFT semantic action (e.g., delete)
- [ ] `Directionality(textDirection: TextDirection.rtl)` is visible in `rtl_screen.dart`

---

## Scenario 7 — Templates Screen (US2)

On the Templates screen:

- [ ] 6 separate `ListTile`s are shown, one per template type
- [ ] Each responds to swipe with the template's default behavior
- [ ] Labels identify which template is which (`SwipeActionCell.delete`, `.archive`, etc.)
- [ ] Source comments explain which factory constructor is used and why

---

## Scenario 8 — Dartdoc Coverage (US3, SC-015-003)

```bash
flutter analyze lib/ --fatal-warnings
```

- [ ] Exit code is 0
- [ ] Zero `Missing documentation for a public member` warnings
- [ ] Zero other warnings or errors

### Spot-check: hover in IDE

- [ ] Hovering over `SwipeState.revealed` shows a non-empty tooltip
- [ ] Hovering over `SwipeController.openLeft()` shows description + usage note
- [ ] Hovering over `SwipeTester.swipeLeft` shows description + example
- [ ] Hovering over `SwipeActionCell.delete` shows description + code example

---

## Scenario 9 — MIGRATION.md: Basic Reveal (US4, SC-015-004)

Starting from this `flutter_slidable` code:

```dart
Slidable(
  endActionPane: ActionPane(
    motion: const ScrollMotion(),
    children: [
      SlidableAction(
        onPressed: (_) => archive(item),
        icon: Icons.archive,
        label: 'Archive',
      ),
    ],
  ),
  child: ListTile(title: Text(item.title)),
)
```

Using ONLY `MIGRATION.md`:

- [ ] Developer can identify `endActionPane` maps to `leftSwipeConfig`
- [ ] Developer can identify `SlidableAction` maps to `SwipeAction` inside `LeftSwipeConfig.actions`
- [ ] The resulting `swipe_action_cell` code compiles and shows an archive button on left swipe

---

## Scenario 10 — Publish Dry-Run (US5, SC-015-007)

```bash
flutter pub publish --dry-run
```

- [ ] Exit code is 0
- [ ] No `ERROR` lines in output
- [ ] No `WARNING` lines in output
- [ ] `Package validation passed.` message is shown (or equivalent clean exit)

---

## Scenario 11 — pubspec.yaml Metadata (US5)

```bash
cat pubspec.yaml | grep -E 'version|description|homepage|repository|issue_tracker'
```

- [ ] `version: 1.0.0` (no pre-release suffix)
- [ ] `description` is present, 60–180 characters
- [ ] `homepage:` is present with a valid URL
- [ ] `repository:` is present with a valid URL
- [ ] `issue_tracker:` is present with a valid URL

---

## Scenario 12 — Single README Code Sample Compiles (SC-015-006)

Take each `dart` code block in `README.md` and paste it into the example app. Run `flutter analyze example/`.

- [ ] Every code sample compiles without errors
- [ ] No `undefined_identifier` or `wrong_number_of_type_arguments` errors

---

## Scenario 13 — CHANGELOG Format (US5)

Open `CHANGELOG.md`:

- [ ] First entry is `## [1.0.0] - YYYY-MM-DD`
- [ ] Under `### Added`, 15 bullet points list F001–F015
- [ ] Existing `0.1.0-beta.1` and `0.0.1` entries are present below
- [ ] No other sections (`### Changed`, `### Fixed`) appear in the 1.0.0 entry

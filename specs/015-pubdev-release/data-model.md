# Data Model: Documentation and pub.dev Release (F016)

**Branch**: `015-pubdev-release` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)

---

## Overview

This feature does not introduce new Dart types or data classes. The "entities" are the human-readable deliverable documents and the example app screen registry. This file documents their required structure and content constraints.

---

## Deliverable 1: `README.md` (root)

**Location**: `README.md` (repository root, replaces current beta placeholder)

| Section | Required | Content |
|---|---|---|
| Badges | Yes | pub.dev version badge, MIT license badge, platform support badge |
| Hero tagline | Yes | ≤ 2 sentences; mentions asymmetric swipe semantics |
| Animated demos | Yes | 2 `![...]` image tags → `doc/assets/demo-delete.gif` + `doc/assets/demo-reveal.gif` |
| Features list | Yes | 8 bullet points covering the package's key capabilities |
| Quick Start | Yes | Code sample ≤ 5 lines; compilable; demonstrates left-swipe delete cell |
| Installation | Yes | `flutter pub add swipe_action_cell` command |
| Platform Support | Yes | Table: iOS / Android / Web / macOS / Windows / Linux; min Flutter version noted |
| Configuration Reference | Yes | Table of all top-level parameters with type and default value |
| vs flutter_slidable | Yes | Comparison table ≥ 5 dimensions |
| Links | Yes | pub.dev API reference URL, GitHub example app link |

**Constraints**:
- Total word count: ≤ 1500 words (scannable, not a tutorial)
- All code samples must compile against the package
- No "under development" or "beta" language — this is the 1.0.0 release README

---

## Deliverable 2: Example App Screen Registry

**Location**: `example/lib/screens/` (new directory)

8 screen widgets, one per file:

| # | File | Tab Label | Demonstrates | Key Config |
|---|---|---|---|---|
| 1 | `basic_screen.dart` | Basic | Simple left+right swipe on a single cell | `LeftSwipeConfig(mode: autoTrigger)` + `RightSwipeConfig` |
| 2 | `counter_screen.dart` | Counter | Right-swipe increment with animated progress bar | `RightSwipeConfig(onSwipeCompleted: ...)` + `rightBackground` with `LinearProgressIndicator` |
| 3 | `reveal_actions_screen.dart` | Reveal | Left swipe reveals Archive + Delete buttons | `LeftSwipeConfig(mode: reveal, actions: [SwipeAction(...), SwipeAction(...)])` |
| 4 | `multi_threshold_screen.dart` | Multi-Zone | Different actions at 30%, 60%, 90% drag distance | `RightSwipeConfig` with multiple thresholds |
| 5 | `custom_visuals_screen.dart` | Custom | Custom painter, decoration, particle effect on swipe | `SwipeVisualConfig`, `SwipeMorphIcon`, custom `rightBackground` |
| 6 | `list_demo_screen.dart` | List Demo | 50+ items, group controller (accordion), undo | `SwipeGroupController`, `SwipeActionCell.delete(...)`, undo strip |
| 7 | `rtl_screen.dart` | RTL | Arabic text, RTL layout, reversed swipe semantics | `Directionality(textDirection: TextDirection.rtl, ...)` wrapping cells |
| 8 | `templates_screen.dart` | Templates | All 6 prebuilt templates in a list | `SwipeActionCell.delete`, `.archive`, `.favorite`, `.checkbox`, `.counter`, `.standard` |

**`main.dart` structure**:
```
MaterialApp
└── DefaultTabController(length: 8)
    └── Scaffold
        └── AppBar(
              title: Text('SwipeActionCell Demo'),
              bottom: TabBar(
                isScrollable: true,
                tabs: [Tab(text: 'Basic'), ..., Tab(text: 'Templates')],
              ),
            )
        └── body: TabBarView(
              children: [BasicScreen(), ..., TemplatesScreen()],
            )
```

**Constraints**:
- No network calls, API keys, or external assets
- Each screen is `StatefulWidget` or `StatelessWidget` only — no external state management packages
- Each screen file has comments explaining non-obvious configuration choices (FR-015-013)
- All screens compile with `flutter analyze example/` → zero issues

---

## Deliverable 3: `CHANGELOG.md` (root)

**Location**: `CHANGELOG.md` (existing file, prepend new entry)

Format: keepachangelog.com

```
## [1.0.0] - 2026-03-01
### Added
  - [15 feature lines — see research.md D8]

## [0.1.0-beta.1] - (existing entry, unchanged)
## [0.0.1] - (existing entry, unchanged)
```

**Constraints**:
- Must appear at the top of the file (newest version first)
- Only the `### Added` category is needed (this is an initial public release)
- Date must match the actual publish date (placeholder: 2026-03-01)

---

## Deliverable 4: `MIGRATION.md` (root)

**Location**: `MIGRATION.md` (new file at repository root)

| Section | Content |
|---|---|
| Overview | 2-paragraph summary: asymmetric model, undo, group controller |
| Installation | Before: `flutter_slidable: ^3.x` / After: `swipe_action_cell: ^1.0.0` |
| API Mapping Table | 7-row table (Slidable → SwipeActionCell, etc.) |
| Behavioral Differences | 5 bullet points |
| Before/After Example 1 | Basic slide action (archive button on left) |
| Before/After Example 2 | Delete with dismiss (flutter_slidable) vs delete with undo (swipe_action_cell) |
| Not available in swipe_action_cell | Explicit list with workarounds |
| Not available in flutter_slidable | Explicit list (package's unique features) |

**Key API mapping** (from research.md D6):

| flutter_slidable (v3.x) | swipe_action_cell (v1.0.0) |
|---|---|
| `Slidable(child: ...)` | `SwipeActionCell(child: ...)` |
| `ActionPane(extentRatio: 0.25, motion: ..., children: [SlidableAction(...)])` | `LeftSwipeConfig(mode: reveal, actions: [SwipeAction(...)])` |
| `ActionPane` on `startActionPane` | `RightSwipeConfig(...)` |
| `ActionPane` on `endActionPane` | `LeftSwipeConfig(...)` |
| `SlidableController` | `SwipeController` |
| `SlidableAutoCloseBehavior` | `SwipeGroupController` |
| `DismissiblePane(onDismissed: ...)` | `LeftSwipeConfig(mode: autoTrigger)` + `SwipeUndoConfig(onUndoExpired: ...)` |

**Not available in swipe_action_cell** (honest limitations):
- `BehindMotionAnimation`, `DrawerMotion`, `ScrollMotion` (motion types) — swipe_action_cell uses fixed reveal; no animated panel motion during drag
- Custom extentRatio per-action — all actions share the reveal panel width
- `SlidableAction.autoClose` — closing is managed by `SwipeGroupController`

**Not available in flutter_slidable** (unique to swipe_action_cell):
- Progressive right-swipe with value tracking and threshold callbacks
- Built-in undo window (`SwipeUndoConfig`) for destructive actions
- Spring-based physics (vs fixed-duration animation)
- Prebuilt zero-config templates (`SwipeActionCell.delete`, `.archive`, etc.)
- Consumer testing utilities (`SwipeTester`, `SwipeAssertions`, etc.)
- Multi-threshold swipe zones

---

## Deliverable 5: `doc/assets/` — Placeholder GIFs

**Location**: `doc/assets/` (new directory)

| File | Placeholder | Final content |
|---|---|---|
| `demo-delete.gif` | 1×1 transparent PNG at `.gif` extension | Screen recording of delete + undo flow |
| `demo-reveal.gif` | 1×1 transparent PNG at `.gif` extension | Screen recording of reveal actions flow |

README image tags:
```markdown
![Delete with undo](https://raw.githubusercontent.com/FadyFouad/swipe_action_cell/main/doc/assets/demo-delete.gif)
![Reveal actions](https://raw.githubusercontent.com/FadyFouad/swipe_action_cell/main/doc/assets/demo-reveal.gif)
```

---

## Modified Files

```text
README.md                                      ← REWRITTEN (full replacement)
CHANGELOG.md                                   ← MODIFIED (prepend 1.0.0 entry)
pubspec.yaml                                   ← MODIFIED (version: 1.0.0)
example/lib/main.dart                          ← MODIFIED (8 tabs, isScrollable)
```

## New Files

```text
MIGRATION.md                                   ← NEW (flutter_slidable migration guide)
doc/assets/
├── demo-delete.gif                            ← NEW (placeholder PNG)
└── demo-reveal.gif                            ← NEW (placeholder PNG)
example/lib/screens/
├── basic_screen.dart                          ← NEW
├── counter_screen.dart                        ← NEW
├── reveal_actions_screen.dart                 ← NEW
├── multi_threshold_screen.dart                ← NEW
├── custom_visuals_screen.dart                 ← NEW
├── list_demo_screen.dart                      ← NEW
├── rtl_screen.dart                            ← NEW
└── templates_screen.dart                      ← NEW
```

## Files to Audit (Dartdoc Completion)

Run `flutter analyze lib/` and fix all `public_member_api_docs` violations. High-risk areas:

```text
lib/src/core/           ← enum values on SwipeState, SwipeDirection, SwipeProgress
lib/src/config/         ← copyWith parameters on all config classes
lib/src/controller/     ← SwipeGroupController members
lib/src/templates/      ← factory constructor named parameters (F013)
lib/src/testing/        ← all 4 utility classes (F014)
lib/swipe_action_cell.dart  ← barrel-level doc comment
lib/testing.dart            ← library-level doc comment
```

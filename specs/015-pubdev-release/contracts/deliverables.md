# Deliverable Contracts: Documentation and pub.dev Release (F016)

**Branch**: `015-pubdev-release` | **Date**: 2026-03-01 | **Spec**: [spec.md](../spec.md)

This file defines the required content and structural contracts for each deliverable document and application component. These contracts are the acceptance criteria for implementation.

---

## Contract 1: `README.md`

### Required Sections (in order)

```markdown
# swipe_action_cell

[![pub.dev](…)](…) [![License: MIT](…)](…)

> <One-sentence tagline mentioning asymmetric swipe>

![Delete with undo](doc/assets/demo-delete.gif)
![Reveal actions](doc/assets/demo-reveal.gif)

## Features
- …(8 bullet points)…

## Quick Start
```dart
…(3-5 compilable lines)…
```

## Platform Support
| Platform | Support |
…

## Installation
```yaml
dependencies:
  swipe_action_cell: ^1.0.0
```

## Configuration Reference
| Parameter | Type | Default | Description |
…

## swipe_action_cell vs flutter_slidable
| Feature | swipe_action_cell | flutter_slidable |
…(≥5 rows)…

## Documentation & Links
- [API reference](…)
- [Example app](…)
```

### Constraints

| Rule | Requirement |
|---|---|
| Tagline length | ≤ 2 sentences |
| Quick Start code | 3–5 lines, compilable, no imports shown (assumed) |
| GIF assets | Both paths exist at `doc/assets/`; each placeholder PNG ≥ 1 byte |
| Platform table | All 6 rows present (iOS, Android, Web, macOS, Windows, Linux) |
| Comparison table | ≥ 5 feature rows; each row has non-empty cells in both package columns |
| Config reference | Covers at minimum: `child`, `leftSwipeConfig`, `rightSwipeConfig`, `controller`, `visualConfig` |
| No beta language | No "under development", "WIP", "coming soon" |
| Word count | ≤ 1500 words |

---

## Contract 2: Example App

### Navigation Contract

```dart
// main.dart skeleton
DefaultTabController(
  length: 8,
  child: Scaffold(
    appBar: AppBar(
      title: const Text('SwipeActionCell Demo'),
      bottom: const TabBar(
        isScrollable: true,
        tabs: [
          Tab(text: 'Basic'),
          Tab(text: 'Counter'),
          Tab(text: 'Reveal'),
          Tab(text: 'Multi-Zone'),
          Tab(text: 'Custom'),
          Tab(text: 'List'),
          Tab(text: 'RTL'),
          Tab(text: 'Templates'),
        ],
      ),
    ),
    body: const TabBarView(
      children: [
        BasicScreen(),
        CounterScreen(),
        RevealActionsScreen(),
        MultiThresholdScreen(),
        CustomVisualsScreen(),
        ListDemoScreen(),
        RtlScreen(),
        TemplatesScreen(),
      ],
    ),
  ),
)
```

### Per-Screen Contract

Each screen file MUST satisfy:

| Check | Requirement |
|---|---|
| Imports | Only `flutter/material.dart` + `swipe_action_cell/swipe_action_cell.dart` (no third-party) |
| Comments | ≥ 1 block comment per non-trivial config parameter |
| Compilation | `flutter analyze example/` reports zero issues for this file |
| Network | No `http`, `dio`, or any network call |
| Interaction | At least one `SwipeActionCell` is present and responds to drag gestures |

**Screen-specific required behavior**:

| Screen | Must demonstrate |
|---|---|
| Basic | Left drag → delete/action fires; Right drag → progressive action fires |
| Counter | Right drag increments a visible count; progress bar updates in real time |
| Reveal | Left drag reveals ≥ 2 labeled `SwipeAction` buttons; tapping each fires its callback |
| Multi-Zone | ≥ 2 distinct threshold levels with different visual feedback at each level |
| Custom | `SwipeMorphIcon` or custom `rightBackground` painter is rendered |
| List | ≥ 50 list items; opening one row closes previously open row (group controller) |
| RTL | Wrapped in `Directionality(textDirection: TextDirection.rtl)`; Arabic or RTL text label |
| Templates | All 6 factory constructors demonstrated: `.delete`, `.archive`, `.favorite`, `.checkbox`, `.counter`, `.standard` |

---

## Contract 3: `CHANGELOG.md`

### Format Contract

```markdown
# Changelog

All notable changes to this project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.0.0] - YYYY-MM-DD

### Added
- F001: <description>
…(15 lines total, one per feature F001–F015)…

## [0.1.0-beta.1] - <existing date>
<existing content, unchanged>

## [0.0.1] - <existing date>
<existing content, unchanged>
```

### Constraints

| Rule | Requirement |
|---|---|
| Order | Newest version at top |
| Version format | `[1.0.0]` (semantic, with brackets) |
| Categories used | Only `### Added` for the 1.0.0 entry (first public release) |
| Existing entries | Must be preserved verbatim below the new entry |
| Feature count | Exactly 15 Added bullet points (F001–F015) |

---

## Contract 4: `MIGRATION.md`

### Section Contract

```markdown
# Migrating from flutter_slidable to swipe_action_cell

## Overview
<2-paragraph summary>

## Installation
<before/after pubspec snippets>

## API Mapping
<table: 7 rows minimum>

## Behavioral Differences
<5 bullet points minimum>

## Code Examples

### Example 1: Basic reveal action
<before — flutter_slidable code block>
<after — swipe_action_cell code block>

### Example 2: Delete with undo
<before — flutter_slidable DismissiblePane code block>
<after — swipe_action_cell SwipeActionCell.delete code block>

## Features not in swipe_action_cell
<explicit list with workarounds>

## Features not in flutter_slidable
<explicit list>
```

### Constraints

| Rule | Requirement |
|---|---|
| "Before" code | Compiles with `flutter_slidable: ^3.0.0` |
| "After" code | Compiles with `swipe_action_cell: ^1.0.0` |
| API mapping | Covers every `flutter_slidable` public class used in its README |
| "Not available" sections | Both directions present; neither is empty |
| Tone | Factual, not disparaging of flutter_slidable |

---

## Contract 5: `pubspec.yaml` Metadata

### Required Fields

```yaml
name: swipe_action_cell
description: '<60-180 chars>'
version: 1.0.0
homepage: https://github.com/FadyFouad/swipe_action_cell
repository: https://github.com/FadyFouad/swipe_action_cell
issue_tracker: https://github.com/FadyFouad/swipe_action_cell/issues

environment:
  sdk: ">=3.4.0 <4.0.0"
  flutter: ">=3.22.0"
```

### Constraints

| Rule | Requirement |
|---|---|
| `version` | Exactly `1.0.0` (no pre-release suffix) |
| `description` | 60–180 characters including spaces |
| No `publish_to: none` | This field must be absent (or set to a registry URL) |
| `flutter_test` in `dependencies` | Already present (F014 requirement); must stay in `dependencies` (not dev_dependencies) |

---

## Contract 6: Dartdoc Coverage

### Coverage Requirements

`flutter analyze lib/` with `public_member_api_docs: true` MUST report zero violations.

Key symbols that MUST have non-empty `///` comments:

| Category | Examples |
|---|---|
| All enum values | `SwipeState.idle`, `SwipeState.revealed`, `LeftSwipeMode.reveal`, `LeftSwipeMode.autoTrigger` |
| All `copyWith` params | Every named param on `LeftSwipeConfig.copyWith`, `RightSwipeConfig.copyWith`, etc. |
| Factory constructors | `SwipeActionCell.delete`, `.archive`, `.favorite`, `.checkbox`, `.counter`, `.standard` |
| Testing utilities | `SwipeTester`, all its static methods; `SwipeAssertions` extension methods |
| Controller members | `SwipeController.openLeft`, `.openRight`, `.close`, `.undo`, `.currentState` |
| Barrel files | `lib/swipe_action_cell.dart` library-level comment; `lib/testing.dart` library-level comment |

### Code Example Requirements

These classes MUST have ≥ 1 dartdoc `///` code fence example:
- `SwipeActionCell` (main class + each factory constructor)
- `SwipeController`
- `SwipeGroupController`
- `SwipeTestHarness`
- `MockSwipeController`
- `LeftSwipeConfig`
- `RightSwipeConfig`

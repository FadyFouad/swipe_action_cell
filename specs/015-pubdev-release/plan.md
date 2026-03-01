# Implementation Plan: Documentation and pub.dev Release (F016)

**Branch**: `015-pubdev-release` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/015-pubdev-release/spec.md`

---

## Summary

Prepare the `swipe_action_cell` package for its `1.0.0` public release by delivering five artifacts: a complete `README.md` rewrite, an 8-screen interactive example app (with scrollable `TabBar` navigation), full dartdoc API coverage, a `flutter_slidable` migration guide (`MIGRATION.md`), and a `CHANGELOG.md` 1.0.0 entry — all while bumping the version to `1.0.0` and confirming `flutter pub publish --dry-run` exits clean.

---

## Technical Context

**Language/Version**: Dart ≥ 3.4.0 < 4.0.0 / Flutter ≥ 3.22.0
**Primary Dependencies**: Flutter SDK only (package); `swipe_action_cell: path: ../` (example app)
**Storage**: N/A — documentation and Dart source files only
**Testing**: `flutter analyze lib/ example/lib/` (zero warnings); `flutter pub publish --dry-run` (zero errors)
**Target Platform**: All Flutter-supported platforms (iOS, Android, Web, macOS, Windows, Linux)
**Performance Goals**: Example app launches in ≤ 10 seconds; 60 fps maintained in all demo interactions
**Constraints**: No new runtime deps; GIF placeholders committed at asset paths; no beta/WIP language in README; all code samples compile
**Scale/Scope**: 1 rewritten file (README.md), 1 modified file (pubspec.yaml), 1 modified file (CHANGELOG.md), 1 modified file (example/lib/main.dart), 3 new top-level files (MIGRATION.md, doc/assets/×2), 8 new example screen files

---

## Constitution Check

*GATE: Must pass before implementation. Re-check after Phase 1 design.*

| Principle | Status | Notes |
|---|---|---|
| I. Composition over Inheritance | ✅ PASS | Example app uses `SwipeActionCell` as a consumer — no new inheritance |
| II. Explicit State Machine | ✅ PASS | No new states; example app demonstrates existing state machine |
| III. Spring-Based Physics | ✅ PASS | No new animations; example app exercises existing spring system |
| IV. Zero External Runtime Deps | ✅ PASS | Package gains no new runtime dependencies; example app is a separate Flutter app with its own pubspec |
| V. Controlled/Uncontrolled Pattern | ✅ PASS | Example app demonstrates both modes (uncontrolled in Basic/Counter; controlled via `SwipeGroupController` in List Demo) |
| VI. Const-Friendly Configuration | ✅ PASS | No new config objects; example app uses `const` constructors throughout |
| VII. Test-First | ✅ PASS (scoped) | No new production API introduced; code sample correctness verified by `flutter analyze example/`; dartdoc examples tested as part of the example app which uses the full API |
| VIII. Dartdoc Everything | ✅ PASS | This feature IS the dartdoc completion story (US3); enforced by `public_member_api_docs` lint |
| IX. Null Config = Feature Disabled | ✅ PASS | No new config objects |
| X. 60 fps Budget | ✅ PASS | No new animation code; example app exercises existing optimized interactions |

No constitution violations. Proceed to implementation.

---

## Project Structure

### Documentation (this feature)

```text
specs/015-pubdev-release/
├── plan.md              ← This file
├── research.md          ← Phase 0 output (10 decisions D1–D10)
├── data-model.md        ← Phase 1 output (5 deliverables + audit list)
├── quickstart.md        ← Phase 1 output (13 verification scenarios)
├── contracts/
│   └── deliverables.md  ← Phase 1 output (6 content contracts)
└── tasks.md             ← Phase 2 output (/speckit.tasks)
```

### Source Code

```text
# Modified files
README.md                                      ← REWRITTEN
CHANGELOG.md                                   ← MODIFIED (prepend 1.0.0 entry)
pubspec.yaml                                   ← MODIFIED (version: 1.0.0)
example/lib/main.dart                          ← MODIFIED (8-tab scrollable TabBar)

# New files
MIGRATION.md                                   ← NEW
doc/
└── assets/
    ├── demo-delete.gif                        ← NEW (placeholder PNG)
    └── demo-reveal.gif                        ← NEW (placeholder PNG)

example/lib/screens/
├── basic_screen.dart                          ← NEW
├── counter_screen.dart                        ← NEW
├── reveal_actions_screen.dart                 ← NEW
├── multi_threshold_screen.dart                ← NEW
├── custom_visuals_screen.dart                 ← NEW
├── list_demo_screen.dart                      ← NEW
├── rtl_screen.dart                            ← NEW
└── templates_screen.dart                      ← NEW

# Dartdoc audit (no new files — edits to existing lib/ files as needed)
lib/src/core/           ← fix any missing enum value docs
lib/src/config/         ← fix any missing copyWith parameter docs
lib/src/controller/     ← fix any missing SwipeGroupController member docs
lib/src/templates/      ← fix any missing factory constructor parameter docs
lib/src/testing/        ← fix any missing testing utility docs
lib/swipe_action_cell.dart  ← verify library-level doc comment
lib/testing.dart            ← verify library-level doc comment
```

**Structure Decision**: Single Flutter package with a companion `example/` Flutter app. The example app is a separate Dart package (`example/pubspec.yaml`) with `swipe_action_cell: path: ../` dependency. New source files are organized by deliverable. No new directories are added to `lib/` — this feature is purely additive to existing public API documentation.

---

## Phase 0: Research Output

See [research.md](research.md) for all 10 architectural decisions (D1–D10).

Key decisions summary:
- **D1** Scrollable TabBar: expand existing 2-tab `main.dart` to 8 tabs with `isScrollable: true`
- **D2** pub.dev scoring: maximize all 5 automated categories; 140/160 target is achievable
- **D3** Version bump: `0.1.0-beta.1` → `1.0.0` in pubspec.yaml
- **D4** GIF placeholder: commit 1×1 transparent PNG at `.gif` paths; swap real GIFs pre-announcement
- **D5** README structure: badges → hero → GIFs → features → quick start → platforms → config ref → comparison → links
- **D6** MIGRATION.md: 7-row API table + 2 before/after examples + explicit "not available" sections
- **D7** Dartdoc audit: `flutter analyze lib/` with `public_member_api_docs: true`; focus on enum values, copyWith params, F013/F014 additions
- **D8** CHANGELOG: prepend 1.0.0 entry with 15 "### Added" bullets
- **D9** Platform support: declared via README table; no `platforms:` key in pubspec (pure Flutter widget package)
- **D10** Code sample verification: example app serves as compile verification; `flutter analyze example/` is the final gate

---

## Phase 1: Design Artifacts

- **Data Model**: [data-model.md](data-model.md) — 5 deliverables with structure, constraints, and modified/new file lists
- **Deliverable Contracts**: [contracts/deliverables.md](contracts/deliverables.md) — content contracts for README, example app, CHANGELOG, MIGRATION.md, pubspec, and dartdoc
- **Quickstart**: [quickstart.md](quickstart.md) — 13 verification scenarios covering all US and SCs

---

## Implementation Clusters

```
Cluster A ─────────────────────── Package Metadata Foundation
  TA01: Bump version to 1.0.0 in pubspec.yaml
  TA02: Prepend [1.0.0] entry to CHANGELOG.md
  TA03: Create doc/assets/ directory; commit placeholder PNGs as demo-delete.gif + demo-reveal.gif

Cluster B ─────────────────────── README.md [US1, after A]
  TB01: Rewrite README.md — hero tagline + GIF image tags + features list
  TB02: Add Quick Start code sample + Installation section
  TB03: Add Platform Support table + Configuration Reference table
  TB04: Add vs flutter_slidable comparison table + Documentation Links

Cluster C ─────────────────────── Dartdoc Audit [US3, parallel with B after A]
  TC01: Run flutter analyze lib/ — capture full list of public_member_api_docs violations
  TC02: Fix dartdoc violations in lib/src/core/ and lib/src/config/ (enum values, copyWith params)
  TC03: Fix dartdoc violations in lib/src/controller/, lib/src/templates/, lib/src/testing/
  TC04: Add code examples to primary-workflow classes (SwipeActionCell, SwipeController, SwipeGroupController, LeftSwipeConfig, RightSwipeConfig)
  TC05: Add code examples to testing utilities (SwipeTestHarness, MockSwipeController, SwipeTester)

Cluster D ─────────────────────── MIGRATION.md [US4, parallel with B+C after A]
  TD01: Write MIGRATION.md — Overview + Installation + API Mapping table
  TD02: Add Behavioral Differences + Before/After Example 1 (basic reveal action)
  TD03: Add Before/After Example 2 (delete with undo) + "Not available" sections

Cluster E ─────────────────────── Example App [US2, parallel with B+C+D after A]
  TE01: Update example/lib/main.dart — 8-tab scrollable TabBar + TabBarView
  TE02: Write basic_screen.dart + counter_screen.dart
  TE03: Write reveal_actions_screen.dart + multi_threshold_screen.dart
  TE04: Write custom_visuals_screen.dart + list_demo_screen.dart
  TE05: Write rtl_screen.dart + templates_screen.dart

Cluster F ─────────────────────── Verification + Polish [after B+C+D+E]
  TF01: Run flutter analyze lib/ example/lib/ — fix any remaining issues
  TF02: Run dart format --set-exit-if-changed . — fix any formatting
  TF03: Verify all 13 quickstart.md scenarios pass
  TF04: Run flutter pub publish --dry-run — fix any errors/warnings
```

**Dependency graph**:
```
A → B [parallel]
A → C [parallel with B]
A → D [parallel with B, C]
A → E [parallel with B, C, D]
B + C + D + E → F
```

---

## Key Implementation Notes

### pubspec.yaml Version Bump

```yaml
# Change:
version: 0.1.0-beta.1
# To:
version: 1.0.0
```

No other pubspec changes needed. `flutter_test` stays in `dependencies` (F014 requirement). Description is already 123 chars (within 60–180 limit).

### README.md Quick Start Code

The Quick Start must compile when placed in a fresh Flutter app. Use the delete template as it requires the fewest imports:

```dart
import 'package:swipe_action_cell/swipe_action_cell.dart';

// Inside a Scaffold body:
SwipeActionCell.delete(
  child: const ListTile(title: Text('Left swipe to delete')),
  onDeleted: () => print('Deleted!'),
)
```

### main.dart Scrollable TabBar

```dart
// example/lib/main.dart
import 'package:flutter/material.dart';
import 'screens/basic_screen.dart';
// ... 7 more imports ...

void main() => runApp(const SwipeActionCellExampleApp());

class SwipeActionCellExampleApp extends StatelessWidget {
  const SwipeActionCellExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SwipeActionCell Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo)),
      home: DefaultTabController(
        length: 8,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('SwipeActionCell Demo'),
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Basic'), Tab(text: 'Counter'),
                Tab(text: 'Reveal'), Tab(text: 'Multi-Zone'),
                Tab(text: 'Custom'), Tab(text: 'List'),
                Tab(text: 'RTL'), Tab(text: 'Templates'),
              ],
            ),
          ),
          body: const TabBarView(children: [
            BasicScreen(), CounterScreen(),
            RevealActionsScreen(), MultiThresholdScreen(),
            CustomVisualsScreen(), ListDemoScreen(),
            RtlScreen(), TemplatesScreen(),
          ]),
        ),
      ),
    );
  }
}
```

### Placeholder GIF (minimal PNG)

A 1×1 transparent PNG can be created as a binary file. The minimum valid PNG header is 67 bytes. Commit the same file at both `doc/assets/demo-delete.gif` and `doc/assets/demo-reveal.gif`. The `.gif` extension is used for the final filenames; the PNG binary is valid content that renders as a tiny transparent image on GitHub and pub.dev.

### List Demo Screen: Group Controller

```dart
// list_demo_screen.dart (key excerpt)
final _group = SwipeGroupController();

@override
void dispose() {
  _group.dispose();
  super.dispose();
}

Widget _buildItem(int index) => SwipeActionCell.delete(
  controller: _group.controllerFor(index),   // accordion behavior
  child: ListTile(title: Text('Item $index')),
  onDeleted: () => setState(() => _items.removeAt(index)),
);
```

### Dartdoc Code Example Pattern

For each primary-workflow class, add a `///` code example following the `package:flutter_test` dartdoc style:

```dart
/// Creates a cell with a delete action on left swipe.
///
/// The undo window shows a strip for 5 seconds before [onDeleted] fires.
///
/// ```dart
/// SwipeActionCell.delete(
///   child: const ListTile(title: Text('Email from Alice')),
///   onDeleted: () => mailbox.delete(message),
/// )
/// ```
factory SwipeActionCell.delete({...}) { ... }
```

---

## Post-Design Constitution Re-Check

All 10 principles confirmed compliant after design. No documented exceptions. All five deliverables are documentation/configuration changes that exercise existing features — no new public API is introduced. Proceed to `/speckit.tasks`.

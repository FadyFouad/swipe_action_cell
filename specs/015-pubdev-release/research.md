# Research: Documentation and pub.dev Release (F016)

**Branch**: `015-pubdev-release` | **Date**: 2026-03-01 | **Spec**: [spec.md](spec.md)

---

## D1: Example App Navigation — Scrollable TabBar

**Decision**: Expand the existing `example/lib/main.dart` `TabController` (currently 2 tabs) to 8 tabs with `isScrollable: true`. Use `DefaultTabController` wrapping a `Scaffold` whose `AppBar` has `bottom: TabBar(isScrollable: true, tabs: [...])` and whose `body` is a `TabBarView` of 8 screen widgets.

**Rationale**: The example app already uses `TabController` — this is a minimal delta change. A scrollable tab bar keeps all 8 screens accessible by horizontal scroll without a modal drawer interrupt. Tabs do not interfere with cell swipe gestures because `TabBar` scroll is in the header zone and `TabBarView` scroll is vertical; horizontal cell drags (which originate mid-content) are handled by the `HorizontalDragGestureRecognizer` inside `SwipeActionCell` before the `PageView`-style scroll can claim them. This was verified in F007 (scroll conflict resolution).

**Alternatives considered**:
- `NavigationDrawer` — rejected after user clarification (answer to Q1); scrollable TabBar preferred.
- Home screen card grid — rejected: requires an extra navigation layer; doesn't keep navigation persistent.

---

## D2: pub.dev Scoring — Target 140/160

**Decision**: Focus implementation on the five automated scoring categories in priority order:

| Category | Max Pts | Strategy |
|---|---|---|
| Pass static analysis | 50 | `flutter analyze` zero issues, including example app |
| Platform support | 20 | Declare all 6 platforms in README; package inherently multi-platform (no platform-specific code) |
| Provide documentation | 20 | Complete dartdoc + example code in `example/` directory |
| Follow Dart conventions | 10 | LICENSE ✅, CHANGELOG ✅, README ✅, `dart format` ✅ |
| Up-to-date dependencies | 10 | `flutter_lints: ^6.0.0` is current; `flutter_test: sdk: flutter` is pinned to SDK |

Static analysis alone (50 pts) + documentation (20 pts) + platform (20 pts) + conventions (10 pts) + deps (10 pts) = 110 pts automated. The remaining 50 pts come from popularity/likes which are user-driven. The 140/160 target is achievable by maximizing all automated categories.

**Rationale**: The 50-point static analysis bucket is the single highest-value item. Zero analyzer warnings is already required by the constitution and enforced in CI for the package; the only new risk is the example app (not previously analyzed as part of the package pipeline).

**Alternatives considered**:
- Targeting exactly 140 (omitting some polish) — rejected: maximizing all automated categories is simple and leaves margin for scoring model changes.

---

## D3: pubspec.yaml Version Bump

**Decision**: Change `version: 0.1.0-beta.1` → `version: 1.0.0`. All other metadata (homepage, repository, issue_tracker) already exist and are correct. Description (123 chars) is within the 60–180 character requirement.

**Rationale**: The spec mandates `1.0.0` (no pre-release suffix). All 15 features (F001–F014 + this feature F015) are complete. The package is ready for a stable release. The version bump signals semantic stability to consumers.

**Alternatives considered**:
- `1.0.0-beta.1` — rejected: spec explicitly states no pre-release suffix.
- `0.2.0` — rejected: spec mandates 1.0.0; this would be an incomplete release signal.

---

## D4: GIF Placeholder Strategy

**Decision**: Commit two minimal valid PNG files (1×1 transparent pixel, base64-encoded standard PNG header) at `doc/assets/demo-delete.gif` and `doc/assets/demo-reveal.gif`. The README `![...]` image tags reference GitHub raw URLs at these paths. When real GIFs are ready (produced externally), they replace the placeholders at the same paths — no README edit required.

**Rationale**: This allows `flutter pub publish --dry-run` to pass immediately (image tags with valid path references) while the package ships. The placeholder PNG renders as a tiny invisible image on pub.dev, which is acceptable during the pre-announcement window. Using a `.gif` extension for a PNG file is technically valid; browsers and pub.dev render it as an image regardless.

**Alternatives considered**:
- Link to external video URL — rejected: external links may rot; pub.dev image tags require relative paths or GitHub raw URLs for inline rendering.
- Omit image tags until GIFs are ready — rejected: pub.dev scoring deducts points for README quality; having image slots signals intent.

---

## D5: README Structure

**Decision**: Follow the standard pub.dev-optimized README structure:

```
1. Badges (pub.dev version, license, platform support)
2. Hero — 1-sentence description + animated GIF pair
3. Features — bullet list (8 key capabilities)
4. Quick Start — minimal 3-5 line code sample (copy-paste ready)
5. Platform Support — table (iOS / Android / Web / macOS / Windows / Linux)
6. Configuration Reference — table (all top-level parameters + defaults)
7. vs flutter_slidable — comparison table (5+ dimensions)
8. Installation — `flutter pub add swipe_action_cell`
9. Links — API docs (pub.dev), Example app (GitHub)
```

**Rationale**: Pub.dev renders the README as the package's landing page. Developers scan top-to-bottom; the hero + GIFs must appear within the first screen. The quick start must be immediately copy-pasteable. Comparison with flutter_slidable is placed after core content so it doesn't distract first-time visitors.

**Alternatives considered**:
- Long-form narrative README — rejected: developers scan, not read; structured sections with headers are more discoverable.
- Putting comparison first — rejected: leads with competitor positioning rather than the package's own value.

---

## D6: MIGRATION.md Structure

**Decision**: Organize as:

```
1. Overview — 2-paragraph summary of key differences
2. Installation change — before/after pubspec snippets
3. API mapping table — flutter_slidable class → swipe_action_cell equivalent
4. Behavioral differences — 5 bullet points with explanations
5. Before/After code examples — 2 full examples (basic slide action, delete with undo)
6. Features not in swipe_action_cell — explicit list with workarounds
7. Features not in flutter_slidable — explicit list (unique differentiators)
```

**flutter_slidable v3.x → swipe_action_cell mapping**:
| flutter_slidable | swipe_action_cell | Notes |
|---|---|---|
| `Slidable` | `SwipeActionCell` | Direct equivalent |
| `SlidableAction` | `SwipeAction` | In `LeftSwipeConfig.actions` |
| `ActionPane` (leading) | `RightSwipeConfig` | Right-direction actions |
| `ActionPane` (trailing) | `LeftSwipeConfig` | Left-direction actions |
| `SlidableController` | `SwipeController` | External control |
| `SlidableAutoCloseBehavior` | `SwipeGroupController` | Group coordination |
| `DismissiblePane` | `LeftSwipeConfig(mode: LeftSwipeMode.autoTrigger)` | Auto-trigger on full drag |

**Key behavioral differences**:
- flutter_slidable: symmetric (both sides are "action panels")
- swipe_action_cell: asymmetric (right = progressive value change, left = committed action)
- flutter_slidable: no undo support built-in
- swipe_action_cell: `SwipeUndoConfig` provides a 5-second undo window for destructive actions
- flutter_slidable: auto-close via `SlidableAutoCloseBehavior` widget in tree
- swipe_action_cell: auto-close via `SwipeGroupController` (controller-based, not tree-based)

**Rationale**: Concrete API mapping table is the fastest path for a migrating developer. The behavioral differences section prevents surprises. Explicit "not available" lists build trust by being honest.

**Alternatives considered**:
- Narrative prose migration guide — rejected: tables and code examples are faster to scan and act on.

---

## D7: Dartdoc Audit Strategy

**Decision**: Run `flutter analyze` with `public_member_api_docs: true` (already enforced in `analysis_options.yaml`) against the full package and the example app. Fix every `Missing documentation for a public member` warning. Focus especially on:
- All enum values (easy to miss individual values)
- All `copyWith` parameters
- All named parameters on config classes
- Factory constructors on `SwipeActionCell` (F013 additions)
- New testing utilities (F014 additions)

The analysis command `flutter analyze lib/ test/ example/lib/` catches all three trees.

**Rationale**: The `public_member_api_docs` lint is already enforced but may have accumulated suppressions or gaps during rapid feature development. A clean sweep before 1.0.0 is non-negotiable per Constitution VIII and directly impacts pub.dev documentation score (20 pts).

**Alternatives considered**:
- Manual review of all files — rejected: the analyzer finds all violations automatically; manual review adds no value over running the tool.

---

## D8: CHANGELOG.md 1.0.0 Entry

**Decision**: Append a new `## [1.0.0] - 2026-03-01` section at the top of CHANGELOG.md (above the existing 0.0.1 and 0.1.0-beta.1 entries) in keepachangelog.com format:

```markdown
## [1.0.0] - 2026-03-01

### Added
- F001: Horizontal gesture detection with direction discrimination
- F002: Spring-based animation with snap-back and completion
- F003: Progressive right-swipe value tracking
- F004: Intentional left-swipe auto-trigger and reveal modes
- F005: Background builders and progress-linked visual transitions
- F006: Consolidated configuration API and app-wide SwipeActionCellTheme
- F007: SwipeController and SwipeGroupController for programmatic control
- F008: Gesture arena and scroll conflict resolution
- F009: Accessibility (semantics, keyboard navigation, motion sensitivity, RTL)
- F010: Multi-zone swipe with configurable thresholds
- F011: Unified haptic and audio feedback
- F012: Undo lifecycle with configurable expiry window
- F013: Custom painter and decoration hooks (SwipeMorphIcon, SwipeParticleEffect)
- F014: Prebuilt zero-configuration templates (delete, archive, favorite, checkbox, counter, standard)
- F015: Consumer testing utilities (SwipeTester, SwipeAssertions, MockSwipeController, SwipeTestHarness)
```

**Rationale**: keepachangelog.com format is required by FR-015-014. Listing all 15 features gives developers a complete picture of what 1.0.0 includes. The date is the planned release date.

**Alternatives considered**:
- One entry per feature (15 version entries) — rejected: these were internal development milestones, not consumer-facing releases; the public changelog should only document the public release history.

---

## D9: Platform Support Declaration

**Decision**: Add a `flutter.plugin.platforms` is NOT appropriate for non-plugin packages. Instead, declare platform support in README via the platform support table (D5). For pub.dev scoring, the package earns platform points by being a Flutter-only package (no platform-specific code, works on all platforms Flutter supports). No changes to pubspec.yaml are needed for platform scoring beyond the existing `flutter: sdk: flutter` dependency.

**Rationale**: `swipe_action_cell` is a pure Flutter widget package with no platform-specific (native) code. Flutter widget packages support all platforms Flutter supports by default. Pub.dev automatically detects this. The platform support table in README documents this to users; no `platforms:` key needed in pubspec.

**Alternatives considered**:
- Adding `platforms:` key to pubspec.yaml — rejected: this key is for packages that have platform-specific implementations (plugins); adding it to a pure Flutter package is incorrect and may cause pub.dev to misclassify it.

---

## D10: Code Sample Compilation Verification

**Decision**: The example app in `example/` serves as the primary compile verification for all README and documentation code samples. Key samples (Quick Start, MIGRATION.md before/after, dartdoc examples) will also be present in the example app's screen files — ensuring they are exercised in real code. A final `flutter analyze example/` pass before publish confirms all sample code compiles.

**Rationale**: The example app already imports the package (`swipe_action_cell: path: ../`) — any API change that breaks a sample would be caught by `flutter analyze`. This is more reliable than standalone snippet files which might go stale. The TDD approach (Constitution VII) means the example app is the integration test for the documentation samples.

**Alternatives considered**:
- Separate `tool/verify_samples.dart` script — rejected: the example app achieves the same goal with less infrastructure; a separate tool adds maintenance burden.

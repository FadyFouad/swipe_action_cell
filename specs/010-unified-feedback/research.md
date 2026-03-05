# Research: Unified Feedback System (F010)

**Generated**: 2026-03-01
**Feature**: [spec.md](spec.md)

---

## D1 — Architecture: Standalone Dispatcher vs Inline Logic

**Decision**: Extract a `FeedbackDispatcher` service class in `lib/src/feedback/feedback_dispatcher.dart`. The widget state holds a `FeedbackDispatcher?` field; all haptic and audio calls are delegated to it. The widget never calls `HapticFeedback.*` directly after migration.

**Rationale**: Centralizing dispatch logic in one class makes it fully unit-testable in isolation (mock the haptic channel), keeps the 1037-line widget leaner, and provides a single location to apply the master toggles and override map lookups. Inline scattered calls cannot be tested without spinning up the full widget.

**Alternatives considered**:
- Keep calls inline, just add config checks around each: rejected — does not reduce complexity, cannot be tested in isolation, still scatters haptic logic across the widget.
- A separate `FeedbackService` singleton: rejected — singletons conflict with the package's per-cell config model and the controlled/uncontrolled pattern (Constitution V).

---

## D2 — Multi-Step Pattern Timer Management

**Decision**: `FeedbackDispatcher` maintains a `List<Timer>` of active pattern timers. `cancelPendingTimers()` cancels and clears all entries. The widget calls this method in two places: `_handleDragStart` (new drag cancels in-flight pattern from previous gesture) and `dispose()` (widget teardown). First step of a pattern fires synchronously; subsequent steps schedule via `Future.delayed` / `Timer`.

**Rationale**: FR-010 is explicit: timers must be cancelled on both new drag start and widget dispose. A flat `List<Timer>` is the simplest structure for bulk cancellation. Dart's `Timer` is the standard non-blocking delay mechanism inside the Flutter SDK constraint (Constitution IV — no external dependencies).

**Alternatives considered**:
- Cancel only on dispose: rejected — residual haptic steps from a prior gesture confuse user on rapid re-swipe.
- `StreamController` sequencing: rejected — overkill for a max-8-step pattern; adds complexity with no benefit.

---

## D3 — Config Resolution Cascade

**Decision**: `FeedbackDispatcher.resolve(cellConfig, themeConfig)` is a factory that returns `FeedbackDispatcher(cellConfig ?? themeConfig ?? null)`. When the resolved config is `null`, the dispatcher uses **legacy mode** (see D4). No field-level merging between cell and theme configs — cell config wins entirely (same precedence model as all other configs in this package).

**Rationale**: Consistent with existing `gestureConfig`, `animationConfig`, `visualConfig` cascade. "Local config fully replaces the theme config for that parameter (no field-level merging)" — existing `SwipeActionCellTheme` dartdoc.

**Alternatives considered**:
- Field-level merge (cell overrides individual theme fields): rejected — inconsistent with the rest of the package, complicates implementation.

---

## D4 — Backward Compatibility with Legacy `enableHaptic`

**Decision**: Three-level priority at runtime:
1. If a `SwipeFeedbackConfig` is resolved (cell or theme) → **unified mode**: dispatcher fires events per config, direction-level `enableHaptic` is ignored at runtime; in debug builds an `assert` fires when `enableHaptic: true` is set on a direction config alongside an active `SwipeFeedbackConfig`.
2. If no `SwipeFeedbackConfig` resolved AND a direction config has `enableHaptic: true` → **legacy mode**: widget fires the same `HapticFeedback.*` calls as today, through the dispatcher with a synthesized legacy config.
3. If no `SwipeFeedbackConfig` AND all direction `enableHaptic` are false (the package default) → **silent mode**: no haptic fires (unchanged existing default behavior).

This ensures SC-001 (zero test regressions) and FR-018 (legacy flag unchanged).

**Rationale**: The edge case in the spec ("both null → predefined defaults apply") would break existing users whose direction configs default to `enableHaptic: false`. Strict backward compat requires silent mode when no config is set. The "predefined defaults" activate only when a `SwipeFeedbackConfig()` is explicitly constructed (even with default arguments).

**Alternatives considered**:
- Auto-enable haptic when no config → rejected: breaks all existing consumers who rely on the default-off behavior.

---

## D5 — SwipeActionPanel Haptic Migration

**Decision**: Add an optional `void Function()?` parameter `onFeedbackRequest` to `SwipeActionPanel`. When non-null, it is called instead of the direct `HapticFeedback.mediumImpact()` call. The parent widget injects `() => _feedbackDispatcher?.fire(SwipeFeedbackEvent.actionTriggered)`. Legacy behavior (`enableHaptic: bool`) is preserved as a fallback when `onFeedbackRequest` is null.

**Rationale**: Avoids threading the full `FeedbackDispatcher` into the panel (which is a semi-public widget). A `VoidCallback?` is the simplest contract; the widget retains control over what event to fire. The panel's `enableHaptic` field is NOT deprecated in this feature — it remains for users who create `SwipeActionPanel` directly.

**Alternatives considered**:
- Add `FeedbackDispatcher?` to panel: rejected — leaks an internal class into a semi-public widget; `FeedbackDispatcher` is not part of the public API.
- Remove `enableHaptic` from panel: rejected — breaking change, violates FR-018 spirit.

---

## D6 — PanelOpened / PanelClosed Trigger Points

**Decision**:
- `panelOpened`: fire after `_updateState(SwipeState.revealed)` when the open animation settles (in `_handleAnimationComplete` when `_state == animatingToOpen`).
- `panelClosed`: fire after `_updateState(SwipeState.idle)` when the close animation settles following a reveal closure.

The widget already has these logical points; dispatcher calls are added there.

**Rationale**: Panel open/close are significant user feedback moments. Firing after animation settle is the correct UX timing — firing during animation would be premature.

---

## D7 — FeedbackDispatcher Lifecycle

**Decision**: The widget state creates the dispatcher in `didChangeDependencies()` (where it also resolves gesture/animation configs). It is recreated on config change (same rebuild trigger). `cancelPendingTimers()` + optionally nulling the field happens in `dispose()`. The dispatcher is NOT a `Disposable` / `ChangeNotifier` — it is a plain class with no Flutter lifecycle dependency.

**Rationale**: Consistent with how the widget already resolves other configs in `didChangeDependencies`. The dispatcher holds no `BuildContext` and no `TickerProvider`, so it doesn't need formal Flutter lifecycle integration.

---

## D8 — FeedbackDispatcher Is Internal (Not Public API)

**Decision**: `FeedbackDispatcher` is placed in `lib/src/feedback/feedback_dispatcher.dart` but is **not** exported from `lib/swipe_action_cell.dart`. Only the config types (`SwipeFeedbackConfig`, `SwipeFeedbackEvent`, `HapticPattern`, `HapticStep`, `HapticType`, `SwipeSoundEvent`) are public.

**Rationale**: Consumers configure feedback via `SwipeFeedbackConfig`; they don't need to interact with the dispatcher directly. Keeping it internal preserves API surface minimalism and future flexibility to change the dispatch implementation.

---

## D9 — Platform-Safe Haptic Invocation

**Decision**: Each `HapticFeedback.*` call inside `FeedbackDispatcher` is wrapped in a `try`/`catch (Object _)` that silently discards any exception. No error is logged, rethrown, or recorded.

**Rationale**: FR-021/FR-022: platform exceptions (web, unsupported Android devices) must not crash or alter swipe behavior. `HapticFeedback` methods return `Future<void>` — awaiting them is unnecessary and would introduce latency; they are called and forgotten.

**Alternatives considered**:
- Catch only `PlatformException`: rejected — `MissingPluginException` and bare `Exception` are also possible on some platforms; catching `Object` is safer.

---

## D10 — `SwipeSoundEvent` Callback Invocation Timing

**Decision**: `onShouldPlaySound` is called **synchronously** on the same Dart frame as the triggering haptic event (i.e., inside `fire(event)`). Any exception from the callback is caught and silently discarded (FR-014). The callback receives the corresponding `SwipeSoundEvent` value.

**Rationale**: FR-013: callback fires synchronously. The consumer is responsible for any async audio dispatch. Not all `SwipeFeedbackEvent` values have a corresponding `SwipeSoundEvent` (e.g., `zoneBoundaryCrossed`, `swipeCancelled` have no sound event); the dispatcher only calls the callback for events in `SwipeSoundEvent`.

---

## Integration Points Summary

| Location | Current Code | F010 Change |
|---|---|---|
| `swipe_action_cell.dart:1118-1129` | `HapticFeedback.lightImpact()` for threshold | `_feedbackDispatcher?.fire(SwipeFeedbackEvent.thresholdCrossed)` |
| `swipe_action_cell.dart:497-502` | Zone haptic + `enableHaptic` mediumImpact | Zone path: `fire(zoneBoundaryCrossed)` if dispatcher; else legacy zone haptic |
| `swipe_action_cell.dart:571-575` | Same as above for progressive | Same migration as above |
| `swipe_action_cell.dart:1097` | `_fireZoneHaptic(zone.hapticPattern)` | Dispatcher present: `fire(zoneBoundaryCrossed)`; absent: existing `_fireZoneHaptic` |
| `swipe_action_cell.dart:502,575` | `config.enableHaptic → mediumImpact` for action trigger | `fire(actionTriggered)` |
| `swipe_action_panel.dart:57,71` | `enableHaptic → mediumImpact` | Inject `onFeedbackRequest` callback |
| New: panel open/close settle | No haptic | `fire(panelOpened)` / `fire(panelClosed)` |
| New: swipe cancelled | No haptic | `fire(swipeCancelled)` — default silent |
| `swipe_action_cell.dart:624` | `_hapticThresholdFired = false` reset | + `_feedbackDispatcher?.cancelPendingTimers()` |

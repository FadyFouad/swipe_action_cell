# Research: Programmatic Control & Multi-Cell Coordination

**Branch**: `006-controller-group` | **Date**: 2026-02-27

---

## Decision 1: Controller ↔ Widget Bridge Pattern

**Decision**: `SwipeCellHandle` abstract class (package-internal, not exported from barrel). `SwipeActionCellState` implements it and calls `controller.attach(this)` in `didChangeDependencies` / `controller.detach()` in `dispose()`.

**Rationale**: Mirrors `ScrollController.attach(ScrollPosition)` — the canonical Flutter pattern for decoupling a consumer-facing controller from a framework-managed position/state object. The handle is in `lib/src/controller/swipe_cell_handle.dart` (imported but not exported), giving cross-file access without leaking the protocol into the public API.

**Alternatives considered**:
- **Command queue on ChangeNotifier** (widget polls a `_pendingCommand` field) — rejected because it creates a polling loop and adds latency. Commands must be consumed exactly once; a notifier-based queue is error-prone.
- **Callback injection** (`controller._openLeft = () => state._animateLeft()`) — rejected because it exposes mutable function fields and breaks const-friendliness. Dart records would work but add complexity for no gain.
- **Part files / single library** — rejected because it couples all source files into one library, making the codebase harder to navigate and eliminating file-level organization.

---

## Decision 2: State Reporting (Widget → Controller)

**Decision**: `SwipeCellHandle` includes a `reportState(SwipeState, double, SwipeDirection?)` method that the widget calls on every `_updateState()` transition and on every progress value change. The controller caches these values and calls `notifyListeners()` so consumers observing the controller always see current state.

**Rationale**: The widget owns the `AnimationController` and is the authoritative source of truth for state. The `SwipeController` is a projection of that state plus a command channel. This one-way "widget pushes, controller broadcasts" flow avoids any dual-ownership conflict.

**Alternatives considered**:
- **Controller as source of truth** — rejected because the `AnimationController` lives inside the widget state (tied to `TickerProvider`). Moving ownership to `SwipeController` would require `SwipeController` to also be a `TickerProvider`, violating Constitution V (simple uncontrolled default) and I (composition over inheritance).
- **`ValueListenable<SwipeState>` on the widget state** — rejected because it duplicates the existing `widget.onStateChanged` callback pattern and doesn't integrate with the group accordion logic.

---

## Decision 3: Accordion Implementation in `SwipeGroupController`

**Decision**: `SwipeGroupController` listens to each registered `SwipeController` via `addListener`. When a controller's state transitions to `animatingToOpen`, the listener synchronously calls `close()` on all other registered controllers before returning. The `close()` on already-idle controllers is a no-op.

**Rationale**: Synchronous closure ensures there is never a rendered frame with two cells simultaneously open. The cost is O(N) listener calls on open, but N in a realistic list is bounded by the number of visible cells (typically < 30), so this is negligible.

**Alternatives considered**:
- **`SwipeController` calls group directly** — rejected because it creates a circular dependency (`SwipeController` → `SwipeGroupController` → `SwipeController`) that is hard to reason about and test.
- **Frame-deferred closure via `SchedulerBinding.addPostFrameCallback`** — rejected because it allows a single frame with two open cells, violating SC-002.

---

## Decision 4: `SwipeControllerProvider` Widget Structure

**Decision**: `SwipeControllerProvider` is a `StatefulWidget` that creates an internal `SwipeGroupController` in `initState` and owns its lifecycle. A nested `_SwipeControllerScope extends InheritedWidget` wraps the child and exposes the group for descendant lookup. Consumers may also pass an explicit `groupController` to share a group across multiple providers.

**Rationale**: This is the standard Flutter pattern used by `Theme`, `Navigator`, `Overlay`, and `DefaultTabController`. The `StatefulWidget` layer manages lifecycle; the `InheritedWidget` layer enables efficient `O(1)` lookup by descendants. Pure `InheritedWidget` cannot own disposable state.

**Alternatives considered**:
- **Pure `InheritedWidget`** — rejected because `InheritedWidget` has no `dispose()` hook; the internal `SwipeGroupController` would leak.
- **`InheritedNotifier<SwipeGroupController>`** — rejected because it rebuilds all dependents on every group notification (accordion close events), causing unbounded rebuilds in long lists. The scope only needs to be queried in `initState`/`dispose`, not subscribed.

---

## Decision 5: Auto-Registration in `SwipeActionCellState`

**Decision**: Registration with `SwipeControllerProvider` happens in `didChangeDependencies()`, not `initState()`. The state caches the group reference as `_registeredGroup`. On `didChangeDependencies`, it diffs the new group against the cached one, unregisters from the old, and registers with the new. On `dispose()`, it unregisters from the cached group.

**Rationale**: `context.dependOnInheritedWidgetOfExactType` is invalid in `initState()` — the element is not yet mounted in the inheritance tree. `didChangeDependencies` is the correct hook (runs after `initState` on first mount, and again whenever an `InheritedWidget` dependency changes). The diff prevents double-registration when the tree rebuilds without the provider changing.

**Alternatives considered**:
- **Registration in `initState` via `WidgetsBinding.instance.addPostFrameCallback`** — rejected because it defers registration by one frame, creating a window where a cell could open without the group being aware.
- **Provider pushing controllers to cells** — rejected because it inverts the dependency direction; cells don't know about providers in their API.

---

## Decision 6: Internal vs. Consumer-Owned Controller

**Decision**: When `widget.controller` is `null`, the widget creates an internal `SwipeController` in `initState` and owns its lifecycle (disposes it). When `widget.controller` is non-null, the widget attaches to it but does NOT dispose it (consumer owns lifecycle). On `didUpdateWidget`, if the controller reference changes, the widget detaches from the old and attaches to the new.

**Rationale**: Matches Flutter's `TextField`/`TextEditingController` and `ScrollView`/`ScrollController` conventions. The widget is always fully functional without a controller — providing one is strictly opt-in (Constitution V).

**Alternatives considered**:
- **Always requiring a controller** — rejected; violates Constitution V.
- **Lazy internal controller creation** — rejected for group coordination: the provider needs a controller to register at mount time, not lazily.

---

## Decision 7: `setProgress()` Clamping vs. Asserting

**Decision**: `setProgress(double value)` clamps the input to `[minValue, maxValue]` silently (no assert, no throw). The resulting value is set directly on the progressive notifier.

**Rationale**: Matches `OverflowBehavior.clamp` semantics already defined in `RightSwipeConfig`. Programmatic value setting should be forgiving — the developer may be forwarding a value from an external source (network, database) that is naturally bounded by the config already.

**Alternatives considered**:
- **Assert on out-of-range** — rejected because `setProgress` is a convenience correction tool; an assert here would fire in the common case of "set value read from storage" where storage was written with different config bounds.

---

## Resolved Unknowns (from Plan Hint)

All decisions align with the plan hint:
- `SwipeController extends ChangeNotifier` ✅ (replaces the stub)
- `SwipeGroupController` holds a `Set<SwipeController>` ✅
- "Weak-reference-style cleanup" → implemented via reliable `unregister()` in widget `dispose()`, not actual weak references (Dart has no built-in weak refs in stable SDK; `Finalizer` is available but unnecessary given the reliable dispose lifecycle) ✅
- `SwipeControllerProvider` is a `StatefulWidget` wrapping an `InheritedWidget` scope ✅

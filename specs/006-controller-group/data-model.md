# Data Model: Programmatic Control & Multi-Cell Coordination

**Branch**: `006-controller-group` | **Date**: 2026-02-27

---

## Entity 1: `SwipeController`

**Role**: Single-cell programmatic interface and observable state projection.

**Fields**:

| Field | Type | Description |
|-------|------|-------------|
| `_state` | `SwipeState` | Cached state pushed by the widget via `reportState()` |
| `_progress` | `double` | Cached progressive value pushed by the widget |
| `_openDirection` | `SwipeDirection?` | `left`, `right`, or `null` when closed |
| `_handle` | `SwipeCellHandle?` | Package-internal delegate installed by `SwipeActionCellState` |

**Computed Properties**:

| Property | Type | Derivation |
|----------|------|------------|
| `currentState` | `SwipeState` | Returns `_state` |
| `currentProgress` | `double` | Returns `_progress` |
| `isOpen` | `bool` | `_state == SwipeState.revealed` |
| `openDirection` | `SwipeDirection?` | Returns `_openDirection`; `null` when not open |

**State transitions (command validity)**:

| Command | Valid when | Invalid behaviour (debug / release) |
|---------|-----------|--------------------------------------|
| `openLeft()` | `_handle != null` AND `_state == idle` | assert / no-op |
| `openRight()` | `_handle != null` AND `_state == idle` | assert / no-op |
| `close()` | `_state == revealed \|\| _state == animatingToOpen` | assert / no-op |
| `resetProgress()` | `_handle != null` | assert / no-op |
| `setProgress(v)` | `_handle != null` | assert / no-op |

**Lifecycle**:
- Created by consumer (before or after widget mounts)
- `attach(handle)` called by widget in `didChangeDependencies`
- `detach()` called by widget in `dispose`
- `dispose()` called by consumer; must be called after widget is disposed

**Relationships**:
- Attached to exactly 0 or 1 `SwipeActionCellState` at any time
- May be registered with 0 or 1 `SwipeGroupController`

---

## Entity 2: `SwipeCellHandle` (internal)

**Role**: Package-internal protocol bridging `SwipeController` commands to `SwipeActionCellState` animations. Not exported from the package barrel.

**Methods**:

| Method | Executed by widget as |
|--------|-----------------------|
| `executeOpenLeft()` | Run completion spring to the left max-translation, then run left-swipe settled logic |
| `executeOpenRight()` | Run completion spring to the right max-translation, then apply progressive increment + snap-back |
| `executeClose()` | Run snap-back spring to 0.0 from current offset |
| `executeResetProgress()` | Set `_progressValueNotifier.value = config.initialValue` |
| `executeSetProgress(v)` | Set `_progressValueNotifier.value = v.clamp(config.minValue, config.maxValue)` |

**Implemented by**: `SwipeActionCellState`

---

## Entity 3: `SwipeGroupController`

**Role**: Multi-cell coordinator enforcing the accordion invariant (at most one open cell at a time).

**Fields**:

| Field | Type | Description |
|-------|------|-------------|
| `_controllers` | `Set<SwipeController>` | All currently registered controllers |
| `_listeners` | `Map<SwipeController, VoidCallback>` | Per-controller listener closure for removal |

**Operations**:

| Method | Behaviour |
|--------|-----------|
| `register(c)` | Add `c` to `_controllers`; install accordion listener; no-op if already registered |
| `unregister(c)` | Remove `c` from `_controllers`; remove listener; no-op if not registered |
| `closeAll()` | For every `c` in `_controllers` where `c.isOpen`, call `c.close()` |
| `closeAllExcept(c)` | For every `c2 != c` in `_controllers` where `c2.isOpen`, call `c2.close()` |

**Accordion listener (per controller)**:
When a registered controller's state changes to `animatingToOpen`, the listener calls `closeAllExcept(thatController)` synchronously.

**Lifecycle**:
- Created by consumer or internally by `SwipeControllerProvider`
- `dispose()` removes all internal listeners; does NOT dispose registered `SwipeController` instances (consumer owns those)

---

## Entity 4: `_SwipeControllerScope` (internal)

**Role**: `InheritedWidget` that makes a `SwipeGroupController` accessible to descendant `SwipeActionCell` widgets.

**Fields**:

| Field | Type | Description |
|-------|------|-------------|
| `controller` | `SwipeGroupController` | The group controller provided to descendants |

**Lookup**: `static SwipeGroupController? maybeOf(BuildContext context)` — does NOT create a dependency (uses `getElementForInheritedWidgetOfExactType`, not `dependOnInheritedWidgetOfExactType`) because `SwipeActionCellState` only needs the reference at mount/unmount time, not reactively.

**`updateShouldNotify`**: Returns `controller != old.controller` — only notifies if the group itself is swapped.

---

## Entity 5: `SwipeControllerProvider`

**Role**: Consumer-facing `StatefulWidget` that owns the lifecycle of an internal `SwipeGroupController` and exposes it via `_SwipeControllerScope`.

**Widget fields**:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `groupController` | `SwipeGroupController?` | `null` | External group; when `null`, an internal one is created |
| `child` | `Widget` | required | The widget subtree to wrap |

**State fields** (`_SwipeControllerProviderState`):

| Field | Type | Description |
|-------|------|-------------|
| `_internalController` | `SwipeGroupController` | Created in `initState` when `widget.groupController == null` |

**Lifecycle**:
- `initState`: creates `_internalController = SwipeGroupController()`
- `dispose`: calls `_internalController.dispose()`
- When `widget.groupController` is provided, `_internalController` is still created but not used

**Static helper**: `static SwipeGroupController? maybeGroupOf(BuildContext context)` delegates to `_SwipeControllerScope.maybeOf(context)`.

---

## State Machine Additions

The existing state machine is unchanged. Valid programmatic transitions:

```
openLeft()  → idle ──────────────────────────► animatingToOpen
openRight() → idle ──────────────────────────► animatingToOpen (snaps back after increment)
close()     → revealed ──────────────────────► animatingToClose
close()     → animatingToOpen ───────────────► animatingToClose (interrupt)
```

No new states are introduced. The `animatingOut` state is not reachable via `openLeft()` directly — it is triggered by the `postActionBehavior` setting after the action fires, as before.

---

## Registration Lifecycle in `SwipeActionCellState`

```
initState()
  └─ create _internalController (if widget.controller == null)

didChangeDependencies()
  ├─ resolve effective configs (existing)
  ├─ newGroup = _SwipeControllerScope.maybeOf(context)
  ├─ if newGroup != _registeredGroup:
  │     _registeredGroup?.unregister(_effectiveSwipeController)
  │     _registeredGroup = newGroup
  │     _registeredGroup?.register(_effectiveSwipeController)
  └─ attach handle to _effectiveSwipeController (if not yet attached)

didUpdateWidget()
  └─ if widget.controller changed:
       oldController.detach()
       newController.attach(this)  [or create new internal]
       _registeredGroup?.unregister(old)
       _registeredGroup?.register(new)

dispose()
  ├─ _registeredGroup?.unregister(_effectiveSwipeController)
  ├─ _effectiveSwipeController.detach()
  └─ _internalController?.dispose() [only if we own it]
```

Where `_effectiveSwipeController` = `widget.controller ?? _internalController`.

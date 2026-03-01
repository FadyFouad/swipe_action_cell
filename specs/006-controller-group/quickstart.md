# Quickstart: Programmatic Control & Multi-Cell Coordination

**Branch**: `006-controller-group` | **Date**: 2026-02-27

---

## Example 1 — Programmatic Open / Close

```dart
import 'package:flutter/material.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

class DeletableItem extends StatefulWidget {
  const DeletableItem({super.key, required this.title});
  final String title;

  @override
  State<DeletableItem> createState() => _DeletableItemState();
}

class _DeletableItemState extends State<DeletableItem> {
  final _controller = SwipeController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onNetworkDeleteComplete() async {
    // Close the cell after an async operation finishes.
    _controller.close();
  }

  @override
  Widget build(BuildContext context) {
    return SwipeActionCell(
      controller: _controller,
      leftSwipeConfig: LeftSwipeConfig(
        mode: LeftSwipeMode.reveal,
        actions: [
          SwipeAction(
            icon: const Icon(Icons.delete),
            label: 'Delete',
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            onTap: () async {
              await deleteOnServer(widget.title);
              _onNetworkDeleteComplete();
            },
            isDestructive: true,
          ),
        ],
      ),
      child: ListTile(title: Text(widget.title)),
    );
  }
}
```

---

## Example 2 — Observing State (Reactive UI)

```dart
class _ListPageState extends State<ListPage> {
  final _controller = SwipeController();
  bool _anyOpen = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onCellStateChanged);
  }

  void _onCellStateChanged() {
    setState(() => _anyOpen = _controller.isOpen);
  }

  @override
  void dispose() {
    _controller.removeListener(_onCellStateChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SwipeActionCell(
        controller: _controller,
        leftSwipeConfig: LeftSwipeConfig(
          mode: LeftSwipeMode.reveal,
          actions: [
            SwipeAction(
              icon: const Icon(Icons.archive),
              label: 'Archive',
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              onTap: () {},
            ),
          ],
        ),
        child: const ListTile(title: Text('Swipe me')),
      ),
      floatingActionButton: _anyOpen
          ? FloatingActionButton.extended(
              onPressed: _controller.close,
              label: const Text('Close'),
              icon: const Icon(Icons.close),
            )
          : null,
    );
  }
}
```

---

## Example 3 — Accordion via `SwipeControllerProvider` (Recommended)

The simplest way to get accordion behavior in a list. No manual controller
management needed — cells auto-register and auto-unregister as they scroll.

```dart
class TodoList extends StatelessWidget {
  const TodoList({super.key, required this.items});
  final List<TodoItem> items;

  @override
  Widget build(BuildContext context) {
    return SwipeControllerProvider(
      child: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return SwipeActionCell(
            leftSwipeConfig: LeftSwipeConfig(
              mode: LeftSwipeMode.reveal,
              actions: [
                SwipeAction(
                  icon: const Icon(Icons.delete),
                  label: 'Delete',
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  onTap: () => deleteItem(item),
                  isDestructive: true,
                ),
                SwipeAction(
                  icon: const Icon(Icons.archive),
                  label: 'Archive',
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  onTap: () => archiveItem(item),
                ),
              ],
            ),
            child: ListTile(
              title: Text(item.title),
              subtitle: Text(item.subtitle),
            ),
          );
        },
      ),
    );
  }
}
```

---

## Example 4 — Manual `SwipeGroupController` (Explicit Control)

Use when you need programmatic access to the whole group (e.g., "close all on
scroll start") or when coordinating cells across multiple lists.

```dart
class _MyListState extends State<MyList> {
  final _group = SwipeGroupController();

  @override
  void dispose() {
    _group.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollStartNotification>(
      onNotification: (_) {
        _group.closeAll(); // close any open cell when the list starts scrolling
        return false;
      },
      child: SwipeControllerProvider(
        groupController: _group, // inject the explicit group
        child: ListView.builder(
          itemCount: widget.items.length,
          itemBuilder: (context, index) => SwipeActionCell(
            leftSwipeConfig: LeftSwipeConfig(
              mode: LeftSwipeMode.autoTrigger,
              onActionTriggered: () => deleteItem(widget.items[index]),
            ),
            child: ListTile(title: Text(widget.items[index].title)),
          ),
        ),
      ),
    );
  }
}
```

---

## Example 5 — `setProgress` / `resetProgress`

```dart
class _CounterRowState extends State<CounterRow> {
  final _controller = SwipeController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwipeActionCell(
          controller: _controller,
          rightSwipeConfig: RightSwipeConfig(
            stepValue: 1.0,
            maxValue: 10.0,
            onProgressChanged: (val, _) => setState(() {}),
          ),
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => ListTile(
              title: Text('Count: ${_controller.currentProgress.toInt()}'),
            ),
          ),
        ),
        Row(
          children: [
            TextButton(
              onPressed: () => _controller.setProgress(5.0),
              child: const Text('Set to 5'),
            ),
            TextButton(
              onPressed: _controller.resetProgress,
              child: const Text('Reset'),
            ),
          ],
        ),
      ],
    );
  }
}
```

---

## Migration from F6 (no breaking changes)

F6 introduced `SwipeController` as a no-op stub. F7 adds the full API.
No existing code breaks — the constructor signature is unchanged:

```dart
// Before F7 (still works):
final controller = SwipeController();
SwipeActionCell(controller: controller, child: ...)

// After F7 — same construction, new capabilities:
controller.openLeft();
controller.close();
controller.addListener(() { ... });
```

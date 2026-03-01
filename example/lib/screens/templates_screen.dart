import 'package:flutter/material.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

/// Showcases all six prebuilt zero-config template factory constructors.
///
/// Each factory constructor provides a fully wired [SwipeActionCell] with
/// sensible defaults for icon, color, haptic feedback, and behavior.
/// Pass only the semantically meaningful parameters (e.g., [onDeleted]).
class TemplatesScreen extends StatefulWidget {
  /// Creates the templates demo screen.
  const TemplatesScreen({super.key});

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  bool _isFavorited = false;
  bool _isChecked = false;
  int _counterValue = 0;
  bool _deleted = false;
  bool _archived = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Prebuilt Templates',
            style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        const Text(
          'All 6 factory constructors — zero manual configuration needed.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 16),

        const _SectionLabel('SwipeActionCell.delete'),
        const SizedBox(height: 8),
        // .delete: left swipe shows red trash icon; fires onDeleted after
        // a 5-second undo window. Uses PostActionBehavior.animateOut internally.
        if (!_deleted)
          SwipeActionCell.delete(
            onDeleted: () => setState(() => _deleted = true),
            child: const ListTile(
              leading: Icon(Icons.mail_outline),
              title: Text('Delete template'),
              subtitle: Text('Left swipe → undo strip → onDeleted'),
            ),
          )
        else
          const Card(
            child: ListTile(
              leading: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Item deleted'),
            ),
          ),
        const SizedBox(height: 16),

        const _SectionLabel('SwipeActionCell.archive'),
        const SizedBox(height: 8),
        // .archive: left swipe shows teal archive icon; fires onArchived
        // immediately on commit via onActionTriggered (no undo window).
        if (!_archived)
          SwipeActionCell.archive(
            onArchived: () => setState(() => _archived = true),
            child: const ListTile(
              leading: Icon(Icons.article_outlined),
              title: Text('Archive template'),
              subtitle: Text('Left swipe → onArchived fires on commit'),
            ),
          )
        else
          const Card(
            child: ListTile(
              leading: Icon(Icons.check_circle, color: Colors.teal),
              title: Text('Item archived'),
            ),
          ),
        const SizedBox(height: 16),

        const _SectionLabel('SwipeActionCell.favorite'),
        const SizedBox(height: 8),
        // .favorite: right swipe toggles the isFavorited state.
        // The background shows SwipeMorphIcon (outline → filled heart).
        // isFavorited: drives both the visual and the semantic label.
        SwipeActionCell.favorite(
          isFavorited: _isFavorited,
          onToggle: (val) => setState(() => _isFavorited = val),
          child: ListTile(
            leading: Icon(
              _isFavorited ? Icons.favorite : Icons.favorite_border,
              color: Colors.amber,
            ),
            title: const Text('Favorite template'),
            subtitle:
                Text(_isFavorited ? 'Favorited ❤️' : 'Right swipe to favorite'),
          ),
        ),
        const SizedBox(height: 16),

        const _SectionLabel('SwipeActionCell.checkbox'),
        const SizedBox(height: 8),
        // .checkbox: right swipe toggles the isChecked state.
        // onChanged receives the new boolean value.
        SwipeActionCell.checkbox(
          isChecked: _isChecked,
          onChanged: (val) => setState(() => _isChecked = val),
          child: ListTile(
            leading: Icon(
              _isChecked ? Icons.check_box : Icons.check_box_outline_blank,
              color: Colors.green,
            ),
            title: const Text('Checkbox template'),
            subtitle: Text(_isChecked ? 'Checked ✅' : 'Right swipe to check'),
          ),
        ),
        const SizedBox(height: 16),

        const _SectionLabel('SwipeActionCell.counter'),
        const SizedBox(height: 8),
        // .counter: right swipe increments count.
        // count: the current value shown in the background label.
        // onCountChanged: receives the new integer value.
        SwipeActionCell.counter(
          count: _counterValue,
          onCountChanged: (val) => setState(() => _counterValue = val),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.shade100,
              child: Text(
                '$_counterValue',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
            title: const Text('Counter template'),
            subtitle: const Text('Right swipe to increment'),
          ),
        ),
        const SizedBox(height: 16),

        const _SectionLabel('SwipeActionCell.standard'),
        const SizedBox(height: 8),
        // .standard: combines a right-swipe favorite toggle and a left-swipe
        // reveal panel. Pass onFavorited and/or actions as needed.
        SwipeActionCell.standard(
          isFavorited: _isFavorited,
          onFavorited: (val) {
            setState(() => _isFavorited = val);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      val ? 'Added to favorites' : 'Removed from favorites')),
            );
          },
          actions: [
            SwipeAction(
              // icon must be a Widget, not IconData.
              icon: const Icon(Icons.share_outlined),
              label: 'Share',
              backgroundColor: Colors.indigo,
              foregroundColor: const Color(0xFFFFFFFF),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share tapped')),
                );
              },
            ),
          ],
          child: ListTile(
            leading: Icon(
              _isFavorited ? Icons.favorite : Icons.favorite_border,
              color: Colors.amber,
            ),
            title: const Text('Standard template'),
            subtitle: const Text(
                'Right swipe → favorite  |  Left swipe → reveal Share'),
          ),
        ),
      ],
    );
  }
}

/// Small section label rendered above each template demo.
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.indigo.shade700,
        fontFamily: 'monospace',
      ),
    );
  }
}

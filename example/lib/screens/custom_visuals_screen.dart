import 'package:flutter/material.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

/// Demonstrates custom visual configuration using [SwipeMorphIcon] and
/// [SwipeVisualConfig].
///
/// [SwipeMorphIcon] cross-fades between two icons as the swipe ratio progresses
/// from 0.0 to 1.0, creating a smooth morphing visual effect.
///
/// [SwipeVisualConfig.borderRadius] rounds the cell corners (Cupertino style).
class CustomVisualsScreen extends StatefulWidget {
  /// Creates the custom visuals demo screen.
  const CustomVisualsScreen({super.key});

  @override
  State<CustomVisualsScreen> createState() => _CustomVisualsScreenState();
}

class _CustomVisualsScreenState extends State<CustomVisualsScreen> {
  bool _isFavorited = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Custom Visuals',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Right swipe morphs the heart icon and toggles favorite status.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            _isFavorited ? '❤️ Favorited' : '♡ Not favorited',
            style: const TextStyle(fontSize: 12, color: Colors.pink),
          ),
          const SizedBox(height: 16),
          SwipeActionCell(
            rightSwipeConfig: RightSwipeConfig(
              onSwipeCompleted: (_) =>
                  setState(() => _isFavorited = !_isFavorited),
              enableHaptic: true,
            ),
            // visualConfig: customizes visual presentation.
            // borderRadius: applies rounded corners (common on iOS/macOS).
            // rightBackground: builder receives SwipeProgress with .ratio field.
            visualConfig: SwipeVisualConfig(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              clipBehavior: Clip.antiAlias,
              rightBackground: (context, progress) => ColoredBox(
                color: Colors.pink.shade400,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    // SwipeMorphIcon cross-fades between startIcon and endIcon
                    // as progress.ratio moves from 0.0 → 1.0.
                    child: SwipeMorphIcon(
                      startIcon: const Icon(Icons.favorite_border,
                          color: Colors.white, size: 32),
                      endIcon: const Icon(Icons.favorite,
                          color: Colors.white, size: 32),
                      // progress.ratio: current drag distance / activation threshold.
                      progress: progress.ratio,
                    ),
                  ),
                ),
              ),
            ),
            child: Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Icon(
                  _isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: Colors.pink,
                ),
                title: const Text('Custom morph icon'),
                subtitle: const Text('Right swipe to toggle favorite'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

/// Demonstrates multi-zone right swipe with distinct visual feedback at each
/// threshold level.
///
/// [SwipeZone] defines named activation zones within a swipe direction. Each
/// zone activates when the drag crosses its [SwipeZone.threshold] ratio. The
/// [SwipeZone.background] builder receives live [SwipeProgress] so the visual
/// can update continuously while the user drags.
///
/// When the user releases inside a zone, [SwipeZone.onActivated] fires if
/// the zone's threshold was the highest crossed.
class MultiThresholdScreen extends StatefulWidget {
  /// Creates the multi-threshold demo screen.
  const MultiThresholdScreen({super.key});

  @override
  State<MultiThresholdScreen> createState() => _MultiThresholdScreenState();
}

class _MultiThresholdScreenState extends State<MultiThresholdScreen> {
  int _swipeCount = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Multi-Zone Swipe',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Right swipe across 3 zones: slow (blue) → medium (orange) → fast (red).\n'
            'Each zone fires a different step value when released.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text('Total swipes: $_swipeCount',
              style: const TextStyle(fontSize: 12, color: Colors.deepOrange)),
          const SizedBox(height: 16),
          SwipeActionCell(
            rightSwipeConfig: RightSwipeConfig(
              // zones: overrides single-threshold behavior with up to 4 named zones.
              // Each zone activates when drag crosses its threshold ratio (0.0–1.0).
              // stepValue: the increment applied when this zone is the highest crossed.
              zones: [
                SwipeZone(
                  // Zone 1 activates at 20% drag distance.
                  threshold: 0.20,
                  semanticLabel: 'Zone 1 — slow',
                  // stepValue: added to cumulative value when released in this zone.
                  stepValue: 1,
                  onActivated: () => setState(() => _swipeCount += 1),
                  background: (context, progress) => ColoredBox(
                    color: Colors.blue.shade200,
                    child: const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.looks_one_outlined,
                            color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ),
                SwipeZone(
                  // Zone 2 activates at 50% drag distance.
                  threshold: 0.50,
                  semanticLabel: 'Zone 2 — medium',
                  stepValue: 2,
                  onActivated: () => setState(() => _swipeCount += 2),
                  background: (context, progress) => ColoredBox(
                    color: Colors.orange.shade400,
                    child: const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.looks_two_outlined,
                            color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ),
                SwipeZone(
                  // Zone 3 activates at 80% drag distance.
                  threshold: 0.80,
                  semanticLabel: 'Zone 3 — fast',
                  stepValue: 5,
                  onActivated: () => setState(() => _swipeCount += 5),
                  background: (context, progress) => ColoredBox(
                    color: Colors.red.shade500,
                    child: const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.looks_3_outlined,
                            color: Colors.white, size: 28),
                      ),
                    ),
                  ),
                ),
              ],
              enableHaptic: true,
            ),
            child: Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.speed),
                title: const Text('Multi-zone right swipe'),
                subtitle: const Text('Drag slowly → zone 1 (+1)\n'
                    'Drag medium → zone 2 (+2)\n'
                    'Drag fast → zone 3 (+5)'),
                isThreeLine: true,
                trailing: Text(
                  '$_swipeCount',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(color: Colors.deepOrange),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

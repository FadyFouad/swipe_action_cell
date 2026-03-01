import 'package:flutter/material.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

/// Demonstrates right-swipe as a progressive counter with a visual progress bar.
///
/// Each right swipe adds [_stepValue] to the counter. The background updates
/// in real time to show the progress ratio, giving the user immediate visual
/// feedback even before releasing the gesture.
class CounterScreen extends StatefulWidget {
  /// Creates the counter demo screen.
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  // Current cumulative value after all successful right swipes.
  double _value = 0;

  // Maximum value before the counter wraps back to 0.
  static const double _maxValue = 10;

  // Amount added per successful right swipe.
  static const double _stepValue = 1;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Counter — Right Swipe Increment',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const Text(
            'Right swipe to increment. The background progress bar updates live.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          // The SwipeActionCell wraps the ListTile.
          SwipeActionCell(
            // rightSwipeConfig drives the progressive increment.
            rightSwipeConfig: RightSwipeConfig(
              stepValue: _stepValue,
              maxValue: _maxValue,
              // OverflowBehavior.wrap resets the value to minValue when
              // maxValue is exceeded, creating an infinite counter.
              overflowBehavior: OverflowBehavior.wrap,
              enableHaptic: true,
              // onSwipeCompleted fires after the spring animation settles,
              // receiving the new cumulative value.
              onSwipeCompleted: (newValue) {
                setState(() => _value = newValue);
              },
            ),
            // rightBackground is a builder called on every animation frame
            // with the current SwipeProgress. Use progress.ratio (0.0–1.0)
            // to drive custom visuals.
            visualConfig: SwipeVisualConfig(
              rightBackground: (context, progress) {
                // progress.ratio reflects how far the drag has traveled
                // relative to the activation threshold, clamped to [0, 1].
                return Stack(
                  children: [
                    // Blue fill grows with swipe distance.
                    FractionallySizedBox(
                      widthFactor: progress.ratio,
                      child: ColoredBox(
                        color: Colors.blue.shade400,
                        child: const SizedBox.expand(),
                      ),
                    ),
                    const Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Icon(Icons.add, color: Colors.white, size: 28),
                      ),
                    ),
                  ],
                );
              },
            ),
            child: Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    _value.toInt().toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
                title: const Text('Swipe right to increment'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    // LinearProgressIndicator shows the current value / maxValue.
                    LinearProgressIndicator(
                      value: _value / _maxValue,
                      backgroundColor: Colors.blue.shade50,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.blue.shade400),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_value.toInt()} / ${_maxValue.toInt()}',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

/// Demonstrates RTL (right-to-left) layout support.
///
/// Wrapping cells in [Directionality] with [TextDirection.rtl] reverses the
/// physical-to-semantic swipe mapping:
/// - Physical LEFT swipe → semantic FORWARD (right-swipe config)
/// - Physical RIGHT swipe → semantic BACKWARD (left-swipe config)
///
/// This means Arabic/Hebrew users get the correct incremental action on a
/// leftward physical gesture, matching their reading direction.
class RtlScreen extends StatefulWidget {
  /// Creates the RTL demo screen.
  const RtlScreen({super.key});

  @override
  State<RtlScreen> createState() => _RtlScreenState();
}

class _RtlScreenState extends State<RtlScreen> {
  final List<_RtlItem> _items = [
    const _RtlItem(label: 'بريد إلكتروني من أحمد', count: 0),
    const _RtlItem(label: 'رسالة من مريم', count: 0),
    const _RtlItem(label: 'إشعار من التطبيق', count: 0),
    const _RtlItem(label: 'تحديث النظام', count: 0),
    const _RtlItem(label: 'طلب صداقة', count: 0),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RTL Support',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              const Text(
                'Physical LEFT swipe → increments (forward in RTL)\n'
                'Physical RIGHT swipe → delete action (backward in RTL)',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Expanded(
          child: Directionality(
            // TextDirection.rtl reverses swipe-direction semantics automatically.
            // No need to swap leftSwipeConfig and rightSwipeConfig.
            textDirection: TextDirection.rtl,
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return SwipeActionCell(
                  // forwardSwipeConfig maps to the "forward" direction:
                  // rightSwipe in LTR, leftSwipe in RTL. This is the
                  // direction-adaptive alternative to rightSwipeConfig.
                  rightSwipeConfig: RightSwipeConfig(
                    enableHaptic: true,
                    onSwipeCompleted: (newValue) {
                      setState(() => _items[index] =
                          _RtlItem(label: item.label, count: newValue.toInt()));
                    },
                  ),
                  // backwardSwipeConfig maps to leftSwipe in LTR, rightSwipe in RTL.
                  leftSwipeConfig: const LeftSwipeConfig(
                    mode: LeftSwipeMode.autoTrigger,
                    postActionBehavior: PostActionBehavior.snapBack,
                    enableHaptic: true,
                  ),
                  visualConfig: SwipeVisualConfig(
                    // In RTL, rightBackground appears on the physical LEFT side.
                    rightBackground: (context, progress) => ColoredBox(
                      color: Colors.blue.shade400,
                      child: const Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Icon(Icons.add, color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                    leftBackground: (context, progress) => ColoredBox(
                      color: Colors.red.shade400,
                      child: const Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Icon(Icons.delete_outline,
                              color: Colors.white, size: 28),
                        ),
                      ),
                    ),
                  ),
                  child: ListTile(
                    // Arabic text is displayed right-aligned due to RTL direction.
                    title: Text(item.label),
                    subtitle: Text('السحب: ${item.count}'),
                    trailing:
                        Icon(Icons.chevron_left, color: Colors.grey.shade400),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _RtlItem {
  const _RtlItem({required this.label, required this.count});

  final String label;
  final int count;
}

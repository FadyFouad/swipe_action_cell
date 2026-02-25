import 'package:flutter/material.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'swipe_action_cell example',
      home: ExampleHome(),
    );
  }
}

class ExampleHome extends StatelessWidget {
  const ExampleHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('swipe_action_cell')),
      body: ListView.builder(
        itemCount: 10,
        itemBuilder: (context, index) {
          return SwipeActionCell(
            // TODO(F1): Configure left/right swipe actions once behaviour is
            // implemented. For now this is a transparent wrapper.
            child: ListTile(
              leading: CircleAvatar(child: Text('${index + 1}')),
              title: Text('Item ${index + 1}'),
              subtitle: const Text('Swipe left or right when ready'),
            ),
          );
        },
      ),
    );
  }
}

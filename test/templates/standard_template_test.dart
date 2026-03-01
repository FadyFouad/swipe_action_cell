import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('SwipeActionCell.standard()', () {
    testWidgets('renders correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCell.standard(
            child: const ListTile(title: Text('Standard item')),
            onFavorited: (_) {},
            actions: [
              SwipeAction(
                icon: const Icon(Icons.reply),
                label: 'Reply',
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                onTap: () {},
              ),
            ],
          ),
        ),
      ));
      expect(find.text('Standard item'), findsOneWidget);
    });
  });
}

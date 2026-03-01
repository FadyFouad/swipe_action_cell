import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  group('Platform adaptation', () {
    testWidgets('auto style maps to material on Android', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SwipeActionCell.delete(
            child: const ListTile(title: Text('item')),
            onDeleted: () {},
          ),
        ),
      ));
      expect(find.text('item'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}

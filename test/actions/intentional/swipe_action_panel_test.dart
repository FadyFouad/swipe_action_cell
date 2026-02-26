import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/swipe_action_cell.dart';

void main() {
  Widget buildPanel({
    required List<SwipeAction> actions,
    double panelWidth = 240.0,
    VoidCallback? onClose,
    bool enableHaptic = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: panelWidth,
          height: 60,
          child: SwipeActionPanel(
            actions: actions,
            panelWidth: panelWidth,
            onClose: onClose ?? () {},
            enableHaptic: enableHaptic,
          ),
        ),
      ),
    );
  }

  void noop() {}

  final archiveAction = SwipeAction(
    icon: const Icon(Icons.archive),
    label: 'Archive',
    backgroundColor: const Color(0xFF43A047),
    foregroundColor: const Color(0xFFFFFFFF),
    onTap: noop,
  );

  group('SwipeActionPanel — rendering', () {
    testWidgets('renders 1 button', (tester) async {
      await tester.pumpWidget(buildPanel(actions: [archiveAction]));
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('renders 2 buttons', (tester) async {
      final deleteAction = SwipeAction(
        icon: const Icon(Icons.delete),
        label: 'Delete',
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: const Color(0xFFFFFFFF),
        onTap: noop,
      );
      await tester.pumpWidget(
        buildPanel(actions: [archiveAction, deleteAction]),
      );
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('renders 3 buttons', (tester) async {
      final a1 = SwipeAction(
        icon: const Icon(Icons.archive),
        backgroundColor: const Color(0xFF43A047),
        foregroundColor: const Color(0xFFFFFFFF),
        onTap: noop,
      );
      final a2 = SwipeAction(
        icon: const Icon(Icons.delete),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: const Color(0xFFFFFFFF),
        onTap: noop,
      );
      final a3 = SwipeAction(
        icon: const Icon(Icons.share),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: const Color(0xFFFFFFFF),
        onTap: noop,
      );
      await tester.pumpWidget(buildPanel(actions: [a1, a2, a3]));
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('shows label when provided', (tester) async {
      await tester.pumpWidget(buildPanel(actions: [archiveAction]));
      expect(find.text('Archive'), findsOneWidget);
    });

    testWidgets('icon-only button when label is null', (tester) async {
      final iconOnly = SwipeAction(
        icon: const Icon(Icons.archive),
        backgroundColor: const Color(0xFF43A047),
        foregroundColor: const Color(0xFFFFFFFF),
        onTap: noop,
      );
      await tester.pumpWidget(buildPanel(actions: [iconOnly]));
      expect(find.byType(Text), findsNothing);
    });
  });

  group('SwipeActionPanel — non-destructive tap', () {
    testWidgets('non-destructive button fires onTap and calls onClose',
        (tester) async {
      bool tapped = false;
      bool closed = false;

      final action = SwipeAction(
        icon: const Icon(Icons.archive),
        backgroundColor: const Color(0xFF43A047),
        foregroundColor: const Color(0xFFFFFFFF),
        onTap: () => tapped = true,
      );

      await tester.pumpWidget(buildPanel(
        actions: [action],
        onClose: () => closed = true,
      ));

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(tapped, isTrue);
      expect(closed, isTrue);
    });
  });

  group('SwipeActionPanel — destructive confirm-expand', () {
    testWidgets('destructive first tap does NOT fire onTap', (tester) async {
      bool tapped = false;

      final destructive = SwipeAction(
        icon: const Icon(Icons.delete),
        label: 'Delete',
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: const Color(0xFFFFFFFF),
        onTap: () => tapped = true,
        isDestructive: true,
      );

      await tester.pumpWidget(buildPanel(actions: [destructive]));
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(tapped, isFalse);
    });

    testWidgets('destructive second tap fires onTap and calls onClose',
        (tester) async {
      bool tapped = false;
      bool closed = false;

      final destructive = SwipeAction(
        icon: const Icon(Icons.delete),
        label: 'Delete',
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: const Color(0xFFFFFFFF),
        onTap: () => tapped = true,
        isDestructive: true,
      );

      await tester.pumpWidget(buildPanel(
        actions: [destructive],
        onClose: () => closed = true,
      ));

      // First tap — expand.
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();
      expect(tapped, isFalse);
      expect(closed, isFalse);

      // Second tap — confirm.
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      expect(tapped, isTrue);
      expect(closed, isTrue);
    });

    testWidgets(
        'destructive expanded shows AnimatedContainer taking full width',
        (tester) async {
      bool tapped = false;

      final destructive = SwipeAction(
        icon: const Icon(Icons.delete),
        label: 'Delete',
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: const Color(0xFFFFFFFF),
        onTap: () => tapped = true,
        isDestructive: true,
      );

      await tester.pumpWidget(buildPanel(actions: [destructive]));

      // First tap — expand.
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      // AnimatedContainer is shown (expanded state).
      expect(find.byType(AnimatedContainer), findsOneWidget);
      expect(tapped, isFalse);
    });
  });
}

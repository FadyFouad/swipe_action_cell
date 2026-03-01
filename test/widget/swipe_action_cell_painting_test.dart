import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:swipe_action_cell/swipe_action_cell.dart";
import "package:swipe_action_cell/src/painting/swipe_painting_config.dart";
import "package:swipe_action_cell/src/painting/particle_config.dart";

class _TestPainter extends CustomPainter {
  _TestPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TestPainter old) => color != old.color;
}

class _ThrowingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    throw Exception("Intentional Painter Error");
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

void main() {
  group("SwipeActionCell Painting US1", () {
    testWidgets("background painter renders", (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SwipeActionCell(
        paintingConfig: SwipePaintingConfig(
            backgroundPainter: (p, s) => _TestPainter(Colors.blue)),
        child: const SizedBox(width: 400, height: 100, child: Text("Cell")),
      ))));
      expect(
          find.byWidgetPredicate(
              (w) => w is CustomPaint && w.painter is _TestPainter),
          findsOneWidget);
    });

    testWidgets("foreground painter renders", (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SwipeActionCell(
        paintingConfig: SwipePaintingConfig(
            foregroundPainter: (p, s) => _TestPainter(Colors.yellow)),
        child: const SizedBox(width: 400, height: 100, child: Text("Cell")),
      ))));
      expect(
          find.byWidgetPredicate(
              (w) => w is CustomPaint && w.painter is _TestPainter),
          findsOneWidget);
    });

    testWidgets("paintingConfig: null -> Stack has no extra children",
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
          home: Scaffold(
              body: SwipeActionCell(
        paintingConfig: null,
        child: SizedBox(width: 400, height: 100, child: Text("Cell")),
      ))));
      expect(
          find.byWidgetPredicate((w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == "_NoOpPainter"),
          findsNothing);
    });
  });

  group("SwipeActionCell Decoration US2", () {
    testWidgets("decoration applies correctly", (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SwipeActionCell(
        paintingConfig: const SwipePaintingConfig(
            restingDecoration: BoxDecoration(color: Colors.grey)),
        child: const SizedBox(width: 400, height: 100, child: Text("Cell")),
      ))));
      expect(find.byType(DecoratedBox), findsOneWidget);
    });
  });

  group("SwipeActionCell Particles US4", () {
    testWidgets(
        "intentional left-swipe action completes -> particle layer added",
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: MediaQuery(
                  data: const MediaQueryData(disableAnimations: true),
                  child: SwipeActionCell(
                    paintingConfig: const SwipePaintingConfig(
                        particleConfig: ParticleConfig(count: 12)),
                    leftSwipeConfig: LeftSwipeConfig(
                        mode: LeftSwipeMode.autoTrigger,
                        onActionTriggered: () {}),
                    child: const SizedBox(
                        width: 400, height: 100, child: Text("Cell")),
                  )))));

      await tester.drag(find.text("Cell"), const Offset(-300, 0));
      await tester.pump();

      expect(
          find.byWidgetPredicate((w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == "SwipeParticlePainter"),
          findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets("progressive right-swipe action -> no particle layer",
        (tester) async {
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: SwipeActionCell(
        paintingConfig: const SwipePaintingConfig(
            particleConfig: ParticleConfig(count: 12)),
        rightSwipeConfig:
            RightSwipeConfig(stepValue: 1.0, onSwipeCompleted: (_) {}),
        child: const SizedBox(width: 400, height: 100, child: Text("Cell")),
      ))));

      await tester.drag(find.text("Cell"), const Offset(300, 0));
      await tester.pump();

      expect(
          find.byWidgetPredicate((w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == "SwipeParticlePainter"),
          findsNothing);
      await tester.pumpAndSettle();
    });
  });
}

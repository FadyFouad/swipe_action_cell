import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:swipe_action_cell/src/painting/swipe_morph_icon.dart";

void main() {
  group("SwipeMorphIcon US3", () {
    testWidgets("progress=0.0 -> only startIcon visible (opacity 1.0)",
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwipeMorphIcon(
              startIcon: Text("Start"),
              endIcon: Text("End"),
              progress: 0.0,
            ),
          ),
        ),
      );

      final startOpacity = tester.widget<Opacity>(find.ancestor(
          of: find.text("Start"), matching: find.byType(Opacity)));
      final endOpacity = tester.widget<Opacity>(
          find.ancestor(of: find.text("End"), matching: find.byType(Opacity)));

      expect(startOpacity.opacity, 1.0);
      expect(endOpacity.opacity, 0.0);
    });

    testWidgets("progress=0.5 -> both icons at opacity 0.5", (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwipeMorphIcon(
              startIcon: Text("Start"),
              endIcon: Text("End"),
              progress: 0.5,
            ),
          ),
        ),
      );

      final startOpacity = tester.widget<Opacity>(find.ancestor(
          of: find.text("Start"), matching: find.byType(Opacity)));
      final endOpacity = tester.widget<Opacity>(
          find.ancestor(of: find.text("End"), matching: find.byType(Opacity)));

      expect(startOpacity.opacity, 0.5);
      expect(endOpacity.opacity, 0.5);
    });

    testWidgets(
        "progress clamped: values < 0.0 and > 1.0 do not crash and clamp correctly",
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwipeMorphIcon(
              startIcon: Text("Start"),
              endIcon: Text("End"),
              progress: 1.5,
            ),
          ),
        ),
      );

      final endOpacity1 = tester.widget<Opacity>(
          find.ancestor(of: find.text("End"), matching: find.byType(Opacity)));
      expect(endOpacity1.opacity, 1.0);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SwipeMorphIcon(
              startIcon: Text("Start"),
              endIcon: Text("End"),
              progress: -0.5,
            ),
          ),
        ),
      );

      final startOpacity2 = tester.widget<Opacity>(find.ancestor(
          of: find.text("Start"), matching: find.byType(Opacity)));
      expect(startOpacity2.opacity, 1.0);
    });
  });
}

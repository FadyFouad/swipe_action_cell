import 'package:flutter/material.dart';
import '../controller/swipe_controller.dart';

/// Wraps a [SwipeActionCell] with all required test ancestors.
///
/// Use this in widget tests instead of `MaterialApp` to avoid the overhead
/// of full Material routing while still providing [Directionality],
/// [MediaQuery], [Localizations], and [Material]:
///
/// ```dart
/// testWidgets('delete fires after undo window', (tester) async {
///   bool deleted = false;
///   await tester.pumpWidget(SwipeTestHarness(
///     child: SwipeActionCell.delete(
///       onDeleted: () => deleted = true,
///       child: const ListTile(title: Text('Item')),
///     ),
///   ));
///   await SwipeTester.swipeLeft(tester, find.byType(SwipeActionCell));
///   // undo window: advance clock
///   await tester.pump(const Duration(seconds: 6));
///   expect(deleted, isTrue);
/// });
/// ```
class SwipeTestHarness extends StatelessWidget {
  /// Creates a [SwipeTestHarness].
  const SwipeTestHarness({
    super.key,
    required this.child,
    this.textDirection = TextDirection.ltr,
    this.locale = const Locale('en'),
    this.screenSize = const Size(390, 844),
    this.controller,
  });

  /// The widget under test (usually [SwipeActionCell]).
  final Widget child;

  /// The text direction context (defaults to LTR).
  final TextDirection textDirection;

  /// The locale context (defaults to 'en').
  final Locale locale;

  /// The simulated screen size (defaults to 390x844).
  final Size screenSize;

  /// Optional [SwipeController] to keep in scope.
  final SwipeController? controller;

  @override
  Widget build(BuildContext context) => MediaQuery(
        data: MediaQueryData(
          size: screenSize,
          devicePixelRatio: 1.0,
          textScaler: TextScaler.noScaling,
        ),
        child: Localizations(
          locale: locale,
          delegates: const [
            DefaultWidgetsLocalizations.delegate,
            DefaultMaterialLocalizations.delegate,
          ],
          child: Directionality(
            textDirection: textDirection,
            child: Material(child: child),
          ),
        ),
      );
}

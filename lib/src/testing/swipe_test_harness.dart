import 'package:flutter/material.dart';
import '../controller/swipe_controller.dart';

/// Wraps a [SwipeActionCell] with all required test ancestors.
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

/// Defines the visual style for prebuilt [SwipeActionCell] templates.
enum TemplateStyle {
  /// Automatically detect platform at call time.
  ///
  /// iOS and macOS map to [cupertino]; all other platforms map to [material].
  auto,

  /// Force Material Design icons and behavior.
  material,

  /// Force Cupertino (iOS) icons and behavior.
  cupertino,
}

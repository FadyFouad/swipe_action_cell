import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../config/swipe_visual_config.dart';
import '../core/typedefs.dart';
import 'template_style.dart';

/// Resolves the effective template style based on the provided [style]
/// and the current platform.
TemplateStyle resolveStyle(TemplateStyle style) {
  if (style != TemplateStyle.auto) return style;
  return (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS)
      ? TemplateStyle.cupertino
      : TemplateStyle.material;
}

/// Builds a [SwipeVisualConfig] tailored to the [resolvedStyle].
SwipeVisualConfig buildVisualConfig({
  required TemplateStyle resolvedStyle,
  SwipeBackgroundBuilder? leftBackground,
  SwipeBackgroundBuilder? rightBackground,
}) {
  return SwipeVisualConfig(
    leftBackground: leftBackground,
    rightBackground: rightBackground,
    clipBehavior: resolvedStyle == TemplateStyle.cupertino
        ? Clip.antiAlias
        : Clip.hardEdge,
    borderRadius: resolvedStyle == TemplateStyle.cupertino
        ? const BorderRadius.all(Radius.circular(12))
        : null,
  );
}

/// Internal helper to resolve assets for the delete template.
({Widget primaryIcon, Color backgroundColor}) deleteAssets(
    TemplateStyle style, Widget? iconOverride, Color? colorOverride) {
  final isCupertino = style == TemplateStyle.cupertino;
  return (
    primaryIcon: iconOverride ??
        (isCupertino
            ? const Icon(CupertinoIcons.trash, color: Colors.white, size: 28)
            : const Icon(Icons.delete_outline, color: Colors.white, size: 28)),
    backgroundColor: colorOverride ?? const Color(0xFFE53935),
  );
}

/// Internal helper to resolve assets for the archive template.
({Widget primaryIcon, Color backgroundColor}) archiveAssets(
    TemplateStyle style, Widget? iconOverride, Color? colorOverride) {
  final isCupertino = style == TemplateStyle.cupertino;
  return (
    primaryIcon: iconOverride ??
        (isCupertino
            ? const Icon(CupertinoIcons.archivebox,
                color: Colors.white, size: 28)
            : const Icon(Icons.archive_outlined,
                color: Colors.white, size: 28)),
    backgroundColor: colorOverride ?? const Color(0xFF00897B),
  );
}

/// Internal helper to resolve assets for the favorite template.
({Widget outlineIcon, Widget filledIcon, Color backgroundColor}) favoriteAssets(
    TemplateStyle style,
    Widget? outlineOverride,
    Widget? filledOverride,
    Color? colorOverride) {
  final isCupertino = style == TemplateStyle.cupertino;
  return (
    outlineIcon: outlineOverride ??
        (isCupertino
            ? const Icon(CupertinoIcons.heart, color: Colors.white, size: 28)
            : const Icon(Icons.favorite_border, color: Colors.white, size: 28)),
    filledIcon: filledOverride ??
        (isCupertino
            ? const Icon(CupertinoIcons.heart_fill,
                color: Colors.white, size: 28)
            : const Icon(Icons.favorite, color: Colors.white, size: 28)),
    backgroundColor: colorOverride ?? const Color(0xFFFFB300),
  );
}

/// Internal helper to resolve assets for the checkbox template.
({Widget uncheckedIcon, Widget checkedIcon, Color backgroundColor})
    checkboxAssets(TemplateStyle style, Widget? uncheckedOverride,
        Widget? checkedOverride, Color? colorOverride) {
  final isCupertino = style == TemplateStyle.cupertino;
  return (
    uncheckedIcon: uncheckedOverride ??
        (isCupertino
            ? const Icon(CupertinoIcons.circle, color: Colors.white, size: 28)
            : const Icon(Icons.check_box_outline_blank,
                color: Colors.white, size: 28)),
    checkedIcon: checkedOverride ??
        (isCupertino
            ? const Icon(CupertinoIcons.checkmark_circle_fill,
                color: Colors.white, size: 28)
            : const Icon(Icons.check_box, color: Colors.white, size: 28)),
    backgroundColor: colorOverride ?? const Color(0xFF43A047),
  );
}

/// Internal helper to resolve assets for the counter template.
({Widget primaryIcon, Color backgroundColor}) counterAssets(
    TemplateStyle style, Widget? iconOverride, Color? colorOverride) {
  final isCupertino = style == TemplateStyle.cupertino;
  return (
    primaryIcon: iconOverride ??
        (isCupertino
            ? const Icon(CupertinoIcons.add_circled,
                color: Colors.white, size: 28)
            : const Icon(Icons.add_circle_outline,
                color: Colors.white, size: 28)),
    backgroundColor: colorOverride ?? const Color(0xFF1E88E5),
  );
}

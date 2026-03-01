import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/src/templates/template_style.dart';
import 'package:swipe_action_cell/src/templates/swipe_cell_templates.dart';

void main() {
  group('TemplateStyle', () {
    test('enum values exist', () {
      expect(TemplateStyle.values.length, 3);
    });
  });

  group('resolveStyle platform mapping', () {
    test('returns material for Android when auto', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(resolveStyle(TemplateStyle.auto), TemplateStyle.material);
      debugDefaultTargetPlatformOverride = null;
    });

    test('returns cupertino for iOS when auto', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      expect(resolveStyle(TemplateStyle.auto), TemplateStyle.cupertino);
      debugDefaultTargetPlatformOverride = null;
    });
  });
}

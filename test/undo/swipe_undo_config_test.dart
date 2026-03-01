import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swipe_action_cell/src/undo/swipe_undo_config.dart';

void main() {
  group('SwipeUndoOverlayPosition', () {
    test('values', () {
      expect(SwipeUndoOverlayPosition.values, [
        SwipeUndoOverlayPosition.top,
        SwipeUndoOverlayPosition.bottom,
      ]);
    });
  });

  group('SwipeUndoOverlayConfig', () {
    test('const construction with defaults', () {
      const config = SwipeUndoOverlayConfig();
      expect(config.position, SwipeUndoOverlayPosition.bottom);
      expect(config.backgroundColor, isNull);
      expect(config.textColor, isNull);
      expect(config.buttonColor, isNull);
      expect(config.progressBarColor, isNull);
      expect(config.progressBarHeight, 3.0);
      expect(config.textStyle, isNull);
      expect(config.undoButtonLabel, 'Undo');
      expect(config.actionLabel, isNull);
    });

    test('custom values', () {
      const config = SwipeUndoOverlayConfig(
        position: SwipeUndoOverlayPosition.top,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        buttonColor: Colors.yellow,
        progressBarColor: Colors.blue,
        progressBarHeight: 5.0,
        textStyle: TextStyle(fontSize: 12),
        undoButtonLabel: 'Revert',
        actionLabel: 'Deleted',
      );
      expect(config.position, SwipeUndoOverlayPosition.top);
      expect(config.backgroundColor, Colors.red);
      expect(config.textColor, Colors.white);
      expect(config.buttonColor, Colors.yellow);
      expect(config.progressBarColor, Colors.blue);
      expect(config.progressBarHeight, 5.0);
      expect(config.textStyle?.fontSize, 12);
      expect(config.undoButtonLabel, 'Revert');
      expect(config.actionLabel, 'Deleted');
    });

    test('copyWith preserves unchanged fields', () {
      const config = SwipeUndoOverlayConfig(progressBarHeight: 4.0);
      final updated = config.copyWith(undoButtonLabel: 'Back');
      expect(updated.progressBarHeight, 4.0);
      expect(updated.undoButtonLabel, 'Back');
    });

    test('equality and hashCode', () {
      const c1 = SwipeUndoOverlayConfig(progressBarHeight: 4.0);
      const c2 = SwipeUndoOverlayConfig(progressBarHeight: 4.0);
      const c3 = SwipeUndoOverlayConfig(progressBarHeight: 5.0);
      expect(c1, c2);
      expect(c1.hashCode, c2.hashCode);
      expect(c1, isNot(c3));
    });

    test('debug assert fires when progressBarHeight < 0', () {
      expect(
        () => SwipeUndoOverlayConfig(progressBarHeight: -1.0),
        throwsAssertionError,
      );
    });
  });

  group('SwipeUndoConfig', () {
    test('const construction with defaults', () {
      const config = SwipeUndoConfig();
      expect(config.duration, const Duration(seconds: 5));
      expect(config.showBuiltInOverlay, true);
      expect(config.overlayConfig, isNull);
      expect(config.onUndoAvailable, isNull);
      expect(config.onUndoTriggered, isNull);
      expect(config.onUndoExpired, isNull);
    });

    test('custom values', () {
      const config = SwipeUndoConfig(
        duration: Duration(seconds: 10),
        showBuiltInOverlay: false,
      );
      expect(config.duration, const Duration(seconds: 10));
      expect(config.showBuiltInOverlay, false);
    });

    test('copyWith preserves unchanged fields', () {
      const config = SwipeUndoConfig(duration: Duration(seconds: 2));
      final updated = config.copyWith(showBuiltInOverlay: false);
      expect(updated.duration, const Duration(seconds: 2));
      expect(updated.showBuiltInOverlay, false);
    });

    test('equality and hashCode', () {
      const c1 = SwipeUndoConfig(duration: Duration(seconds: 2));
      const c2 = SwipeUndoConfig(duration: Duration(seconds: 2));
      const c3 = SwipeUndoConfig(duration: Duration(seconds: 3));
      expect(c1, c2);
      expect(c1.hashCode, c2.hashCode);
      expect(c1, isNot(c3));
    });
  });
}

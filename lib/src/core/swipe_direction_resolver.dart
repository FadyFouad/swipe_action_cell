import 'package:flutter/widgets.dart';

import 'swipe_direction.dart';

/// Controls how [SwipeActionCell] resolves its effective text direction.
enum ForceDirection {
  /// Read ambient [Directionality.of(context)] automatically (default).
  auto,

  /// Force left-to-right layout regardless of ambient directionality.
  ltr,

  /// Force right-to-left layout regardless of ambient directionality.
  rtl,
}

/// Resolves the effective text direction and maps physical drag directions
/// to semantic action roles (forward/backward).
///
/// This class is not intended to be instantiated. All members are static
/// utility methods.
abstract final class SwipeDirectionResolver {
  /// Returns `true` if the effective direction is right-to-left.
  ///
  /// When [force] is [ForceDirection.auto], reads [Directionality.of] from [context].
  /// Otherwise, the forced direction wins.
  static bool isRtl(BuildContext context, ForceDirection force) {
    switch (force) {
      case ForceDirection.ltr:
        return false;
      case ForceDirection.rtl:
        return true;
      case ForceDirection.auto:
        return Directionality.of(context) == TextDirection.rtl;
    }
  }

  /// The physical direction that triggers the forward (progressive) action.
  ///
  /// In LTR, forward is [SwipeDirection.right].
  /// In RTL, forward is [SwipeDirection.left].
  static SwipeDirection forwardPhysical(bool isRtl) =>
      isRtl ? SwipeDirection.left : SwipeDirection.right;

  /// The physical direction that triggers the backward (intentional) action.
  ///
  /// In LTR, backward is [SwipeDirection.left].
  /// In RTL, backward is [SwipeDirection.right].
  static SwipeDirection backwardPhysical(bool isRtl) =>
      isRtl ? SwipeDirection.right : SwipeDirection.left;

  /// Returns the config for the given [physical] direction considering [isRtl].
  ///
  /// In LTR: right → [rightConfig], left → [leftConfig].
  /// In RTL: right → [leftConfig], left → [rightConfig].
  static T? configForPhysical<T>(
    SwipeDirection physical, {
    required bool isRtl,
    required T? rightConfig,
    required T? leftConfig,
  }) {
    if (!isRtl) {
      return physical == SwipeDirection.right ? rightConfig : leftConfig;
    } else {
      return physical == SwipeDirection.right ? leftConfig : rightConfig;
    }
  }
}

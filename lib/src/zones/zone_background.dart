import 'package:flutter/material.dart';
import 'package:swipe_action_cell/src/core/swipe_progress.dart';
import 'package:swipe_action_cell/src/core/swipe_zone.dart';
import 'zone_resolver.dart';

/// Renders the background for a multi-zone swipe direction.
///
/// Provides visual feedback including zone-specific backgrounds, smooth
/// transitions between zones, and a scale-bump click effect on boundary crossing.
class ZoneAwareBackground extends StatefulWidget {
  /// The list of zones for the current direction.
  final List<SwipeZone> zones;

  /// The current swipe progress.
  final SwipeProgress progress;

  /// The style used for transitions between zone backgrounds.
  final ZoneTransitionStyle transitionStyle;

  /// Creates a [ZoneAwareBackground].
  const ZoneAwareBackground({
    super.key,
    required this.zones,
    required this.progress,
    this.transitionStyle = ZoneTransitionStyle.instant,
  });

  @override
  State<ZoneAwareBackground> createState() => _ZoneAwareBackgroundState();
}

class _ZoneAwareBackgroundState extends State<ZoneAwareBackground>
    with TickerProviderStateMixin {
  late AnimationController _clickController;
  late Animation<double> _scaleAnimation;
  int _previousZoneIndex = -1;

  @override
  void initState() {
    super.initState();
    _clickController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_clickController);

    _previousZoneIndex =
        resolveActiveZoneIndex(widget.zones, widget.progress.ratio);
  }

  @override
  void didUpdateWidget(ZoneAwareBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newZoneIndex =
        resolveActiveZoneIndex(widget.zones, widget.progress.ratio);
    if (newZoneIndex != _previousZoneIndex) {
      if ((MediaQuery.maybeDisableAnimationsOf(context) ?? false) == false) {
        _clickController.forward(from: 0.0);
      }
      _previousZoneIndex = newZoneIndex;
    }
  }

  @override
  void dispose() {
    _clickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeZoneIndex =
        resolveActiveZoneIndex(widget.zones, widget.progress.ratio);
    if (activeZoneIndex == -1) return const SizedBox.shrink();

    final zone = widget.zones[activeZoneIndex];
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context);
    final effectiveStyle = (disableAnimations ?? false)
        ? ZoneTransitionStyle.instant
        : widget.transitionStyle;

    Widget background;
    if (zone.background != null) {
      background = zone.background!(context, widget.progress);
    } else {
      background = Container(
        color: zone.color,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (zone.icon != null) zone.icon!,
              if (zone.label != null)
                Text(
                  zone.label!,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
            ],
          ),
        ),
      );
    }

    // Apply scale bump
    background = ScaleTransition(
      scale: _scaleAnimation,
      child: background,
    );

    if (effectiveStyle == ZoneTransitionStyle.instant) {
      return KeyedSubtree(
        key: ValueKey<int>(activeZoneIndex),
        child: background,
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        if (effectiveStyle == ZoneTransitionStyle.crossfade) {
          return FadeTransition(opacity: animation, child: child);
        } else {
          // SlideTransition
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.2, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(opacity: animation, child: child),
          );
        }
      },
      child: KeyedSubtree(
        key: ValueKey<int>(activeZoneIndex),
        child: background,
      ),
    );
  }
}

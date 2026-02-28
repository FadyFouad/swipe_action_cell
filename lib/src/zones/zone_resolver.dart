import 'package:swipe_action_cell/src/core/swipe_zone.dart';

/// Returns index of highest zone with threshold <= ratio, or -1 if none.
/// Assumes zones are already sorted ascending.
int resolveActiveZoneIndex(List<SwipeZone> zones, double ratio) {
  if (zones.isEmpty) return -1;
  
  int activeIndex = -1;
  for (int i = 0; i < zones.length; i++) {
    if (ratio >= zones[i].threshold) {
      activeIndex = i;
    } else {
      // Since zones are sorted ascending, if ratio < current threshold,
      // it will be < all subsequent thresholds.
      break;
    }
  }
  return activeIndex;
}

/// Convenience wrapper over resolveActiveZoneIndex. Returns null if -1.
SwipeZone? resolveActiveZone(List<SwipeZone> zones, double ratio) {
  final index = resolveActiveZoneIndex(zones, ratio);
  return index == -1 ? null : zones[index];
}

/// Asserts that the provided list of [SwipeZone]s is valid.
void assertZonesValid(List<SwipeZone> zones, {bool progressive = false}) {
  assert(zones.length <= 4, 'zones must have at most 4 entries for the swipe direction.');
  
  double lastThreshold = -1.0;
  for (final zone in zones) {
    assert(zone.threshold > lastThreshold, 'Zone thresholds must be strictly ascending.');
    lastThreshold = zone.threshold;
    
    if (progressive) {
      assert(zone.stepValue != null && zone.stepValue! > 0, 
        'Progressive zones must each have a stepValue > 0.');
    }
  }
}

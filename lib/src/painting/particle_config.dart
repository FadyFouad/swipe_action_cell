import 'package:flutter/widgets.dart';

/// Configuration for the particle burst effect.
@immutable
class ParticleConfig {
  /// Creates a [ParticleConfig].
  const ParticleConfig({
    this.count = 12,
    this.colors = const <Color>[],
    this.spreadAngle = 360.0,
    this.duration = const Duration(milliseconds: 500),
  });

  /// Number of particles emitted per burst. 0 = no burst.
  final int count;

  /// Color palette. Particles cycle through this list.
  /// If empty, a default palette is used.
  final List<Color> colors;

  /// Total spread angle in degrees. 360 = all directions; 90 = cone.
  final double spreadAngle;

  /// Total animation duration.
  final Duration duration;

  /// Returns a copy of this config with the specified fields replaced.
  ParticleConfig copyWith({
    int? count,
    List<Color>? colors,
    double? spreadAngle,
    Duration? duration,
  }) {
    return ParticleConfig(
      count: count ?? this.count,
      colors: colors ?? this.colors,
      spreadAngle: spreadAngle ?? this.spreadAngle,
      duration: duration ?? this.duration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ParticleConfig) return false;

    // Quick length check before deeper equality
    if (other.count != count ||
        other.spreadAngle != spreadAngle ||
        other.duration != duration ||
        other.colors.length != colors.length) {
      return false;
    }

    for (int i = 0; i < colors.length; i++) {
      if (colors[i] != other.colors[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
        count,
        Object.hashAll(colors),
        spreadAngle,
        duration,
      );
}

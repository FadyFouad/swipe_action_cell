import 'package:flutter/foundation.dart';

/// Physics parameters for a single spring animation.
@immutable
class SpringConfig {
  /// Creates a [SpringConfig] with the given spring physics parameters.
  const SpringConfig({
    this.mass = 1.0,
    this.stiffness = 500.0,
    this.damping = 28.0,
  });

  /// Simulated mass of the dragged object. Higher mass = slower response.
  final double mass;

  /// Spring constant (k). Higher stiffness = snappier animation.
  final double stiffness;

  /// Damping coefficient.
  final double damping;

  /// A preset for snap-back animations: responsive but not jarring.
  static const SpringConfig snapBack = SpringConfig(
    stiffness: 400.0,
    damping: 25.0,
  );

  /// A preset for undo reveal animations: slight bounce, distinct from snapBack.
  static const SpringConfig undoReveal = SpringConfig(
    mass: 1.0,
    stiffness: 300.0,
    damping: 18.0,
  );

  /// A preset for completion animations: snappy and decisive.
  static const SpringConfig completion = SpringConfig(
    stiffness: 600.0,
    damping: 32.0,
  );

  /// Returns a copy of this config with the specified fields replaced.
  SpringConfig copyWith({double? mass, double? stiffness, double? damping}) {
    return SpringConfig(
      mass: mass ?? this.mass,
      stiffness: stiffness ?? this.stiffness,
      damping: damping ?? this.damping,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpringConfig &&
        other.mass == mass &&
        other.stiffness == stiffness &&
        other.damping == damping;
  }

  @override
  int get hashCode => Object.hash(mass, stiffness, damping);
}

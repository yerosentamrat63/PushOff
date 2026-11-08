/// Configuration thresholds for the Push-Up Rep Counting Engine.
/// Pure Dart - No Flutter imports.
class RepCounterConfig {
  /// Angle in degrees the elbow must reach or go below at the bottom for a valid rep.
  final double minElbowDepthAngle;

  /// Angle in degrees the elbow must reach at the top for a lockout.
  final double minElbowLockoutAngle;

  /// Hysteresis threshold: elbow angle must drop below this to enter DOWN state.
  final double enterDownAngle;

  /// Hysteresis threshold: elbow angle must rise above this to leave DOWN state.
  final double leaveDownAngle;

  /// Hysteresis threshold: elbow angle must rise above this to enter UP state.
  final double enterUpAngle;

  /// Minimum body line (shoulder-hip-ankle) angle required throughout the rep.
  final double minBodyLineAngle;

  /// Ideal straight body line angle for 100% form score calculation.
  final double idealBodyLineAngle;

  /// Minimum duration in seconds a full rep must take to be valid (blocks jitter).
  final double minRepDurationSeconds;

  /// Minimum landmark confidence (likelihood) threshold.
  final double minConfidenceThreshold;

  /// Legacy window size for moving average smoothing.
  ///
  /// A value of 1 (or [useOneEuroFilter] = false) disables smoothing so the
  /// engine consumes raw angles, which keeps deterministic tests stable.
  final int movingAverageWindowSize;

  /// Enables the adaptive One Euro filter (replaces the fixed moving average).
  final bool useOneEuroFilter;

  /// One Euro filter: baseline cutoff frequency in Hz. Lower = smoother.
  final double oneEuroMinCutoff;

  /// One Euro filter: speed coefficient. Higher = less lag on fast reps.
  final double oneEuroBeta;

  /// One Euro filter: derivative cutoff frequency in Hz.
  final double oneEuroDerivativeCutoff;

  const RepCounterConfig({
    this.minElbowDepthAngle = 90.0,
    this.minElbowLockoutAngle = 155.0,
    this.enterDownAngle = 100.0,
    this.leaveDownAngle = 120.0,
    this.enterUpAngle = 155.0,
    this.minBodyLineAngle = 165.0,
    this.idealBodyLineAngle = 175.0,
    this.minRepDurationSeconds = 0.4,
    this.minConfidenceThreshold = 0.6,
    this.movingAverageWindowSize = 5,
    this.useOneEuroFilter = true,
    this.oneEuroMinCutoff = 1.2,
    this.oneEuroBeta = 0.05,
    this.oneEuroDerivativeCutoff = 1.0,
  });

  /// Default standard push-up configuration.
  static const RepCounterConfig defaultConfig = RepCounterConfig();
}


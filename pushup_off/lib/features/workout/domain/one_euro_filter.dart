import 'dart:math' as math;

/// One Euro adaptive low-pass filter.
///
/// A fixed moving average has constant phase lag, which suppresses the true
/// turnaround point of fast reps. The One Euro filter lowers its cutoff when
/// the signal is slow (heavy smoothing) and raises it when the signal moves
/// fast (minimal lag), so it tracks real reps without jitter.
///
/// Parameters are expressed in Hz for [minCutoff]/[derivativeCutoff] and in
/// "cutoff units per degree/second" for [beta].
class OneEuroFilter {
  final double minCutoff;
  final double beta;
  final double derivativeCutoff;

  double _lastValue = 0.0;
  double _lastDerivative = 0.0;
  DateTime? _lastTimestamp;
  bool _initialized = false;

  OneEuroFilter({
    this.minCutoff = 1.2,
    this.beta = 0.05,
    this.derivativeCutoff = 1.0,
  });

  bool get isInitialized => _initialized;

  double filter(double value, DateTime timestamp) {
    double dt = 1.0 / 30.0;
    final previous = _lastTimestamp;
    if (previous != null) {
      dt = timestamp.difference(previous).inMicroseconds / 1000000.0;
    }
    // Guard against clock jitter, duplicate timestamps and long suspensions.
    if (!dt.isFinite || dt <= 0) {
      dt = 1.0 / 30.0;
    }
    dt = dt.clamp(1.0 / 240.0, 0.25).toDouble();
    _lastTimestamp = timestamp;

    if (!_initialized) {
      _initialized = true;
      _lastValue = value;
      _lastDerivative = 0.0;
      return value;
    }

    final rawDerivative = (value - _lastValue) / dt;
    final derivative = _lowPass(
      rawDerivative,
      _lastDerivative,
      _alpha(dt, derivativeCutoff),
    );
    _lastDerivative = derivative;

    final cutoff = minCutoff + beta * derivative.abs();
    final filtered = _lowPass(value, _lastValue, _alpha(dt, cutoff));
    _lastValue = filtered;
    return filtered;
  }

  static double _alpha(double dt, double cutoff) {
    final tau = 1.0 / (2.0 * math.pi * cutoff);
    return 1.0 / (1.0 + tau / dt);
  }

  static double _lowPass(double value, double previous, double alpha) {
    return alpha * value + (1.0 - alpha) * previous;
  }

  void reset() {
    _lastValue = 0.0;
    _lastDerivative = 0.0;
    _lastTimestamp = null;
    _initialized = false;
  }
}

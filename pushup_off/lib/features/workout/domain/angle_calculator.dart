import 'dart:collection';
import 'dart:math' as math;
import 'models/pose_frame.dart';

class AngleCalculator {
  /// Computes the 2D interior angle at vertex B formed by rays BA and BC in degrees [0, 180].
  static double calculateAngle(PosePoint a, PosePoint b, PosePoint c) {
    final v1x = a.x - b.x;
    final v1y = a.y - b.y;
    final v2x = c.x - b.x;
    final v2y = c.y - b.y;

    final dot = v1x * v2x + v1y * v2y;
    final mag1 = math.sqrt(v1x * v1x + v1y * v1y);
    final mag2 = math.sqrt(v2x * v2x + v2y * v2y);

    if (mag1 == 0.0 || mag2 == 0.0) return 180.0;

    final cosine = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    final radians = math.acos(cosine);
    return radians * (180.0 / math.pi);
  }

  /// Computes the interior angle at vertex B in 3D using the landmark depth
  /// component. Perspective foreshortening collapses a real elbow angle in 2D
  /// when the phone is not exactly side-on; incorporating z restores the
  /// component the camera cannot see.
  static double calculateAngle3D(PosePoint a, PosePoint b, PosePoint c) {
    final v1x = a.x - b.x;
    final v1y = a.y - b.y;
    final v1z = a.z - b.z;
    final v2x = c.x - b.x;
    final v2y = c.y - b.y;
    final v2z = c.z - b.z;

    final dot = v1x * v2x + v1y * v2y + v1z * v2z;
    final mag1 = math.sqrt(v1x * v1x + v1y * v1y + v1z * v1z);
    final mag2 = math.sqrt(v2x * v2x + v2y * v2y + v2z * v2z);

    if (mag1 == 0.0 || mag2 == 0.0) return 180.0;

    final cosine = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    final radians = math.acos(cosine);
    return radians * (180.0 / math.pi);
  }

  /// Uses 3D when the landmark set actually carries depth, otherwise falls back
  /// to the planar calculation (synthetic data and 2D-only sources).
  static double calculateAngleAuto(PosePoint a, PosePoint b, PosePoint c) {
    final hasDepth = a.z.abs() > 1e-4 || b.z.abs() > 1e-4 || c.z.abs() > 1e-4;
    return hasDepth
        ? calculateAngle3D(a, b, c)
        : calculateAngle(a, b, c);
  }

  /// Determines whether hip misalignment represents sagging (towards floor) or piking (towards ceiling).
  /// In 2D screen coordinates, Y increases downwards towards the ground.
  static bool isHipSagging({
    required PosePoint shoulder,
    required PosePoint hip,
    required PosePoint ankle,
  }) {
    // Expected y on straight segment from shoulder to ankle
    final dx = ankle.x - shoulder.x;
    if (dx.abs() < 1e-4) {
      // Near vertical orientation
      return hip.x > shoulder.x;
    }

    final t = (hip.x - shoulder.x) / dx;
    final expectedY = shoulder.y + t * (ankle.y - shoulder.y);

    // If hip.y > expectedY, hip is lower down (closer to floor in screen coordinates) -> Sagging!
    return hip.y > expectedY;
  }
}

/// A sliding window moving average filter for smoothing joint angle jitter.
class MovingAverageFilter {
  final int windowSize;
  final Queue<double> _buffer = Queue<double>();
  double _sum = 0.0;

  MovingAverageFilter({this.windowSize = 5}) : assert(windowSize > 0);

  double add(double value) {
    _buffer.addLast(value);
    _sum += value;

    if (_buffer.length > windowSize) {
      _sum -= _buffer.removeFirst();
    }

    return average;
  }

  double get average => _buffer.isEmpty ? 0.0 : _sum / _buffer.length;

  int get count => _buffer.length;

  void reset() {
    _buffer.clear();
    _sum = 0.0;
  }
}


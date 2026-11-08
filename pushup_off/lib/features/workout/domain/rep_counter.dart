import 'angle_calculator.dart';
import 'models/pose_frame.dart';
import 'models/rep_counter_output.dart';
import 'one_euro_filter.dart';
import 'rep_counter_config.dart';

/// Pure Dart Push-Up Rep Counting Engine.
/// No Flutter dependencies.
class RepCounter {
  final RepCounterConfig config;

  // Adaptive smoothing filters for joint angles.
  late final OneEuroFilter _elbowAngleFilter;
  late final OneEuroFilter _bodyLineFilter;
  late final bool _useSmoothing;

  // Last filtered values so paused frames still report something sensible.
  double _lastElbowAngle = 180.0;
  double _lastBodyLineAngle = 180.0;

  // State machine variables
  RepState _currentState = RepState.up;
  int _validReps = 0;
  int _rejectedReps = 0;
  final List<RejectedRepDetail> _rejectedRepsList = [];
  RejectionReason? _latestRejectionReason;
  String _latestFeedbackMessage = 'Get into high plank position';

  // Current active rep metrics
  bool _isRepInProgress = false;
  DateTime? _repStartTime;
  double _minElbowAngleInRep = 180.0;
  double _minBodyLineAngleInRep = 180.0;
  bool _bodyLineViolated = false;
  bool _isSagging = false;
  bool _reachedDownState = false;
  bool _reachedLockout = false;

  // Form score tracking
  final List<double> _repFormScores = [];
  double _currentFormScore = 100.0;
  Duration? _lastRepDuration;

  RepCounter({RepCounterConfig? config})
      : config = config ?? RepCounterConfig.defaultConfig {
    _useSmoothing = this.config.useOneEuroFilter &&
        this.config.movingAverageWindowSize > 1;
    _elbowAngleFilter = OneEuroFilter(
      minCutoff: this.config.oneEuroMinCutoff,
      beta: this.config.oneEuroBeta,
      derivativeCutoff: this.config.oneEuroDerivativeCutoff,
    );
    _bodyLineFilter = OneEuroFilter(
      minCutoff: this.config.oneEuroMinCutoff,
      beta: this.config.oneEuroBeta,
      derivativeCutoff: this.config.oneEuroDerivativeCutoff,
    );
  }

  double _smoothElbow(double raw, DateTime timestamp) {
    return _useSmoothing ? _elbowAngleFilter.filter(raw, timestamp) : raw;
  }

  double _smoothBodyLine(double raw, DateTime timestamp) {
    return _useSmoothing ? _bodyLineFilter.filter(raw, timestamp) : raw;
  }

  /// Processes an incoming [PoseFrame] and returns the updated [RepCounterOutput].
  RepCounterOutput processFrame(PoseFrame frame) {
    final activeSide = frame.prominentSide;
    final sideConfidence = frame.prominentConfidence;

    // Check if key landmarks drop below confidence threshold
    if (sideConfidence < config.minConfidenceThreshold) {
      return _buildOutput(
        liveElbow: _lastElbowAngle,
        liveBodyLine: _lastBodyLineAngle,
        isPaused: true,
        activeSide: activeSide,
        feedback: 'Position body clearly in camera view',
      );
    }

    // Extract side landmarks
    final shoulder = frame.get(
      activeSide == BodySide.left
          ? LandmarkId.leftShoulder
          : LandmarkId.rightShoulder,
    );
    final elbow = frame.get(
      activeSide == BodySide.left
          ? LandmarkId.leftElbow
          : LandmarkId.rightElbow,
    );
    final wrist = frame.get(
      activeSide == BodySide.left
          ? LandmarkId.leftWrist
          : LandmarkId.rightWrist,
    );
    final hip = frame.get(
      activeSide == BodySide.left ? LandmarkId.leftHip : LandmarkId.rightHip,
    );
    final ankle = frame.get(
      activeSide == BodySide.left
          ? LandmarkId.leftAnkle
          : LandmarkId.rightAnkle,
    );

    if (shoulder == null ||
        elbow == null ||
        wrist == null ||
        hip == null ||
        ankle == null) {
      return _buildOutput(
        liveElbow: _lastElbowAngle,
        liveBodyLine: _lastBodyLineAngle,
        isPaused: true,
        activeSide: activeSide,
        feedback: 'Align shoulders, hips and ankles in view',
      );
    }

    // 1. Calculate raw angles. Use depth-aware 3D when landmarks carry it;
    //    synthetic/2D sources fall back to the planar calculation.
    final rawElbowAngle =
        AngleCalculator.calculateAngleAuto(shoulder, elbow, wrist);
    final rawBodyLineAngle =
        AngleCalculator.calculateAngleAuto(shoulder, hip, ankle);

    // 2. Smooth angles with the adaptive One Euro filter.
    final liveElbowAngle = _smoothElbow(rawElbowAngle, frame.timestamp);
    final liveBodyLineAngle =
        _smoothBodyLine(rawBodyLineAngle, frame.timestamp);
    _lastElbowAngle = liveElbowAngle;
    _lastBodyLineAngle = liveBodyLineAngle;

    // 3. Process State Machine & Hysteresis
    _updateStateMachine(
      elbowAngle: liveElbowAngle,
      bodyLineAngle: liveBodyLineAngle,
      shoulder: shoulder,
      hip: hip,
      ankle: ankle,
      timestamp: frame.timestamp,
    );

    return _buildOutput(
      liveElbow: liveElbowAngle,
      liveBodyLine: liveBodyLineAngle,
      isPaused: false,
      activeSide: activeSide,
      feedback: _latestFeedbackMessage,
    );
  }

  void _updateStateMachine({
    required double elbowAngle,
    required double bodyLineAngle,
    required PosePoint shoulder,
    required PosePoint hip,
    required PosePoint ankle,
    required DateTime timestamp,
  }) {
    switch (_currentState) {
      case RepState.up:
        // Transition to DESCENDING when elbow starts bending down past 140°
        if (elbowAngle < 140.0) {
          _currentState = RepState.descending;
          _startNewRep(
              timestamp: timestamp,
              initialElbow: elbowAngle,
              initialBodyLine: bodyLineAngle);
          _latestFeedbackMessage = 'Lower chest to elbow level';
        }
        break;

      case RepState.descending:
        _trackRepExtremes(
            elbowAngle: elbowAngle,
            bodyLineAngle: bodyLineAngle,
            shoulder: shoulder,
            hip: hip,
            ankle: ankle);

        // Hysteresis: Enter DOWN state when elbow drops below enterDownAngle (100°)
        if (elbowAngle <= config.enterDownAngle) {
          _currentState = RepState.down;
          _reachedDownState = true;
          _latestFeedbackMessage = 'Bottom reached! Push up strongly';
        } else if (elbowAngle >= config.enterUpAngle && _isRepInProgress) {
          // User aborted or went back up without hitting bottom threshold
          _reachedLockout = true;
          _evaluateCompletedRep(timestamp: timestamp);
          _currentState = RepState.up;
        }
        break;

      case RepState.down:
        _trackRepExtremes(
            elbowAngle: elbowAngle,
            bodyLineAngle: bodyLineAngle,
            shoulder: shoulder,
            hip: hip,
            ankle: ankle);

        // Hysteresis: Leave DOWN state when elbow rises above leaveDownAngle (120°)
        if (elbowAngle > config.leaveDownAngle) {
          _currentState = RepState.ascending;
          _latestFeedbackMessage = 'Lock out elbows at top';
        }
        break;

      case RepState.ascending:
        _trackRepExtremes(
            elbowAngle: elbowAngle,
            bodyLineAngle: bodyLineAngle,
            shoulder: shoulder,
            hip: hip,
            ankle: ankle);

        // Hysteresis: Enter UP state when elbow rises to enterUpAngle (155°+)
        if (elbowAngle >= config.enterUpAngle) {
          _reachedLockout = true;
          _evaluateCompletedRep(timestamp: timestamp);
          _currentState = RepState.up;
        } else if (elbowAngle <= config.enterDownAngle) {
          // Bounced back down before full lockout: count it as a failed rep
          // instead of silently leaving it incomplete.
          _evaluateCompletedRep(timestamp: timestamp);
          _currentState = RepState.down;
        }
        break;
    }
  }

  void _startNewRep({
    required DateTime timestamp,
    required double initialElbow,
    required double initialBodyLine,
  }) {
    _isRepInProgress = true;
    _repStartTime = timestamp;
    _minElbowAngleInRep = initialElbow;
    _minBodyLineAngleInRep = initialBodyLine;
    _bodyLineViolated = false;
    _isSagging = false;
    _reachedDownState = false;
    _reachedLockout = false;
  }

  void _trackRepExtremes({
    required double elbowAngle,
    required double bodyLineAngle,
    required PosePoint shoulder,
    required PosePoint hip,
    required PosePoint ankle,
  }) {
    if (!_isRepInProgress) return;

    if (elbowAngle < _minElbowAngleInRep) {
      _minElbowAngleInRep = elbowAngle;
    }

    if (bodyLineAngle < _minBodyLineAngleInRep) {
      _minBodyLineAngleInRep = bodyLineAngle;
    }

    // Check body line validity (must remain >= minBodyLineAngle, default 165°)
    if (bodyLineAngle < config.minBodyLineAngle) {
      _bodyLineViolated = true;
      _isSagging = AngleCalculator.isHipSagging(
        shoulder: shoulder,
        hip: hip,
        ankle: ankle,
      );
    }
  }

  void _evaluateCompletedRep({required DateTime timestamp}) {
    if (!_isRepInProgress) return;
    _isRepInProgress = false;

    final duration = _repStartTime != null
        ? timestamp.difference(_repStartTime!)
        : const Duration(milliseconds: 500);

    _lastRepDuration = duration;
    final durationSeconds = duration.inMilliseconds / 1000.0;
    final int repNumber = _validReps + _rejectedReps + 1;

    // Rule 1: Minimum duration (must be >= minRepDurationSeconds, e.g. 0.4s)
    if (durationSeconds < config.minRepDurationSeconds) {
      _rejectRep(
        repNumber: repNumber,
        reason: RejectionReason.tooFast,
        detail:
            '${durationSeconds.toStringAsFixed(1)}s (min ${config.minRepDurationSeconds}s)',
      );
      return;
    }

    // Rule 2: Minimum elbow depth (must reach <= minElbowDepthAngle, e.g. 90°)
    if (!_reachedDownState || _minElbowAngleInRep > config.minElbowDepthAngle) {
      _rejectRep(
        repNumber: repNumber,
        reason: RejectionReason.notDeepEnough,
        detail: 'Elbow ${_minElbowAngleInRep.toStringAsFixed(0)}°',
      );
      return;
    }

    // Rule 3: Body line integrity (must stay >= minBodyLineAngle, e.g. 165°)
    if (_bodyLineViolated || _minBodyLineAngleInRep < config.minBodyLineAngle) {
      final reason =
          _isSagging ? RejectionReason.hipsSagging : RejectionReason.hipsPiked;
      _rejectRep(
        repNumber: repNumber,
        reason: reason,
        detail: 'Body ${_minBodyLineAngleInRep.toStringAsFixed(0)}°',
      );
      return;
    }

    // Rule 4: Full lockout at the top (must reach minElbowLockoutAngle, e.g. 155°)
    if (!_reachedLockout) {
      _rejectRep(
        repNumber: repNumber,
        reason: RejectionReason.noLockout,
        detail: 'Elbow ${_minElbowAngleInRep.toStringAsFixed(0)}°',
      );
      return;
    }

    // All rules passed: VALID REP!
    _validReps++;
    _latestRejectionReason = null;
    _latestFeedbackMessage = 'Clean rep! Keep going';

    // Calculate form score for this rep (0 - 100)
    final repScore = _calculateRepFormScore(
      elbowDepth: _minElbowAngleInRep,
      minBodyLine: _minBodyLineAngleInRep,
    );
    _repFormScores.add(repScore);
    _updateCumulativeFormScore();
  }

  void _rejectRep({
    required int repNumber,
    required RejectionReason reason,
    required String detail,
  }) {
    _rejectedReps++;
    _latestRejectionReason = reason;
    _latestFeedbackMessage = reason.coachTip;

    final rejectedDetail = RejectedRepDetail(
      repNumber: repNumber,
      reason: reason,
      detail: detail,
      timestamp: DateTime.now(),
    );
    _rejectedRepsList.add(rejectedDetail);

    // Penalized form score for rejected rep
    _repFormScores.add(60.0);
    _updateCumulativeFormScore();
  }

  double _calculateRepFormScore({
    required double elbowDepth,
    required double minBodyLine,
  }) {
    // Depth score: 100 if <= 85°, scales to 90 at 90°
    double depthScore = 100.0;
    if (elbowDepth > 85.0) {
      depthScore = 100.0 -
          ((elbowDepth - 85.0) / (config.minElbowDepthAngle - 85.0)) * 10.0;
    }

    // Body line score: 100 if >= idealBodyLineAngle (175°), scales to 90 at 165°
    double bodyScore = 100.0;
    if (minBodyLine < config.idealBodyLineAngle) {
      bodyScore = 90.0 +
          ((minBodyLine - config.minBodyLineAngle) /
                  (config.idealBodyLineAngle - config.minBodyLineAngle)) *
              10.0;
    }

    final score = (depthScore * 0.5 + bodyScore * 0.5).clamp(70.0, 100.0);
    return score;
  }

  void _updateCumulativeFormScore() {
    if (_repFormScores.isEmpty) {
      _currentFormScore = 100.0;
      return;
    }
    final sum = _repFormScores.reduce((a, b) => a + b);
    _currentFormScore = (sum / _repFormScores.length).roundToDouble();
  }

  RepCounterOutput _buildOutput({
    required double liveElbow,
    required double liveBodyLine,
    required bool isPaused,
    required BodySide activeSide,
    required String feedback,
  }) {
    return RepCounterOutput(
      state: _currentState,
      validReps: _validReps,
      rejectedReps: _rejectedReps,
      latestRejectionReason: _latestRejectionReason,
      latestFeedbackMessage: feedback,
      rejectedRepsList: List.unmodifiable(_rejectedRepsList),
      liveElbowAngle: liveElbow,
      liveBodyLineAngle: liveBodyLine,
      formScore: _currentFormScore,
      isTrackingPaused: isPaused,
      activeSide: activeSide,
      lastRepDuration: _lastRepDuration,
    );
  }

  /// Resets all counters and state for a fresh workout set.
  void reset() {
    _currentState = RepState.up;
    _validReps = 0;
    _rejectedReps = 0;
    _rejectedRepsList.clear();
    _latestRejectionReason = null;
    _latestFeedbackMessage = 'Get into high plank position';
    _isRepInProgress = false;
    _repStartTime = null;
    _minElbowAngleInRep = 180.0;
    _minBodyLineAngleInRep = 180.0;
    _bodyLineViolated = false;
    _isSagging = false;
    _reachedDownState = false;
    _reachedLockout = false;
    _repFormScores.clear();
    _currentFormScore = 100.0;
    _lastRepDuration = null;
    _lastElbowAngle = 180.0;
    _lastBodyLineAngle = 180.0;
    _elbowAngleFilter.reset();
    _bodyLineFilter.reset();
  }
}

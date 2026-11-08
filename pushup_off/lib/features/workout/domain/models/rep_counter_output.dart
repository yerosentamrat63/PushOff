import 'pose_frame.dart';

enum RepState {
  up,
  descending,
  down,
  ascending,
}

enum RejectionReason {
  none,
  notDeepEnough,
  hipsSagging,
  hipsPiked,
  noLockout,
  tooFast,
}

extension RejectionReasonExtension on RejectionReason {
  String get displayTitle {
    switch (this) {
      case RejectionReason.none:
        return 'Clean rep';
      case RejectionReason.notDeepEnough:
        return 'Not deep enough';
      case RejectionReason.hipsSagging:
        return 'Hips sagging';
      case RejectionReason.hipsPiked:
        return 'Hips piked';
      case RejectionReason.noLockout:
        return 'No lockout';
      case RejectionReason.tooFast:
        return 'Too fast';
    }
  }

  String get coachTip {
    switch (this) {
      case RejectionReason.none:
        return 'Good form! Keep going.';
      case RejectionReason.notDeepEnough:
        return 'Go lower. Chest to elbow height.';
      case RejectionReason.hipsSagging:
        return 'Keep hips up. Engage your core.';
      case RejectionReason.hipsPiked:
        return 'Lower hips into a flat plank.';
      case RejectionReason.noLockout:
        return 'Push all the way up to full lockout.';
      case RejectionReason.tooFast:
        return 'Control your tempo. Don\'t rush.';
    }
  }
}

class RejectedRepDetail {
  final int repNumber;
  final RejectionReason reason;
  final String detail;
  final DateTime? timestamp;

  const RejectedRepDetail({
    required this.repNumber,
    required this.reason,
    required this.detail,
    this.timestamp,
  });

  @override
  String toString() => 'Rep $repNumber: ${reason.displayTitle} ($detail)';
}

class RepCounterOutput {
  final RepState state;
  final int validReps;
  final int rejectedReps;
  final RejectionReason? latestRejectionReason;
  final String latestFeedbackMessage;
  final List<RejectedRepDetail> rejectedRepsList;
  final double liveElbowAngle;
  final double liveBodyLineAngle;
  final double formScore; // 0 to 100
  final bool isTrackingPaused;
  final BodySide activeSide;
  final Duration? lastRepDuration;

  const RepCounterOutput({
    this.state = RepState.up,
    this.validReps = 0,
    this.rejectedReps = 0,
    this.latestRejectionReason,
    this.latestFeedbackMessage = 'Get into high plank position',
    this.rejectedRepsList = const [],
    this.liveElbowAngle = 180.0,
    this.liveBodyLineAngle = 180.0,
    this.formScore = 100.0,
    this.isTrackingPaused = false,
    this.activeSide = BodySide.left,
    this.lastRepDuration,
  });

  int get totalAttemptedReps => validReps + rejectedReps;

  RepCounterOutput copyWith({
    RepState? state,
    int? validReps,
    int? rejectedReps,
    RejectionReason? latestRejectionReason,
    String? latestFeedbackMessage,
    List<RejectedRepDetail>? rejectedRepsList,
    double? liveElbowAngle,
    double? liveBodyLineAngle,
    double? formScore,
    bool? isTrackingPaused,
    BodySide? activeSide,
    Duration? lastRepDuration,
  }) {
    return RepCounterOutput(
      state: state ?? this.state,
      validReps: validReps ?? this.validReps,
      rejectedReps: rejectedReps ?? this.rejectedReps,
      latestRejectionReason: latestRejectionReason ?? this.latestRejectionReason,
      latestFeedbackMessage: latestFeedbackMessage ?? this.latestFeedbackMessage,
      rejectedRepsList: rejectedRepsList ?? this.rejectedRepsList,
      liveElbowAngle: liveElbowAngle ?? this.liveElbowAngle,
      liveBodyLineAngle: liveBodyLineAngle ?? this.liveBodyLineAngle,
      formScore: formScore ?? this.formScore,
      isTrackingPaused: isTrackingPaused ?? this.isTrackingPaused,
      activeSide: activeSide ?? this.activeSide,
      lastRepDuration: lastRepDuration ?? this.lastRepDuration,
    );
  }
}


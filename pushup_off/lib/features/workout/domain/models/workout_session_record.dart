import 'package:intl/intl.dart';
import 'completed_set_summary.dart';
import 'rep_counter_output.dart';

class WorkoutSessionRecord {
  final String id;
  final DateTime startedAt;
  final DateTime completedAt;
  final int durationSeconds;
  final int validReps;
  final int rejectedReps;
  final double formScore;
  final double? averageElbowAngle;
  final double? averageBodyLineAngle;
  final String? prominentSide;
  final List<RejectedRepDetail> rejectedRepsList;

  const WorkoutSessionRecord({
    required this.id,
    required this.startedAt,
    required this.completedAt,
    required this.durationSeconds,
    required this.validReps,
    required this.rejectedReps,
    required this.formScore,
    this.averageElbowAngle,
    this.averageBodyLineAngle,
    this.prominentSide,
    this.rejectedRepsList = const [],
  });

  int get totalAttemptedReps => validReps + rejectedReps;

  String get formattedDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${seconds}s';
  }

  String get formattedClockDuration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get formattedRelativeDate {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final sessionDay = DateTime(completedAt.year, completedAt.month, completedAt.day);
    final difference = today.difference(sessionDay).inDays;

    final timeStr = DateFormat('h:mm a').format(completedAt);

    if (difference == 0) {
      return 'Today, $timeStr';
    } else if (difference == 1) {
      return 'Yesterday, $timeStr';
    } else if (difference < 7) {
      return '${DateFormat('EEEE').format(completedAt)}, $timeStr';
    } else {
      return DateFormat('MMM d, h:mm a').format(completedAt);
    }
  }

  factory WorkoutSessionRecord.fromCompletedSetSummary(CompletedSetSummary summary) {
    return WorkoutSessionRecord(
      id: summary.id,
      startedAt: summary.startedAt,
      completedAt: summary.completedAt,
      durationSeconds: summary.durationSeconds,
      validReps: summary.validReps,
      rejectedReps: summary.rejectedReps,
      formScore: summary.formScore,
      averageElbowAngle: summary.averageElbowAngle,
      averageBodyLineAngle: summary.averageBodyLineAngle,
      prominentSide: summary.prominentSide,
      rejectedRepsList: summary.rejectedRepsList,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'started_at': startedAt.toIso8601String(),
      'completed_at': completedAt.toIso8601String(),
      'duration_seconds': durationSeconds,
      'valid_reps': validReps,
      'rejected_reps': rejectedReps,
      'form_score': formScore,
      'average_elbow_angle': averageElbowAngle,
      'average_body_line_angle': averageBodyLineAngle,
      'prominent_side': prominentSide,
    };
  }

  factory WorkoutSessionRecord.fromMap(
    Map<String, dynamic> map, {
    List<RejectedRepDetail> rejections = const [],
  }) {
    return WorkoutSessionRecord(
      id: map['id'] as String,
      startedAt: DateTime.parse(map['started_at'] as String),
      completedAt: DateTime.parse(map['completed_at'] as String),
      durationSeconds: (map['duration_seconds'] as num).toInt(),
      validReps: (map['valid_reps'] as num).toInt(),
      rejectedReps: (map['rejected_reps'] as num).toInt(),
      formScore: (map['form_score'] as num).toDouble(),
      averageElbowAngle: (map['average_elbow_angle'] as num?)?.toDouble(),
      averageBodyLineAngle: (map['average_body_line_angle'] as num?)?.toDouble(),
      prominentSide: map['prominent_side'] as String?,
      rejectedRepsList: rejections,
    );
  }
}


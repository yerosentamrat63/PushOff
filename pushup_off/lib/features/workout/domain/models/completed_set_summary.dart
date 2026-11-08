import 'rep_counter_output.dart';

/// Summary of a finished workout set. Lives in the domain layer so that
/// persistence models do not depend on presentation controllers.
class CompletedSetSummary {
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

  int get secondsDuration => durationSeconds;

  CompletedSetSummary({
    String? id,
    DateTime? startedAt,
    required this.completedAt,
    int? secondsDuration,
    int? durationSeconds,
    required this.validReps,
    required this.rejectedReps,
    required this.formScore,
    this.averageElbowAngle,
    this.averageBodyLineAngle,
    this.prominentSide,
    required this.rejectedRepsList,
  })  : id = id ?? 'set-${DateTime.now().millisecondsSinceEpoch}',
        durationSeconds = durationSeconds ?? (secondsDuration ?? 0),
        startedAt = startedAt ??
            completedAt.subtract(Duration(seconds: durationSeconds ?? (secondsDuration ?? 0)));

  String get formattedDuration {
    final m = durationSeconds ~/ 60;
    final s = durationSeconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

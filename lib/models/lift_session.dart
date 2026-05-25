// lib/models/lift_session.dart
import 'package:hive/hive.dart';
import 'rep_record.dart';

part 'lift_session.g.dart';

@HiveType(typeId: 0)
class LiftSession extends HiveObject {
  @HiveField(0)
  final DateTime startTime;

  @HiveField(1)
  final String liftType; // 'squat' | 'benchPress' | 'deadlift'

  @HiveField(2)
  final List<RepRecord> reps;

  @HiveField(3)
  final DateTime endTime;

  LiftSession({
    required this.startTime,
    required this.liftType,
    required this.reps,
    required this.endTime,
  });

  int get totalReps => reps.length;
  int get validReps => reps.where((r) => r.isValid).length;
  int get invalidReps => totalReps - validReps;

  double get averageFormScore {
    if (reps.isEmpty) return 0.0;
    final valid = reps.where((r) => r.isValid).toList();
    if (valid.isEmpty) return 0.0;
    return valid.map((r) => r.formScore).reduce((a, b) => a + b) / valid.length;
  }

  Duration get sessionDuration => endTime.difference(startTime);

  String get formattedDate {
    return '${startTime.day}/${startTime.month}/${startTime.year}';
  }

  String get formattedDuration {
    final mins = sessionDuration.inMinutes;
    final secs = sessionDuration.inSeconds % 60;
    return '${mins}m ${secs}s';
  }
}

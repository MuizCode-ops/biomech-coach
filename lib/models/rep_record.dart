// lib/models/rep_record.dart
import 'package:hive/hive.dart';

part 'rep_record.g.dart';

@HiveType(typeId: 1)
class RepRecord extends HiveObject {
  @HiveField(0)
  final DateTime timestamp;

  @HiveField(1)
  final bool isValid;

  @HiveField(2)
  final double formScore; // 0–100

  @HiveField(3)
  final double minDepthAngle; // e.g. lowest hip angle in squat

  @HiveField(4)
  final double lockoutAngle;

  @HiveField(5)
  final List<String> faultNotes; // e.g. ['Back rounding', 'Insufficient depth']

  @HiveField(6)
  final double durationSeconds;

  RepRecord({
    required this.timestamp,
    required this.isValid,
    required this.formScore,
    required this.minDepthAngle,
    required this.lockoutAngle,
    required this.faultNotes,
    required this.durationSeconds,
  });

  /// Compute form score (0–100) based on faults and depth quality.
  static double computeFormScore({
    required bool validDepth,
    required bool validLockout,
    required List<String> faults,
  }) {
    double score = 100.0;
    if (!validDepth) score -= 30.0;
    if (!validLockout) score -= 20.0;
    score -= faults.length * 10.0;
    return score.clamp(0.0, 100.0);
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'isValid': isValid,
        'formScore': formScore,
        'minDepthAngle': minDepthAngle,
        'lockoutAngle': lockoutAngle,
        'faultNotes': faultNotes,
        'durationSeconds': durationSeconds,
      };

  factory RepRecord.fromJson(Map<String, dynamic> json) => RepRecord(
        timestamp: DateTime.parse(json['timestamp'] as String),
        isValid: json['isValid'] as bool,
        formScore: (json['formScore'] as num).toDouble(),
        minDepthAngle: (json['minDepthAngle'] as num).toDouble(),
        lockoutAngle: (json['lockoutAngle'] as num).toDouble(),
        faultNotes: List<String>.from(json['faultNotes'] as List),
        durationSeconds: (json['durationSeconds'] as num).toDouble(),
      );
}

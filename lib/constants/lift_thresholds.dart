// lib/constants/lift_thresholds.dart
// Competition-grade angle thresholds based on IPF/IWF standards.

enum LiftType { squat, benchPress, deadlift }

extension LiftTypeExtension on LiftType {
  String get displayName {
    switch (this) {
      case LiftType.squat:
        return 'Squat';
      case LiftType.benchPress:
        return 'Bench Press';
      case LiftType.deadlift:
        return 'Deadlift';
    }
  }

  String get emoji {
    switch (this) {
      case LiftType.squat:
        return '🏋️';
      case LiftType.benchPress:
        return '🤸';
      case LiftType.deadlift:
        return '💪';
    }
  }
}

class LiftThresholds {
  // ──────────────────────────────────────────
  //  SQUAT thresholds (degrees)
  // ──────────────────────────────────────────
  /// Hip angle must be BELOW this for valid depth (hip crease below knee)
  static const double squatDepthHipAngle = 90.0;

  /// Knee angle at parallel depth
  static const double squatDepthKneeAngle = 90.0;

  /// Hip angle must drop below this to trigger the start of the squat descent
  static const double squatStartHipAngle = 138.0;

  /// Hip angle for lockout (standing tall)
  static const double squatLockoutHipAngle = 145.0;

  /// Knee angle for lockout
  static const double squatLockoutKneeAngle = 145.0;

  /// Torso lean threshold — excessive forward lean warning
  static const double squatMaxTorsoLean = 70.0;

  // ──────────────────────────────────────────
  //  BENCH PRESS thresholds (degrees)
  // ──────────────────────────────────────────
  /// Elbow angle must drop below this to start the bench press descent
  static const double benchStartElbowAngle = 135.0;

  /// Elbow angle at bottom (bar to chest) — must be ≤ this
  static const double benchBottomElbowAngle = 90.0;

  /// Elbow angle for lockout — must be ≥ this
  static const double benchLockoutElbowAngle = 140.0;

  /// Wrist should track roughly over the elbow
  static const double benchWristAlignmentTolerance = 20.0;

  // ──────────────────────────────────────────
  //  DEADLIFT thresholds (degrees)
  // ──────────────────────────────────────────
  /// Hip angle must drop below this to start the deadlift hinge/descent
  static const double deadliftStartHipAngle = 138.0;

  /// Hip angle at bottom (hinge) — must be ≤ this to start
  static const double deadliftBottomHipAngle = 75.0;

  /// Knee angle at bottom
  static const double deadliftBottomKneeAngle = 110.0;

  /// Hip angle for full lockout — must be ≥ this
  static const double deadliftLockoutHipAngle = 145.0;

  /// Knee angle for full lockout
  static const double deadliftLockoutKneeAngle = 145.0;

  /// Max back angle — excessive rounding warning
  static const double deadliftMaxBackRound = 40.0;

  // ──────────────────────────────────────────
  //  GENERAL
  // ──────────────────────────────────────────
  /// Minimum landmark visibility score (0–1) to trust a pose point
  static const double minLandmarkConfidence = 0.5;

  /// Smoothing window for angle history (frames)
  static const int smoothingWindow = 3;
}

/// Returns a human-readable description of what each lift phase requires.
Map<LiftType, Map<String, String>> liftPhaseDescriptions = {
  LiftType.squat: {
    'start': 'Stand tall, bar on traps',
    'descent': 'Break hips back, knees out',
    'depth': 'Hip crease below knee parallel',
    'ascent': 'Drive through heels',
    'lockout': 'Full hip & knee extension',
  },
  LiftType.benchPress: {
    'start': 'Retract shoulder blades, arch set',
    'descent': 'Bar path to lower chest',
    'depth': 'Bar touches chest',
    'ascent': 'Drive bar up and back',
    'lockout': 'Elbows fully extended',
  },
  LiftType.deadlift: {
    'start': 'Hip hinge, bar over mid-foot',
    'pull': 'Leg drive, flat back',
    'midpoint': 'Bar passes knees',
    'lockout': 'Full hip & knee extension, shoulders back',
  },
};

// lib/services/biomechanics_engine.dart
// Dart-based trigonometric joint angle calculations using atan2.

import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class BiomechanicsEngine {
  // ──────────────────────────────────────────
  //  Core angle calculation
  // ──────────────────────────────────────────

  /// Calculate the angle at point [b] formed by vectors b→a and b→c.
  /// Returns angle in degrees (0–180).
  static double calculateAngle(
    PoseLandmark a,
    PoseLandmark b,
    PoseLandmark c,
  ) {
    final radians =
        math.atan2(c.y - b.y, c.x - b.x) -
        math.atan2(a.y - b.y, a.x - b.x);
    double angle = (radians * 180.0 / math.pi).abs();
    if (angle > 180.0) angle = 360.0 - angle;
    return angle;
  }

  /// Calculate angle between two 2D vectors from a central point.
  static double calculateAngleFromCoords(
    double ax, double ay, // point A
    double bx, double by, // vertex B
    double cx, double cy, // point C
  ) {
    final radians =
        math.atan2(cy - by, cx - bx) - math.atan2(ay - by, ax - bx);
    double angle = (radians * 180.0 / math.pi).abs();
    if (angle > 180.0) angle = 360.0 - angle;
    return angle;
  }

  // ──────────────────────────────────────────
  //  Dynamic Side Selection
  // ──────────────────────────────────────────

  /// Determine the most visible side ('left' or 'right') based on average likelihood.
  static String getMostVisibleSide(Map<PoseLandmarkType, PoseLandmark> lm) {
    final leftShoulder = lm[PoseLandmarkType.leftShoulder];
    final leftHip = lm[PoseLandmarkType.leftHip];
    final leftKnee = lm[PoseLandmarkType.leftKnee];
    final leftAnkle = lm[PoseLandmarkType.leftAnkle];

    final rightShoulder = lm[PoseLandmarkType.rightShoulder];
    final rightHip = lm[PoseLandmarkType.rightHip];
    final rightKnee = lm[PoseLandmarkType.rightKnee];
    final rightAnkle = lm[PoseLandmarkType.rightAnkle];

    double leftConf = 0.0;
    int leftCount = 0;
    if (leftShoulder != null) { leftConf += leftShoulder.likelihood; leftCount++; }
    if (leftHip != null) { leftConf += leftHip.likelihood; leftCount++; }
    if (leftKnee != null) { leftConf += leftKnee.likelihood; leftCount++; }
    if (leftAnkle != null) { leftConf += leftAnkle.likelihood; leftCount++; }

    double rightConf = 0.0;
    int rightCount = 0;
    if (rightShoulder != null) { rightConf += rightShoulder.likelihood; rightCount++; }
    if (rightHip != null) { rightConf += rightHip.likelihood; rightCount++; }
    if (rightKnee != null) { rightConf += rightKnee.likelihood; rightCount++; }
    if (rightAnkle != null) { rightConf += rightAnkle.likelihood; rightCount++; }

    final leftAvg = leftCount > 0 ? leftConf / leftCount : 0.0;
    final rightAvg = rightCount > 0 ? rightConf / rightCount : 0.0;

    return leftAvg >= rightAvg ? 'left' : 'right';
  }

  // ──────────────────────────────────────────
  //  SQUAT angles
  // ──────────────────────────────────────────

  /// Knee flexion angle (hip → knee → ankle)
  static double squatKneeAngle(Map<PoseLandmarkType, PoseLandmark> lm) {
    final side = getMostVisibleSide(lm);
    final hip = lm[side == 'left' ? PoseLandmarkType.leftHip : PoseLandmarkType.rightHip];
    final knee = lm[side == 'left' ? PoseLandmarkType.leftKnee : PoseLandmarkType.rightKnee];
    final ankle = lm[side == 'left' ? PoseLandmarkType.leftAnkle : PoseLandmarkType.rightAnkle];
    if (hip == null || knee == null || ankle == null) return 180.0;
    return calculateAngle(hip, knee, ankle);
  }

  /// Hip flexion angle (shoulder → hip → knee)
  static double squatHipAngle(Map<PoseLandmarkType, PoseLandmark> lm) {
    final side = getMostVisibleSide(lm);
    final shoulder = lm[side == 'left' ? PoseLandmarkType.leftShoulder : PoseLandmarkType.rightShoulder];
    final hip = lm[side == 'left' ? PoseLandmarkType.leftHip : PoseLandmarkType.rightHip];
    final knee = lm[side == 'left' ? PoseLandmarkType.leftKnee : PoseLandmarkType.rightKnee];
    if (shoulder == null || hip == null || knee == null) return 180.0;
    return calculateAngle(shoulder, hip, knee);
  }

  /// Torso lean angle relative to vertical (0 = upright, 90 = horizontal)
  static double squatTorsoLean(Map<PoseLandmarkType, PoseLandmark> lm) {
    final side = getMostVisibleSide(lm);
    final shoulder = lm[side == 'left' ? PoseLandmarkType.leftShoulder : PoseLandmarkType.rightShoulder];
    final hip = lm[side == 'left' ? PoseLandmarkType.leftHip : PoseLandmarkType.rightHip];
    if (shoulder == null || hip == null) return 0.0;
    final dx = (shoulder.x - hip.x).abs();
    final dy = (hip.y - shoulder.y).abs();
    if (dy == 0) return 90.0;
    return math.atan2(dx, dy) * 180.0 / math.pi;
  }

  // ──────────────────────────────────────────
  //  BENCH PRESS angles
  // ──────────────────────────────────────────

  /// Elbow flexion (shoulder → elbow → wrist)
  static double benchElbowAngle(Map<PoseLandmarkType, PoseLandmark> lm) {
    final shoulder = lm[PoseLandmarkType.leftShoulder];
    final elbow = lm[PoseLandmarkType.leftElbow];
    final wrist = lm[PoseLandmarkType.leftWrist];
    if (shoulder == null || elbow == null || wrist == null) return 180.0;
    return calculateAngle(shoulder, elbow, wrist);
  }

  /// Right elbow flexion
  static double benchElbowAngleRight(Map<PoseLandmarkType, PoseLandmark> lm) {
    final shoulder = lm[PoseLandmarkType.rightShoulder];
    final elbow = lm[PoseLandmarkType.rightElbow];
    final wrist = lm[PoseLandmarkType.rightWrist];
    if (shoulder == null || elbow == null || wrist == null) return 180.0;
    return calculateAngle(shoulder, elbow, wrist);
  }

  /// Average elbow angle across both arms
  static double benchAvgElbowAngle(Map<PoseLandmarkType, PoseLandmark> lm) {
    return (benchElbowAngle(lm) + benchElbowAngleRight(lm)) / 2.0;
  }

  // ──────────────────────────────────────────
  //  DEADLIFT angles
  // ──────────────────────────────────────────

  /// Hip hinge angle (shoulder → hip → knee)
  static double deadliftHipAngle(Map<PoseLandmarkType, PoseLandmark> lm) {
    final side = getMostVisibleSide(lm);
    final shoulder = lm[side == 'left' ? PoseLandmarkType.leftShoulder : PoseLandmarkType.rightShoulder];
    final hip = lm[side == 'left' ? PoseLandmarkType.leftHip : PoseLandmarkType.rightHip];
    final knee = lm[side == 'left' ? PoseLandmarkType.leftKnee : PoseLandmarkType.rightKnee];
    if (shoulder == null || hip == null || knee == null) return 180.0;
    return calculateAngle(shoulder, hip, knee);
  }

  /// Knee extension angle (hip → knee → ankle)
  static double deadliftKneeAngle(Map<PoseLandmarkType, PoseLandmark> lm) {
    final side = getMostVisibleSide(lm);
    final hip = lm[side == 'left' ? PoseLandmarkType.leftHip : PoseLandmarkType.rightHip];
    final knee = lm[side == 'left' ? PoseLandmarkType.leftKnee : PoseLandmarkType.rightKnee];
    final ankle = lm[side == 'left' ? PoseLandmarkType.leftAnkle : PoseLandmarkType.rightAnkle];
    if (hip == null || knee == null || ankle == null) return 180.0;
    return calculateAngle(hip, knee, ankle);
  }

  /// Back rounding approximated by mid-spine angle deviation
  static double deadliftBackAngle(Map<PoseLandmarkType, PoseLandmark> lm) {
    final side = getMostVisibleSide(lm);
    final shoulder = lm[side == 'left' ? PoseLandmarkType.leftShoulder : PoseLandmarkType.rightShoulder];
    final hip = lm[side == 'left' ? PoseLandmarkType.leftHip : PoseLandmarkType.rightHip];
    if (shoulder == null || hip == null) return 0.0;
    final dx = (shoulder.x - hip.x).abs();
    final dy = (hip.y - shoulder.y).abs();
    if (dy == 0) return 90.0;
    return math.atan2(dx, dy) * 180.0 / math.pi;
  }

  // ──────────────────────────────────────────
  //  Helpers
  // ──────────────────────────────────────────

  /// Average a sliding window of angles for smoothing.
  static double smoothAngle(List<double> history) {
    if (history.isEmpty) return 0.0;
    return history.reduce((a, b) => a + b) / history.length;
  }

  /// Check if a landmark has sufficient confidence.
  static bool isVisible(PoseLandmark? lm, {double minScore = 0.5}) {
    if (lm == null) return false;
    return (lm.likelihood) >= minScore;
  }

  /// Check if all required landmarks are visible.
  static bool allVisible(
    Map<PoseLandmarkType, PoseLandmark> lm,
    List<PoseLandmarkType> required,
  ) {
    return required.every((t) => isVisible(lm[t]));
  }
}

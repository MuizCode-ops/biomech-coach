// lib/widgets/skeleton_painter.dart
// CustomPainter that draws 33 ML Kit pose landmarks and connections on camera preview.

import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../services/state_machine.dart';

class SkeletonPainter extends CustomPainter {
  final List<Pose> poses;
  final Size imageSize;
  final bool isFrontCamera;
  final RepState repState;
  final double primaryAngle;

  SkeletonPainter({
    required this.poses,
    required this.imageSize,
    required this.isFrontCamera,
    required this.repState,
    required this.primaryAngle,
  });

  // Connection pairs: [from, to]
  static const List<List<PoseLandmarkType>> _connections = [
    // Face
    [PoseLandmarkType.leftEar, PoseLandmarkType.leftEye],
    [PoseLandmarkType.rightEar, PoseLandmarkType.rightEye],
    [PoseLandmarkType.leftEye, PoseLandmarkType.nose],
    [PoseLandmarkType.rightEye, PoseLandmarkType.nose],
    // Torso
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    // Left arm
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    // Right arm
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    // Left leg
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    [PoseLandmarkType.leftAnkle, PoseLandmarkType.leftHeel],
    [PoseLandmarkType.leftHeel, PoseLandmarkType.leftFootIndex],
    // Right leg
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    [PoseLandmarkType.rightAnkle, PoseLandmarkType.rightHeel],
    [PoseLandmarkType.rightHeel, PoseLandmarkType.rightFootIndex],
  ];

  Color get _skeletonColor {
    switch (repState) {
      case RepState.idle:
        return const Color(0xFF00B4D8); // cyan
      case RepState.descending:
        return const Color(0xFF90E0EF); // light blue
      case RepState.atDepth:
        return const Color(0xFF00F5A0); // green flash
      case RepState.ascending:
        return const Color(0xFFFFD60A); // yellow
      case RepState.lockout:
        return const Color(0xFF00F5A0); // green
      case RepState.complete:
        return const Color(0xFF00F5A0);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (poses.isEmpty) return;

    final linePaint = Paint()
      ..color = _skeletonColor
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final jointPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final jointBorderPaint = Paint()
      ..color = _skeletonColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final pose in poses) {
      final landmarks = pose.landmarks;

      // Draw connections
      for (final conn in _connections) {
        final from = landmarks[conn[0]];
        final to = landmarks[conn[1]];
        if (from == null || to == null) continue;
        if (from.likelihood < 0.4 || to.likelihood < 0.4) continue;

        final fromOffset = _landmarkToScreen(from, size);
        final toOffset = _landmarkToScreen(to, size);
        canvas.drawLine(fromOffset, toOffset, linePaint);
      }

      // Draw joint dots
      for (final entry in landmarks.entries) {
        final lm = entry.value;
        if (lm.likelihood < 0.5) continue;

        final offset = _landmarkToScreen(lm, size);
        canvas.drawCircle(offset, 6.0, jointPaint);
        canvas.drawCircle(offset, 6.0, jointBorderPaint);
      }
    }
  }

  Offset _landmarkToScreen(PoseLandmark landmark, Size canvasSize) {
    double x = landmark.x / imageSize.width * canvasSize.width;
    double y = landmark.y / imageSize.height * canvasSize.height;

    // Mirror for front camera
    if (isFrontCamera) {
      x = canvasSize.width - x;
    }
    return Offset(x, y);
  }

  @override
  bool shouldRepaint(SkeletonPainter oldDelegate) {
    return oldDelegate.poses != poses || oldDelegate.repState != repState;
  }
}

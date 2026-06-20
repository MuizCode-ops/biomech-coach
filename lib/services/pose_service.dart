// lib/services/pose_service.dart
// Google ML Kit Pose Detection wrapper with camera image processing.

import 'dart:io';
import 'dart:ui' show Size;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PoseService {
  PoseDetector? _detector;
  bool _isProcessing = false;
  bool _isInitialized = false;

  Future<void> initialize() async {
    final options = PoseDetectorOptions(
      mode: PoseDetectionMode.stream,
      model: PoseDetectionModel.accurate,
    );
    _detector = PoseDetector(options: options);
    _isInitialized = true;
  }

  bool get isInitialized => _isInitialized;

  /// Process a CameraImage frame and return detected poses.
  Future<List<Pose>> processFrame(
    CameraImage image,
    CameraDescription camera,
    InputImageRotation rotation,
  ) async {
    if (!_isInitialized || _isProcessing || _detector == null) return [];

    _isProcessing = true;
    try {
      final inputImage = _buildInputImage(image, camera, rotation);
      if (inputImage == null) return [];
      return await _detector!.processImage(inputImage);
    } catch (e) {
      debugPrint('[PoseService] Error processing frame: $e');
      return [];
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _buildInputImage(
    CameraImage image,
    CameraDescription camera,
    InputImageRotation rotation,
  ) {
    // iOS uses kCVPixelFormatType_32BGRA, Android uses nv21
    final format = Platform.isIOS
        ? InputImageFormat.bgra8888
        : InputImageFormat.nv21;

    if (image.planes.isEmpty) return null;

    final bytes = Platform.isIOS
        ? image.planes[0].bytes
        : _concatenatePlanes(image.planes);

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final bytes = <int>[];
    for (final plane in planes) {
      bytes.addAll(plane.bytes);
    }
    return Uint8List.fromList(bytes);
  }

  /// Convert CameraDescription sensorOrientation to InputImageRotation.
  static InputImageRotation rotationFromCamera(CameraDescription camera) {
    switch (camera.sensorOrientation) {
      case 0:
        return InputImageRotation.rotation0deg;
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Future<void> dispose() async {
    await _detector?.close();
    _detector = null;
    _isInitialized = false;
  }
}

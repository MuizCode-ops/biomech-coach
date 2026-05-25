// lib/screens/camera_screen.dart
// Live camera + pose detection — defaults to front camera, clean frosted HUD.

import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../constants/lift_thresholds.dart';
import '../models/lift_session.dart';
import '../models/rep_record.dart';
import '../services/biomechanics_engine.dart';
import '../services/database_service.dart';
import '../services/pose_service.dart';
import '../services/state_machine.dart';
import '../services/tts_coach.dart';
import '../widgets/angle_indicator.dart';
import '../widgets/rep_counter_widget.dart';
import '../widgets/skeleton_painter.dart';
import 'session_screen.dart';

class CameraScreen extends StatefulWidget {
  final LiftType liftType;
  const CameraScreen({super.key, required this.liftType});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  // ── Camera ─────────────────────────────
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0; // resolved to front in _initCamera
  bool _isCameraInitialized = false;

  // ── Services ───────────────────────────
  final PoseService _poseService = PoseService();
  final TtsCoach _ttsCoach = TtsCoach();

  // ── State ──────────────────────────────
  List<Pose> _poses = [];
  late RepStateMachine _stateMachine;
  double _primaryAngle = 180.0;
  double _secondaryAngle = 180.0;
  final List<double> _angleHistory = [];

  // ── Session ────────────────────────────
  final List<RepRecord> _sessionReps = [];
  late DateTime _sessionStart;
  bool _sessionActive = false;

  // ── UI ─────────────────────────────────
  bool _showOverlay = true;
  String? _lastFault;
  Timer? _faultClearTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionStart = DateTime.now();
    _initAll();
  }

  Future<void> _initAll() async {
    await _poseService.initialize();
    await _ttsCoach.initialize();
    _setupStateMachine();
    await _initCamera();
    await _ttsCoach.cueReady();
  }

  void _setupStateMachine() {
    _stateMachine = createStateMachine(widget.liftType);

    _stateMachine.onRepComplete = (result) {
      final record = result.toRepRecord();
      setState(() => _sessionReps.add(record));
      _ttsCoach.announceRepResult(
        isValid: result.isValid,
        validCount: _stateMachine.validRepCount,
      );
    };

    _stateMachine.onCoachingCue = (cue) {
      setState(() => _lastFault = cue);
      _faultClearTimer?.cancel();
      _faultClearTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) setState(() => _lastFault = null);
      });
    };
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;

    // Default to front camera
    _selectedCameraIndex = _findFrontCamera();
    await _startCamera(_selectedCameraIndex);
  }

  /// Find front camera index; falls back to 0 if none found.
  int _findFrontCamera() {
    for (int i = 0; i < _cameras.length; i++) {
      if (_cameras[i].lensDirection == CameraLensDirection.front) return i;
    }
    return 0;
  }

  Future<void> _startCamera(int index) async {
    if (index >= _cameras.length) return;

    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();

    _cameraController = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.bgra8888,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    setState(() => _isCameraInitialized = true);

    final rotation = PoseService.rotationFromCamera(_cameras[index]);

    _cameraController!.startImageStream((image) async {
      final poses = await _poseService.processFrame(
          image, _cameras[index], rotation);
      if (!mounted) return;
      setState(() => _poses = poses);
      if (poses.isNotEmpty) _processPose(poses.first);
    });
  }

  void _processPose(Pose pose) {
    final lm = pose.landmarks;
    double primary = 180.0;
    double secondary = 180.0;
    Map<String, double> extras = {};

    switch (widget.liftType) {
      case LiftType.squat:
        primary = BiomechanicsEngine.squatHipAngle(lm);
        secondary = BiomechanicsEngine.squatKneeAngle(lm);
        extras = {
          'knee': secondary,
          'torso': BiomechanicsEngine.squatTorsoLean(lm),
        };
      case LiftType.benchPress:
        primary = BiomechanicsEngine.benchAvgElbowAngle(lm);
        secondary = BiomechanicsEngine.benchElbowAngleRight(lm);
      case LiftType.deadlift:
        primary = BiomechanicsEngine.deadliftHipAngle(lm);
        secondary = BiomechanicsEngine.deadliftKneeAngle(lm);
        extras = {
          'knee': secondary,
          'back': BiomechanicsEngine.deadliftBackAngle(lm),
        };
    }

    // Smooth
    _angleHistory.add(primary);
    if (_angleHistory.length > LiftThresholds.smoothingWindow) {
      _angleHistory.removeAt(0);
    }
    final smoothed = BiomechanicsEngine.smoothAngle(_angleHistory);

    setState(() {
      _primaryAngle = smoothed;
      _secondaryAngle = secondary;
    });

    if (_sessionActive) {
      _stateMachine.update(smoothed, extras);
    }
  }

  void _toggleSession() {
    setState(() {
      _sessionActive = !_sessionActive;
      if (_sessionActive) {
        _sessionStart = DateTime.now();
        _sessionReps.clear();
        _stateMachine.reset();
      } else {
        _endSession();
      }
    });
  }

  Future<void> _endSession() async {
    if (_sessionReps.isEmpty) return;
    final session = LiftSession(
      startTime: _sessionStart,
      liftType: widget.liftType.name,
      reps: List.from(_sessionReps),
      endTime: DateTime.now(),
    );
    await DatabaseService.instance.saveSession(session);
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SessionSummaryScreen(session: session),
        ),
      );
    }
  }

  void _flipCamera() async {
    final next = (_selectedCameraIndex + 1) % _cameras.length;
    _selectedCameraIndex = next;
    await _startCamera(next);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      _cameraController?.stopImageStream();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera(_selectedCameraIndex);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    _poseService.dispose();
    _ttsCoach.dispose();
    _faultClearTimer?.cancel();
    super.dispose();
  }

  // ──────────────────────────────────────────
  //  Build
  // ──────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildCameraPreview(),
          if (_isCameraInitialized && _showOverlay && _poses.isNotEmpty)
            _buildSkeleton(),
          // Gradient vignette for readability
          _buildVignette(),
          // Top bar
          Positioned(top: 0, left: 0, right: 0, child: _buildTopBar()),
          // Left: angle indicators
          Positioned(left: 16, top: 110, child: _buildAngles()),
          // Fault banner
          if (_lastFault != null)
            Positioned(
              top: 106,
              left: 16,
              right: 16,
              child: _buildFaultBanner(_lastFault!),
            ),
          // Right: rep counter
          Positioned(right: 16, top: 110, child: _buildRepCounter()),
          // Bottom bar
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar()),
        ],
      ),
    );
  }

  Widget _buildVignette() {
    return IgnorePointer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [
              Color(0xCC000000),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF2563EB)),
      );
    }
    return CameraPreview(_cameraController!);
  }

  Widget _buildSkeleton() {
    return CustomPaint(
      painter: SkeletonPainter(
        poses: _poses,
        imageSize: Size(
          _cameraController!.value.previewSize!.height,
          _cameraController!.value.previewSize!.width,
        ),
        isFrontCamera: _cameras[_selectedCameraIndex].lensDirection ==
            CameraLensDirection.front,
        repState: _stateMachine.state,
        primaryAngle: _primaryAngle,
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Row(
          children: [
            // Back
            _HudButton(
              icon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(width: 10),
            // Lift label
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                ),
                child: Text(
                  '${widget.liftType.emoji}  ${widget.liftType.displayName.toUpperCase()}',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Overlay toggle
            _HudButton(
              icon: _showOverlay
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              onTap: () => setState(() => _showOverlay = !_showOverlay),
            ),
            const SizedBox(width: 8),
            // Flip camera
            _HudButton(
              icon: Icons.flip_camera_ios_rounded,
              onTap: _flipCamera,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAngles() {
    final (primaryLabel, secondaryLabel, targetPrimary) =
        switch (widget.liftType) {
      LiftType.squat =>
        ('HIP', 'KNEE', LiftThresholds.squatDepthHipAngle),
      LiftType.benchPress =>
        ('ELBOW L', 'ELBOW R', LiftThresholds.benchBottomElbowAngle),
      LiftType.deadlift =>
        ('HIP', 'KNEE', LiftThresholds.deadliftBottomHipAngle),
    };

    final isGood = _primaryAngle <= targetPrimary + 15;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AngleIndicator(
          label: primaryLabel,
          angle: _primaryAngle,
          targetAngle: targetPrimary,
          isGood: isGood,
        ),
        const SizedBox(height: 8),
        AngleIndicator(
          label: secondaryLabel,
          angle: _secondaryAngle,
          isGood: true,
        ),
      ],
    );
  }

  Widget _buildRepCounter() {
    return RepCounterWidget(
      validReps: _stateMachine.validRepCount,
      totalReps: _stateMachine.totalRepCount,
      state: _stateMachine.state,
    );
  }

  Widget _buildFaultBanner(String fault) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF4444).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            fault,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
          ),
          child: GestureDetector(
            onTap: _toggleSession,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              height: 52,
              decoration: BoxDecoration(
                color: _sessionActive
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: (_sessionActive
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF2563EB))
                        .withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _sessionActive
                        ? Icons.stop_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _sessionActive ? 'End Session' : 'Start Session',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Compact HUD icon button ────────────────────────────────

class _HudButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _HudButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

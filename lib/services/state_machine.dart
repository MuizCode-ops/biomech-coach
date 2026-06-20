// lib/services/state_machine.dart
// Deterministic rep state machine calibrated to competition powerlifting standards.

import '../constants/lift_thresholds.dart';
import '../models/rep_record.dart';

/// States a rep can be in.
enum RepState {
  idle,
  descending,
  atDepth,
  ascending,
  lockout,
  complete,
}

/// Result returned when a rep completes.
class RepResult {
  final bool isValid;
  final double formScore;
  final double minDepthAngle;
  final double lockoutAngle;
  final List<String> faultNotes;
  final double durationSeconds;

  const RepResult({
    required this.isValid,
    required this.formScore,
    required this.minDepthAngle,
    required this.lockoutAngle,
    required this.faultNotes,
    required this.durationSeconds,
  });

  RepRecord toRepRecord() => RepRecord(
        timestamp: DateTime.now(),
        isValid: isValid,
        formScore: formScore,
        minDepthAngle: minDepthAngle,
        lockoutAngle: lockoutAngle,
        faultNotes: faultNotes,
        durationSeconds: durationSeconds,
      );
}

/// Abstract base state machine. Subclasses implement lift-specific logic.
abstract class RepStateMachine {
  RepState _state = RepState.idle;
  RepState get state => _state;

  double _minPrimaryAngle = 180.0; // lowest angle reached (depth)
  double _lockoutAngle = 0.0;
  final List<String> _faults = [];
  DateTime? _repStartTime;

  int _validRepCount = 0;
  int _totalRepCount = 0;
  int get validRepCount => _validRepCount;
  int get totalRepCount => _totalRepCount;

  /// Callback triggered when a rep completes (valid or invalid).
  Function(RepResult)? onRepComplete;

  /// Callback for mid-rep coaching cues.
  Function(String)? onCoachingCue;

  /// Feed the current primary angle (e.g. knee or elbow angle) into the machine.
  /// [primaryAngle] is the main tracking angle.
  /// [secondaryAngles] are supporting angles for fault detection.
  void update(double primaryAngle, Map<String, double> secondaryAngles);

  void _transition(RepState next) {
    final prev = _state;
    _state = next;
    print('[StateMachine] Transition: ${prev.name} -> ${next.name} (Min Primary: ${_minPrimaryAngle.toStringAsFixed(1)}°)');
  }

  void _addFault(String fault) {
    if (!_faults.contains(fault)) {
      _faults.add(fault);
      onCoachingCue?.call(fault);
    }
  }

  void _completeRep(double lockoutAngle) {
    final duration = _repStartTime != null
        ? DateTime.now().difference(_repStartTime!).inMilliseconds / 1000.0
        : 0.0;
    final valid = _faults.isEmpty;
    final score = RepRecord.computeFormScore(
      validDepth: _minPrimaryAngle < _depthThreshold,
      validLockout: lockoutAngle >= _lockoutThreshold,
      faults: _faults,
    );

    _totalRepCount++;
    if (valid) _validRepCount++;

    final result = RepResult(
      isValid: valid,
      formScore: score,
      minDepthAngle: _minPrimaryAngle,
      lockoutAngle: lockoutAngle,
      faultNotes: List.from(_faults),
      durationSeconds: duration,
    );
    onRepComplete?.call(result);

    // Reset for next rep
    _faults.clear();
    _minPrimaryAngle = 180.0;
    _lockoutAngle = 0.0;
    _repStartTime = null;
    _transition(RepState.idle);
  }

  /// Lift-specific depth threshold (must be below this angle).
  double get _depthThreshold;

  /// Lift-specific lockout threshold (must be above this angle).
  double get _lockoutThreshold;

  void reset() {
    _state = RepState.idle;
    _faults.clear();
    _minPrimaryAngle = 180.0;
    _lockoutAngle = 0.0;
    _repStartTime = null;
  }
}

// ──────────────────────────────────────────────────
//  SQUAT State Machine
// ──────────────────────────────────────────────────
class SquatStateMachine extends RepStateMachine {
  @override
  double get _depthThreshold => LiftThresholds.squatDepthHipAngle;

  @override
  double get _lockoutThreshold => LiftThresholds.squatLockoutHipAngle;

  @override
  void update(double primaryAngle, Map<String, double> secondaryAngles) {
    // primaryAngle = hip angle
    final kneeAngle = secondaryAngles['knee'] ?? 180.0;
    final torsoLean = secondaryAngles['torso'] ?? 0.0;

    // Track minimum depth angle
    if (primaryAngle < _minPrimaryAngle) {
      _minPrimaryAngle = primaryAngle;
    }

    // Fault detection (continuous)
    if (torsoLean > LiftThresholds.squatMaxTorsoLean && 
        state != RepState.idle) {
      _addFault('Back rounding!');
    }

    switch (state) {
      case RepState.idle:
        // Starts when hip angle drops below standing threshold
        if (primaryAngle < LiftThresholds.squatStartHipAngle) {
          _repStartTime = DateTime.now();
          _transition(RepState.descending);
        }

      case RepState.descending:
        // Valid depth: hip angle < 90°
        if (primaryAngle <= LiftThresholds.squatDepthHipAngle) {
          _transition(RepState.atDepth);
        }

      case RepState.atDepth:
        // Start ascending when angle increases by > 10°
        if (primaryAngle > _minPrimaryAngle + 10.0) {
          // Check if depth was achieved
          if (_minPrimaryAngle > LiftThresholds.squatDepthHipAngle) {
            _addFault('Deeper!');
          }
          _transition(RepState.ascending);
        }

      case RepState.ascending:
        // Lockout: both hip and knee fully extended
        if (primaryAngle >= LiftThresholds.squatLockoutHipAngle &&
            kneeAngle >= LiftThresholds.squatLockoutKneeAngle) {
          _lockoutAngle = primaryAngle;
          _transition(RepState.lockout);
        }

      case RepState.lockout:
        _completeRep(_lockoutAngle);

      case RepState.complete:
        break;
    }
  }
}

// ──────────────────────────────────────────────────
//  BENCH PRESS State Machine
// ──────────────────────────────────────────────────
class BenchStateMachine extends RepStateMachine {
  @override
  double get _depthThreshold => LiftThresholds.benchBottomElbowAngle;

  @override
  double get _lockoutThreshold => LiftThresholds.benchLockoutElbowAngle;

  @override
  void update(double primaryAngle, Map<String, double> secondaryAngles) {
    // primaryAngle = average elbow angle
    if (primaryAngle < _minPrimaryAngle) {
      _minPrimaryAngle = primaryAngle;
    }

    switch (state) {
      case RepState.idle:
        if (primaryAngle < LiftThresholds.benchStartElbowAngle) {
          _repStartTime = DateTime.now();
          _transition(RepState.descending);
        }

      case RepState.descending:
        if (primaryAngle <= LiftThresholds.benchBottomElbowAngle) {
          _transition(RepState.atDepth);
        }

      case RepState.atDepth:
        if (primaryAngle > _minPrimaryAngle + 10.0) {
          if (_minPrimaryAngle > LiftThresholds.benchBottomElbowAngle) {
            _addFault('Touch chest!');
          }
          _transition(RepState.ascending);
        }

      case RepState.ascending:
        if (primaryAngle >= LiftThresholds.benchLockoutElbowAngle) {
          _lockoutAngle = primaryAngle;
          _transition(RepState.lockout);
        } else if (primaryAngle < 120.0 && _minPrimaryAngle > 80.0) {
          _addFault('Full lockout!');
        }

      case RepState.lockout:
        _completeRep(_lockoutAngle);

      case RepState.complete:
        break;
    }
  }
}

// ──────────────────────────────────────────────────
//  DEADLIFT State Machine
// ──────────────────────────────────────────────────
class DeadliftStateMachine extends RepStateMachine {
  @override
  double get _depthThreshold => LiftThresholds.deadliftBottomHipAngle;

  @override
  double get _lockoutThreshold => LiftThresholds.deadliftLockoutHipAngle;

  @override
  void update(double primaryAngle, Map<String, double> secondaryAngles) {
    // primaryAngle = hip angle
    final kneeAngle = secondaryAngles['knee'] ?? 180.0;
    final backAngle = secondaryAngles['back'] ?? 0.0;

    if (primaryAngle < _minPrimaryAngle) {
      _minPrimaryAngle = primaryAngle;
    }

    // Back rounding check
    if (backAngle > LiftThresholds.deadliftMaxBackRound &&
        state != RepState.idle) {
      _addFault('Back rounding!');
    }

    switch (state) {
      case RepState.idle:
        // Start when hip angle drops below standing threshold (hinge begins)
        if (primaryAngle < LiftThresholds.deadliftStartHipAngle) {
          _repStartTime = DateTime.now();
          _transition(RepState.descending);
        }

      case RepState.descending:
        if (primaryAngle <= LiftThresholds.deadliftBottomHipAngle) {
          _transition(RepState.atDepth);
        }

      case RepState.atDepth:
        if (primaryAngle > _minPrimaryAngle + 10.0) {
          _transition(RepState.ascending);
        }

      case RepState.ascending:
        if (primaryAngle >= LiftThresholds.deadliftLockoutHipAngle &&
            kneeAngle >= LiftThresholds.deadliftLockoutKneeAngle) {
          _lockoutAngle = primaryAngle;
          _transition(RepState.lockout);
        }

      case RepState.lockout:
        _completeRep(_lockoutAngle);

      case RepState.complete:
        break;
    }
  }
}

/// Factory to get the right state machine for a lift type.
RepStateMachine createStateMachine(LiftType liftType) {
  switch (liftType) {
    case LiftType.squat:
      return SquatStateMachine();
    case LiftType.benchPress:
      return BenchStateMachine();
    case LiftType.deadlift:
      return DeadliftStateMachine();
  }
}

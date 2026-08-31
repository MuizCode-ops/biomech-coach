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
  double _prevAngle = 180.0;       // previous frame angle — used for direction reversal
  double _lockoutAngle = 0.0;
  final List<String> _faults = [];
  DateTime? _repStartTime;

  // ── Stability tracking for referee cues ──
  final List<double> _stabilityBuffer = [];
  static const int _stabilityFrames = 15;
  static const double _stabilityTolerance = 3.0;
  bool _squatCueGiven = false;
  bool _pressCueGiven = false;
  bool _rackCueGiven = false;

  /// Lift-specific start cue text. Override in subclasses.
  String get _startCueText => 'Squat!';

  /// Returns true when the last [_stabilityFrames] angles vary by ≤ [_stabilityTolerance]°.
  bool _isStable(double angle) {
    _stabilityBuffer.add(angle);
    if (_stabilityBuffer.length > _stabilityFrames) {
      _stabilityBuffer.removeAt(0);
    }
    if (_stabilityBuffer.length < _stabilityFrames) return false;
    final maxVal = _stabilityBuffer.reduce((a, b) => a > b ? a : b);
    final minVal = _stabilityBuffer.reduce((a, b) => a < b ? a : b);
    return (maxVal - minVal) <= _stabilityTolerance;
  }

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
    _prevAngle = 180.0;
    _lockoutAngle = 0.0;
    _repStartTime = null;
    _stabilityBuffer.clear();
    _squatCueGiven = false;
    _pressCueGiven = false;
    _rackCueGiven = false;
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
    _prevAngle = 180.0;
    _lockoutAngle = 0.0;
    _repStartTime = null;
    _stabilityBuffer.clear();
    _squatCueGiven = false;
    _pressCueGiven = false;
    _rackCueGiven = false;
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
        // Wait for stability, then give start cue before allowing descent
        if (!_squatCueGiven) {
          if (_isStable(primaryAngle)) {
            onCoachingCue?.call(_startCueText);
            _squatCueGiven = true;
            _stabilityBuffer.clear();
          }
        } else if (primaryAngle < LiftThresholds.squatStartHipAngle) {
          _repStartTime = DateTime.now();
          _transition(RepState.descending);
        }

      case RepState.descending:
        // Detect bottom by direction reversal (angle stops falling and starts rising)
        if (primaryAngle > _prevAngle) {
          _transition(RepState.atDepth);
        }
        _prevAngle = primaryAngle;

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
        // Wait for stability, then give 'Rack!' cue before completing
        if (!_rackCueGiven) {
          if (_isStable(primaryAngle)) {
            onCoachingCue?.call('Rack!');
            _rackCueGiven = true;
            _stabilityBuffer.clear();
          }
        } else if (_isStable(primaryAngle)) {
          _completeRep(_lockoutAngle);
        }

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
  String get _startCueText => 'Start!';

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
        // Wait for stability, then give 'Start!' cue before allowing descent
        if (!_squatCueGiven) {
          if (_isStable(primaryAngle)) {
            onCoachingCue?.call(_startCueText);
            _squatCueGiven = true;
            _stabilityBuffer.clear();
          }
        } else if (primaryAngle < LiftThresholds.benchStartElbowAngle) {
          _repStartTime = DateTime.now();
          _transition(RepState.descending);
        }

      case RepState.descending:
        // Detect bottom by direction reversal (angle stops falling and starts rising)
        if (primaryAngle > _prevAngle) {
          _transition(RepState.atDepth);
        }
        _prevAngle = primaryAngle;

      case RepState.atDepth:
        // Require stable pause at chest before allowing press
        if (!_pressCueGiven) {
          if (_isStable(primaryAngle)) {
            onCoachingCue?.call('Press!');
            _pressCueGiven = true;
            _stabilityBuffer.clear();
          }
          return;
        }
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
        } else if (primaryAngle < LiftThresholds.benchAscendShallowCheckAngle &&
            _minPrimaryAngle > LiftThresholds.benchMinDepthForShallowCheck) {
          _addFault('Not deep enough!');
        }

      case RepState.lockout:
        if (!_rackCueGiven) {
          if (_isStable(primaryAngle)) {
            onCoachingCue?.call('Rack!');
            _rackCueGiven = true;
            _stabilityBuffer.clear();
          }
        } else if (_isStable(primaryAngle)) {
          _completeRep(_lockoutAngle);
        }

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
        // Wait for stability, then give start cue before allowing descent
        if (!_squatCueGiven) {
          if (_isStable(primaryAngle)) {
            onCoachingCue?.call(_startCueText);
            _squatCueGiven = true;
            _stabilityBuffer.clear();
          }
        } else if (primaryAngle < LiftThresholds.deadliftStartHipAngle) {
          _repStartTime = DateTime.now();
          _transition(RepState.descending);
        }

      case RepState.descending:
        // Detect bottom by direction reversal (angle stops falling and starts rising)
        if (primaryAngle > _prevAngle) {
          _transition(RepState.atDepth);
        }
        _prevAngle = primaryAngle;

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
        if (!_rackCueGiven) {
          if (_isStable(primaryAngle)) {
            onCoachingCue?.call('Rack!');
            _rackCueGiven = true;
            _stabilityBuffer.clear();
          }
        } else if (_isStable(primaryAngle)) {
          _completeRep(_lockoutAngle);
        }

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

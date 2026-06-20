// lib/services/database_service.dart
// Hive-based local database for training journal storage.

import 'package:hive_flutter/hive_flutter.dart';
import '../models/lift_session.dart';
import '../models/rep_record.dart';

class DatabaseService {
  static const String _sessionsBox = 'lift_sessions';
  late Box<LiftSession> _sessions;

  static DatabaseService? _instance;
  static DatabaseService get instance => _instance ??= DatabaseService._();
  DatabaseService._();

  /// Initialize Hive and open boxes. Call once at app start.
  Future<void> initialize() async {
    await Hive.initFlutter();

    // Register adapters (pre-generated)
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LiftSessionAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(RepRecordAdapter());
    }

    _sessions = await Hive.openBox<LiftSession>(_sessionsBox);
  }

  // ──────────────────────────────────────────
  //  WRITE
  // ──────────────────────────────────────────

  /// Save a completed session to the database.
  Future<void> saveSession(LiftSession session) async {
    await _sessions.add(session);
  }

  // ──────────────────────────────────────────
  //  READ
  // ──────────────────────────────────────────

  /// Get all sessions, newest first.
  List<LiftSession> getAllSessions() {
    return _sessions.values.toList().reversed.toList();
  }

  /// Get sessions filtered by lift type.
  List<LiftSession> getSessionsByLift(String liftType) {
    return _sessions.values
        .where((s) => s.liftType == liftType)
        .toList()
        .reversed
        .toList();
  }

  /// Get recent N sessions.
  List<LiftSession> getRecentSessions({int limit = 10}) {
    final all = getAllSessions();
    return all.take(limit).toList();
  }

  /// Calculate total valid reps across all sessions.
  int get totalValidReps =>
      _sessions.values.fold(0, (sum, s) => sum + s.validReps);

  /// Calculate total invalid (bad form) reps across all sessions.
  int get totalInvalidReps =>
      _sessions.values.fold(0, (sum, s) => sum + s.invalidReps);

  /// Calculate average form score across all sessions.
  double get overallAverageFormScore {
    final sessions = _sessions.values.toList();
    if (sessions.isEmpty) return 0.0;
    final scores = sessions
        .where((s) => s.validReps > 0)
        .map((s) => s.averageFormScore)
        .toList();
    if (scores.isEmpty) return 0.0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  /// Get form score trend (last N sessions) for chart display.
  List<double> getFormScoreTrend({int limit = 10}) {
    return getRecentSessions(limit: limit)
        .reversed
        .map((s) => s.averageFormScore)
        .toList();
  }

  // ──────────────────────────────────────────
  //  DELETE
  // ──────────────────────────────────────────

  Future<void> deleteSession(LiftSession session) async {
    await session.delete();
  }

  Future<void> clearAll() async {
    await _sessions.clear();
  }

  Future<void> close() async {
    await _sessions.close();
  }
}

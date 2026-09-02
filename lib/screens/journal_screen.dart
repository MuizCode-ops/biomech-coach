// lib/screens/journal_screen.dart
// Training journal — Premium Dark NBA-Style Theme with scoreboard boxes and stats.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/lift_thresholds.dart';
import '../constants/app_theme.dart';
import '../models/lift_session.dart';
import '../services/backup_service.dart';
import '../services/database_service.dart';
import 'session_screen.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<LiftSession> _sessions = [];
  String? _selectedLiftType; // 'benchPress', 'squat', or null for all

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _sessions = DatabaseService.instance.getAllSessions();
    });
  }

  Future<void> _exportBackup() async {
    final success = await BackupService.exportBackup();
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup file exported successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export backup. Make sure you have session logs.'),
          ),
        );
      }
    }
  }

  Future<void> _importBackup() async {
    final count = await BackupService.importBackup();
    if (mounted) {
      if (count > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Success! Imported $count new session logs.')),
        );
        _load();
      } else if (count == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Import complete. All sessions in file were duplicates.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Backup import cancelled or failed.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedLiftType == null
        ? _sessions
        : _sessions.where((s) => s.liftType == _selectedLiftType).toList();

    return Scaffold(
      backgroundColor: AppColors.background, // Midnight Obsidian Navy
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildCategoryTabs(),
            const SizedBox(height: 16),
            _buildOverallStats(filtered),
            const SizedBox(height: 16),
            if (filtered.length >= 2) ...[
              _buildTrendChart(filtered),
              const SizedBox(height: 16),
            ],
            Expanded(child: _buildSessionList(filtered)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TRAINING HISTORIES',
                style: GoogleFonts.outfit(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              Text(
                'Journal',
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Import/Export buttons (Game menu style)
          IconButton(
            icon: const Icon(Icons.download_rounded,
                color: AppColors.textMuted, size: 22),
            tooltip: 'Import Backup',
            onPressed: _importBackup,
          ),
          IconButton(
            icon: const Icon(Icons.upload_rounded,
                color: AppColors.textMuted, size: 22),
            tooltip: 'Export Backup',
            onPressed: _exportBackup,
          ),
          const SizedBox(width: 8),
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.surfaceBorder, width: 1),
              ),
              child: const Icon(Icons.chevron_left_rounded,
                  color: AppColors.textPrimary, size: 22),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final benchPressSessions = _sessions.where((s) => s.liftType == 'benchPress').toList();
    final squatSessions = _sessions.where((s) => s.liftType == 'squat').toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildCategoryCard(
                  title: 'B.P',
                  fullName: 'Bench Press',
                  emoji: '🤸',
                  sessionCount: benchPressSessions.length,
                  typeKey: 'benchPress',
                  accentColor: const Color(0xFFC9082A), // NBA Red
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildCategoryCard(
                  title: 'Squat',
                  fullName: 'Squat',
                  emoji: '🏋️',
                  sessionCount: squatSessions.length,
                  typeKey: 'squat',
                  accentColor: AppColors.accentLive, // Emerald
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({
    required String title,
    required String fullName,
    required String emoji,
    required int sessionCount,
    required String typeKey,
    required Color accentColor,
    bool isFullWidth = false,
  }) {
    final isSelected = _selectedLiftType == typeKey;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedLiftType == typeKey) {
            _selectedLiftType = null;
          } else {
            _selectedLiftType = typeKey;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isFullWidth ? 20 : 12,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? accentColor : AppColors.surfaceBorder,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accentColor : AppColors.surfaceBorder,
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Text(
                  emoji,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$sessionCount Games',
                    style: GoogleFonts.barlowCondensed(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.check_circle_rounded,
                color: accentColor,
                size: 18,
              ),
            ] else if (isFullWidth) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverallStats(List<LiftSession> displayedSessions) {
    final totalSessions = displayedSessions.length;
    int totalReps = 0;
    int totalBadReps = 0;
    double totalScoreSum = 0;
    int ratedSessionsCount = 0;

    for (var session in displayedSessions) {
      totalReps += session.validReps;
      totalBadReps += session.invalidReps;
      if (session.reps.isNotEmpty) {
        totalScoreSum += session.averageFormScore;
        ratedSessionsCount++;
      }
    }

    final avgScore = ratedSessionsCount == 0 ? 0.0 : totalScoreSum / ratedSessionsCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          _StatCard(
              value: '$totalSessions',
              label: 'Games',
              color: const Color(0xFF1D428A)), // NBA Blue
          const SizedBox(width: 8),
          _StatCard(
              value: '$totalReps',
              label: 'Valid Reps',
              color: AppColors.accentLive),
          const SizedBox(width: 8),
          _StatCard(
              value: '$totalBadReps',
              label: 'Bad Form',
              color: AppColors.accentAlert), // NBA Red
          const SizedBox(width: 8),
          _StatCard(
              value: '${avgScore.toStringAsFixed(0)}%',
              label: 'Avg Form',
              color: const Color(0xFF7C3AED)),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<LiftSession> displayedSessions) {
    final sorted = List<LiftSession>.from(displayedSessions)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    final scores = sorted.map((s) => s.averageFormScore).toList();
    final trendScores = scores.length > 10 ? scores.sublist(scores.length - 10) : scores;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceBorder, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FORM SCORE TREND',
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 90,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: 100,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: trendScores
                          .asMap()
                          .entries
                          .map((e) =>
                              FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: AppColors.accentBlue,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.accentBlue.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionList(List<LiftSession> displayedSessions) {
    if (displayedSessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              _selectedLiftType == null
                  ? 'No training games logged'
                  : 'No ${_selectedLiftType == 'benchPress' ? 'Bench Press' : 'Squat'} games logged',
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Complete a session scan to start tracking history.',
              style: GoogleFonts.outfit(
                color: AppColors.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      itemCount: displayedSessions.length,
      itemBuilder: (_, i) => _SessionCard(session: displayedSessions[i]),
    );
  }
}

// ── Stat card (Score box style) ─────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatCard(
      {required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.barlowCondensed(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label.toUpperCase(),
              style: GoogleFonts.outfit(
                color: AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Session card (Match Score Card style) ──────────────────────────────────────────────

class _SessionCard extends StatelessWidget {
  final LiftSession session;
  const _SessionCard({required this.session});

  LiftType get _liftType => LiftType.values.firstWhere(
        (l) => l.name == session.liftType,
        orElse: () => LiftType.squat,
      );

  String get _abbreviation {
    switch (_liftType) {
      case LiftType.squat:
        return 'SQT';
      case LiftType.benchPress:
        return 'B.P';
    }
  }

  Color get _themeColor {
    switch (_liftType) {
      case LiftType.squat:
        return AppColors.accentLive;
      case LiftType.benchPress:
        return const Color(0xFFC9082A);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = session.averageFormScore >= 80
        ? AppColors.accentLive
        : const Color(0xFFF59E0B);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SessionSummaryScreen(
              session: session,
              fromJournal: true,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
        ),
        child: Row(
          children: [
            // Typographic team-like badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _themeColor.withValues(alpha: 0.7),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  _abbreviation,
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Text details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _liftType.displayName.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${session.formattedDate}  ·  ${session.formattedDuration}',
                    style: GoogleFonts.outfit(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Stats column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  session.invalidReps > 0
                      ? '${session.validReps} W - ${session.invalidReps} L'
                      : '${session.totalReps} REPS',
                  style: GoogleFonts.barlowCondensed(
                    color: session.invalidReps > 0
                        ? AppColors.accentAlert
                        : AppColors.accentLive,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.averageFormScore.toStringAsFixed(0)}%',
                  style: GoogleFonts.barlowCondensed(
                    color: scoreColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

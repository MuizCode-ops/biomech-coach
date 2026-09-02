// lib/screens/session_screen.dart
// Post-session summary — Premium Dark NBA-Style Theme with game final scoreboard layouts.

import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/lift_thresholds.dart';
import '../models/lift_session.dart';
import '../models/rep_record.dart';
import '../constants/app_theme.dart';
import 'home_screen.dart';

class SessionSummaryScreen extends StatelessWidget {
  final LiftSession session;
  final bool fromJournal;

  const SessionSummaryScreen({
    super.key,
    required this.session,
    this.fromJournal = false,
  });

  LiftType get _liftType => LiftType.values.firstWhere(
        (l) => l.name == session.liftType,
        orElse: () => LiftType.squat,
      );

  Color get _accent => const Color(0xFF2F80ED); // Neon Game Blue

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Midnight Obsidian Navy
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildScoreBanner(),
                    const SizedBox(height: 20),
                    _buildStatRow(),
                    const SizedBox(height: 24),
                    _buildChartSection(),
                    const SizedBox(height: 24),
                    _buildRepList(),
                    if (session.faultFrequency.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildImprovementCard(),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            _buildDoneButton(context),
          ],
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────

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
        return const Color(0xFF10B981);
      case LiftType.benchPress:
        return const Color(0xFFC9082A);
    }
  }

  Widget _buildHeader(BuildContext context) {
    final statusColor = fromJournal ? const Color(0xFF2F80ED) : const Color(0xFF10B981);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (fromJournal) {
                Navigator.pop(context);
              } else {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (_) => false,
                );
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.surfaceBorder, width: 1),
              ),
              child: const Icon(Icons.close_rounded,
                  color: AppColors.textPrimary, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                (fromJournal ? 'GAME DETAIL SUMMARY' : 'MATCH COMPLETE').toUpperCase(),
                style: GoogleFonts.outfit(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              Text(
                _liftType.displayName.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Typographic team-like badge instead of emoji
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
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
        ],
      ),
    );
  }

  // ── Score banner (NBA Game Final Box style) ────────────────────────

  Widget _buildScoreBanner() {
    final score = session.averageFormScore;
    final isGreat = score >= 80;
    final color = isGreat ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
                  ),
                  child: Text(
                    'FINAL RATING',
                    style: GoogleFonts.outfit(
                      color: color,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  isGreat ? '🎯 Form locked in!' : '💪 Adjust parameters',
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isGreat
                      ? 'Reps hit absolute depth/lockout standards.'
                      : 'Audio logs flag warnings for deep angle thresholds.',
                  style: GoogleFonts.outfit(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Text(
            '${score.toStringAsFixed(0)}%',
            style: GoogleFonts.barlowCondensed(
              color: color,
              fontSize: 38,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats ───────────────────────────────

  Widget _buildStatRow() {
    return Row(
      children: [
        _StatBox(
          value: '${session.validReps}',
          label: 'Wins',
          color: const Color(0xFF10B981),
        ),
        const SizedBox(width: 8),
        _StatBox(
          value: '${session.invalidReps}',
          label: 'Losses',
          color: const Color(0xFFC9082A),
        ),
        const SizedBox(width: 8),
        _StatBox(
          value: '${session.totalReps}',
          label: 'Total',
          color: const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 8),
        _StatBox(
          value: session.formattedDuration,
          label: 'Duration',
          color: _accent,
        ),
      ],
    );
  }

  // ── Chart (Neon Grid style) ───────────────────────────────

  Widget _buildChartSection() {
    if (session.reps.length < 2) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REP FLEX PERFORMANCE CHART',
            style: GoogleFonts.outfit(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.surfaceBorder,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: GoogleFonts.barlowCondensed(
                            color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text(
                        'R${v.toInt() + 1}',
                        style: GoogleFonts.barlowCondensed(
                            color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: session.reps
                        .asMap()
                        .entries
                        .map((e) =>
                            FlSpot(e.key.toDouble(), e.value.formScore))
                        .toList(),
                    isCurved: true,
                    color: _accent,
                    barWidth: 3.0,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 5,
                        color: session.reps[spot.x.toInt()].isValid
                            ? AppColors.accentLive
                            : AppColors.accentAlert,
                        strokeWidth: 1.5,
                        strokeColor: AppColors.textPrimary,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _accent.withValues(alpha: 0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Rep list ────────────────────────────

  // ── Fault tips lookup ──────────────────

  static const Map<String, String> _faultTips = {
    'Deeper!': 'Focus on breaking parallel \u2014 try pausing at the bottom of a few warm-up reps to build depth awareness.',
    'Back rounding!': 'Brace your core before descending and keep your chest up throughout the lift.',
    'Not deep enough!': 'Lower the bar fully to your chest before pressing \u2014 a spotter or slower tempo can help.',
    'Touch chest!': 'Ensure the bar makes contact with your chest at the bottom \u2014 pause reps in warm-ups build this habit.',
    'Full lockout!': 'Drive through to full arm extension at the top of each rep \u2014 don\u2019t cut reps short.',
  };

  Widget _buildImprovementCard() {
    final faults = session.faultFrequency;
    final topFaults = faults.entries.take(3).toList();
    final totalReps = session.totalReps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'IMPROVE NEXT SESSION',
          style: GoogleFonts.outfit(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 12),
        ...topFaults.map((entry) {
          final fault = entry.key;
          final count = entry.value;
          final tip = _faultTips[fault] ?? 'Work on this consistently \u2014 focus on controlled reps during warm-ups.';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.surfaceBorder,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentAlert.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        fault,
                        style: GoogleFonts.outfit(
                          color: AppColors.accentAlert,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '$count of $totalReps reps',
                      style: GoogleFonts.outfit(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('\ud83d\udca1 ', style: TextStyle(fontSize: 13)),
                    Expanded(
                      child: Text(
                        tip,
                        style: GoogleFonts.outfit(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildRepList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PLAY-BY-PLAY BREAKDOWN',
          style: GoogleFonts.outfit(
            color: AppColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 2.0,
          ),
        ),
        const SizedBox(height: 12),
        ...session.reps.asMap().entries.map((e) =>
            _RepRow(number: e.key + 1, rep: e.value, liftType: _liftType)),
      ],
    );
  }

  // ── Done button ─────────────────────────

  Widget _buildDoneButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
      child: GestureDetector(
        onTap: () {
          if (fromJournal) {
            Navigator.pop(context);
          } else {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (_) => false,
            );
          }
        },
        child: Container(
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF1D428A), // NBA Blue
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1D428A).withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              (fromJournal ? 'RETURN TO JOURNAL' : 'CLOSE REPORT').toUpperCase(),
              style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stat box (NBA score card segment) ──────────────────────────────────────────────────

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  const _StatBox(
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

// ── Rep row ───────────────────────────────────────────────────

class _RepRow extends StatefulWidget {
  final int number;
  final RepRecord rep;
  final LiftType liftType;

  const _RepRow({
    required this.number,
    required this.rep,
    required this.liftType,
  });

  @override
  State<_RepRow> createState() => _RepRowState();
}

class _RepRowState extends State<_RepRow> {
  bool _isExpanded = false;
  String? _imagePath;
  bool _imageExists = false;

  @override
  void initState() {
    super.initState();
    _checkImage();
  }

  Future<void> _checkImage() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final filepath = '${appDir.path}/wrongdoing_${widget.rep.timestamp.millisecondsSinceEpoch}.jpg';
      final file = File(filepath);
      if (await file.exists()) {
        setState(() {
          _imagePath = filepath;
          _imageExists = true;
        });
      }
    } catch (e) {
      debugPrint('Error checking wrongdoing image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final valid = widget.rep.isValid;
    final statusColor = valid ? AppColors.accentLive : AppColors.accentAlert;

    final (depthLabel, lockoutLabel, depthTarget, lockoutTarget) =
        switch (widget.liftType) {
      LiftType.squat => (
          'Min Hip',
          'Lockout Hip',
          '< ${LiftThresholds.squatDepthHipAngle.toStringAsFixed(0)}°',
          '> ${LiftThresholds.squatLockoutHipAngle.toStringAsFixed(0)}°'
        ),
      LiftType.benchPress => (
          'Min Elbow',
          'Lockout Elbow',
          '< ${LiftThresholds.benchBottomElbowAngle.toStringAsFixed(0)}°',
          '> ${LiftThresholds.benchLockoutElbowAngle.toStringAsFixed(0)}°'
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _isExpanded
              ? AppColors.accentBlue
              : AppColors.surfaceBorder,
          width: _isExpanded ? 1.5 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Number jersey circle
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                          border: Border.all(color: statusColor, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            '${widget.number}',
                            style: GoogleFonts.barlowCondensed(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              valid ? '✓  CLEAR REP' : '✗  FAULT DECLARED',
                              style: GoogleFonts.outfit(
                                color: statusColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            if (widget.rep.faultNotes.isNotEmpty)
                              Text(
                                widget.rep.faultNotes.join(' · ').toUpperCase(),
                                style: GoogleFonts.outfit(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            else
                              Text(
                                _isExpanded ? 'TAP TO COLLAPSE' : 'TAP TO INSPECT METRICS',
                                style: GoogleFonts.outfit(
                                  color: AppColors.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${widget.rep.formScore.toStringAsFixed(0)}%',
                        style: GoogleFonts.barlowCondensed(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                    ],
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(height: 14),
                    const Divider(color: AppColors.surfaceBorder, height: 1),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        _buildMetricCell(
                          icon: Icons.timer_outlined,
                          label: 'TEMPO',
                          value: '${widget.rep.durationSeconds.toStringAsFixed(1)}s',
                          subLabel: 'Lift Duration',
                          color: const Color(0xFF2F80ED),
                        ),
                        const SizedBox(width: 8),
                        _buildMetricCell(
                          icon: Icons.vertical_align_bottom_rounded,
                          label: depthLabel,
                          value: '${widget.rep.minDepthAngle.toStringAsFixed(1)}°',
                          subLabel: 'Req. $depthTarget',
                          color: const Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 8),
                        _buildMetricCell(
                          icon: Icons.vertical_align_top_rounded,
                          label: lockoutLabel,
                          value: widget.rep.lockoutAngle > 0
                              ? '${widget.rep.lockoutAngle.toStringAsFixed(1)}°'
                              : 'N/A',
                          subLabel: 'Req. $lockoutTarget',
                          color: const Color(0xFF10B981),
                        ),
                      ],
                    ),
                    if (_imageExists && _imagePath != null) ...[
                      const SizedBox(height: 14),
                      const Divider(color: AppColors.surfaceBorder, height: 1),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'KINESIOLOGY ALARM SNAPSHOT:',
                          style: GoogleFonts.outfit(
                            color: AppColors.accentAlert,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.accentAlert.withValues(alpha: 0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Stack(
                            alignment: Alignment.bottomLeft,
                            children: [
                              Image.file(
                                File(_imagePath!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 220,
                              ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                color: AppColors.accentAlert.withValues(alpha: 0.85),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        widget.rep.faultNotes.join(' · ').toUpperCase(),
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCell({
    required IconData icon,
    required String label,
    required String value,
    required String subLabel,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.surfaceBorder, width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.barlowCondensed(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subLabel,
              style: GoogleFonts.outfit(
                color: AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

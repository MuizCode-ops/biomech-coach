// lib/screens/session_screen.dart
// Post-session summary — clean white light theme.

import 'package:fl_chart/fl_chart.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/lift_thresholds.dart';
import '../models/lift_session.dart';
import '../models/rep_record.dart';
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

  Color get _accent => const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
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
            child: const Icon(Icons.close_rounded,
                color: Color(0xFF64748B), size: 26),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fromJournal ? 'SESSION DETAILS' : 'SESSION COMPLETE',
                style: GoogleFonts.outfit(
                  color: fromJournal ? const Color(0xFF2563EB) : const Color(0xFF10B981),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.0,
                ),
              ),
              Text(
                _liftType.displayName,
                style: GoogleFonts.outfit(
                  color: const Color(0xFF0F172A),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(_liftType.emoji, style: const TextStyle(fontSize: 36)),
        ],
      ),
    );
  }

  // ── Score banner ────────────────────────

  Widget _buildScoreBanner() {
    final score = session.averageFormScore;
    final isGreat = score >= 80;
    final color = isGreat ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isGreat ? '🎯 Excellent Form!' : '💪 Keep Improving!',
                style: GoogleFonts.outfit(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                isGreat
                    ? 'Your reps met competition standards.'
                    : 'Work on depth and lockout consistency.',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF64748B),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '${score.toStringAsFixed(0)}%',
            style: GoogleFonts.outfit(
              color: color,
              fontSize: 36,
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
          label: 'Valid Reps',
          color: const Color(0xFF10B981),
        ),
        const SizedBox(width: 8),
        _StatBox(
          value: '${session.invalidReps}',
          label: 'Bad Form',
          color: const Color(0xFFEF4444),
        ),
        const SizedBox(width: 8),
        _StatBox(
          value: '${session.totalReps}',
          label: 'Total Reps',
          color: const Color(0xFF64748B),
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

  // ── Chart ───────────────────────────────

  Widget _buildChartSection() {
    if (session.reps.length < 2) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: const Border.fromBorderSide(
            BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Form Score per Rep',
            style: GoogleFonts.outfit(
              color: const Color(0xFF0F172A),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
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
                    color: Color(0xFFF1F5F9),
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
                        style: GoogleFonts.outfit(
                            color: const Color(0xFF94A3B8), fontSize: 10),
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
                        style: GoogleFonts.outfit(
                            color: const Color(0xFF94A3B8), fontSize: 10),
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
                    barWidth: 2.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
                        radius: 5,
                        color: session.reps[spot.x.toInt()].isValid
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        strokeWidth: 0,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _accent.withValues(alpha: 0.05),
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

  Widget _buildRepList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rep Breakdown',
          style: GoogleFonts.outfit(
            color: const Color(0xFF0F172A),
            fontSize: 15,
            fontWeight: FontWeight.w700,
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
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
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
          height: 54,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              fromJournal ? 'Back to Journal' : 'Done',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Stat box ──────────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: const Border.fromBorderSide(
              BorderSide(color: Color(0xFFE2E8F0), width: 1)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.outfit(
                color: const Color(0xFF94A3B8),
                fontSize: 11,
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
    final statusColor =
        valid ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    final (depthLabel, lockoutLabel, depthTarget, lockoutTarget) =
        switch (widget.liftType) {
      LiftType.squat => (
          'Min Hip Angle',
          'Lockout Hip',
          '< ${LiftThresholds.squatDepthHipAngle.toStringAsFixed(0)}°',
          '> ${LiftThresholds.squatLockoutHipAngle.toStringAsFixed(0)}°'
        ),
      LiftType.benchPress => (
          'Min Elbow Angle',
          'Lockout Elbow',
          '< ${LiftThresholds.benchBottomElbowAngle.toStringAsFixed(0)}°',
          '> ${LiftThresholds.benchLockoutElbowAngle.toStringAsFixed(0)}°'
        ),
      LiftType.deadlift => (
          'Min Hip Angle',
          'Lockout Hip',
          '< ${LiftThresholds.deadliftBottomHipAngle.toStringAsFixed(0)}°',
          '> ${LiftThresholds.deadliftLockoutHipAngle.toStringAsFixed(0)}°'
        ),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isExpanded
              ? const Color(0xFF2563EB)
              : statusColor.withValues(alpha: 0.2),
          width: _isExpanded ? 1.5 : 1,
        ),
        boxShadow: _isExpanded
            ? [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
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
                      // Number circle
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${widget.number}',
                            style: GoogleFonts.outfit(
                              color: statusColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              valid ? '✓  Valid Rep' : '✗  Invalid Rep',
                              style: GoogleFonts.outfit(
                                color: statusColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            if (widget.rep.faultNotes.isNotEmpty)
                              Text(
                                widget.rep.faultNotes.join(' · '),
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 11,
                                ),
                              )
                            else
                              Text(
                                _isExpanded ? 'Hide metrics' : 'Tap to view metrics',
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        '${widget.rep.formScore.toStringAsFixed(0)}%',
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        _isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF94A3B8),
                        size: 20,
                      ),
                    ],
                  ),
                  if (_isExpanded) ...[
                    const SizedBox(height: 12),
                    const Divider(color: Color(0xFFF1F5F9), height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildMetricCell(
                          icon: Icons.timer_outlined,
                          label: 'Duration',
                          value: '${widget.rep.durationSeconds.toStringAsFixed(1)}s',
                          subLabel: 'Tempo',
                          color: const Color(0xFF2563EB),
                        ),
                        const SizedBox(width: 8),
                        _buildMetricCell(
                          icon: Icons.vertical_align_bottom_rounded,
                          label: depthLabel,
                          value: '${widget.rep.minDepthAngle.toStringAsFixed(1)}°',
                          subLabel: 'Target $depthTarget',
                          color: const Color(0xFF7C3AED),
                        ),
                        const SizedBox(width: 8),
                        _buildMetricCell(
                          icon: Icons.vertical_align_top_rounded,
                          label: lockoutLabel,
                          value: widget.rep.lockoutAngle > 0
                              ? '${widget.rep.lockoutAngle.toStringAsFixed(1)}°'
                              : 'N/A',
                          subLabel: 'Target $lockoutTarget',
                          color: const Color(0xFF10B981),
                        ),
                      ],
                    ),
                    if (_imageExists && _imagePath != null) ...[
                      const SizedBox(height: 14),
                      const Divider(color: Color(0xFFF1F5F9), height: 1),
                      const SizedBox(height: 14),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Captured Wrongdoing:',
                          style: GoogleFonts.outfit(
                            color: const Color(0xFFEF4444),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.25),
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
                                color: const Color(0xFFEF4444).withValues(alpha: 0.85),
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
                                        widget.rep.faultNotes.join(' · '),
                                        style: GoogleFonts.outfit(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
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
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF64748B),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.outfit(
                color: const Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subLabel,
              style: GoogleFonts.outfit(
                color: const Color(0xFF94A3B8),
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

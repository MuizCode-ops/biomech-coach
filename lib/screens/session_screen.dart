// lib/screens/session_screen.dart
// Post-session summary — clean white light theme.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/lift_thresholds.dart';
import '../models/lift_session.dart';
import '../models/rep_record.dart';
import 'home_screen.dart';

class SessionSummaryScreen extends StatelessWidget {
  final LiftSession session;
  const SessionSummaryScreen({super.key, required this.session});

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
            onTap: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (_) => false,
            ),
            child: const Icon(Icons.close_rounded,
                color: Color(0xFF64748B), size: 26),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SESSION COMPLETE',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF10B981),
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
        const SizedBox(width: 10),
        _StatBox(
          value: '${session.totalReps}',
          label: 'Total Reps',
          color: const Color(0xFF64748B),
        ),
        const SizedBox(width: 10),
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
            _RepRow(number: e.key + 1, rep: e.value)),
      ],
    );
  }

  // ── Done button ─────────────────────────

  Widget _buildDoneButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: GestureDetector(
        onTap: () => Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (_) => false,
        ),
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
              'Done',
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

class _RepRow extends StatelessWidget {
  final int number;
  final RepRecord rep;
  const _RepRow({required this.number, required this.rep});

  @override
  Widget build(BuildContext context) {
    final valid = rep.isValid;
    final statusColor =
        valid ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
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
                '$number',
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
                if (rep.faultNotes.isNotEmpty)
                  Text(
                    rep.faultNotes.join(' · '),
                    style: GoogleFonts.outfit(
                      color: const Color(0xFF94A3B8),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${rep.formScore.toStringAsFixed(0)}%',
            style: GoogleFonts.outfit(
              color: const Color(0xFF0F172A),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}

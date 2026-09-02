// lib/widgets/rep_counter_widget.dart
// Scoreboard-style rep counter — dark sports aesthetic with pulsing LIVE dot.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_theme.dart';
import '../constants/lift_thresholds.dart';
import '../services/state_machine.dart';

class RepCounterWidget extends StatefulWidget {
  final int validReps;
  final int totalReps;
  final RepState state;
  final LiftType liftType;

  const RepCounterWidget({
    super.key,
    required this.validReps,
    required this.totalReps,
    required this.state,
    required this.liftType,
  });

  @override
  State<RepCounterWidget> createState() => _RepCounterWidgetState();
}

class _RepCounterWidgetState extends State<RepCounterWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnim;
  late AnimationController _liveController;
  int _prevValid = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.elasticOut),
    );
    _liveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void didUpdateWidget(RepCounterWidget old) {
    super.didUpdateWidget(old);
    if (widget.validReps > _prevValid) {
      _prevValid = widget.validReps;
      _pulseController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _liveController.dispose();
    super.dispose();
  }

  // ── State colours ───────────────────────
  Color get _stateColor => switch (widget.state) {
        RepState.idle => AppColors.accentBlue,
        RepState.descending => const Color(0xFF7C3AED),
        RepState.atDepth => AppColors.accentLive,
        RepState.ascending => const Color(0xFFF59E0B),
        RepState.lockout => AppColors.accentLive,
        RepState.complete => AppColors.accentLive,
      };

  String get _stateLabel {
    switch (widget.state) {
      case RepState.idle:
        if (widget.liftType == LiftType.benchPress) return 'READY / BAR UP';
        return 'STAND TALL';
      case RepState.descending:
        if (widget.liftType == LiftType.benchPress) return 'LOWER BAR';
        return 'DESCEND';
      case RepState.atDepth:
        if (widget.liftType == LiftType.benchPress) return 'TOUCH CHEST';
        return 'DEPTH HOLD';
      case RepState.ascending:
        if (widget.liftType == LiftType.benchPress) return 'PRESS UP';
        return 'DRIVE UP';
      case RepState.lockout:
        return 'LOCKOUT';
      case RepState.complete:
        return 'GOOD REP!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // LIVE indicator + state pill row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing LIVE dot
              FadeTransition(
                opacity: _liveController,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: AppColors.accentLive,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accentLive,
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'LIVE',
                style: GoogleFonts.outfit(
                  color: AppColors.accentLive,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // State pill
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _stateColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: _stateColor.withValues(alpha: 0.25), width: 0.8),
            ),
            child: Text(
              _stateLabel,
              style: GoogleFonts.outfit(
                color: _stateColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Rep count — big Barlow Condensed scoreboard number
          ScaleTransition(
            scale: _scaleAnim,
            child: Text(
              '${widget.validReps}',
              style: GoogleFonts.barlowCondensed(
                color: AppColors.textPrimary,
                fontSize: 64,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
          ),
          // Thin scoreboard divider
          Container(
            width: 36,
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 6),
            color: AppColors.surfaceBorder,
          ),
          Text(
            'VALID REPS',
            style: GoogleFonts.outfit(
              color: AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          // Breakdown row (Win/Loss style)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: AppColors.surfaceBorder, width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TOTAL: ',
                  style: GoogleFonts.outfit(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${widget.totalReps}',
                  style: GoogleFonts.barlowCondensed(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (widget.totalReps > widget.validReps) ...[
                  const SizedBox(width: 8),
                  Container(width: 1, height: 10, color: AppColors.surfaceBorder),
                  const SizedBox(width: 8),
                  Text(
                    '✗ ${widget.totalReps - widget.validReps}',
                    style: GoogleFonts.barlowCondensed(
                      color: AppColors.accentAlert,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

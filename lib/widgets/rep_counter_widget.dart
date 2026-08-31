// lib/widgets/rep_counter_widget.dart
// Animated valid rep counter — Premium Dark HUD theme.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnim;
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
    super.dispose();
  }

  // ── State colours ───────────────────────
  Color get _stateColor => switch (widget.state) {
        RepState.idle => const Color(0xFF2F80ED),
        RepState.descending => const Color(0xFF7C3AED),
        RepState.atDepth => const Color(0xFF10B981),
        RepState.ascending => const Color(0xFFF59E0B),
        RepState.lockout => const Color(0xFF10B981),
        RepState.complete => const Color(0xFF10B981),
      };

  String get _stateLabel {
    switch (widget.state) {
      case RepState.idle:
        if (widget.liftType == LiftType.benchPress) return 'READY / BAR UP';
        return 'STAND TALL';
      case RepState.descending:
        if (widget.liftType == LiftType.benchPress) return 'LOWER BAR';
        if (widget.liftType == LiftType.deadlift) return 'HINGE DOWN';
        return 'DESCEND';
      case RepState.atDepth:
        if (widget.liftType == LiftType.benchPress) return 'TOUCH CHEST';
        if (widget.liftType == LiftType.deadlift) return 'BOTTOM HOLD';
        return 'DEPTH HOLD';
      case RepState.ascending:
        if (widget.liftType == LiftType.benchPress) return 'PRESS UP';
        if (widget.liftType == LiftType.deadlift) return 'PULL UP';
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
        color: const Color(0xFF161F38).withValues(alpha: 0.85), // Dark Slate Navy Glass
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF263254), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // State pill
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _stateColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _stateColor.withValues(alpha: 0.3), width: 0.8),
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
          // Rep count
          ScaleTransition(
            scale: _scaleAnim,
            child: Text(
              '${widget.validReps}',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 60,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'VALID REPS',
            style: GoogleFonts.outfit(
              color: const Color(0xFF64748B),
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
              color: const Color(0xFF0F1524),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF1E2640), width: 0.8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'TOTAL: ${widget.totalReps}',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (widget.totalReps > widget.validReps) ...[
                  const SizedBox(width: 8),
                  Container(width: 1, height: 10, color: const Color(0xFF263254)),
                  const SizedBox(width: 8),
                  Text(
                    '✗ ${widget.totalReps - widget.validReps}',
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFEF4444),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
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

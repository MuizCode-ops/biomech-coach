// lib/widgets/rep_counter_widget.dart
// Animated valid rep counter — clean light theme.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/state_machine.dart';

class RepCounterWidget extends StatefulWidget {
  final int validReps;
  final int totalReps;
  final RepState state;

  const RepCounterWidget({
    super.key,
    required this.validReps,
    required this.totalReps,
    required this.state,
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
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.2).animate(
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
        RepState.idle => const Color(0xFF2563EB),
        RepState.descending => const Color(0xFF7C3AED),
        RepState.atDepth => const Color(0xFF10B981),
        RepState.ascending => const Color(0xFFF59E0B),
        RepState.lockout => const Color(0xFF10B981),
        RepState.complete => const Color(0xFF10B981),
      };

  String get _stateLabel => switch (widget.state) {
        RepState.idle => 'READY',
        RepState.descending => 'LOWER',
        RepState.atDepth => 'DEPTH ✓',
        RepState.ascending => 'DRIVE UP',
        RepState.lockout => 'LOCKOUT ✓',
        RepState.complete => 'GREAT REP!',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.93),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _stateColor.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _stateColor.withValues(alpha: 0.12),
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
              color: _stateColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _stateLabel,
              style: GoogleFonts.outfit(
                color: _stateColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
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
                color: const Color(0xFF0F172A),
                fontSize: 60,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
          Text(
            'VALID REPS',
            style: GoogleFonts.outfit(
              color: const Color(0xFF94A3B8),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          // Breakdown row
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Total: ${widget.totalReps}',
                style: GoogleFonts.outfit(
                  color: const Color(0xFF94A3B8),
                  fontSize: 11,
                ),
              ),
              if (widget.totalReps > widget.validReps) ...[
                const SizedBox(width: 10),
                Text(
                  '✗ ${widget.totalReps - widget.validReps}',
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFEF4444),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// lib/widgets/angle_indicator.dart
// Real-time joint angle display widget — clean light theme.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AngleIndicator extends StatelessWidget {
  final String label;
  final double angle;
  final double? targetAngle;
  final bool isGood;

  const AngleIndicator({
    super.key,
    required this.label,
    required this.angle,
    this.targetAngle,
    required this.isGood,
  });

  @override
  Widget build(BuildContext context) {
    final color = isGood ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final bgColor = isGood
        ? const Color(0xFF10B981).withValues(alpha: 0.08)
        : const Color(0xFFEF4444).withValues(alpha: 0.08);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${angle.toStringAsFixed(0)}°',
            style: GoogleFonts.outfit(
              color: const Color(0xFF0F172A),
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          if (targetAngle != null) ...[
            const SizedBox(height: 3),
            Text(
              'target ≤ ${targetAngle!.toStringAsFixed(0)}°',
              style: GoogleFonts.outfit(
                color: const Color(0xFF94A3B8),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// lib/widgets/angle_indicator.dart
// Real-time joint angle display widget — dark scoreboard HUD.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_theme.dart';

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
    final color = isGood ? AppColors.accentLive : AppColors.accentAlert;
    final bgColor = color.withValues(alpha: 0.10);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
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
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
            ),
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${angle.toStringAsFixed(0)}°',
            style: GoogleFonts.barlowCondensed(
              color: AppColors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.0,
            ),
          ),
          if (targetAngle != null) ...[
            const SizedBox(height: 4),
            Text(
              'REQ ≤ ${targetAngle!.toStringAsFixed(0)}°',
              style: GoogleFonts.outfit(
                color: AppColors.textMuted,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// lib/screens/home_screen.dart
// Home screen — Premium Dark NBA-Style Theme with live scoreboard elements.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/lift_thresholds.dart';
import '../constants/app_theme.dart';
import 'camera_screen.dart';
import 'journal_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Midnight Obsidian Navy
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader(context)),
            SliverToBoxAdapter(child: _buildGreeting()),
            SliverToBoxAdapter(child: _buildActiveLifts(context)),
            SliverToBoxAdapter(child: _buildFooter()),
          ],
        ),
      ),
    );
  }

  // ── Header (NBA inspired style) ─────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Row(
        children: [
          Row(
            children: [
              Text(
                'BIOMECH',
                style: GoogleFonts.outfit(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1D428A), Color(0xFFC9082A)], // NBA Blue & Red split
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                ),
                child: Text(
                  'COACH',
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Stats/Journal button (Scoreboard style)
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const JournalScreen()),
            ),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.surfaceBorder, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.analytics_rounded,
                    color: AppColors.accentBlue,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'JOURNAL',
                    style: GoogleFonts.outfit(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
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

  // ── Greeting/Live Feed alert ticker ─────────────────

  Widget _buildGreeting() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.surfaceBorder,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const _BlinkingLiveDot(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EDGE-AI FEED ACTIVE',
                    style: GoogleFonts.outfit(
                      color: AppColors.accentLive,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pose tracker running locally. Zero cloud lag.',
                    style: GoogleFonts.outfit(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Active Lifts (Match Cards Style) ────────────────────

  Widget _buildActiveLifts(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ACTIVE GAME MODES',
            style: GoogleFonts.outfit(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          _LiftHeroCard(
            liftType: LiftType.squat,
            subtitle: 'Checks hip crease depth & knee alignment.',
            themeColor: const Color(0xFF1D428A), // NBA Blue
            checkpoints: const [
              'Hip angle < 90°',
              'Knee valgus alarm',
              'Lockout verification',
            ],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CameraScreen(liftType: LiftType.squat),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _LiftHeroCard(
            liftType: LiftType.benchPress,
            subtitle: 'Tracks elbow extension, chest touch & bar pause.',
            themeColor: const Color(0xFFC9082A), // NBA Red
            checkpoints: const [
              'Chest touch check',
              'Elbow angle < 90°',
              'Elbow lockout check',
            ],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CameraScreen(liftType: LiftType.benchPress),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.shield_rounded,
              color: AppColors.accentLive, size: 14),
          const SizedBox(width: 6),
          Text(
            'Secure Offline Processing Active',
            style: GoogleFonts.outfit(
              color: AppColors.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Blinking Live Dot Widget ──────────────────────────────────────────

class _BlinkingLiveDot extends StatefulWidget {
  const _BlinkingLiveDot();

  @override
  State<_BlinkingLiveDot> createState() => _BlinkingLiveDotState();
}

class _BlinkingLiveDotState extends State<_BlinkingLiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: AppColors.accentLive,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.accentLive,
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable Lift Hero Card ────────────────────────────────────────

class _LiftHeroCard extends StatefulWidget {
  final LiftType liftType;
  final String subtitle;
  final List<String> checkpoints;
  final Color themeColor;
  final VoidCallback onTap;

  const _LiftHeroCard({
    required this.liftType,
    required this.subtitle,
    required this.checkpoints,
    required this.themeColor,
    required this.onTap,
  });

  @override
  State<_LiftHeroCard> createState() => _LiftHeroCardState();
}

class _LiftHeroCardState extends State<_LiftHeroCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.98)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final abbreviation = widget.liftType == LiftType.squat
        ? 'SQT'
        : widget.liftType == LiftType.benchPress
            ? 'B.P'
            : 'DL';

    return ScaleTransition(
      scale: _scale,
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface, // Cleaner darker card navy
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceBorder, width: 1.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top section
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Typographic team abbreviation-like badge
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: widget.themeColor.withValues(alpha: 0.7),
                            width: 2.0),
                      ),
                      child: Center(
                        child: Text(
                          abbreviation,
                          style: GoogleFonts.outfit(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.liftType.displayName.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  color: AppColors.textPrimary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accentLive.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                      color: AppColors.accentLive.withValues(alpha: 0.3),
                                      width: 0.8),
                                ),
                                child: Text(
                                  'READY',
                                  style: GoogleFonts.outfit(
                                    color: AppColors.accentLive,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: GoogleFonts.outfit(
                              color: AppColors.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Checkpoints (styled as mini stats indicators)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: widget.checkpoints
                      .map((label) => _Checkpoint(
                          label: label.toUpperCase(), color: widget.themeColor))
                      .toList(),
                ),
              ),

              // Divider
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Divider(color: AppColors.surfaceBorder, height: 1),
              ),

              // Start button row
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: widget.themeColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                'START GAME SCAN',
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.surfaceBorder, width: 1),
                      ),
                      child: const Icon(
                        Icons.videocam_rounded,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Checkpoint chip (Scoreboard badge style) ──────────────────────────────────────────

class _Checkpoint extends StatelessWidget {
  final String label;
  final Color color;
  const _Checkpoint({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: AppColors.textMuted,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}


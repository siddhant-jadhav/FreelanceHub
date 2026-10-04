import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/services/firebase_service.dart';
import '../core/theme/app_colors.dart';

/// Splash Screen featuring centered brand identity:
/// Logo, FreelanceHub title with green dot, tagline, and animated shimmer bar.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _pulseController;
  late final AnimationController _shimmerController;

  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    // 1. Entrance animation (fade + smooth slide up)
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    // 2. Pulse / breathing glow animation behind the logo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    // 3. Shimmer progress indicator animation
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _entranceController.forward();

    _navigationTimer =
        Timer(const Duration(milliseconds: 2500), _navigateToNext);
  }

  void _navigateToNext() async {
    _navigationTimer?.cancel();
    if (!mounted) return;

    final user = FirebaseService.instance.currentUser;
    if (user != null) {
      final role = await FirebaseService.instance.getUserRole(user.uid);
      if (!mounted) return;
      if (role == 'freelancer') {
        Navigator.of(context).pushReplacementNamed('/freelancer-dashboard');
      } else {
        Navigator.of(context).pushReplacementNamed('/client-home');
      }
    } else {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _entranceController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navigateToNext,
        child: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo with ambient pulsing glow
                Stack(
                  alignment: Alignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        final double scale =
                            1.0 + (_pulseController.value * 0.12);
                        final double opacity =
                            0.5 + (_pulseController.value * 0.4);
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.20 * opacity),
                                  blurRadius: 36,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/logo_high.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Title: "FreelanceHub."
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'FreelanceHub',
                      style: GoogleFonts.inter(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.6,
                      ),
                    ),
                    Container(
                      width: 7.5,
                      height: 7.5,
                      margin: const EdgeInsets.only(left: 3.5),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // Tagline: "Work without limits"
                Text(
                  'Work without limits',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                    letterSpacing: -0.1,
                  ),
                ),

                const SizedBox(height: 32),

                // Shimmer Loading Bar
                SizedBox(
                  width: 144,
                  height: 4,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          color: AppColors.surfaceContainer,
                        ),
                        AnimatedBuilder(
                          animation: _shimmerController,
                          builder: (context, child) {
                            const double trackWidth = 144;
                            const double indicatorWidth = 48;
                            // Smooth sweeping loop with sinusoidal easing
                            final double progress = Curves.easeInOut
                                .transform(_shimmerController.value);
                            final double left = (progress *
                                    (trackWidth + indicatorWidth * 2)) -
                                indicatorWidth;

                            return Positioned(
                              left: left,
                              top: 0,
                              bottom: 0,
                              width: indicatorWidth,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}

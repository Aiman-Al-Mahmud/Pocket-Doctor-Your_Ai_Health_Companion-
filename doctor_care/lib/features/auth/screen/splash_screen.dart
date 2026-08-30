import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';
import '../../../core/services/supabase_service.dart';
import 'welcome_screen.dart';
import '../../dashboard/screen/dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _floatController;
  late AnimationController _scanController;
  late AnimationController _pulseController;
  
  final Color background = const Color(0xFF0A0C10);
  final Color primary = const Color(0xFF2563EB);
  final Color secondaryFixed = const Color(0xFF6FFBBE);
  
  @override
  void initState() {
    super.initState();
    
    // Float animation
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    // Scan line animation
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    
    // Pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Progress animation
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    
    _progressController.forward().then((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          final currentUser = SupabaseService.client.auth.currentUser;
          final Widget targetScreen = currentUser != null ? const DashboardScreen() : const WelcomeScreen();

          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 600),
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    _floatController.dispose();
    _scanController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: DotGridPainter(),
            ),
          ),
          
          Center(
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primary.withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: primary.withOpacity(0.15),
                    blurRadius: 160,
                    spreadRadius: 80,
                  ),
                ],
              ),
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: 1.0 + (_pulseController.value * 0.4),
                            child: Opacity(
                              opacity: 1.0 - _pulseController.value,
                              child: Container(
                                width: 260,
                                height: 260,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: primary.withOpacity(0.5), width: 2),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      
                      ClipOval(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.03),
                              border: Border.all(color: Colors.white.withOpacity(0.08)),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(32.0),
                                  child: Icon(Icons.medical_services_outlined, size: 80, color: primary),
                                ),
                                AnimatedBuilder(
                                  animation: _scanController,
                                  builder: (context, child) {
                                    return Positioned(
                                      top: -110 + (_scanController.value * 440),
                                      left: 0,
                                      right: 0,
                                      child: Container(
                                        height: 110,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              primary.withOpacity(0.3),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                RichText(
                  text: const TextSpan(
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 36,
                      letterSpacing: 4,
                      color: Colors.white,
                    ),
                    children: [
                      TextSpan(text: 'DOCTOR', style: TextStyle(fontWeight: FontWeight.w300)),
                      TextSpan(text: 'CARE', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 1,
                      width: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, primary.withOpacity(0.4)],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'NEXT-GEN AI HEALTHCARE',
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 3,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      height: 1,
                      width: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [primary.withOpacity(0.4), Colors.transparent],
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 48),
                
                SizedBox(
                  width: 240,
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return Container(
                            height: 4,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: _progressController.value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: primary,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primary,
                                      blurRadius: 10,
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline, size: 14, color: primary),
                          const SizedBox(width: 8),
                          Text(
                            'SECURING NEURAL GATEWAY',
                            style: TextStyle(
                              fontSize: 10,
                              letterSpacing: 2,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.fill;
      
    const double spacing = 32.0;
    const double radius = 1.0;
    
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/call_ringtone_service.dart';
import '../../../core/services/webrtc_service.dart';
import '../../../data/repositories/call_repository.dart';
import '../../appointments/screens/appointments_screen.dart';
import '../../call/screens/patient_call_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../reviews/screens/reviews_screen.dart';
import 'home_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final String userId;

  const MainNavigationShell({
    super.key,
    this.userId = 'demo-patient-id',
  });

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;
  final CallRepository _callRepository = CallRepository();
  StreamSubscription<CallSessionModel?>? _incomingCallSub;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _listenForIncomingCalls();
  }

  void _listenForIncomingCalls() {
    _incomingCallSub = _callRepository
        .streamIncomingCallForPatient(widget.userId)
        .listen((session) {
      if (session != null && session.status == 'calling' && !_isDialogShowing && mounted) {
        CallRingtoneService.startRingtone();
        _showIncomingCallDialog(session);
      } else if (session == null || session.status != 'calling') {
        CallRingtoneService.stopRingtone();
      }
    });
  }

  void _showIncomingCallDialog(CallSessionModel session) {
    setState(() => _isDialogShowing = true);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: const Color(0xFF0F172A),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.video_call_rounded, color: Color(0xFF0D9488), size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Incoming Call',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 8),
              Text(
                'Your attending physician is starting your scheduled telehealth video consultation.',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          actions: [
            OutlinedButton.icon(
              onPressed: () async {
                await CallRingtoneService.stopRingtone();
                await _callRepository.updateCallStatus(session.id, 'declined');
                if (mounted) {
                  setState(() => _isDialogShowing = false);
                  Navigator.of(context).pop();
                }
              },
              icon: const Icon(Icons.call_end, color: Colors.redAccent),
              label: const Text('Decline', style: TextStyle(color: Colors.redAccent)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.redAccent),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                await CallRingtoneService.stopRingtone();
                final hasPermissions = await WebRTCService.requestCallPermissions();
                if (!hasPermissions) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Camera and Microphone permissions are required for video calls.'),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                  }
                  return;
                }

                await _callRepository.updateCallStatus(session.id, 'active');
                if (mounted) {
                  setState(() => _isDialogShowing = false);
                  Navigator.of(context).pop(); // dismiss dialog
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PatientCallScreen(
                        sessionId: session.id,
                        appointmentId: session.appointmentId,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.videocam, color: Colors.white),
              label: const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0D9488),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        );
      },
    ).then((_) {
      if (mounted) {
        setState(() => _isDialogShowing = false);
      }
    });
  }

  @override
  void dispose() {
    _incomingCallSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeScreen(userId: widget.userId),
      PatientReviewsScreen(patientId: widget.userId),
      PatientAppointmentsScreen(userId: widget.userId),
      ProfileScreen(userId: widget.userId),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            backgroundColor: Colors.white,
            indicatorColor: const Color(0xFF4ECDC4).withValues(alpha: 0.2),
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D9488),
                  letterSpacing: 0.2,
                );
              }
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A5568),
                letterSpacing: 0.2,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(
                  color: Color(0xFF0D9488),
                  size: 24,
                );
              }
              return const IconThemeData(
                color: Color(0xFF4A5568),
                size: 24,
              );
            }),
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
            height: 68,
            elevation: 0,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.rate_review_outlined),
                selectedIcon: Icon(Icons.rate_review_rounded),
                label: 'Reviews',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Appointments',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

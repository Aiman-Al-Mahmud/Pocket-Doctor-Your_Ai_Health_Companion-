import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/doctor_auth_service.dart';
import '../../../data/repositories/doctor_appointment_repository.dart';
import '../../../data/repositories/call_repository.dart';
import '../../call/screens/telehealth_call_screen.dart';
import 'dashboard_screen.dart';
import 'profile_screen.dart';
import 'reviews_screen.dart';

class PatientAppointmentRequest {
  final String id;
  final String name;
  final String patientId;
  final String reason;
  final List<String> availableSlots;
  String? selectedSlot;
  bool isApproved;
  bool isDeclined;

  PatientAppointmentRequest({
    required this.id,
    required this.name,
    required this.patientId,
    required this.reason,
    required this.availableSlots,
    this.selectedSlot,
    this.isApproved = false,
    this.isDeclined = false,
  });
}

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  // Design Tokens matching Tailwind spec
  final Color primary = const Color(0xFF004AC6);
  final Color onPrimary = const Color(0xFFFFFFFF);
  final Color primaryContainer = const Color(0xFF2563EB);
  final Color onPrimaryContainer = const Color(0xFFEEEFFF);
  final Color primaryFixed = const Color(0xFFDBE1FF);
  final Color onPrimaryFixed = const Color(0xFF00174B);

  final Color secondary = const Color(0xFF006C49);
  final Color onSecondary = const Color(0xFFFFFFFF);
  final Color secondaryContainer = const Color(0xFF6CF8BB);
  final Color onSecondaryContainer = const Color(0xFF00714D);

  final Color tertiaryContainer = const Color(0xFF585BE6);
  final Color onTertiaryContainer = const Color(0xFFF1EEFF);

  final Color background = const Color(0xFFFAF8FF);
  final Color surface = const Color(0xFFFAF8FF);
  final Color surfaceContainerLowest = const Color(0xFFFFFFFF);
  final Color surfaceContainerLow = const Color(0xFFF3F3FE);
  final Color surfaceContainer = const Color(0xFFEDEDF9);
  final Color surfaceContainerHigh = const Color(0xFFE7E7F3);
  final Color surfaceContainerHighest = const Color(0xFFE1E2ED);

  final Color onSurface = const Color(0xFF191B23);
  final Color onSurfaceVariant = const Color(0xFF434655);
  final Color outline = const Color(0xFF737686);
  final Color outlineVariant = const Color(0xFFC3C6D7);
  final Color error = const Color(0xFFBA1A1A);
  final Color errorContainer = const Color(0xFFFFDAD6);
  final Color onErrorContainer = const Color(0xFF93000A);

  int _selectedIndex = 2; // Appointments is index 2

  Timer? _timer;
  int _timeRemaining = 252; // 4 minutes 12 seconds

  int _currentPage = 1;
  static const int _pageSize = 5;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        if (mounted) {
          setState(() {
            _timeRemaining--;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    if (_timeRemaining <= 0) return "Session Overdue";
    int minutes = _timeRemaining ~/ 60;
    int seconds = _timeRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _approveRequest(DoctorAppointmentModel req) async {
    final slot = req.selectedSlot ?? (req.availableSlots.isNotEmpty ? req.availableSlots.first : '09:00 AM - 09:30 AM');
    final success = await DoctorAppointmentRepository().updateAppointmentStatus(req.id, 'confirmed', timeSlot: slot);
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Appointment confirmed for ${req.patientName} at $slot!',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to approve appointment in database.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineRequest(DoctorAppointmentModel req) async {
    final success = await DoctorAppointmentRepository().updateAppointmentStatus(req.id, 'cancelled');
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.cancel_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Appointment request from ${req.patientName} declined.'),
              ],
            ),
            backgroundColor: error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update appointment status.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _startLiveCall(DoctorAppointmentModel session) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final callRepo = CallRepository();
    final callSession = await callRepo.initiateCall(
      appointmentId: session.id,
      doctorId: session.doctorId,
      patientId: session.patientId,
    );

    if (mounted) {
      Navigator.of(context).pop(); // dismiss loading dialog

      if (callSession != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TelehealthCallScreen(
              sessionId: callSession.id,
              appointmentId: session.id,
              patientName: session.patientName,
              patientId: session.patientId,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to initiate live telehealth call session.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildNoActiveSessionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceContainerLowest.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_available, size: 48, color: onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No Active Live Sessions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              'Approved appointments will appear here when ready.',
              style: TextStyle(fontSize: 13, color: onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentDoctorId = DoctorAuthService.currentDoctor?.id ?? SupabaseService.currentUser?.id;

    return Scaffold(
      backgroundColor: background,
      extendBody: true,
      appBar: _buildAppBar(),
      body: StreamBuilder<List<DoctorAppointmentModel>>(
        stream: DoctorAppointmentRepository().streamDoctorAppointments(currentDoctorId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allAppointments = snapshot.data ?? [];
          final pendingRequests = allAppointments.where((a) => a.status == 'pending').toList();
          final confirmedAppointments = allAppointments.where((a) => a.status == 'confirmed').toList();
          final completedCount = allAppointments.where((a) => a.status == 'completed').toList().length;
          final waitingCount = pendingRequests.length;
          final reservedCount = confirmedAppointments.length;

          // Determine active session
          DoctorAppointmentModel? activeSession;
          if (confirmedAppointments.isNotEmpty) {
            activeSession = confirmedAppointments.first;
          } else if (allAppointments.isNotEmpty) {
            activeSession = allAppointments.first;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title Section
                    _buildTitleSection(),
                    const SizedBox(height: 24),

                    // Active Session Focus & Stats
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 920) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 2,
                                child: activeSession != null
                                    ? _buildLiveSessionCardWithData(activeSession)
                                    : _buildNoActiveSessionCard(),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                flex: 1,
                                child: _buildStatsCardWithData(
                                  total: allAppointments.length,
                                  completed: completedCount,
                                  waiting: waitingCount,
                                  reserved: reservedCount,
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              activeSession != null
                                  ? _buildLiveSessionCardWithData(activeSession)
                                  : _buildNoActiveSessionCard(),
                              const SizedBox(height: 20),
                              _buildStatsCardWithData(
                                total: allAppointments.length,
                                completed: completedCount,
                                waiting: waitingCount,
                                reserved: reservedCount,
                              ),
                            ],
                          );
                        }
                      },
                    ),

                    const SizedBox(height: 32),

                    // Main Section: Pending Appointment Requests
                    _buildPendingRequestsSectionWithData(pendingRequests),

                    const SizedBox(height: 100), // Spacer for bottom navigation
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AppBar(
            backgroundColor: surface.withOpacity(0.85),
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Row(
              children: [
                const DoctorAvatarWidget(size: 40),
                const SizedBox(width: 12),
                Text(
                  'Pocket Doctor',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.notifications_none_outlined, color: primary, size: 24),
                onPressed: () {},
                tooltip: 'Notifications',
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 700;

        Widget title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LIVE PORTAL',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primary, letterSpacing: 1.5),
            ),
            const SizedBox(height: 2),
            Text(
              'Consultation Schedule',
              style: TextStyle(
                fontSize: isDesktop ? 30 : 26,
                fontWeight: FontWeight.w700,
                color: onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ],
        );

        Widget dateBadge = Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: surfaceContainer,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: outlineVariant.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.calendar_month, color: secondary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Wednesday, Oct 24, 2023',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: onSurfaceVariant),
              ),
            ],
          ),
        );

        if (isDesktop) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [title, dateBadge],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 14), dateBadge],
          );
        }
      },
    );
  }

  Widget _buildLiveSessionCardWithData(DoctorAppointmentModel activeSession) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceContainerLowest.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 12, offset: const Offset(0, 3)),
        ],
      ),
      child: Stack(
        children: [
          // Background Gradient Decoration
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: secondary.withOpacity(0.08),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              bool isDesktop = constraints.maxWidth > 540;

              Widget info = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Live Session Indicator
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(color: error, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'LIVE SESSION',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: error,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Patient Avatar & Info
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: surfaceContainerHigh,
                          border: Border.all(color: outlineVariant.withOpacity(0.3)),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          activeSession.patientName.isNotEmpty
                              ? activeSession.patientName.substring(0, 1).toUpperCase()
                              : 'P',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primary),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeSession.patientName,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface),
                          ),
                          Text(
                            activeSession.patientCode,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Consultation Tags
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBadge('Consultation', Icons.emergency, primary, primary.withOpacity(0.1)),
                      _buildBadge('Video Call', Icons.video_call, onSurfaceVariant, surfaceContainerHigh),
                    ],
                  ),
                ],
              );

              Widget action = Column(
                crossAxisAlignment: isDesktop ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    'Scheduled for',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: onSurfaceVariant),
                  ),
                  Text(
                    activeSession.selectedSlot ?? '10:00 AM - 10:30 AM',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer, color: error, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        '$_formattedTime Remaining',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: error),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _startLiveCall(activeSession),
                    icon: const Icon(Icons.video_chat, size: 20),
                    label: const Text('Join Now', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ],
              );

              if (isDesktop) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [info, action],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [info, const SizedBox(height: 20), action],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon, Color textColor, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: textColor),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
        ],
      ),
    );
  }

  Widget _buildStatsCardWithData({
    required int total,
    required int completed,
    required int waiting,
    required int reserved,
  }) {
    final remaining = total - completed > 0 ? total - completed : 0;
    final progress = total > 0 ? (completed / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TODAY\'S LOAD',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: outline, letterSpacing: 1),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Appointments', style: TextStyle(fontSize: 14, color: onSurfaceVariant)),
              Text('$total', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: surfaceContainer,
              valueColor: AlwaysStoppedAnimation<Color>(primary),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Text('$completed Completed | $remaining Remaining',
              style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
          const SizedBox(height: 16),
          Divider(color: outlineVariant.withOpacity(0.3)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: secondaryContainer.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text('WAITING', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: onSecondaryContainer)),
                      Text('$waiting', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSecondaryContainer)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: primaryFixed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Text('RESERVED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: onPrimaryFixed)),
                      Text('$reserved', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onPrimaryFixed)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPendingRequestsSectionWithData(List<DoctorAppointmentModel> pendingRequests) {
    final totalItems = pendingRequests.length;
    final totalPages = totalItems == 0 ? 1 : (totalItems / _pageSize).ceil();

    if (_currentPage > totalPages) _currentPage = totalPages;
    if (_currentPage < 1) _currentPage = 1;

    final startIndex = totalItems == 0 ? 0 : (_currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize > totalItems) ? totalItems : (startIndex + _pageSize);
    final pageItems = totalItems == 0 ? <DoctorAppointmentModel>[] : pendingRequests.sublist(startIndex, endIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pending Requests',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$totalItems New',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (pageItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: outlineVariant.withOpacity(0.3)),
            ),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.check_circle_outline, size: 48, color: secondary),
                const SizedBox(height: 12),
                Text(
                  'All Consultation Requests Handled!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  'All requested patient appointments have been scheduled.',
                  style: TextStyle(fontSize: 13, color: onSurfaceVariant),
                ),
              ],
            ),
          )
        else
          Column(
            children: pageItems.map((req) => _buildPendingRequestCardWithData(req)).toList(),
          ),

        // Interactive Pagination Footer for Appointments
        if (totalItems > 0)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: outlineVariant.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${startIndex + 1}-$endIndex of $totalItems requests',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurfaceVariant),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: _currentPage > 1
                          ? () => setState(() => _currentPage--)
                          : null,
                    ),
                    ...List.generate(totalPages, (i) {
                      final pNum = i + 1;
                      final isActive = pNum == _currentPage;
                      return InkWell(
                        onTap: () => setState(() => _currentPage = pNum),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 32,
                          height: 32,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isActive ? primaryContainer : Colors.transparent,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '$pNum',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isActive ? onPrimaryContainer : onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: _currentPage < totalPages
                          ? () => setState(() => _currentPage++)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildPendingRequestCardWithData(DoctorAppointmentModel req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 650;

          Widget patientInfo = Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  req.patientName.isNotEmpty ? req.patientName.substring(0, 1).toUpperCase() : 'P',
                  style: TextStyle(fontWeight: FontWeight.bold, color: primary, fontSize: 18),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    req.patientName,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface),
                  ),
                  Text(
                    '${req.patientCode} • ${req.reason}',
                    style: TextStyle(fontSize: 13, color: onSurfaceVariant),
                  ),
                ],
              ),
            ],
          );

          Widget slotAndActions = Row(
            mainAxisSize: isWide ? MainAxisSize.min : MainAxisSize.max,
            children: [
              // Time Slot Dropdown
              Expanded(
                flex: isWide ? 0 : 1,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 190),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  decoration: BoxDecoration(
                    color: surfaceContainer,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: outlineVariant.withOpacity(0.4)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: req.selectedSlot,
                      hint: Text(
                        'Assign Time Slot',
                        style: TextStyle(fontSize: 13, color: onSurfaceVariant),
                      ),
                      icon: Icon(Icons.keyboard_arrow_down, color: onSurfaceVariant),
                      items: req.availableSlots.map((slot) {
                        return DropdownMenuItem<String>(
                          value: slot,
                          child: Text(
                            slot,
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: onSurface),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          req.selectedSlot = val;
                        });
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Approve Button
              ElevatedButton(
                onPressed: () => _approveRequest(req),
                style: ElevatedButton.styleFrom(
                  backgroundColor: secondary,
                  foregroundColor: onSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 1,
                ),
                child: const Text('Approve', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 8),

              // Decline Button
              OutlinedButton(
                onPressed: () => _declineRequest(req),
                style: OutlinedButton.styleFrom(
                  foregroundColor: error,
                  side: BorderSide(color: error),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Decline', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ],
          );

          if (isWide) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: patientInfo),
                const SizedBox(width: 16),
                slotAndActions,
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                patientInfo,
                const SizedBox(height: 14),
                slotAndActions,
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildBottomNav() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: surface.withOpacity(0.85),
            border: Border(top: BorderSide(color: outlineVariant.withOpacity(0.3))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedIndex: _selectedIndex,
            indicatorColor: secondaryContainer,
            onDestinationSelected: (index) {
              if (index == _selectedIndex) return;
              setState(() {
                _selectedIndex = index;
              });
              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, anim1, anim2) => const DashboardScreen(),
                    transitionDuration: Duration.zero,
                  ),
                );
              } else if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, anim1, anim2) => const ReviewsScreen(),
                    transitionDuration: Duration.zero,
                  ),
                );
              } else if (index == 3) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, anim1, anim2) => const ProfileScreen(),
                    transitionDuration: Duration.zero,
                  ),
                );
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.rate_review_outlined),
                selectedIcon: Icon(Icons.rate_review),
                label: 'Reviews',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_today_outlined),
                selectedIcon: Icon(Icons.calendar_today),
                label: 'Appointments',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

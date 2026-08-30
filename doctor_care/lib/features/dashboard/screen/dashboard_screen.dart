import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../core/services/doctor_auth_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../data/repositories/doctor_review_repository.dart';
import '../../../data/repositories/doctor_appointment_repository.dart';
import '../../../core/models/review_request_model.dart';
import 'profile_screen.dart';
import 'appointments_screen.dart';
import 'reviews_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DoctorReviewRepository _reviewRepo = DoctorReviewRepository();
  final DoctorAppointmentRepository _appointmentRepo = DoctorAppointmentRepository();

  // Colors based on the tailwind config
  final Color primary = const Color(0xFF004AC6);
  final Color secondary = const Color(0xFF006C49);
  final Color tertiary = const Color(0xFF3E3FCC);
  final Color background = const Color(0xFFFAF8FF);
  final Color onSurface = const Color(0xFF191B23);
  final Color onSurfaceVariant = const Color(0xFF434655);
  final Color surface = const Color(0xFFFAF8FF);
  final Color surfaceContainerLow = const Color(0xFFF3F3FE);
  final Color outlineVariant = const Color(0xFFC3C6D7);
  final Color error = const Color(0xFFBA1A1A);
  
  final Color primaryFixed = const Color(0xFFDBE1FF);
  final Color secondaryFixed = const Color(0xFF6FFBBE);
  final Color tertiaryFixed = const Color(0xFFE1E0FF);
  final Color onSecondaryContainer = const Color(0xFF00714D);
  final Color onTertiaryFixedVariant = const Color(0xFF2F2EBE);
  final Color secondaryContainer = const Color(0xFF6CF8BB);

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final currentDoc = DoctorAuthService.currentDoctor;
    final doctorId = currentDoc?.id ?? SupabaseService.currentUser?.id;
    final doctorName = currentDoc?.fullName.isNotEmpty == true ? currentDoc!.fullName : 'Dr. Mahmud';

    return Scaffold(
      backgroundColor: background,
      extendBody: true, // For bottom nav bar blur effect
      appBar: _buildAppBar(),
      body: StreamBuilder<List<ReviewRequestModel>>(
        stream: _reviewRepo.streamPendingReviewRequests(
          doctorId: currentDoc?.id,
          specialization: currentDoc?.specialization,
        ),
        builder: (context, reviewSnapshot) {
          final pendingRequests = reviewSnapshot.data ?? [];
          final pendingCount = pendingRequests.length.toString();

          return StreamBuilder<List<DoctorAppointmentModel>>(
            stream: _appointmentRepo.streamDoctorAppointments(doctorId),
            builder: (context, apptSnapshot) {
              final appointments = apptSnapshot.data ?? [];
              
              // Count appointments for today or currently pending/confirmed active slots
              final now = DateTime.now();
              final todaysAppts = appointments.where((a) {
                final isSameDay = a.appointmentDate.year == now.year &&
                    a.appointmentDate.month == now.month &&
                    a.appointmentDate.day == now.day;
                return isSameDay || a.status == 'pending' || a.status == 'confirmed';
              }).toList();

              final todaysCount = todaysAppts.length.toString();
              final completedCount = appointments.where((a) => a.status == 'completed').length.toString();

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting Section
                    const Text(
                      'PHYSICIAN PORTAL',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: Color(0xFF434655),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome, $doctorName',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: onSurface,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Stats Grid
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                          return Row(
                            children: [
                              Expanded(child: _buildStatCard('Pending AI Reviews', pendingCount, Icons.precision_manufacturing, primary)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildStatCard('Today\'s Appointments', todaysCount, Icons.event, secondary)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildStatCard('Completed Consultations', completedCount, Icons.task_alt, tertiary)),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildStatCard('Pending AI Reviews', pendingCount, Icons.precision_manufacturing, primary),
                              const SizedBox(height: 16),
                              _buildStatCard('Today\'s Appointments', todaysCount, Icons.event, secondary),
                              const SizedBox(height: 16),
                              _buildStatCard('Completed Consultations', completedCount, Icons.task_alt, tertiary),
                            ],
                          );
                        }
                      }
                    ),
                
                const SizedBox(height: 32),
                
                // Quick Actions
                Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildActionCard(
                      'Review AI Chats', 
                      Icons.chat_bubble_outline, 
                      primary, 
                      badgeCount: pendingCount != '0' ? pendingCount : null,
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, anim1, anim2) => const ReviewsScreen(),
                            transitionDuration: Duration.zero,
                          ),
                        );
                      },
                    ),
                    _buildActionCard(
                      'Today\'s Patients', 
                      Icons.groups_outlined, 
                      secondary,
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, anim1, anim2) => const AppointmentsScreen(),
                            transitionDuration: Duration.zero,
                          ),
                        );
                      },
                    ),
                    _buildActionCard(
                      'Edit Profile', 
                      Icons.badge_outlined, 
                      primary,
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, anim1, anim2) => const ProfileScreen(),
                            transitionDuration: Duration.zero,
                          ),
                        );
                      },
                    ),
                    _buildActionCard(
                      'Manage Schedule', 
                      Icons.calendar_month_outlined, 
                      tertiary,
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, anim1, anim2) => const AppointmentsScreen(),
                            transitionDuration: Duration.zero,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Recent Requests Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Recent Patient Requests',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: onSurface),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, anim1, anim2) => const ReviewsScreen(),
                            transitionDuration: Duration.zero,
                          ),
                        );
                      },
                      child: Text(
                        'View All',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                if (pendingRequests.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: outlineVariant.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline, size: 44, color: secondary),
                        const SizedBox(height: 12),
                        Text(
                          'All Caught Up!',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No pending patient review requests right now. New AI consultation reviews will appear here in real-time.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 13, color: onSurfaceVariant, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: pendingRequests.length > 5 ? 5 : pendingRequests.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final req = pendingRequests[idx];
                      final isHigh = req.medicalDivision.toLowerCase().contains('cardio') ||
                          req.medicalDivision.toLowerCase().contains('neuro') ||
                          req.userQuery.toLowerCase().contains('urgent');
                      
                      final displayInitials = req.medicalDivision.isNotEmpty && req.medicalDivision.length >= 2
                          ? req.medicalDivision.substring(0, 2).toUpperCase()
                          : 'PT';
                      
                      final displayName = 'Patient #${req.patientId.length >= 6 ? req.patientId.substring(0, 6) : req.patientId}';
                      final displayDetails = '${req.medicalDivision} • ${req.userQuery}';

                      return _buildPatientRequest(
                        initials: displayInitials,
                        name: displayName,
                        details: displayDetails,
                        priority: isHigh ? 'High Priority' : 'Medium Priority',
                        color: isHigh ? primaryFixed : secondaryFixed,
                        textColor: isHigh ? primary : onSecondaryContainer,
                        isHighPriority: isHigh,
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            PageRouteBuilder(
                              pageBuilder: (context, anim1, anim2) => const ReviewsScreen(),
                              transitionDuration: Duration.zero,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
                
                const SizedBox(height: 80), // Spacer for bottom nav
              ],
            ),
          );
        },
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
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            backgroundColor: surface.withOpacity(0.8),
            elevation: 0,
            title: Row(
              children: [
                const DoctorAvatarWidget(size: 40),
                const SizedBox(width: 12),
                Text(
                  'Pocket Doctor',
                  style: TextStyle(
                    color: primary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_none, color: primary),
                    onPressed: () {},
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: error,
                        shape: BoxShape.circle,
                        border: Border.all(color: surface, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineVariant.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        value,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: onSurface,
                        ),
                      ),
                      Icon(icon, size: 36, color: color.withOpacity(0.4)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, {String? badgeCount, VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap ?? () {},
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: outlineVariant.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, size: 32, color: color),
                  if (badgeCount != null)
                    Positioned(
                      top: -6,
                      right: -10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badgeCount,
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientRequest({
    required String initials,
    required String name,
    required String details,
    required String priority,
    required Color color,
    required Color textColor,
    required bool isHighPriority,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: outlineVariant.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurface),
                  ),
                  Text(
                    details,
                    style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isHighPriority ? error.withOpacity(0.1) : secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isHighPriority ? error.withOpacity(0.2) : secondary.withOpacity(0.2)),
              ),
              child: Text(
                priority,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isHighPriority ? error : secondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Icon(Icons.chevron_right, color: outlineVariant),
          ],
        ),
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
              if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, anim1, anim2) => const ReviewsScreen(),
                    transitionDuration: Duration.zero,
                  ),
                );
              } else if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, anim1, anim2) => const AppointmentsScreen(),
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

import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/appointment.dart';
import '../../../data/database/database_helper.dart';
import 'department_doctors_screen.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  final String userId;

  const PatientAppointmentsScreen({
    super.key,
    this.userId = 'demo-patient-id',
  });

  @override
  State<PatientAppointmentsScreen> createState() => _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  List<Appointment> _myAppointments = [];
  bool _isLoadingAppointments = true;

  // The 15 Medical Divisions matching Ui/Appoinment 1st preview.html
  final List<Map<String, dynamic>> _divisions = [
    {
      'name': 'Cardiology',
      'icon': Icons.monitor_heart_rounded,
      'color': const Color(0xFF004AC6),
      'description': 'Heart & cardiovascular care',
    },
    {
      'name': 'Neurology',
      'icon': Icons.psychology_rounded,
      'color': const Color(0xFF3E3FCC),
      'description': 'Brain & nervous system',
    },
    {
      'name': 'Pediatrics',
      'icon': Icons.child_care_rounded,
      'color': const Color(0xFF006C49),
      'description': 'Child & infant healthcare',
    },
    {
      'name': 'Orthopedics',
      'icon': Icons.accessibility_new_rounded,
      'color': const Color(0xFF2563EB),
      'description': 'Bones, joints & mobility',
    },
    {
      'name': 'Dermatology',
      'icon': Icons.face_retouching_natural_rounded,
      'color': const Color(0xFFD97706),
      'description': 'Skin, hair & nail care',
    },
    {
      'name': 'Gastroenterology',
      'icon': Icons.science_rounded,
      'color': const Color(0xFF059669),
      'description': 'Digestive system disorders',
    },
    {
      'name': 'Oncology',
      'icon': Icons.healing_rounded,
      'color': const Color(0xFFDC2626),
      'description': 'Cancer treatment & care',
    },
    {
      'name': 'Radiology',
      'icon': Icons.document_scanner_rounded,
      'color': const Color(0xFF4F46E5),
      'description': 'Diagnostic medical imaging',
    },
    {
      'name': 'Psychiatry',
      'icon': Icons.psychology_alt_rounded,
      'color': const Color(0xFF7C3AED),
      'description': 'Mental health & wellness',
    },
    {
      'name': 'Urology',
      'icon': Icons.water_drop_rounded,
      'color': const Color(0xFF0284C7),
      'description': 'Urinary & renal care',
    },
    {
      'name': 'Ophthalmology',
      'icon': Icons.visibility_rounded,
      'color': const Color(0xFF0D9488),
      'description': 'Eye & vision specialists',
    },
    {
      'name': 'Endocrinology',
      'icon': Icons.bloodtype_rounded,
      'color': const Color(0xFFE11D48),
      'description': 'Hormones & diabetes',
    },
    {
      'name': 'Pulmonology',
      'icon': Icons.air_rounded,
      'color': const Color(0xFF0891B2),
      'description': 'Lungs & respiratory health',
    },
    {
      'name': 'Nephrology',
      'icon': Icons.water_rounded,
      'color': const Color(0xFF2563EB),
      'description': 'Kidney health & dialysis',
    },
    {
      'name': 'General Medicine',
      'icon': Icons.health_and_safety_rounded,
      'color': const Color(0xFF006C49),
      'description': 'Primary & family care',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _loadMyAppointments();
      }
    });
    _loadMyAppointments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMyAppointments() async {
    setState(() => _isLoadingAppointments = true);
    try {
      final list = await DatabaseHelper.instance.getAppointmentsByPatientId(widget.userId);
      if (mounted) {
        setState(() {
          _myAppointments = list;
          _isLoadingAppointments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAppointments = false);
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredDivisions() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _divisions;
    return _divisions.where((d) {
      final name = d['name'].toString().toLowerCase();
      final desc = d['description'].toString().toLowerCase();
      return name.contains(query) || desc.contains(query);
    }).toList();
  }

  void _navigateToDepartment(String specialty, {String? searchQuery}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => DepartmentDoctorsScreen(
          specialty: specialty,
          userId: widget.userId,
          initialSearchQuery: searchQuery,
        ),
      ),
    ).then((_) {
      _loadMyAppointments();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.medical_services_rounded, color: Color(0xFF004AC6)),
            SizedBox(width: 8),
            Text(
              'Pocket Doctor',
              style: TextStyle(
                color: Color(0xFF004AC6),
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF004AC6),
          labelColor: const Color(0xFF004AC6),
          unselectedLabelColor: const Color(0xFF434655),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(
              icon: Icon(Icons.grid_view_rounded, size: 18),
              text: 'Find Doctors',
            ),
            Tab(
              icon: Icon(Icons.event_available_rounded, size: 18),
              text: 'My Appointments',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Medical Divisions Bento Grid
          _buildDivisionsTab(),

          // Tab 2: My Booked Appointments
          _buildAppointmentsTab(),
        ],
      ),
    );
  }

  Widget _buildDivisionsTab() {
    final filtered = _getFilteredDivisions();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section matching HTML
          const Text(
            'Select Medical Division',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF191B23),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Choose a specialty to find the right healthcare professional for your needs.',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF434655),
            ),
          ),
          const SizedBox(height: 16),

          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F3FE),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: const Color(0xFFC3C6D7)),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              onSubmitted: (query) {
                if (query.trim().isNotEmpty) {
                  _navigateToDepartment('All Specialties', searchQuery: query.trim());
                }
              },
              decoration: InputDecoration(
                hintText: 'Search specialties, conditions, or doctors...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF737686), size: 22),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      ),
                    if (_searchController.text.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFF004AC6), size: 20),
                        onPressed: () {
                          _navigateToDepartment('All Specialties', searchQuery: _searchController.text.trim());
                        },
                      ),
                  ],
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _navigateToDepartment('All Specialties', searchQuery: _searchController.text.trim()),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF004AC6).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF004AC6).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_search_rounded, color: Color(0xFF004AC6), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Search registered doctors matching "${_searchController.text.trim()}"',
                        style: const TextStyle(
                          color: Color(0xFF004AC6),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Color(0xFF004AC6)),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),

          // View All Doctors Banner
          GestureDetector(
            onTap: () => _navigateToDepartment('All Specialties'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF004AC6), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF004AC6).withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.people_alt_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Browse All Available Doctors',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Verified specialists ready for consultation',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Divisions Bento Grid
          Text(
            'Medical Specialties (${filtered.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF191B23),
            ),
          ),
          const SizedBox(height: 12),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.25,
            ),
            itemBuilder: (context, index) {
              final division = filtered[index];
              return _buildDivisionCard(division);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDivisionCard(Map<String, dynamic> division) {
    final name = division['name'] as String;
    final icon = division['icon'] as IconData;
    final color = division['color'] as Color;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToDepartment(name),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFC3C6D7).withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.1),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 10),
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF191B23),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    if (_isLoadingAppointments) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_myAppointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFF3F3FE),
                ),
                child: const Icon(Icons.event_busy_rounded, size: 48, color: Color(0xFF004AC6)),
              ),
              const SizedBox(height: 16),
              const Text(
                'No Appointments Scheduled',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF191B23)),
              ),
              const SizedBox(height: 6),
              Text(
                'You have not booked any consultations yet. Explore medical divisions to schedule a session.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004AC6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => _tabController.animateTo(0),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Book an Appointment'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMyAppointments,
      color: const Color(0xFF004AC6),
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _myAppointments.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final apt = _myAppointments[index];
          return _buildAppointmentCard(apt);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Appointment appointment) {
    final isConfirmed = appointment.status == 'confirmed';
    final isCancelled = appointment.status == 'cancelled';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E2ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: const Color(0xFFF3F3FE),
                    backgroundImage: appointment.doctorAvatarUrl != null
                        ? NetworkImage(appointment.doctorAvatarUrl!)
                        : null,
                    child: appointment.doctorAvatarUrl == null
                        ? const Icon(Icons.person, color: Color(0xFF004AC6))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctorName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        appointment.doctorSpecialty,
                        style: const TextStyle(color: Color(0xFF004AC6), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isConfirmed
                      ? const Color(0xFF6CF8BB).withValues(alpha: 0.3)
                      : isCancelled
                          ? Colors.red.shade50
                          : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appointment.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isConfirmed
                        ? const Color(0xFF005236)
                        : isCancelled
                            ? Colors.red.shade700
                            : Colors.amber.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFFE1E2ED)),
          const SizedBox(height: 12),

          // Date & Time Row
          Row(
            children: [
              const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF737686)),
              const SizedBox(width: 6),
              Text(
                '${appointment.appointmentDate.day}/${appointment.appointmentDate.month}/${appointment.appointmentDate.year}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF191B23)),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF737686)),
              const SizedBox(width: 6),
              Text(
                '${appointment.startTime} - ${appointment.endTime}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF191B23)),
              ),
            ],
          ),

          if (appointment.notes != null && appointment.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Reason: ${appointment.notes}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
            ),
          ],

          if (!isCancelled) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(50, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _confirmCancelAppointment(appointment.id),
                icon: const Icon(Icons.cancel_outlined, size: 14),
                label: const Text('Cancel Consultation', style: TextStyle(fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _confirmCancelAppointment(String appointmentId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Appointment?'),
        content: const Text('Are you sure you want to cancel this scheduled consultation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await DatabaseHelper.instance.cancelAppointment(appointmentId);
              if (!mounted) return;
              _loadMyAppointments();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Appointment cancelled.')),
              );
            },
            child: const Text('Cancel Appointment', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

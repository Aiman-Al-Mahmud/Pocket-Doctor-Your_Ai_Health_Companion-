import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/doctor.dart';
import '../../../data/models/chat.dart';
import '../../../data/database/database_helper.dart';
import '../../chat/screens/chat_screen.dart';

class DepartmentDoctorsScreen extends StatefulWidget {
  final String specialty;
  final String userId;
  final String? initialSearchQuery;

  const DepartmentDoctorsScreen({
    super.key,
    required this.specialty,
    this.userId = 'demo-patient-id',
    this.initialSearchQuery,
  });

  @override
  State<DepartmentDoctorsScreen> createState() => _DepartmentDoctorsScreenState();
}

class _DepartmentDoctorsScreenState extends State<DepartmentDoctorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Doctor> _doctors = [];
  bool _isLoading = true;
  String _selectedSubFilter = 'All';
  bool _availableTodayOnly = false;
  final Set<String> _favoriteDoctorIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
    }
    _loadDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() => _isLoading = true);
    try {
      final docs = await DatabaseHelper.instance.getDoctors(
        specialty: widget.specialty == 'All Specialties' ? null : widget.specialty,
        searchQuery: _searchController.text.trim(),
        availableOnly: _availableTodayOnly,
      );

      if (mounted) {
        setState(() {
          _doctors = docs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<String> _getSubFilters() {
    final subFilters = <String>{'All'};
    for (final doc in _doctors) {
      if (doc.subSpecialty != null && doc.subSpecialty!.isNotEmpty) {
        subFilters.add(doc.subSpecialty!);
      }
    }
    return subFilters.take(5).toList();
  }

  List<Doctor> _getFilteredDoctors() {
    var list = _doctors;
    if (_selectedSubFilter != 'All') {
      list = list.where((d) => d.subSpecialty == _selectedSubFilter).toList();
    }
    if (_availableTodayOnly) {
      list = list.where((d) => (d.availableSlot ?? '').toLowerCase().contains('today')).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filteredDoctors = _getFilteredDoctors();
    final subFilters = _getSubFilters();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimaryLight, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.specialty == 'All Specialties' ? 'Available Specialists' : '${widget.specialty} Department',
          style: const TextStyle(
            color: Color(0xFF004AC6),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.15),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 22),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F3FE),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: const Color(0xFFC3C6D7)),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _loadDoctors(),
                decoration: InputDecoration(
                  hintText: 'Search by name, sub-specialty, or clinic...',
                  hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF434655), size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _loadDoctors();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),

          // Filter Chips Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Main All Filter
                  _buildFilterChip(
                    label: widget.specialty == 'All Specialties' ? 'All Doctors' : 'All ${widget.specialty}',
                    isSelected: _selectedSubFilter == 'All' && !_availableTodayOnly,
                    onTap: () {
                      setState(() {
                        _selectedSubFilter = 'All';
                        _availableTodayOnly = false;
                      });
                    },
                  ),
                  const SizedBox(width: 8),

                  // Sub-specialties
                  ...subFilters.where((s) => s != 'All').map((sub) {
                    final isSelected = _selectedSubFilter == sub;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildFilterChip(
                        label: sub,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedSubFilter = isSelected ? 'All' : sub;
                          });
                        },
                      ),
                    );
                  }),

                  // Available Today Filter
                  _buildFilterChip(
                    label: 'Available Today',
                    icon: Icons.event_available_rounded,
                    isSelected: _availableTodayOnly,
                    onTap: () {
                      setState(() {
                        _availableTodayOnly = !_availableTodayOnly;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // Doctor List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : filteredDoctors.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadDoctors,
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredDoctors.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 14),
                          itemBuilder: (context, index) {
                            return _buildDoctorCard(filteredDoctors[index]);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF004AC6) : const Color(0xFFEDEDF9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF004AC6) : const Color(0xFFC3C6D7),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: const Color(0xFF004AC6).withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : const Color(0xFF434655),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF434655),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Doctor doctor) {
    final isFavorite = _favoriteDoctorIds.contains(doctor.id);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE1E2ED)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Photo / Avatar
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFF3F3FE),
                        image: doctor.avatarUrl != null
                            ? DecorationImage(
                                image: NetworkImage(doctor.avatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: doctor.avatarUrl == null
                          ? const Center(
                              child: Icon(Icons.person_rounded, size: 40, color: Color(0xFF004AC6)),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: doctor.isAvailable ? const Color(0xFF10B981) : Colors.grey,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Doctor Information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              doctor.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF191B23),
                              ),
                            ),
                          ),
                          // Favorite / Rating Row
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isFavorite) {
                                      _favoriteDoctorIds.remove(doctor.id);
                                    } else {
                                      _favoriteDoctorIds.add(doctor.id);
                                    }
                                  });
                                },
                                child: Icon(
                                  isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  size: 18,
                                  color: isFavorite ? Colors.red : const Color(0xFF737686),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6CF8BB).withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFF6CF8BB)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                                    const SizedBox(width: 3),
                                    Text(
                                      doctor.rating.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF005236),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        doctor.subSpecialty ?? doctor.specialization,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF004AC6),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Experience
                      Row(
                        children: [
                          const Icon(Icons.work_outline_rounded, size: 14, color: Color(0xFF737686)),
                          const SizedBox(width: 5),
                          Text(
                            '${doctor.yearsOfExperience} years experience',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF434655)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Hospital Affiliation
                      Row(
                        children: [
                          const Icon(Icons.local_hospital_outlined, size: 14, color: Color(0xFF737686)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              doctor.hospitalAffiliation,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF434655)),
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

          // Divider
          const Divider(height: 1, color: Color(0xFFE1E2ED)),

          // Bottom Action Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                // Available slot indicator
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 15, color: Color(0xFF10B981)),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          doctor.availableSlot ?? 'Today, 4:00 PM',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Chat consultation button
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3FE),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF004AC6).withValues(alpha: 0.3)),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.chat_outlined, size: 18, color: Color(0xFF004AC6)),
                    tooltip: 'Consult Doctor',
                    onPressed: () => _openConsultationChat(doctor),
                  ),
                ),
                const SizedBox(width: 8),

                // Book Appointment Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF004AC6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    minimumSize: const Size(0, 38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _showBookingBottomSheet(doctor),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month_rounded, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Book Slot',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
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

  Widget _buildEmptyState() {
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
              child: const Icon(Icons.medical_information_outlined, size: 48, color: Color(0xFF004AC6)),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Physicians Found',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF191B23)),
            ),
            const SizedBox(height: 6),
            Text(
              'Try changing your filters or searching with a different specialty keyword.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _selectedSubFilter = 'All';
                  _availableTodayOnly = false;
                });
                _loadDoctors();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF004AC6)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('Reset Filters', style: TextStyle(color: Color(0xFF004AC6))),
            ),
          ],
        ),
      ),
    );
  }

  void _openConsultationChat(Doctor doctor) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final chat = Chat(
        userId: widget.userId,
        specialty: doctor.specialization,
        title: 'Consultation with ${doctor.name}',
        createdAt: DateTime.now(),
      );
      final chatId = await DatabaseHelper.instance.insertChat(chat);
      final newChat = chat.copyWith(id: chatId);

      if (!mounted) return;
      navigator.push(
        MaterialPageRoute(
          builder: (context) => ChatScreen(chat: newChat),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Could not open chat: $e')),
      );
    }
  }

  void _showBookingBottomSheet(Doctor doctor) {
    DateTime selectedDate = DateTime.now();
    String selectedSlot = '04:00 PM';
    final notesController = TextEditingController();
    bool isBooking = false;

    final List<String> availableSlots = [
      '09:00 AM',
      '10:30 AM',
      '11:45 AM',
      '02:00 PM',
      '03:30 PM',
      '04:00 PM',
      '05:15 PM',
      '06:30 PM',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (sheetContext, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Doctor Header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFF3F3FE),
                          backgroundImage: doctor.avatarUrl != null ? NetworkImage(doctor.avatarUrl!) : null,
                          child: doctor.avatarUrl == null ? const Icon(Icons.person, color: Color(0xFF004AC6)) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doctor.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                '${doctor.subSpecialty ?? doctor.specialization} • ${doctor.hospitalAffiliation}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 12),

                    // Select Date
                    const Text(
                      'Select Consultation Date',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF191B23)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildDateOption(
                          label: 'Today',
                          subLabel: '${DateTime.now().day}/${DateTime.now().month}',
                          isSelected: selectedDate.day == DateTime.now().day,
                          onTap: () => setModalState(() => selectedDate = DateTime.now()),
                        ),
                        const SizedBox(width: 10),
                        _buildDateOption(
                          label: 'Tomorrow',
                          subLabel: '${DateTime.now().add(const Duration(days: 1)).day}/${DateTime.now().month}',
                          isSelected: selectedDate.day == DateTime.now().add(const Duration(days: 1)).day,
                          onTap: () => setModalState(() => selectedDate = DateTime.now().add(const Duration(days: 1))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: sheetContext,
                                initialDate: selectedDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 30)),
                              );
                              if (picked != null) {
                                setModalState(() => selectedDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF3F3FE),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFC3C6D7)),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF004AC6)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Select Time Slot
                    const Text(
                      'Available Time Slots',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF191B23)),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: availableSlots.map((slot) {
                        final isSlotSelected = selectedSlot == slot;
                        return GestureDetector(
                          onTap: () => setModalState(() => selectedSlot = slot),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSlotSelected ? const Color(0xFF004AC6) : const Color(0xFFF3F3FE),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSlotSelected ? const Color(0xFF004AC6) : const Color(0xFFC3C6D7),
                              ),
                            ),
                            child: Text(
                              slot,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSlotSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSlotSelected ? Colors.white : const Color(0xFF191B23),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Notes / Reason for Visit
                    const Text(
                      'Reason for Visit / Symptoms (Optional)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF191B23)),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Describe your symptoms or reason for scheduling...',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFFF3F3FE),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFC3C6D7)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFC3C6D7)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Confirm Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF004AC6),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: isBooking
                            ? null
                            : () async {
                                setModalState(() => isBooking = true);
                                try {
                                  await DatabaseHelper.instance.bookAppointment(
                                    patientId: widget.userId,
                                    doctorId: doctor.id,
                                    doctorName: doctor.name,
                                    doctorSpecialty: doctor.subSpecialty ?? doctor.specialization,
                                    doctorHospital: doctor.hospitalAffiliation,
                                    doctorAvatarUrl: doctor.avatarUrl,
                                    appointmentDate: selectedDate,
                                    startTime: selectedSlot,
                                    endTime: _calculateEndTime(selectedSlot),
                                    notes: notesController.text.trim(),
                                  );

                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext);
                                    _showSuccessDialog(doctor.name, selectedDate, selectedSlot);
                                  }
                                } catch (e) {
                                  setModalState(() => isBooking = false);
                                  if (sheetContext.mounted) {
                                    ScaffoldMessenger.of(sheetContext).showSnackBar(
                                      SnackBar(content: Text('Booking error: $e'), backgroundColor: AppColors.error),
                                    );
                                  }
                                }
                              },
                        child: isBooking
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text(
                                'Confirm Appointment',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDateOption({
    required String label,
    required String subLabel,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF004AC6) : const Color(0xFFF3F3FE),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF004AC6) : const Color(0xFFC3C6D7),
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF191B23),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _calculateEndTime(String startTime) {
    try {
      final parts = startTime.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]) + 30;
      String period = parts[1];
      if (minute >= 60) {
        minute -= 60;
        hour += 1;
        if (hour == 12 && period == 'AM') {
          period = 'PM';
        } else if (hour > 12) {
          hour -= 12;
        }
      }
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
    } catch (_) {
      return '30 mins later';
    }
  }

  void _showSuccessDialog(String doctorName, DateTime date, String slot) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Appointment Confirmed!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF191B23)),
            ),
            const SizedBox(height: 8),
            Text(
              'Your consultation with $doctorName is scheduled for ${date.day}/${date.month}/${date.year} at $slot.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF004AC6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Done', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../core/models/review_request_model.dart';
import '../../../core/services/doctor_auth_service.dart';
import '../../../data/repositories/doctor_review_repository.dart';
import 'review_detail_screen.dart';
import 'dashboard_screen.dart';
import 'appointments_screen.dart';
import 'profile_screen.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  // Colors
  final Color primary = const Color(0xFF004AC6);
  final Color secondary = const Color(0xFF006C49);
  final Color background = const Color(0xFFFAF8FF);
  final Color onSurface = const Color(0xFF191B23);
  final Color onSurfaceVariant = const Color(0xFF434655);
  final Color surface = const Color(0xFFFAF8FF);
  final Color surfaceContainerLowest = const Color(0xFFFFFFFF);
  final Color surfaceContainerLow = const Color(0xFFF3F3FE);
  final Color surfaceContainerHigh = const Color(0xFFE7E7F3);
  final Color surfaceContainer = const Color(0xFFEDEDF9);
  final Color surfaceVariant = const Color(0xFFE1E2ED);
  final Color outlineVariant = const Color(0xFFC3C6D7);
  final Color outline = const Color(0xFF737686);
  final Color error = const Color(0xFFBA1A1A);
  
  final Color errorContainer = const Color(0xFFFFDAD6);
  final Color onErrorContainer = const Color(0xFF93000A);
  final Color primaryContainer = const Color(0xFF2563EB);
  final Color onPrimaryContainer = const Color(0xFFEEEFFF);
  final Color secondaryContainer = const Color(0xFF6CF8BB);
  final Color onSecondaryContainer = const Color(0xFF00714D);
  final Color secondaryFixedDim = const Color(0xFF4EDEA3);
  
  final Color tertiaryContainer = const Color(0xFF585BE6);
  final Color onTertiaryContainer = const Color(0xFFF1EEFF);
  final Color onSecondaryFixed = const Color(0xFF002113);
  final Color primaryFixed = const Color(0xFFDBE1FF);
  final Color onPrimaryFixed = const Color(0xFF00174B);
  final Color tertiaryFixedDim = const Color(0xFFC0C1FF);
  final Color onTertiaryFixed = const Color(0xFF07006C);

  int _selectedIndex = 1; // Reviews is index 1
  int _currentPage = 1;
  static const int _pageSize = 5;
  String _searchQuery = '';

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: AppBar(
            backgroundColor: surface.withValues(alpha: 0.85),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      extendBody: true,
      appBar: _buildAppBar(),
      body: StreamBuilder<List<ReviewRequestModel>>(
        stream: DoctorReviewRepository().streamPendingReviewRequests(
          doctorId: DoctorAuthService.currentDoctor?.id,
          specialization: DoctorAuthService.currentDoctor?.specialization,
        ),
        builder: (context, snapshot) {
          final requests = snapshot.data ?? [];
          final filtered = requests.where((req) {
            if (_searchQuery.trim().isEmpty) return true;
            final q = _searchQuery.toLowerCase();
            return req.patientName.toLowerCase().contains(q) ||
                req.patientId.toLowerCase().contains(q) ||
                req.complaintTag.toLowerCase().contains(q) ||
                req.userQuery.toLowerCase().contains(q);
          }).toList();

          final highUrgencyCount = requests.where((r) =>
              r.priority.toLowerCase().contains('high') ||
              r.priority.toLowerCase().contains('urgent')).length;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Filters
                _buildHeaderAndFilters(requestsCount: requests.length),
                const SizedBox(height: 32),

                // Dashboard Stats
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 768) {
                      return Row(
                        children: [
                          Expanded(child: _buildStatCard('High Urgency', '${highUrgencyCount.toString().padLeft(2, '0')}', Icons.warning_amber_rounded, errorContainer, onErrorContainer)),
                          const SizedBox(width: 24),
                          Expanded(child: _buildStatCard('Pending Reviews', '${requests.length.toString().padLeft(2, '0')}', Icons.pending_actions, primaryContainer, onPrimaryContainer, borderLeftColor: primary)),
                          const SizedBox(width: 24),
                          Expanded(child: _buildStatCard('Validated Total', '0', Icons.check_circle_outline, secondaryContainer, onSecondaryContainer)),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildStatCard('High Urgency', '${highUrgencyCount.toString().padLeft(2, '0')}', Icons.warning_amber_rounded, errorContainer, onErrorContainer),
                          const SizedBox(height: 16),
                          _buildStatCard('Pending Reviews', '${requests.length.toString().padLeft(2, '0')}', Icons.pending_actions, primaryContainer, onPrimaryContainer, borderLeftColor: primary),
                          const SizedBox(height: 16),
                          _buildStatCard('Validated Total', '0', Icons.check_circle_outline, secondaryContainer, onSecondaryContainer),
                        ],
                      );
                    }
                  }
                ),

                const SizedBox(height: 40),

                // Main Queue Table/List connected to Supabase Realtime with Dynamic Pagination
                if (snapshot.connectionState == ConnectionState.waiting)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
                else
                  _buildPaginatedQueueTable(filtered),

                const SizedBox(height: 100), // Spacer for FAB and Bottom Nav
              ],
            ),
          );
        },
      ),
      floatingActionButton: _buildFAB(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildPaginatedQueueTable(List<ReviewRequestModel> filteredRequests) {
    final totalItems = filteredRequests.length;
    final totalPages = totalItems == 0 ? 1 : (totalItems / _pageSize).ceil();
    
    if (_currentPage > totalPages) _currentPage = totalPages;
    if (_currentPage < 1) _currentPage = 1;

    final startIndex = totalItems == 0 ? 0 : (_currentPage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize > totalItems) ? totalItems : (startIndex + _pageSize);
    final pageItems = totalItems == 0 ? <ReviewRequestModel>[] : filteredRequests.sublist(startIndex, endIndex);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineVariant),
      ),
      child: Column(
        children: [
          // Header Row (Desktop only)
          if (MediaQuery.of(context).size.width > 768)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: surfaceContainerLow,
                border: Border(bottom: BorderSide(color: outlineVariant)),
              ),
              child: Row(
                children: [
                  Expanded(flex: 3, child: Text('PATIENT & ID', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurfaceVariant, letterSpacing: 1))),
                  Expanded(flex: 3, child: Text('CHIEF COMPLAINT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurfaceVariant, letterSpacing: 1))),
                  Expanded(flex: 2, child: Center(child: Text('AI CONFIDENCE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurfaceVariant, letterSpacing: 1)))),
                  Expanded(flex: 2, child: Text('PRIORITY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurfaceVariant, letterSpacing: 1))),
                  const Expanded(flex: 2, child: SizedBox()),
                ],
              ),
            ),

          if (pageItems.isEmpty)
            Container(
              padding: const EdgeInsets.all(48),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: outline),
                  const SizedBox(height: 12),
                  Text(
                    totalItems == 0 ? 'No Pending Review Requests' : 'No matching results on this page',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    totalItems == 0
                        ? 'All patient AI conversations have been validated.'
                        : 'Try adjusting your search query.',
                    style: TextStyle(fontSize: 13, color: onSurfaceVariant),
                  ),
                ],
              ),
            )
          else
            ...pageItems.map((request) => Column(
                  children: [
                    _buildQueueItem(
                      request: request,
                      initials: request.patientInitials,
                      initialsBg: tertiaryContainer,
                      initialsText: onTertiaryContainer,
                      name: request.patientName,
                      id: request.patientId,
                      complaintTag: request.complaintTag,
                      complaintDesc: request.complaintDesc,
                      accuracy: request.accuracy,
                      accuracyText: '${(request.accuracy * 100).toInt()}% Accurate',
                      accuracyColor: secondary,
                      priorityIcon: request.priority.toLowerCase().contains('high')
                          ? Icons.priority_high
                          : Icons.low_priority,
                      priorityText: request.priority,
                      priorityColor: request.priority.toLowerCase().contains('high')
                          ? error
                          : onSurfaceVariant,
                    ),
                    Divider(height: 1, color: outlineVariant),
                  ],
                )),

          // Dynamic Interactive Footer & Pagination
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: surfaceContainerLowest,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  totalItems == 0
                      ? 'Showing 0 of 0 cases'
                      : 'Showing ${startIndex + 1}-${endIndex} of $totalItems cases',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurfaceVariant),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      onPressed: _currentPage > 1
                          ? () {
                              setState(() {
                                _currentPage--;
                              });
                            }
                          : null,
                    ),
                    ...List.generate(totalPages, (index) {
                      final pageNum = index + 1;
                      return _buildPaginationBtn('$pageNum', isActive: pageNum == _currentPage, onTap: () {
                        setState(() {
                          _currentPage = pageNum;
                        });
                      });
                    }),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      onPressed: _currentPage < totalPages
                          ? () {
                              setState(() {
                                _currentPage++;
                              });
                            }
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color iconBgColor, Color iconColor, {Color? borderLeftColor}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineVariant.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          if (borderLeftColor != null)
            Container(
              width: 4,
              height: 48,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: borderLeftColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBgColor, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurfaceVariant, letterSpacing: 1)),
              Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: onSurface)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationBtn(String text, {required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
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
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isActive ? onPrimaryContainer : onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderAndFilters({int requestsCount = 0}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isDesktop = constraints.maxWidth > 768;
        
        Widget title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.space_dashboard_rounded, color: onSurface, size: 28),
                const SizedBox(width: 8),
                Text('Review Queue', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: onSurface)),
              ],
            ),
            const SizedBox(height: 4),
            Text('$requestsCount patient consultations awaiting physician validation', style: TextStyle(fontSize: 16, color: onSurfaceVariant)),
          ],
        );
        
        Widget searchBar = Container(
          width: isDesktop ? 256 : double.infinity,
          height: 48,
          decoration: BoxDecoration(
            color: surfaceContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
                _currentPage = 1;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search patient or ID',
              hintStyle: TextStyle(color: onSurfaceVariant),
              prefixIcon: Icon(Icons.search, color: onSurfaceVariant),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        );

        if (isDesktop) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [title, searchBar],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 16), searchBar],
          );
        }
      },
    );
  }


  void _openReviewDetail({
    ReviewRequestModel? request,
    required String name,
    required String id,
    required String complaintTag,
    required String complaintDesc,
  }) {
    final effectiveRequest = request ??
        ReviewRequestModel(
          id: id.replaceAll('ID: #', '').replaceAll(' ', ''),
          patientId: name,
          userQuery: complaintDesc,
          aiResponseContent:
              'Based on your description of pulsing pain, photophobia (sensitivity to light), and visual scintillations (zig-zag patterns), this strongly suggests a migraine with aura. Have you experienced any nausea or weakness in your limbs? It is also important to note if this is the "worst headache of your life."',
          medicalDivision: complaintTag,
          status: 'pending',
          createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
          updatedAt: DateTime.now(),
        );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewDetailScreen(request: effectiveRequest),
      ),
    );
  }

  Widget _buildQueueItem({
    ReviewRequestModel? request,
    required String initials, required Color initialsBg, required Color initialsText,
    required String name, required String id,
    required String complaintTag, required String complaintDesc,
    required double accuracy, required String accuracyText, required Color accuracyColor,
    required IconData priorityIcon, required String priorityText, required Color priorityColor,
  }) {
    return InkWell(
      onTap: () => _openReviewDetail(
        request: request,
        name: name,
        id: id,
        complaintTag: complaintTag,
        complaintDesc: complaintDesc,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            bool isMobile = constraints.maxWidth < 768;
            
            Widget col1 = Row(
              children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: initialsBg, shape: BoxShape.circle), alignment: Alignment.center, child: Text(initials, style: TextStyle(fontWeight: FontWeight.bold, color: initialsText))),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface)), Text(id, style: TextStyle(fontSize: 12, color: onSurfaceVariant))]),
              ],
            );
            
            Widget col2 = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: surfaceVariant, borderRadius: BorderRadius.circular(16)), child: Text(complaintTag, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurfaceVariant))),
                const SizedBox(height: 4),
                Text(complaintDesc, style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: onSurfaceVariant)),
              ],
            );
            
            Widget col3 = Column(
              crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Container(
                  width: 100, height: 6, decoration: BoxDecoration(color: surfaceContainer, borderRadius: BorderRadius.circular(4)),
                  child: FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: accuracy, child: Container(decoration: BoxDecoration(color: accuracyColor, borderRadius: BorderRadius.circular(4)))),
                ),
                const SizedBox(height: 4),
                Text(accuracyText, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: accuracyColor)),
              ],
            );
            
            Widget col4 = Row(
              children: [
                Icon(priorityIcon, color: priorityColor, size: 16),
                const SizedBox(width: 8),
                Text(priorityText.toUpperCase(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: priorityColor)),
              ],
            );
            
            Widget col5 = ElevatedButton(
              onPressed: () => _openReviewDetail(
                request: request,
                name: name,
                id: id,
                complaintTag: complaintTag,
                complaintDesc: complaintDesc,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: const Text('Review', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            );

            if (!isMobile) {
              return Row(
                children: [
                  Expanded(flex: 3, child: col1),
                  Expanded(flex: 3, child: col2),
                  Expanded(flex: 2, child: col3),
                  Expanded(flex: 2, child: col4),
                  Expanded(flex: 2, child: Align(alignment: Alignment.centerRight, child: col5)),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: col1), col4]),
                  const SizedBox(height: 16),
                  col2,
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [col3, col5]),
                ],
              );
            }
          }
        ),
      ),
    );
  }

  Widget _buildFAB() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80.0), // Padding to avoid bottom nav bar
      child: FloatingActionButton(
        onPressed: () {},
        backgroundColor: primary,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
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

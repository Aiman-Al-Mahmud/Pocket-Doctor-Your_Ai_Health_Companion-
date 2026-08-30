import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/doctor_auth_service.dart';
import 'dashboard_screen.dart';
import 'appointments_screen.dart';
import 'reviews_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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

  int _selectedIndex = 3; // Profile is index 3
  bool _twoFactorEnabled = true;
  bool _availableForBooking = true;
  bool _isUploadingAvatar = false;

  ImageProvider _getAvatarImageProvider(String? url) {
    return DoctorAuthService.getAvatarImageProvider(url) ??
        const NetworkImage('https://images.unsplash.com/photo-1622253692010-333f2da6031d?auto=format&fit=crop&q=80&w=300');
  }

  Future<void> _pickAndUploadAvatar() async {
    final ImagePicker picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Profile Photo Source',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.photo_library, color: primary),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: primary),
              title: const Text('Take a Photo (Camera)'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    try {
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );

      if (file == null) return;

      setState(() {
        _isUploadingAvatar = true;
      });

      final res = await DoctorAuthService.uploadAvatar(file);

      if (!mounted) return;

      setState(() {
        _isUploadingAvatar = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? 'Photo updated successfully!'),
          backgroundColor: res.success ? secondary : error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUploadingAvatar = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      extendBody: true,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Profile Section
                _buildHeroSection(),
                const SizedBox(height: 24),

                // Main Content Bento Grid
                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 900) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildProfessionalInfo()),
                          const SizedBox(width: 20),
                          Expanded(child: _buildCertificates()),
                          const SizedBox(width: 20),
                          Expanded(child: _buildConsultationSettings()),
                        ],
                      );
                    } else if (constraints.maxWidth > 600) {
                      return Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(child: _buildProfessionalInfo()),
                              const SizedBox(width: 20),
                              Expanded(child: _buildCertificates()),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildConsultationSettings(),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          _buildProfessionalInfo(),
                          const SizedBox(height: 20),
                          _buildCertificates(),
                          const SizedBox(height: 20),
                          _buildConsultationSettings(),
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 24),

                // Security & Verification Section
                _buildSecuritySection(),

                const SizedBox(height: 100), // Spacer for bottom navigation
              ],
            ),
          ),
        ),
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
                icon: Icon(Icons.notifications_none_outlined, color: onSurfaceVariant, size: 24),
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
  void initState() {
    super.initState();
    final currentDoc = DoctorAuthService.currentDoctor;
    if (currentDoc != null) {
      _availableForBooking = currentDoc.availabilityStatus == 'available';
    }
  }

  Widget _buildHeroSection() {
    final currentDoc = DoctorAuthService.currentDoctor;
    final doctorName = currentDoc?.fullName.isNotEmpty == true ? currentDoc!.fullName : 'Dr. Sadik Hasnat';
    final doctorEmail = currentDoc?.email ?? 'dr.sadik@hospital.com';
    final doctorSpecialty = currentDoc?.specialization.isNotEmpty == true ? currentDoc!.specialization : 'Senior Clinical Physician & Specialist';
    final doctorBio = currentDoc?.biography.isNotEmpty == true 
        ? currentDoc!.biography 
        : 'Leading expert in internal medicine, respiratory assessment, and telehealth case validation with patient-centered treatment plans.';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceContainerLowest.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth > 768;

          Widget avatarWidget = GestureDetector(
            onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primary.withOpacity(0.2), width: 3),
                    image: DecorationImage(
                      image: _getAvatarImageProvider(currentDoc?.avatarUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: _isUploadingAvatar
                      ? Container(
                          decoration: const BoxDecoration(
                            color: Colors.black38,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          ),
                        )
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                ),
              ],
            ),
          );

          Widget infoWidget = Column(
            crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  Text(
                    doctorName,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                      letterSpacing: -0.5,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: secondaryContainer.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_user, size: 14, color: onSecondaryContainer),
                        const SizedBox(width: 4),
                        Text(
                          'Verified Specialist',
                          style: TextStyle(fontSize: 11, color: onSecondaryContainer, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                doctorSpecialty,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primary),
              ),
              const SizedBox(height: 4),
              Text(
                doctorEmail,
                style: TextStyle(fontSize: 13, color: onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Text(
                doctorBio,
                textAlign: isDesktop ? TextAlign.left : TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.4, color: onSurfaceVariant),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: isDesktop ? WrapAlignment.start : WrapAlignment.center,
                children: [
                  _buildTag(currentDoc?.specialization ?? 'General Medicine'),
                  _buildTag('Telehealth Certified'),
                  _buildTag('AI Reviewer'),
                ],
              ),
            ],
          );

          Widget actionsWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EditProfileScreen()),
                  );
                  if (result == true && mounted) {
                    setState(() {});
                  }
                },
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Profile link copied: pocketdoctor.app/doc/${doctorEmail.split('@').first}'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.share, size: 16),
                label: const Text('Share Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: secondary,
                  side: BorderSide(color: secondary, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          );

          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                avatarWidget,
                const SizedBox(width: 24),
                Expanded(child: infoWidget),
                const SizedBox(width: 24),
                SizedBox(width: 180, child: actionsWidget),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                avatarWidget,
                const SizedBox(height: 18),
                infoWidget,
                const SizedBox(height: 20),
                SizedBox(width: double.infinity, child: actionsWidget),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: onSurfaceVariant, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildProfessionalInfo() {
    final doc = DoctorAuthService.currentDoctor;
    return _buildGlassCard(
      title: 'Professional Info',
      icon: Icons.business_center_outlined,
      child: Column(
        children: [
          _buildInfoRow(Icons.local_hospital, 'Primary Hospital', doc?.hospitalAffiliation.isNotEmpty == true ? doc!.hospitalAffiliation : 'Apex Medical Center, NY'),
          const SizedBox(height: 14),
          _buildInfoRow(Icons.badge, 'License Number', doc?.medicalLicenseNumber.isNotEmpty == true ? doc!.medicalLicenseNumber : '#MD-9982736154'),
          const SizedBox(height: 14),
          _buildInfoRow(Icons.history_edu, 'Experience', '${doc?.yearsOfExperience ?? 12} Years Clinical Practice'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primary, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: onSurfaceVariant, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurface)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCertificates() {
    final doc = DoctorAuthService.currentDoctor;
    return _buildGlassCard(
      title: 'Certificates & Qualifications',
      icon: Icons.workspace_premium_outlined,
      child: Column(
        children: [
          _buildCertificateRow(Icons.school, 'Qualification', doc?.qualification.isNotEmpty == true ? doc!.qualification : 'MD - Doctor of Medicine'),
          const SizedBox(height: 10),
          _buildCertificateRow(Icons.favorite, 'Specialization', doc?.specialization.isNotEmpty == true ? doc!.specialization : 'Internal Medicine'),
          const SizedBox(height: 10),
          _buildCertificateRow(Icons.military_tech, 'Medical Board Status', doc?.isVerified == true ? 'Verified & Active Doctor' : 'Pending Verification'),
        ],
      ),
    );
  }

  Widget _buildCertificateRow(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: surfaceContainerLow,
        border: Border.all(color: outlineVariant.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: onSurface)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.verified, color: secondary, size: 16),
        ],
      ),
    );
  }

  Widget _buildConsultationSettings() {
    final doc = DoctorAuthService.currentDoctor;
    final feeText = doc != null && doc.consultationFee > 0 
        ? '\$${doc.consultationFee.toStringAsFixed(0)}' 
        : '\$120';

    return _buildGlassCard(
      title: 'Consultation Settings',
      icon: Icons.settings_applications_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: secondaryContainer.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: secondary.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STANDARD TELEHEALTH FEE',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1, color: onSecondaryContainer),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      feeText,
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: onSecondaryContainer),
                    ),
                    Text(
                      ' /session',
                      style: TextStyle(fontSize: 13, color: onSurfaceVariant, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('Availability', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: onSurfaceVariant)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
                child: const Text('Mon-Fri: 9am - 5pm', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: surfaceContainerHigh, borderRadius: BorderRadius.circular(16)),
                child: const Text('Sat: 10am - 2pm', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _availableForBooking ? secondary : outline,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Available for Booking', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _availableForBooking ? secondary : onSurfaceVariant)),
                ],
              ),
              Switch(
                value: _availableForBooking,
                onChanged: (val) async {
                  setState(() {
                    _availableForBooking = val;
                  });
                  final current = DoctorAuthService.currentDoctor;
                  if (current != null) {
                    await DoctorAuthService.updateDoctorProfile(
                      fullName: current.fullName,
                      specialization: current.specialization,
                      hospitalAffiliation: current.hospitalAffiliation,
                      medicalLicenseNumber: current.medicalLicenseNumber,
                      qualification: current.qualification,
                      yearsOfExperience: current.yearsOfExperience,
                      biography: current.biography,
                      consultationFee: current.consultationFee,
                      availabilityStatus: val ? 'available' : 'offline',
                    );
                  }
                },
                activeColor: secondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required String title, required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceContainerLowest.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primary, size: 22),
              const SizedBox(width: 10),
              Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: onSurface)),
            ],
          ),
          const SizedBox(height: 14),
          Divider(color: outlineVariant.withOpacity(0.3), height: 1),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surfaceContainerLowest.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: secondaryContainer.withOpacity(0.4), shape: BoxShape.circle),
                child: Icon(Icons.gpp_good, color: onSecondaryContainer, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Security & Verification', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: onSurface)),
                    Text('Manage physician credentials, RLS policies, and access tokens', style: TextStyle(fontSize: 12, color: onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 700) {
                return Row(
                  children: [
                    Expanded(
                      child: _buildSecurityItem(
                        Icons.verified,
                        secondary,
                        'Medical License Verified',
                        'Active credentials verified with Supabase RLS',
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: secondaryContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                          child: Text('VALID', style: TextStyle(color: secondary, fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSecurityItem(
                        Icons.enhanced_encryption,
                        primary,
                        '2-Factor Authentication',
                        'Biometric lock enabled for prescriptions',
                        trailing: Switch(
                          value: _twoFactorEnabled,
                          onChanged: (v) => setState(() => _twoFactorEnabled = v),
                          activeColor: primary,
                        ),
                      ),
                    ),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildSecurityItem(
                      Icons.verified,
                      secondary,
                      'Medical License Verified',
                      'Active credentials verified with Supabase RLS',
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: secondaryContainer.withOpacity(0.3), borderRadius: BorderRadius.circular(12)),
                        child: Text('VALID', style: TextStyle(color: secondary, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildSecurityItem(
                      Icons.enhanced_encryption,
                      primary,
                      '2-Factor Authentication',
                      'Biometric lock enabled for prescriptions',
                      trailing: Switch(
                        value: _twoFactorEnabled,
                        onChanged: (v) => setState(() => _twoFactorEnabled = v),
                        activeColor: primary,
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityItem(IconData icon, Color color, String title, String subtitle, {required Widget trailing}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: outlineVariant.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurface)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 11, color: onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
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
              } else if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, anim1, anim2) => const AppointmentsScreen(),
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

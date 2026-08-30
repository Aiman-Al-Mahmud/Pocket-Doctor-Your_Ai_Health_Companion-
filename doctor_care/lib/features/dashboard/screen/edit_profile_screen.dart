import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/doctor_auth_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // Design Tokens
  final Color primary = const Color(0xFF004AC6);
  final Color onPrimary = const Color(0xFFFFFFFF);
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
  final Color onSurface = const Color(0xFF191B23);
  final Color onSurfaceVariant = const Color(0xFF434655);
  final Color outline = const Color(0xFF737686);
  final Color outlineVariant = const Color(0xFFC3C6D7);
  final Color error = const Color(0xFFBA1A1A);

  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _hospitalController;
  late TextEditingController _licenseController;
  late TextEditingController _qualificationController;
  late TextEditingController _bioController;
  late TextEditingController _feeController;

  String _selectedSpecialty = 'Internal Medicine';
  int _yearsOfExperience = 8;
  bool _availableForBooking = true;
  bool _isLoading = false;
  bool _isUploadingAvatar = false;
  String? _avatarUrl;

  final List<String> _specialties = const [
    'Cardiology',
    'Neurology',
    'Pediatrics',
    'General Practice',
    'Orthopedics',
    'Dermatology',
    'Gastroenterology',
    'Psychiatry',
    'Pulmonology',
    'Ophthalmology',
    'Oncology',
    'Endocrinology',
    'Nephrology',
    'Urology',
    'Gynecology & Obstetrics',
  ];

  @override
  void initState() {
    super.initState();
    final doc = DoctorAuthService.currentDoctor;
    _avatarUrl = doc?.avatarUrl;

    _nameController = TextEditingController(text: doc?.fullName ?? '');
    _emailController = TextEditingController(text: doc?.email ?? '');
    _phoneController = TextEditingController(text: doc?.phoneNumber ?? '');
    _hospitalController = TextEditingController(text: doc?.hospitalAffiliation ?? '');
    _licenseController = TextEditingController(text: doc?.medicalLicenseNumber ?? '');
    _qualificationController = TextEditingController(text: doc?.qualification ?? '');
    _bioController = TextEditingController(text: doc?.biography ?? '');
    _feeController = TextEditingController(
      text: doc != null && doc.consultationFee > 0 ? doc.consultationFee.toStringAsFixed(2) : '',
    );

    if (doc?.specialization.isNotEmpty == true) {
      if (_specialties.contains(doc!.specialization)) {
        _selectedSpecialty = doc.specialization;
      } else {
        _selectedSpecialty = _specialties.first;
      }
    } else {
      _selectedSpecialty = _specialties.first;
    }
    if (doc != null && doc.yearsOfExperience > 0) {
      _yearsOfExperience = doc.yearsOfExperience;
    }
    if (doc != null) {
      _availableForBooking = doc.availabilityStatus == 'available';
    }
  }

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
        if (res.url != null) {
          _avatarUrl = res.url;
        }
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
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _hospitalController.dispose();
    _licenseController.dispose();
    _qualificationController.dispose();
    _bioController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final fee = double.tryParse(_feeController.text.trim()) ?? 0.0;

    final res = await DoctorAuthService.updateDoctorProfile(
      fullName: _nameController.text,
      specialization: _selectedSpecialty,
      hospitalAffiliation: _hospitalController.text,
      medicalLicenseNumber: _licenseController.text,
      qualification: _qualificationController.text,
      yearsOfExperience: _yearsOfExperience,
      biography: _bioController.text,
      consultationFee: fee,
      availabilityStatus: _availableForBooking ? 'available' : 'offline',
      phoneNumber: _phoneController.text,
      avatarUrl: _avatarUrl,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (res.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(res.message ?? 'Doctor profile updated successfully!'),
            ],
          ),
          backgroundColor: secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message ?? 'Failed to update profile.'),
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
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Avatar and Header Card
                  _buildAvatarCard(),
                  const SizedBox(height: 24),

                  // Personal Information
                  _buildSectionCard(
                    title: 'Personal & Contact Information',
                    icon: Icons.person_outline,
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name (with Title)',
                        hint: 'e.g. Dr. Sadik Hasnat',
                        icon: Icons.badge_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Work Email Address',
                        hint: 'dr.sadik@hospital.com',
                        icon: Icons.email_outlined,
                        readOnly: true,
                        helperText: 'Email is registered with Supabase Authentication',
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Direct Phone / Office Line',
                        hint: '+1 (555) 000-0000',
                        icon: Icons.phone_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Clinical Practice & Credentials
                  _buildSectionCard(
                    title: 'Clinical Practice & Credentials',
                    icon: Icons.local_hospital_outlined,
                    children: [
                      // Specialty Dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Primary Specialization',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: onSurfaceVariant),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: outlineVariant.withOpacity(0.5)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: _selectedSpecialty,
                                icon: Icon(Icons.keyboard_arrow_down, color: primary),
                                items: _specialties.map((s) {
                                  return DropdownMenuItem<String>(
                                    value: s,
                                    child: Text(
                                      s,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() {
                                      _selectedSpecialty = val;
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _hospitalController,
                        label: 'Primary Hospital Affiliation',
                        hint: 'e.g. Apex Medical Center, NY',
                        icon: Icons.business_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter hospital affiliation' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _licenseController,
                        label: 'Medical License Registration Number',
                        hint: 'e.g. MD-9982736154',
                        icon: Icons.verified_user_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter license number' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _qualificationController,
                        label: 'Highest Qualification & University',
                        hint: 'e.g. MD - Doctor of Medicine, Johns Hopkins',
                        icon: Icons.school_outlined,
                      ),
                      const SizedBox(height: 16),

                      // Years of Experience Slider
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Years of Clinical Practice',
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: onSurfaceVariant),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$_yearsOfExperience Years',
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primary),
                                ),
                              ),
                            ],
                          ),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: primary,
                              thumbColor: primary,
                              overlayColor: primary.withOpacity(0.12),
                            ),
                            child: Slider(
                              value: _yearsOfExperience.toDouble(),
                              min: 1,
                              max: 40,
                              divisions: 39,
                              label: '$_yearsOfExperience Years',
                              onChanged: (val) {
                                setState(() {
                                  _yearsOfExperience = val.round();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Practice Bio & Telehealth
                  _buildSectionCard(
                    title: 'Practice Bio & Consultation Settings',
                    icon: Icons.settings_suggest_outlined,
                    children: [
                      _buildTextField(
                        controller: _bioController,
                        label: 'Physician Bio & Treatment Philosophy',
                        hint: 'Write a brief description of your clinical experience and specialty...',
                        icon: Icons.description_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _feeController,
                        label: 'Standard Telehealth Fee (\$ USD / Session)',
                        hint: '120',
                        icon: Icons.attach_money,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Available for Online Patient Consultations',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurface),
                        ),
                        subtitle: Text(
                          'Allows new patients to book direct telehealth appointment slots',
                          style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                        ),
                        value: _availableForBooking,
                        activeColor: secondary,
                        onChanged: (v) {
                          setState(() {
                            _availableForBooking = v;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: onSurfaceVariant,
                            side: BorderSide(color: outlineVariant),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _handleSave,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check, size: 20),
                          label: Text(
                            _isLoading ? 'Saving Changes...' : 'Save Profile Changes',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
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
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: primary),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Edit Doctor Profile',
              style: TextStyle(
                fontFamily: 'Inter',
                color: onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            actions: [
              TextButton.icon(
                onPressed: _isLoading ? null : _handleSave,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  foregroundColor: primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceContainerLowest.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: primary.withOpacity(0.2), width: 3),
                    image: DecorationImage(
                      image: _getAvatarImageProvider(_avatarUrl),
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
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                        )
                      : null,
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Picture & Credentials',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  'Upload or take a photo to update your avatar in patient reviews and telehealth queues.',
                  style: TextStyle(fontSize: 12, color: onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                  icon: _isUploadingAvatar
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.upload, size: 14),
                  label: Text(
                    _isUploadingAvatar ? 'Uploading...' : 'Upload Photo',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primary,
                    side: BorderSide(color: primary.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: surfaceContainerLowest.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primary, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: onSurface),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: outlineVariant.withOpacity(0.3), height: 1),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool readOnly = false,
    String? helperText,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: readOnly ? onSurfaceVariant : onSurface,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 13, color: outline),
            helperText: helperText,
            helperStyle: TextStyle(fontSize: 11, color: outline),
            prefixIcon: Icon(icon, color: primary, size: 20),
            filled: true,
            fillColor: readOnly ? surfaceContainer : surfaceContainerLow,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outlineVariant.withOpacity(0.4)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primary, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: error, width: 1.8),
            ),
          ),
        ),
      ],
    );
  }
}

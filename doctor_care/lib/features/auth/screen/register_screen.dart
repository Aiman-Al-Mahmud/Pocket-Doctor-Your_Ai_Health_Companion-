import 'package:flutter/material.dart';
import '../../../core/services/doctor_auth_service.dart';
import '../../dashboard/screen/dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Text Controllers starting empty with placeholders
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _licenseController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _experienceController = TextEditingController();
  final _biographyController = TextEditingController();
  final _feeController = TextEditingController();

  String? _selectedDegree = 'MD - Doctor of Medicine';
  String? _selectedSpecialty = 'Cardiology';
  bool _isLoading = false;

  static const List<String> _allSpecializations = [
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

  // Colors based on tailwind config
  final Color primary = const Color(0xFF004AC6);
  final Color secondary = const Color(0xFF006C49);
  final Color background = const Color(0xFFFAF8FF);
  final Color onSurface = const Color(0xFF191B23);
  final Color onSurfaceVariant = const Color(0xFF434655);
  final Color surfaceContainerLowest = const Color(0xFFFFFFFF);
  final Color surfaceContainerLow = const Color(0xFFF3F3FE);
  final Color outlineVariant = const Color(0xFFC3C6D7);
  final Color secondaryContainer = const Color(0xFF6CF8BB);
  final Color onSecondaryContainer = const Color(0xFF00714D);
  final Color surface = const Color(0xFFFAF8FF);

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _licenseController.dispose();
    _phoneController.dispose();
    _hospitalController.dispose();
    _experienceController.dispose();
    _biographyController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();
    final licenseNumber = _licenseController.text.trim();
    final phone = _phoneController.text.trim();
    final hospital = _hospitalController.text.trim();
    final experience = int.tryParse(_experienceController.text.trim()) ?? 5;
    final qualification = _selectedDegree ?? 'MD - Doctor of Medicine';
    final specialization = _selectedSpecialty ?? 'General Practice';
    final biography = _biographyController.text.trim();
    final consultationFee = double.tryParse(_feeController.text.trim()) ?? 50.0;

    final result = await DoctorAuthService.registerDoctor(
      email: email,
      password: password,
      fullName: fullName,
      licenseNumber: licenseNumber,
      phone: phone,
      hospital: hospital,
      experience: experience,
      qualification: qualification,
      specialization: specialization,
      biography: biography,
      consultationFee: consultationFee,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Doctor Account Registered Successfully! Welcome, ${result.doctor?.fullName ?? 'Doctor'}'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Registration encountered an issue.'),
          backgroundColor: const Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: surface.withOpacity(0.95),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.medical_services, color: primary, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              'Doctor Care Portal',
              style: TextStyle(
                color: primary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1024),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Progress Indicator & Title
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Physician Registration',
                              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: onSurface),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create your official medical practitioner profile in the cloud database',
                              style: TextStyle(fontSize: 13, color: onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Step 1 of 1',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Responsive Grid Form
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isDesktop = constraints.maxWidth > 800;
                      if (isDesktop) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 8, child: _buildMainForm()),
                            const SizedBox(width: 24),
                            Expanded(flex: 4, child: _buildSidebar()),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            _buildMainForm(),
                            const SizedBox(height: 24),
                            _buildSidebar(),
                          ],
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 20),

                  // Submit Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to Login'),
                        style: TextButton.styleFrom(
                          foregroundColor: onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                children: const [
                                  Text('Complete Registration', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  SizedBox(width: 8),
                                  Icon(Icons.check_circle_outline, size: 18),
                                ],
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surfaceContainerLowest.withOpacity(0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: outlineVariant.withOpacity(0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services, color: primary),
              const SizedBox(width: 8),
              Text(
                'Professional Credentials',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: onSurface),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildFormInput('Full Name (With Title)', 'e.g. Dr. Jane Smith', _fullNameController, (val) => val == null || val.isEmpty ? 'Full name required' : null),
          const SizedBox(height: 16),
          _buildFormInput('Doctor Work Email', 'e.g. dr.janesmith@hospital.com', _emailController, (val) => val == null || !val.contains('@') ? 'Valid email required' : null),
          const SizedBox(height: 16),
          _buildFormInput('Account Password', '••••••••', _passwordController, (val) => val == null || val.length < 6 ? 'At least 6 characters' : null, isPassword: true),
          const SizedBox(height: 16),
          _buildFormInput('Contact Phone Number', 'e.g. +1 (555) 345-6789', _phoneController, null),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 500) {
                return Row(
                  children: [
                    Expanded(child: _buildDropdownField('Medical Degree', ['MD - Doctor of Medicine', 'DO - Doctor of Osteopathic Medicine', 'MBBS - Bachelor of Medicine & Surgery', 'PhD - Medical Research'], _selectedDegree, (val) => setState(() => _selectedDegree = val))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildFormInput('Medical License Number', 'e.g. MD-99887711', _licenseController, (val) => val == null || val.isEmpty ? 'License required' : null)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildDropdownField('Medical Degree', ['MD - Doctor of Medicine', 'DO - Doctor of Osteopathic Medicine', 'MBBS - Bachelor of Medicine & Surgery', 'PhD - Medical Research'], _selectedDegree, (val) => setState(() => _selectedDegree = val)),
                    const SizedBox(height: 16),
                    _buildFormInput('Medical License Number', 'e.g. MD-99887711', _licenseController, (val) => val == null || val.isEmpty ? 'License required' : null),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 500) {
                return Row(
                  children: [
                    Expanded(child: _buildDropdownField('Specialization', _allSpecializations, _selectedSpecialty, (val) => setState(() => _selectedSpecialty = val))),
                    const SizedBox(width: 16),
                    Expanded(child: _buildFormInput('Years of Experience', 'e.g. 8', _experienceController, null, keyboardType: TextInputType.number)),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildDropdownField('Specialization', _allSpecializations, _selectedSpecialty, (val) => setState(() => _selectedSpecialty = val)),
                    const SizedBox(height: 16),
                    _buildFormInput('Years of Experience', 'e.g. 8', _experienceController, null, keyboardType: TextInputType.number),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),
          _buildFormInput('Hospital / Primary Clinic', 'e.g. St. Jude Medical Center', _hospitalController, null),
          const SizedBox(height: 16),
          _buildFormInput('Consultation Fee (\$ USD)', 'e.g. 75.00', _feeController, null, keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _buildFormInput('Professional Biography', 'e.g. Board-certified practitioner specializing in cardiac care...', _biographyController, null),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: outlineVariant.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.verified, color: secondary),
                  const SizedBox(width: 8),
                  Text(
                    'Instant Cloud Sync',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: onSurface),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Your credentials link directly to the Supabase PostgreSQL database, enabling live AI review queues and patient appointments.',
                style: TextStyle(fontSize: 13, color: onSurfaceVariant, height: 1.4),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: secondaryContainer.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.security, color: onSecondaryContainer, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '100% Synchronized with Pocket Doctor',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: onSecondaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormInput(
    String label,
    String hint,
    TextEditingController controller,
    String? Function(String?)? validator, {
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurfaceVariant),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outlineVariant.withOpacity(0.6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, List<String> items, String? value, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurfaceVariant),
          ),
        ),
        DropdownButtonFormField<String>(
          value: value,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: outlineVariant.withOpacity(0.6)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

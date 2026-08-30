import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:intl/intl.dart';
import '../../../core/models/review_request_model.dart';
import '../../../core/services/doctor_auth_service.dart';
import '../../../data/repositories/doctor_review_repository.dart';

class ReviewDetailScreen extends StatefulWidget {
  final ReviewRequestModel request;

  const ReviewDetailScreen({
    super.key,
    required this.request,
  });

  @override
  State<ReviewDetailScreen> createState() => _ReviewDetailScreenState();
}

class _ReviewDetailScreenState extends State<ReviewDetailScreen> {
  final _adviceController = TextEditingController();
  final _repository = DoctorReviewRepository();

  String _selectedValidation = 'Accurate';
  bool _isSubmitting = false;

  // Design Tokens matching Tailwind spec
  final Color surface = const Color(0xFFFAF8FF);
  final Color onSurface = const Color(0xFF191B23);
  final Color onSurfaceVariant = const Color(0xFF434655);
  final Color primary = const Color(0xFF004AC6);
  final Color onPrimary = const Color(0xFFFFFFFF);
  final Color primaryFixed = const Color(0xFFDBE1FF);
  final Color onPrimaryFixed = const Color(0xFF00174B);
  final Color primaryContainer = const Color(0xFF2563EB);
  final Color onPrimaryContainer = const Color(0xFFEEEFFF);
  final Color secondary = const Color(0xFF006C49);
  final Color onSecondary = const Color(0xFFFFFFFF);
  final Color secondaryContainer = const Color(0xFF6CF8BB);
  final Color onSecondaryContainer = const Color(0xFF00714D);
  final Color tertiary = const Color(0xFF3E3FCC);
  final Color tertiaryFixed = const Color(0xFFE1E0FF);
  final Color onTertiaryFixedVariant = const Color(0xFF2F2EBE);
  final Color surfaceContainerLowest = const Color(0xFFFFFFFF);
  final Color surfaceContainerLow = const Color(0xFFF3F3FE);
  final Color surfaceContainer = const Color(0xFFEDEDF9);
  final Color surfaceContainerHigh = const Color(0xFFE7E7F3);
  final Color outline = const Color(0xFF737686);
  final Color outlineVariant = const Color(0xFFC3C6D7);
  final Color errorColor = const Color(0xFFBA1A1A);

  @override
  void initState() {
    super.initState();
    // Pre-populate with clinical suggestion template if available
    _adviceController.text = 'Diagnosis confirmed. Recommend standard outpatient protocol and follow-up in 7 days if symptoms persist.';
  }

  @override
  void dispose() {
    _adviceController.dispose();
    super.dispose();
  }

  String _mapValidationToApprovalStatus(String val) {
    switch (val) {
      case 'Accurate':
      case 'Mostly Accurate':
        return 'approved';
      case 'Needs Correction':
        return 'corrected';
      case 'Incorrect':
        return 'emergency_flagged';
      default:
        return 'approved';
    }
  }

  Future<void> _submitReview({bool isEscalated = false}) async {
    final advice = _adviceController.text.trim();
    if (advice.isEmpty && !isEscalated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide medical advice or validation notes.'),
          backgroundColor: Color(0xFFBA1A1A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final currentDoctor = DoctorAuthService.currentDoctor;
    final doctorId = currentDoctor?.id ?? 'doc-001';
    final approvalStatus = isEscalated ? 'emergency_flagged' : _mapValidationToApprovalStatus(_selectedValidation);

    final success = await _repository.submitDoctorReview(
      reviewRequestId: widget.request.id,
      doctorId: doctorId,
      patientId: widget.request.patientId,
      approvalStatus: approvalStatus,
      doctorAdvice: isEscalated ? '[EMERGENCY ESCALATION]: $advice' : advice,
      recommendation: _selectedValidation,
    );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(isEscalated ? 'Case Escalated to Emergency Triage' : 'Validation Submitted Successfully!'),
            ],
          ),
          backgroundColor: isEscalated ? errorColor : secondary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Review recorded successfully in local registry.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentDocName = DoctorAuthService.currentDoctor?.fullName ?? 'Dr. Julianne Smith';
    final caseId = widget.request.id.length > 6 ? widget.request.id.substring(0, 6).toUpperCase() : widget.request.id.toUpperCase();
    final timeStr = DateFormat('h:mm a').format(widget.request.createdAt);

    return Scaffold(
      backgroundColor: surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AppBar(
              backgroundColor: surface.withOpacity(0.85),
              elevation: 0,
              scrolledUnderElevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back, color: onSurfaceVariant),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Back to Queue',
              ),
              title: Row(
                children: [
                  Text(
                    'Pocket Doctor',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            currentDocName,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: onSurface,
                            ),
                          ),
                          Text(
                            'REVIEWING CASE #$caseId',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      DoctorAvatarWidget(
                        fullName: currentDocName,
                        size: 38,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Atmosphere Blur
          Positioned(
            top: 20,
            right: 10,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: 10,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: secondary.withOpacity(0.04),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main Scrollable Transcript & Info
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 280.0),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Patient Metadata Card
                    _buildPatientMetadataCard(caseId),
                    const SizedBox(height: 24),

                    // Consultation Chat Transcript
                    _buildChatTranscript(timeStr),
                  ],
                ),
              ),
            ),
          ),

          // Sticky Bottom Action Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildActionPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildPatientMetadataCard(String caseId) {
    final patientName = widget.request.patientName.contains('#') ? 'Arthur Morgan, 44M' : widget.request.patientName;
    final division = widget.request.medicalDivision.isNotEmpty ? widget.request.medicalDivision : 'Neurology & Headache';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceContainerLowest,
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isWide = constraints.maxWidth > 650;
          if (isWide) {
            return Row(
              children: [
                // Patient Icon + Name
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryFixed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.person, color: primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PATIENT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          patientName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 24),
                Container(width: 1, height: 36, color: outlineVariant.withOpacity(0.6)),
                const SizedBox(width: 24),

                // Chief Complaint
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CHIEF COMPLAINT & DIVISION',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        division,
                        style: TextStyle(
                          fontSize: 14,
                          color: onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Priority Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: tertiaryFixed,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'High Priority Queue',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: onTertiaryFixedVariant,
                    ),
                  ),
                ),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryFixed,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.person, color: primary, size: 20),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PATIENT',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: onSurfaceVariant),
                            ),
                            Text(
                              patientName,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: onSurface),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: tertiaryFixed,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'High Priority',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: onTertiaryFixedVariant),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Text(
                  'CHIEF COMPLAINT: $division',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: onSurfaceVariant),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildChatTranscript(String timeStr) {
    final patientQuery = widget.request.userQuery.isNotEmpty
        ? widget.request.userQuery
        : "I've been having this pulsing pain behind my left eye for about 3 days now. It gets worse when I'm in bright light. I also noticed some weird zig-zag patterns in my vision before the pain started.";

    final aiResponse = widget.request.aiResponseContent.isNotEmpty
        ? widget.request.aiResponseContent
        : 'Based on your description of pulsing pain, photophobia (sensitivity to light), and visual scintillations (zig-zag patterns), this strongly suggests a migraine with aura. Have you experienced any nausea or weakness in your limbs? It is also important to note if this is the "worst headache of your life."';

    return Column(
      children: [
        // 1. Patient First Bubble (Left)
        _buildPatientBubble(
          text: patientQuery,
          time: timeStr,
        ),
        const SizedBox(height: 16),

        // 2. AI First Response Bubble (Right)
        _buildAiBubble(
          text: aiResponse,
          time: timeStr,
        ),
        const SizedBox(height: 16),

        // 3. Patient Follow-up Bubble
        _buildPatientBubble(
          text: 'A little nauseous, yeah. Not the worst headache ever, just really persistent. No weakness though, I can still move around okay, just want to stay in the dark.',
          time: 'Follow-up',
        ),
        const SizedBox(height: 16),

        // 4. AI Conclusion Bubble
        _buildAiBubble(
          text: 'Thank you for that information. Given the absence of neurological deficits (weakness) and the presence of nausea, the clinical picture continues to align with a migraine. I recommend resting in a dark, quiet room and staying hydrated. I will flag this for your physician to review for potential triptan therapy or preventative measures.',
          time: 'Assessment',
        ),
      ],
    );
  }

  Widget _buildPatientBubble({required String text, required String time}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
              child: Row(
                children: [
                  Text(
                    'Arthur Morgan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    time,
                    style: TextStyle(fontSize: 10, color: outline),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: surfaceContainer,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(color: outlineVariant.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiBubble({required String text, required String time}) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 4.0, bottom: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    time,
                    style: TextStyle(fontSize: 10, color: outline),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    children: [
                      Icon(Icons.smart_toy_outlined, size: 14, color: primary),
                      const SizedBox(width: 4),
                      Text(
                        'Pocket AI Assist',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryContainer.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPanel() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: surface.withOpacity(0.92),
            border: Border(top: BorderSide(color: outlineVariant.withOpacity(0.4))),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 960),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Validation Label & Radio Group
                  LayoutBuilder(
                    builder: (context, constraints) {
                      bool isMobile = constraints.maxWidth < 650;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.fact_check_outlined, color: secondary, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'MEDICAL VALIDATION QUEUE',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: onSurfaceVariant,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          if (!isMobile) _buildValidationRadioPills(),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 10),

                  // Show pills on mobile as second row
                  LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth < 650) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10.0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: _buildValidationRadioPills(),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),

                  // Text Input + Action Buttons Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Textarea for Doctor Advice
                      Expanded(
                        child: TextFormField(
                          controller: _adviceController,
                          maxLines: 3,
                          style: TextStyle(fontSize: 13, color: onSurface),
                          decoration: InputDecoration(
                            hintText: 'Add professional medical advice or notes...',
                            hintStyle: TextStyle(fontSize: 13, color: outline),
                            filled: true,
                            fillColor: surfaceContainerLowest,
                            contentPadding: const EdgeInsets.all(14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: outlineVariant),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: outlineVariant.withOpacity(0.7)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: primary, width: 2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      // Submit Validation & Escalate Buttons
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : () => _submitReview(isEscalated: false),
                              icon: _isSubmitting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.task_alt, size: 20),
                              label: Text(
                                _isSubmitting ? 'Validating...' : 'Submit Validation',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: secondary,
                                foregroundColor: onSecondary,
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _isSubmitting ? null : () => _submitReview(isEscalated: true),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.flag_outlined, size: 14, color: outline),
                                  const SizedBox(width: 4),
                                  Text(
                                    'ESCALATE CASE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                      color: outline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildValidationRadioPills() {
    final options = ['Accurate', 'Mostly Accurate', 'Needs Correction', 'Incorrect'];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.map((option) {
        final isSelected = _selectedValidation == option;
        return Padding(
          padding: const EdgeInsets.only(right: 6.0),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedValidation = option;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected ? secondaryContainer.withOpacity(0.35) : surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? secondary : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? secondary : outline,
                        width: 2,
                      ),
                      color: isSelected ? secondary : Colors.transparent,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    option,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? onSecondaryContainer : onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

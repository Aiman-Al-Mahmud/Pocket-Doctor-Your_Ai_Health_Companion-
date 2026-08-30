import 'package:flutter/material.dart';
import '../../../core/models/review_request_model.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/review_repository.dart';

class PatientReviewsScreen extends StatefulWidget {
  final String? patientId;

  const PatientReviewsScreen({
    super.key,
    this.patientId,
  });

  @override
  State<PatientReviewsScreen> createState() => _PatientReviewsScreenState();
}

class _PatientReviewsScreenState extends State<PatientReviewsScreen> {
  final _reviewRepository = ReviewRepository();

  String get _effectivePatientId {
    final pid = widget.patientId;
    if (pid != null && pid.isNotEmpty && pid != 'demo-patient-id') {
      return pid;
    }
    final currentUser = SupabaseService.client.auth.currentUser;
    if (currentUser != null) {
      return currentUser.id;
    }
    return pid ?? 'demo-patient-id';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.rate_review_rounded, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Doctor Reviews', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<ReviewRequestModel>>(
        stream: _reviewRepository.streamPatientReviewRequests(_effectivePatientId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = snapshot.data ?? [];

          if (requests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No Doctor Validation Requests',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimaryLight,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Text(
                      'When you chat with Pocket Doctor AI, tap "Validate with Doctor" to request a physician review.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = requests[index];
              final isCompleted = item.status == 'completed';

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey[200]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item.medicalDivision,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCompleted
                                  ? AppColors.success.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isCompleted ? 'Reviewed' : 'Pending Doctor',
                              style: TextStyle(
                                color: isCompleted ? AppColors.success : Colors.orange[800],
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Query: ${item.userQuery}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'AI Response: ${item.aiResponseContent}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        StreamBuilder<DoctorReviewModel?>(
                          stream: _reviewRepository.streamDoctorReviewForRequest(item.id),
                          builder: (context, docSnapshot) {
                            if (!docSnapshot.hasData || docSnapshot.data == null) {
                              return FutureBuilder<DoctorReviewModel?>(
                                future: _reviewRepository.getDoctorReviewForRequest(item.id),
                                builder: (context, fSnapshot) {
                                  if (!fSnapshot.hasData || fSnapshot.data == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return _buildDoctorReviewWidget(fSnapshot.data!);
                                },
                              );
                            }
                            return _buildDoctorReviewWidget(docSnapshot.data!);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDoctorReviewWidget(DoctorReviewModel review) {
    Color statusColor = AppColors.primary;
    if (review.approvalStatus.contains('approved')) {
      statusColor = AppColors.success;
    } else if (review.approvalStatus.contains('emergency')) {
      statusColor = Colors.red;
    } else if (review.approvalStatus.contains('corrected')) {
      statusColor = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: statusColor, size: 18),
              const SizedBox(width: 6),
              Text(
                'Doctor Advice (${review.approvalStatus.toUpperCase().replaceAll('_', ' ')})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            review.doctorAdvice,
            style: const TextStyle(fontSize: 13, height: 1.4),
          ),
          if (review.recommendation != null && review.recommendation!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Recommendation: ${review.recommendation}',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }
}

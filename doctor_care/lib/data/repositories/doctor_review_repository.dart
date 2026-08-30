import 'package:flutter/foundation.dart';
import '../../core/models/review_request_model.dart';
import '../../core/services/supabase_service.dart';

class DoctorReviewRepository {
  final _client = SupabaseService.client;

  /// Stream pending review requests in real-time with category and doctor routing
  Stream<List<ReviewRequestModel>> streamPendingReviewRequests({
    String? doctorId,
    String? specialization,
  }) {
    return _client
        .from('review_requests')
        .stream(primaryKey: ['id'])
        .eq('status', 'pending')
        .order('created_at', ascending: false)
        .map((data) {
          final requests = data.map((json) => ReviewRequestModel.fromJson(json)).toList();
          if (doctorId == null && specialization == null) return requests;

          final cleanSpec = (specialization ?? '').toLowerCase().trim();
          return requests.where((req) {
            final isAssigned = req.assignedDoctorId == null || req.assignedDoctorId == doctorId;
            final isCategoryMatch = cleanSpec.isEmpty ||
                cleanSpec == 'general practice' ||
                req.medicalDivision.toLowerCase().contains(cleanSpec) ||
                cleanSpec.contains(req.medicalDivision.toLowerCase());
            return isAssigned && isCategoryMatch;
          }).toList();
        });
  }

  /// Submit Doctor Review Feedback
  Future<bool> submitDoctorReview({
    required String reviewRequestId,
    required String doctorId,
    required String patientId,
    required String approvalStatus, // 'approved', 'corrected', 'emergency_flagged'
    required String doctorAdvice,
    String? recommendation,
  }) async {
    try {
      // 1. Insert into doctor_reviews table
      await _client.from('doctor_reviews').insert({
        'review_request_id': reviewRequestId,
        'doctor_id': doctorId,
        'patient_id': patientId,
        'approval_status': approvalStatus,
        'doctor_advice': doctorAdvice,
        'recommendation': recommendation,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2. Update status in review_requests table to completed
      await _client.from('review_requests').update({
        'status': 'completed',
        'assigned_doctor_id': doctorId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', reviewRequestId);

      return true;
    } catch (e) {
      debugPrint('Error submitting doctor review: $e');
      return false;
    }
  }
}

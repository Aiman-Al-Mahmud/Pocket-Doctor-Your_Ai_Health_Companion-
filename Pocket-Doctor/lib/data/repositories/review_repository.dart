import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../../core/models/review_request_model.dart';
import '../../core/services/supabase_service.dart';

class ReviewRepository {
  final _client = SupabaseService.client;

  /// Submit an AI conversation response for doctor validation
  Future<ReviewRequestModel?> submitForDoctorValidation({
    required String patientId,
    required String userQuery,
    required String aiResponseContent,
    required String medicalDivision,
    String? chatId,
    String? assignedDoctorId,
  }) async {
    try {
      final validPatientId = _ensureValidUuid(patientId, 'patient-session');
      final validChatId = chatId != null ? _ensureValidUuid(chatId, 'chat-session') : null;
      final response = await _client.from('review_requests').insert({
        'patient_id': validPatientId,
        'chat_id': validChatId,
        'assigned_doctor_id': assignedDoctorId,
        'user_query': userQuery,
        'ai_response_content': aiResponseContent,
        'medical_division': medicalDivision,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      return ReviewRequestModel.fromJson(response);
    } catch (e) {
      debugPrint('Error submitting review request: $e');
      return null;
    }
  }

  /// Get review requests submitted by patient
  Future<List<ReviewRequestModel>> getPatientReviewRequests(String patientId) async {
    final validPatientId = _ensureValidUuid(patientId, 'patient-session');
    try {
      final response = await _client
          .from('review_requests')
          .select()
          .eq('patient_id', validPatientId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => ReviewRequestModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching patient review requests: $e');
      return [];
    }
  }

  String _ensureValidUuid(String? id, [String? fallbackSeed]) {
    final validUuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (id != null && validUuidRegex.hasMatch(id)) {
      return id;
    }
    final seed = (id != null && id.isNotEmpty) ? id : (fallbackSeed ?? 'demo-session');
    final bytes = utf8.encode(seed);
    final digest = md5.convert(bytes).toString();
    return '${digest.substring(0, 8)}-${digest.substring(8, 12)}-4${digest.substring(13, 16)}-a${digest.substring(17, 20)}-${digest.substring(20, 32)}';
  }

  /// Stream review requests submitted by patient in real-time
  Stream<List<ReviewRequestModel>> streamPatientReviewRequests(String patientId) {
    final validPatientId = _ensureValidUuid(patientId, 'patient-session');
    return _client
        .from('review_requests')
        .stream(primaryKey: ['id'])
        .eq('patient_id', validPatientId)
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => ReviewRequestModel.fromJson(e)).toList());
  }

  /// Get doctor review feedback for a specific request
  Future<DoctorReviewModel?> getDoctorReviewForRequest(String requestId) async {
    try {
      final response = await _client
          .from('doctor_reviews')
          .select()
          .eq('review_request_id', requestId)
          .maybeSingle();

      if (response == null) return null;
      return DoctorReviewModel.fromJson(response);
    } catch (e) {
      debugPrint('Error fetching doctor review: $e');
      return null;
    }
  }

  /// Stream doctor review feedback for a specific request in real-time
  Stream<DoctorReviewModel?> streamDoctorReviewForRequest(String requestId) {
    return _client
        .from('doctor_reviews')
        .stream(primaryKey: ['id'])
        .eq('review_request_id', requestId)
        .map((data) => data.isNotEmpty ? DoctorReviewModel.fromJson(data.first) : null);
  }
}

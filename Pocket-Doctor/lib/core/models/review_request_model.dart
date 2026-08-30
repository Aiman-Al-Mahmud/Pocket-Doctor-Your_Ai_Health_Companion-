import 'package:flutter/foundation.dart';

class ReviewRequestModel {
  final String id;
  final String patientId;
  final String? chatId;
  final String userQuery;
  final String aiResponseContent;
  final String medicalDivision;
  final String status; // 'pending', 'under_review', 'completed', 'rejected'
  final String? assignedDoctorId;
  final DateTime createdAt;
  final DateTime updatedAt;

  ReviewRequestModel({
    required this.id,
    required this.patientId,
    this.chatId,
    required this.userQuery,
    required this.aiResponseContent,
    required this.medicalDivision,
    this.status = 'pending',
    this.assignedDoctorId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReviewRequestModel.fromJson(Map<String, dynamic> json) {
    return ReviewRequestModel(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      chatId: json['chat_id'] as String?,
      userQuery: json['user_query'] as String? ?? '',
      aiResponseContent: json['ai_response_content'] as String? ?? '',
      medicalDivision: json['medical_division'] as String? ?? 'General Health',
      status: json['status'] as String? ?? 'pending',
      assignedDoctorId: json['assigned_doctor_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'patient_id': patientId,
      'chat_id': chatId,
      'user_query': userQuery,
      'ai_response_content': aiResponseContent,
      'medical_division': medicalDivision,
      'status': status,
      'assigned_doctor_id': assignedDoctorId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class DoctorReviewModel {
  final String id;
  final String reviewRequestId;
  final String doctorId;
  final String patientId;
  final String approvalStatus; // 'approved', 'corrected', 'emergency_flagged'
  final String doctorAdvice;
  final String? recommendation;
  final DateTime createdAt;

  DoctorReviewModel({
    required this.id,
    required this.reviewRequestId,
    required this.doctorId,
    required this.patientId,
    required this.approvalStatus,
    required this.doctorAdvice,
    this.recommendation,
    required this.createdAt,
  });

  factory DoctorReviewModel.fromJson(Map<String, dynamic> json) {
    return DoctorReviewModel(
      id: json['id'] as String,
      reviewRequestId: json['review_request_id'] as String,
      doctorId: json['doctor_id'] as String,
      patientId: json['patient_id'] as String,
      approvalStatus: json['approval_status'] as String? ?? 'approved',
      doctorAdvice: json['doctor_advice'] as String? ?? '',
      recommendation: json['recommendation'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'review_request_id': reviewRequestId,
      'doctor_id': doctorId,
      'patient_id': patientId,
      'approval_status': approvalStatus,
      'doctor_advice': doctorAdvice,
      'recommendation': recommendation,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

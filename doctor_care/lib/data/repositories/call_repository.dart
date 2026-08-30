import 'package:flutter/foundation.dart';
import '../../core/services/supabase_service.dart';

class CallSessionModel {
  final String id;
  final String appointmentId;
  final String doctorId;
  final String patientId;
  final String status; // 'calling', 'active', 'ended', 'declined'
  final String channelName;
  final DateTime startedAt;
  final DateTime? endedAt;

  CallSessionModel({
    required this.id,
    required this.appointmentId,
    required this.doctorId,
    required this.patientId,
    required this.status,
    required this.channelName,
    required this.startedAt,
    this.endedAt,
  });

  factory CallSessionModel.fromJson(Map<String, dynamic> json) {
    return CallSessionModel(
      id: json['id'] as String,
      appointmentId: json['appointment_id'] as String? ?? '',
      doctorId: json['doctor_id'] as String? ?? '',
      patientId: json['patient_id'] as String? ?? '',
      status: json['status'] as String? ?? 'calling',
      channelName: json['channel_name'] as String? ?? '',
      startedAt: json['started_at'] != null
          ? DateTime.tryParse(json['started_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      endedAt: json['ended_at'] != null
          ? DateTime.tryParse(json['ended_at'].toString())
          : null,
    );
  }
}

class CallRepository {
  final _client = SupabaseService.client;

  /// Doctor initiates a call session for a confirmed appointment
  Future<CallSessionModel?> initiateCall({
    required String appointmentId,
    required String doctorId,
    required String patientId,
  }) async {
    try {
      final channelName = 'telehealth_${appointmentId.replaceAll('-', '_')}';
      final response = await _client.from('call_sessions').insert({
        'appointment_id': appointmentId,
        'doctor_id': doctorId,
        'patient_id': patientId,
        'status': 'calling',
        'channel_name': channelName,
        'started_at': DateTime.now().toIso8601String(),
      }).select().single();

      return CallSessionModel.fromJson(response);
    } catch (e) {
      debugPrint('Error initiating call session: $e');
      return null;
    }
  }

  /// Listen to state changes for a specific appointment call session
  Stream<CallSessionModel?> streamCallSession(String appointmentId) {
    return _client
        .from('call_sessions')
        .stream(primaryKey: ['id'])
        .eq('appointment_id', appointmentId)
        .map((data) {
          if (data.isEmpty) return null;
          return CallSessionModel.fromJson(data.last);
        });
  }

  /// Update call session status (e.g. 'active', 'ended', 'declined')
  Future<bool> updateCallStatus(String sessionId, String status) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status,
      };
      if (status == 'ended' || status == 'declined') {
        updateData['ended_at'] = DateTime.now().toIso8601String();
      }

      await _client.from('call_sessions').update(updateData).eq('id', sessionId);
      return true;
    } catch (e) {
      debugPrint('Error updating call status: $e');
      return false;
    }
  }

  /// End call session and mark the appointment as completed
  Future<bool> endCallSession(String sessionId, String appointmentId) async {
    try {
      await updateCallStatus(sessionId, 'ended');
      await _client.from('appointments').update({
        'status': 'completed',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', appointmentId);
      return true;
    } catch (e) {
      debugPrint('Error ending call session: $e');
      return false;
    }
  }
}

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

  /// Stream incoming active/calling sessions for the patient
  Stream<CallSessionModel?> streamIncomingCallForPatient(String patientId) {
    return _client
        .from('call_sessions')
        .stream(primaryKey: ['id'])
        .eq('patient_id', patientId)
        .map((data) {
          if (data.isEmpty) return null;
          final activeSessions = data.where((item) => item['status'] == 'calling' || item['status'] == 'active').toList();
          if (activeSessions.isEmpty) return null;
          return CallSessionModel.fromJson(activeSessions.last);
        });
  }

  /// Listen to a specific call session
  Stream<CallSessionModel?> streamCallSession(String sessionId) {
    return _client
        .from('call_sessions')
        .stream(primaryKey: ['id'])
        .eq('id', sessionId)
        .map((data) {
          if (data.isEmpty) return null;
          return CallSessionModel.fromJson(data.last);
        });
  }

  /// Update call session status ('active', 'ended', 'declined')
  Future<bool> updateCallStatus(String sessionId, String status) async {
    try {
      Map<String, dynamic> updateData = {'status': status};
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
}

import 'package:flutter/foundation.dart';
import '../../core/services/supabase_service.dart';

class DoctorAppointmentModel {
  final String id;
  final String patientId;
  final String doctorId;
  final DateTime appointmentDate;
  final String? startTime;
  final String? endTime;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final String? notes;
  final String patientName;
  final String patientCode;
  final String reason;
  final List<String> availableSlots;
  String? selectedSlot;

  DoctorAppointmentModel({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.appointmentDate,
    this.startTime,
    this.endTime,
    required this.status,
    this.notes,
    required this.patientName,
    required this.patientCode,
    required this.reason,
    this.availableSlots = const [
      '09:00 AM - 09:30 AM',
      '10:00 AM - 10:30 AM',
      '02:00 PM - 02:30 PM',
      '04:00 PM - 04:30 PM'
    ],
    this.selectedSlot,
  });

  factory DoctorAppointmentModel.fromJson(Map<String, dynamic> json) {
    String pId = json['patient_id'] as String? ?? 'PD-1000';
    String shortId = pId.length >= 8 ? pId.substring(0, 8).toUpperCase() : pId;
    
    return DoctorAppointmentModel(
      id: json['id'] as String,
      patientId: pId,
      doctorId: json['doctor_id'] as String? ?? '',
      appointmentDate: json['appointment_date'] != null
          ? DateTime.tryParse(json['appointment_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      patientName: json['patient_name'] as String? ?? 'Patient #$shortId',
      patientCode: 'ID: #PD-$shortId',
      reason: json['notes'] as String? ?? 'General Health Checkup & Consultation',
      selectedSlot: json['start_time'] != null && json['end_time'] != null
          ? '${json['start_time']} - ${json['end_time']}'
          : null,
    );
  }
}

class DoctorAppointmentRepository {
  final _client = SupabaseService.client;

  /// Stream appointments for a given doctor in real-time
  Stream<List<DoctorAppointmentModel>> streamDoctorAppointments(String? doctorId) {
    var query = _client.from('appointments').stream(primaryKey: ['id']);
    
    return query.order('appointment_date', ascending: true).map((data) {
      final list = data.map((json) => DoctorAppointmentModel.fromJson(json)).toList();
      if (doctorId == null || doctorId.isEmpty) {
        return list;
      }
      return list.where((a) => a.doctorId == doctorId || a.doctorId.isEmpty).toList();
    });
  }

  /// Create or update appointment status
  Future<bool> updateAppointmentStatus(String appointmentId, String status, {String? timeSlot}) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (timeSlot != null && timeSlot.contains('-')) {
        final parts = timeSlot.split('-');
        updateData['start_time'] = parts[0].trim();
        updateData['end_time'] = parts[1].trim();
      }

      await _client.from('appointments').update(updateData).eq('id', appointmentId);
      return true;
    } catch (e) {
      debugPrint('Error updating appointment status: $e');
      return false;
    }
  }
}


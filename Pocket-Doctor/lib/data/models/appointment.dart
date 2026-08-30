class Appointment {
  final String id;
  final String patientId;
  final String doctorId;
  final String doctorName;
  final String doctorSpecialty;
  final String? doctorHospital;
  final String? doctorAvatarUrl;
  final DateTime appointmentDate;
  final String startTime;
  final String endTime;
  final String status; // 'pending', 'confirmed', 'cancelled', 'completed'
  final String? notes;
  final DateTime createdAt;

  const Appointment({
    required this.id,
    required this.patientId,
    required this.doctorId,
    this.doctorName = 'Dr. Specialist',
    this.doctorSpecialty = 'General Medicine',
    this.doctorHospital,
    this.doctorAvatarUrl,
    required this.appointmentDate,
    required this.startTime,
    required this.endTime,
    this.status = 'pending',
    this.notes,
    required this.createdAt,
  });

  factory Appointment.fromMap(Map<String, dynamic> map, [Map<String, dynamic>? doctorUserMap, Map<String, dynamic>? doctorMap]) {
    return Appointment(
      id: map['id']?.toString() ?? 'apt-${DateTime.now().millisecondsSinceEpoch}',
      patientId: map['patient_id']?.toString() ?? '',
      doctorId: map['doctor_id']?.toString() ?? '',
      doctorName: doctorUserMap?['full_name']?.toString() ?? map['doctor_name']?.toString() ?? 'Dr. Specialist',
      doctorSpecialty: doctorMap?['specialization']?.toString() ?? map['doctor_specialty']?.toString() ?? 'General Practice',
      doctorHospital: doctorMap?['hospital_affiliation']?.toString() ?? map['doctor_hospital']?.toString(),
      doctorAvatarUrl: doctorUserMap?['avatar_url']?.toString(),
      appointmentDate: map['appointment_date'] != null
          ? DateTime.tryParse(map['appointment_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      startTime: map['start_time']?.toString() ?? '10:00 AM',
      endTime: map['end_time']?.toString() ?? '10:30 AM',
      status: map['status']?.toString() ?? 'pending',
      notes: map['notes']?.toString(),
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patient_id': patientId,
      'doctor_id': doctorId,
      'appointment_date': appointmentDate.toIso8601String().split('T').first,
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Appointment copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? doctorName,
    String? doctorSpecialty,
    String? doctorHospital,
    String? doctorAvatarUrl,
    DateTime? appointmentDate,
    String? startTime,
    String? endTime,
    String? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      doctorName: doctorName ?? this.doctorName,
      doctorSpecialty: doctorSpecialty ?? this.doctorSpecialty,
      doctorHospital: doctorHospital ?? this.doctorHospital,
      doctorAvatarUrl: doctorAvatarUrl ?? this.doctorAvatarUrl,
      appointmentDate: appointmentDate ?? this.appointmentDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

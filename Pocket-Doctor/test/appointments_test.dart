import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_doctor/data/database/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dynamic Doctor & Appointment System Tests', () {
    final dbHelper = DatabaseHelper.instance;
    const testPatientId = 'test-patient-uuid-12345';

    test('Fetch doctors from database with fallback seed', () async {
      final doctors = await dbHelper.getDoctors();
      expect(doctors, isNotEmpty);
      expect(doctors.length, greaterThanOrEqualTo(5));

      final firstDoc = doctors.first;
      expect(firstDoc.id, isNotEmpty);
      expect(firstDoc.name, isNotEmpty);
      expect(firstDoc.specialization, isNotEmpty);
      expect(firstDoc.rating, greaterThanOrEqualTo(4.0));
      expect(firstDoc.hospitalAffiliation, isNotEmpty);
    });

    test('Filter doctors by Cardiology specialty', () async {
      final cardioDocs = await dbHelper.getDoctors(specialty: 'Cardiology');
      expect(cardioDocs, isNotEmpty);
      for (final doc in cardioDocs) {
        expect(
          doc.specialization.toLowerCase().contains('cardio') ||
              (doc.subSpecialty ?? '').toLowerCase().contains('cardio'),
          isTrue,
        );
      }
    });

    test('Filter doctors by Search Query', () async {
      final searchResults = await dbHelper.getDoctors(searchQuery: 'Elena');
      expect(searchResults, isNotEmpty);
      expect(searchResults.first.name, contains('Elena'));
    });

    test('Book an appointment and verify patient history', () async {
      final doctors = await dbHelper.getDoctors();
      final doctor = doctors.first;
      final tomorrow = DateTime.now().add(const Duration(days: 1));

      final appointment = await dbHelper.bookAppointment(
        patientId: testPatientId,
        doctorId: doctor.id,
        doctorName: doctor.name,
        doctorSpecialty: doctor.specialization,
        doctorHospital: doctor.hospitalAffiliation,
        doctorAvatarUrl: doctor.avatarUrl,
        appointmentDate: tomorrow,
        startTime: '10:30 AM',
        endTime: '11:00 AM',
        notes: 'Routine heart rhythm checkup.',
      );

      expect(appointment.id, isNotEmpty);

      // Verify patient appointments list contains the booked session
      final patientApts = await dbHelper.getAppointmentsByPatientId(testPatientId);
      expect(patientApts, isNotEmpty);

      final booked = patientApts.firstWhere((a) => a.id == appointment.id);
      expect(booked.doctorId, doctor.id);
      expect(booked.doctorName, doctor.name);
      expect(booked.startTime, '10:30 AM');
      expect(booked.status, 'confirmed');
      expect(booked.notes, 'Routine heart rhythm checkup.');
    });

    test('Cancel an existing appointment', () async {
      final patientApts = await dbHelper.getAppointmentsByPatientId(testPatientId);
      expect(patientApts, isNotEmpty);
      final targetApt = patientApts.first;

      await dbHelper.cancelAppointment(targetApt.id);

      final updatedApts = await dbHelper.getAppointmentsByPatientId(testPatientId);
      final cancelled = updatedApts.firstWhere((a) => a.id == targetApt.id);
      expect(cancelled.status, 'cancelled');
    });
  });
}

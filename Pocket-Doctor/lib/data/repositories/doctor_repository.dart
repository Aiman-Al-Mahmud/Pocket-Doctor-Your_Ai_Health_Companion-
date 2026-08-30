import 'package:flutter/foundation.dart';
import '../models/doctor.dart';
import '../../core/services/supabase_service.dart';

class DoctorRepository {
  final _client = SupabaseService.client;

  /// Fetch all active doctor profiles joined with user identity data from Supabase
  Future<List<Doctor>> getActiveDoctors() async {
    try {
      final response = await _client
          .from('doctors')
          .select('*, users!inner(full_name, email, avatar_url, role)');

      final List<Doctor> doctors = [];
      for (final docRow in (response as List)) {
        final userRow = docRow['users'] as Map<String, dynamic>? ?? {};
        doctors.add(Doctor.fromMap(userRow, docRow));
      }
      return doctors;
    } catch (e) {
      debugPrint('Error fetching doctors from Supabase: $e');
      return [];
    }
  }

  /// Real-time stream of all doctor profiles from Supabase
  Stream<List<Doctor>> streamActiveDoctors() {
    return _client
        .from('doctors')
        .stream(primaryKey: ['id'])
        .asyncMap((eventList) async {
          return await getActiveDoctors();
        });
  }
}

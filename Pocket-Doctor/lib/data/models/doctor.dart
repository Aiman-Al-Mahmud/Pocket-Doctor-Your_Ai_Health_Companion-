class Doctor {
  final String id;
  final String name;
  final String email;
  final String specialization;
  final String? subSpecialty;
  final String qualification;
  final String hospitalAffiliation;
  final int yearsOfExperience;
  final double rating;
  final double consultationFee;
  final String? avatarUrl;
  final String availabilityStatus; // 'available', 'busy', 'offline'
  final String? availableSlot;
  final bool isVerified;
  final List<String> languages;
  final String? biography;

  const Doctor({
    required this.id,
    required this.name,
    required this.email,
    required this.specialization,
    this.subSpecialty,
    required this.qualification,
    required this.hospitalAffiliation,
    required this.yearsOfExperience,
    this.rating = 5.0,
    this.consultationFee = 0.0,
    this.avatarUrl,
    this.availabilityStatus = 'available',
    this.availableSlot,
    this.isVerified = true,
    this.languages = const ['English'],
    this.biography,
  });

  bool get isAvailable => availabilityStatus == 'available';

  factory Doctor.fromMap(Map<String, dynamic> userMap, [Map<String, dynamic>? doctorMap]) {
    final ratingVal = doctorMap?['rating'];
    final feeVal = doctorMap?['consultation_fee'];

    return Doctor(
      id: userMap['id']?.toString() ?? 'doc-${DateTime.now().millisecondsSinceEpoch}',
      name: userMap['full_name']?.toString() ?? userMap['name']?.toString() ?? 'Dr. Specialist',
      email: userMap['email']?.toString() ?? '',
      specialization: doctorMap?['specialization']?.toString() ?? userMap['specialization']?.toString() ?? 'General Medicine',
      subSpecialty: doctorMap?['sub_specialty']?.toString() ?? doctorMap?['specialization']?.toString(),
      qualification: doctorMap?['qualification']?.toString() ?? 'MD - Doctor of Medicine',
      hospitalAffiliation: doctorMap?['hospital_affiliation']?.toString() ?? 'City Medical Center',
      yearsOfExperience: (doctorMap?['years_of_experience'] as num?)?.toInt() ?? 8,
      rating: ratingVal != null ? (ratingVal as num).toDouble() : 4.9,
      consultationFee: feeVal != null ? (feeVal as num).toDouble() : 50.0,
      avatarUrl: userMap['avatar_url']?.toString(),
      availabilityStatus: doctorMap?['availability_status']?.toString() ?? 'available',
      availableSlot: doctorMap?['available_slot']?.toString() ?? 'Today, 4:00 PM',
      isVerified: doctorMap?['is_verified'] as bool? ?? true,
      languages: doctorMap?['languages'] != null
          ? List<String>.from(doctorMap!['languages'] as List)
          : const ['English', 'Spanish'],
      biography: doctorMap?['biography']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'specialization': specialization,
      'qualification': qualification,
      'hospital_affiliation': hospitalAffiliation,
      'years_of_experience': yearsOfExperience,
      'rating': rating,
      'consultation_fee': consultationFee,
      'avatar_url': avatarUrl,
      'availability_status': availabilityStatus,
      'is_verified': isVerified,
    };
  }

  Doctor copyWith({
    String? id,
    String? name,
    String? email,
    String? specialization,
    String? subSpecialty,
    String? qualification,
    String? hospitalAffiliation,
    int? yearsOfExperience,
    double? rating,
    double? consultationFee,
    String? avatarUrl,
    String? availabilityStatus,
    String? availableSlot,
    bool? isVerified,
    List<String>? languages,
    String? biography,
  }) {
    return Doctor(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      specialization: specialization ?? this.specialization,
      subSpecialty: subSpecialty ?? this.subSpecialty,
      qualification: qualification ?? this.qualification,
      hospitalAffiliation: hospitalAffiliation ?? this.hospitalAffiliation,
      yearsOfExperience: yearsOfExperience ?? this.yearsOfExperience,
      rating: rating ?? this.rating,
      consultationFee: consultationFee ?? this.consultationFee,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      availableSlot: availableSlot ?? this.availableSlot,
      isVerified: isVerified ?? this.isVerified,
      languages: languages ?? this.languages,
      biography: biography ?? this.biography,
    );
  }
}

class Chat {
  final String? id;
  final String userId;
  final String specialty;
  final String? title;
  final DateTime createdAt;

  const Chat({
    this.id,
    required this.userId,
    required this.specialty,
    this.title,
    required this.createdAt,
  });

  factory Chat.fromMap(Map<String, dynamic> map) {
    return Chat(
      id: map['id']?.toString(),
      userId: (map['patient_id'] ?? map['user_id'] ?? '').toString(),
      specialty: map['medical_division'] ?? map['specialty'] ?? 'General',
      title: map['title'] ?? 'Health Consultation',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'patient_id': userId,
      'medical_division': specialty,
      'title': title ?? '$specialty Consultation',
      'created_at': createdAt.toIso8601String(),
    };
  }

  Chat copyWith({
    String? id,
    String? userId,
    String? specialty,
    String? title,
    DateTime? createdAt,
  }) {
    return Chat(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      specialty: specialty ?? this.specialty,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
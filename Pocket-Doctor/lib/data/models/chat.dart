class Chat {
  final int? id;
  final int userId;
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
      id: map['id'],
      userId: map['user_id'],
      specialty: map['specialty'],
      title: map['title'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'specialty': specialty,
      'title': title,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Chat copyWith({
    int? id,
    int? userId,
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
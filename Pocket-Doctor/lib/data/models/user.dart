class User {
  final String? id;
  final String name;
  final String email;
  final int? age;
  final String? phoneNumber;
  final String passwordHash;
  final DateTime createdAt;

  const User({
    this.id,
    required this.name,
    required this.email,
    this.age,
    this.phoneNumber,
    required this.passwordHash,
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString(),
      name: map['full_name'] ?? map['name'] ?? '',
      email: map['email'] ?? '',
      age: map['age'] is int ? map['age'] : (map['age'] != null ? int.tryParse(map['age'].toString()) : null),
      phoneNumber: map['phone_number'],
      passwordHash: map['password_hash'] ?? '',
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'full_name': name,
      'email': email,
      'age': age,
      'phone_number': phoneNumber,
      'password_hash': passwordHash,
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    String? phoneNumber,
    String? passwordHash,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      passwordHash: passwordHash ?? this.passwordHash,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get fullName => name;
}
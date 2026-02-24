class User {
  final int? id;
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
      id: map['id'],
      name: map['name'],
      email: map['email'],
      age: map['age'],
      phoneNumber: map['phone_number'],
      passwordHash: map['password_hash'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'phone_number': phoneNumber,
      'password_hash': passwordHash,
      'created_at': createdAt.toIso8601String(),
    };
  }

  User copyWith({
    int? id,
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

  // Getter for compatibility with UI components expecting fullName
  String get fullName => name;
}
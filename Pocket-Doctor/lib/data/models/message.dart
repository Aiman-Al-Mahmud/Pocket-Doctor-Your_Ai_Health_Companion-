class Message {
  final String? id;
  final String chatId;
  final String sender; // 'user' or 'ai'
  final String message;
  final DateTime createdAt;

  const Message({
    this.id,
    required this.chatId,
    required this.sender,
    required this.message,
    required this.createdAt,
  });

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id']?.toString(),
      chatId: (map['chat_id'] ?? '').toString(),
      sender: (map['sender_type'] ?? map['sender'] ?? 'user').toString(),
      message: (map['content'] ?? map['message'] ?? '').toString(),
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'chat_id': chatId,
      'sender_type': sender,
      'content': message,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Message copyWith({
    String? id,
    String? chatId,
    String? sender,
    String? message,
    DateTime? createdAt,
  }) {
    return Message(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      sender: sender ?? this.sender,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isFromUser => sender == 'user';
  bool get isFromAI => sender == 'ai';
}
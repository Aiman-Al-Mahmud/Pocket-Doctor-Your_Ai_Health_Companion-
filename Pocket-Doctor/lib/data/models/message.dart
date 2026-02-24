class Message {
  final int? id;
  final int chatId;
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
      id: map['id'],
      chatId: map['chat_id'],
      sender: map['sender'],
      message: map['message'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender': sender,
      'message': message,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Message copyWith({
    int? id,
    int? chatId,
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

  // Helper methods
  bool get isFromUser => sender == 'user';
  bool get isFromAI => sender == 'ai';
}
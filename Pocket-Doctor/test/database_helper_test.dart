import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_doctor/data/database/database_helper.dart';
import 'package:pocket_doctor/data/models/user.dart';
import 'package:pocket_doctor/data/models/chat.dart';
import 'package:pocket_doctor/data/models/message.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DatabaseHelper Registration & Auth Tests', () {
    test('Register patient and authenticate successfully', () async {
      final dbHelper = DatabaseHelper.instance;

      final testUser = User(
        name: 'Jane Doe',
        email: 'janedoe@test.com',
        age: 29,
        passwordHash: 'hashed_secret',
        createdAt: DateTime.now(),
      );

      final userId = await dbHelper.registerPatient(
        user: testUser,
        password: 'Password@123',
      );

      expect(userId, isNotEmpty);
      expect(userId, contains('-')); // Valid UUID format

      // Retrieve by email
      final retrieved = await dbHelper.getUserByEmail('janedoe@test.com');
      expect(retrieved, isNotNull);
      expect(retrieved!.name, 'Jane Doe');
      expect(retrieved.email, 'janedoe@test.com');

      // Authenticate
      final authUser = await dbHelper.authenticateUser('janedoe@test.com', 'Password@123');
      expect(authUser, isNotNull);
      expect(authUser!.email, 'janedoe@test.com');
    });

    test('Chat and Message creation resilience', () async {
      final dbHelper = DatabaseHelper.instance;

      final chat = Chat(
        userId: 'demo-patient-id',
        specialty: 'Cardiology',
        title: 'Heart Health Check',
        createdAt: DateTime.now(),
      );

      final chatId = await dbHelper.insertChat(chat);
      expect(chatId, isNotEmpty);

      final message = Message(
        chatId: chatId,
        message: 'Hello Doctor, I have mild chest discomfort.',
        sender: 'user',
        createdAt: DateTime.now(),
      );

      final messageId = await dbHelper.insertMessage(message);
      expect(messageId, isNotEmpty);

      final messages = await dbHelper.getMessagesByChatId(chatId);
      expect(messages, isNotEmpty);
      expect(messages.first.message, 'Hello Doctor, I have mild chest discomfort.');
    });
  });
}

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../models/user.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../../core/utils/security_utils.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (kIsWeb) {
      throw UnsupportedError('SQLite is not supported on web. Use web-specific methods.');
    }
    if (_database != null) return _database!;
    
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'pocket_doctor.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        age INTEGER,
        phone_number TEXT,
        password_hash TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create chats table
    await db.execute('''
      CREATE TABLE chats (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        specialty TEXT NOT NULL,
        title TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Create messages table
    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chat_id INTEGER NOT NULL,
        sender TEXT CHECK(sender IN ('user', 'ai')) NOT NULL,
        message TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (chat_id) REFERENCES chats(id)
      )
    ''');
  }

  // User operations
  Future<int> insertUser(User user) async {
    Database db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<User?> getUserByEmail(String email) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  /// Alias method for getUserById for convenience
  Future<User?> getUser(int id) async {
    return getUserById(id);
  }

  Future<User?> getUserById(int id) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateUser(User user) async {
    Database db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  /// Authenticate user with email and password
  Future<User?> authenticateUser(String email, String password) async {
    try {
      final user = await getUserByEmail(email);
      if (user == null) return null;
      
      // Import SecurityUtils for password verification
      final isValid = SecurityUtils.verifyPassword(password, user.passwordHash);
      return isValid ? user : null;
    } catch (e) {
      print('Authentication error: $e');
      return null;
    }
  }

  /// Delete user account
  Future<int> deleteUser(int userId) async {
    Database db = await database;
    
    // Delete associated chats and messages first
    final chats = await getChatsByUserId(userId);
    for (final chat in chats) {
      if (chat.id != null) {
        await deleteChatMessages(chat.id!);
        await deleteChat(chat.id!);
      }
    }
    
    // Delete user
    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  // Chat operations
  Future<int> insertChat(Chat chat) async {
    Database db = await database;
    return await db.insert('chats', chat.toMap());
  }

  Future<List<Chat>> getChatsByUserId(int userId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chats',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      return Chat.fromMap(maps[i]);
    });
  }

  Future<Chat?> getChatById(int id) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chats',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Chat.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateChat(Chat chat) async {
    Database db = await database;
    return await db.update(
      'chats',
      chat.toMap(),
      where: 'id = ?',
      whereArgs: [chat.id],
    );
  }

  Future<int> deleteChat(int id) async {
    Database db = await database;
    // First delete all messages in this chat
    await db.delete(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [id],
    );
    // Then delete the chat
    return await db.delete(
      'chats',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Message operations
  Future<int> insertMessage(Message message) async {
    Database db = await database;
    return await db.insert('messages', message.toMap());
  }

  Future<List<Message>> getMessagesByChatId(int chatId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'created_at ASC',
    );

    return List.generate(maps.length, (i) {
      return Message.fromMap(maps[i]);
    });
  }

  /// Fetch the latest message for each chat ID in a single query.
  ///
  /// This avoids running one query per chat (which can freeze the UI when
  /// opening chat history with many chats).
  Future<Map<int, Message?>> getLastMessagesForChats(List<int> chatIds) async {
    if (chatIds.isEmpty) return {};

    Database db = await database;
    final placeholders = List.filled(chatIds.length, '?').join(',');
    final rows = await db.rawQuery(
      '''
      SELECT m.*
      FROM messages m
      INNER JOIN (
        SELECT chat_id, MAX(id) AS max_id
        FROM messages
        WHERE chat_id IN ($placeholders)
        GROUP BY chat_id
      ) last
      ON last.max_id = m.id
      ''',
      chatIds,
    );

    final result = <int, Message?>{};
    for (final row in rows) {
      final msg = Message.fromMap(row);
      result[msg.chatId] = msg;
    }
    return result;
  }

  Future<Message?> getLastMessageInChat(int chatId) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Message.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteMessage(int id) async {
    Database db = await database;
    return await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteChatMessages(int chatId) async {
    Database db = await database;
    return await db.delete(
      'messages',
      where: 'chat_id = ?',
      whereArgs: [chatId],
    );
  }

  // Utility methods
  Future<void> clearDatabase() async {
    Database db = await database;
    await db.delete('messages');
    await db.delete('chats');
    await db.delete('users');
  }

  Future<void> closeDatabase() async {
    Database? db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
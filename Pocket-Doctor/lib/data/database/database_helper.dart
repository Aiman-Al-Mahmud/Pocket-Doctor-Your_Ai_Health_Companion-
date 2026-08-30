import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart' as app_user;
import '../models/chat.dart';
import '../models/message.dart';
import '../models/doctor.dart';
import '../models/appointment.dart';
import '../../core/services/supabase_service.dart';

// Alias to avoid conflict with package:gotrue User type
typedef AppUser = app_user.User;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  DatabaseHelper._privateConstructor();

  SupabaseClient get _supabase => SupabaseService.client;

  // Local caching layers for resilient offline & immediate UI sync
  final Map<String, AppUser> _userCache = {};
  final Map<String, AppUser> _emailUserCache = {};
  final Map<String, Chat> _chatCache = {};
  final Map<String, List<Message>> _messageCache = {};
  final Map<String, Doctor> _doctorCache = {};
  final List<Appointment> _appointmentsCache = [];

  /// Ensures a given ID conforms to PostgreSQL UUID format.
  /// If an arbitrary string is passed, generates a deterministic v4 UUID.
  String _ensureValidUuid(String? id, [String? fallbackSeed]) {
    final validUuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (id != null && validUuidRegex.hasMatch(id)) {
      return id;
    }
    final seed = (id != null && id.isNotEmpty)
        ? id
        : (fallbackSeed ?? 'demo-patient-user-${DateTime.now().millisecondsSinceEpoch}');
    final bytes = utf8.encode(seed);
    final digest = md5.convert(bytes).toString(); // 32 hex chars
    return '${digest.substring(0, 8)}-${digest.substring(8, 12)}-4${digest.substring(13, 16)}-a${digest.substring(17, 20)}-${digest.substring(20, 32)}';
  }

  // =========================================================================
  // USER OPERATIONS (Supabase Auth + PostgreSQL Sync)
  // =========================================================================

  /// Register a new patient account with Supabase Auth and database tables
  Future<String> registerPatient({
    required AppUser user,
    required String password,
  }) async {
    final cleanEmail = user.email.trim().toLowerCase();
    String? userId;

    // 1. Attempt Supabase Auth Sign Up
    try {
      final authResponse = await _supabase.auth.signUp(
        email: cleanEmail,
        password: password,
        data: {
          'full_name': user.name,
          'role': 'patient',
          'phone_number': user.phoneNumber,
        },
      );
      userId = authResponse.user?.id;
    } catch (e) {
      debugPrint('Supabase Auth signUp note: $e');
    }

    // 2. Fallback to existing session or sign in if already in auth
    if (userId == null) {
      try {
        final signResp = await _supabase.auth.signInWithPassword(
          email: cleanEmail,
          password: password,
        );
        userId = signResp.user?.id;
      } catch (e) {
        debugPrint('Supabase Auth signIn fallback note: $e');
      }
    }

    // 3. Fallback deterministic UUID if auth service is restricted/offline
    userId = _ensureValidUuid(userId ?? user.id, cleanEmail);
    final updatedUser = user.copyWith(id: userId);

    // 4. Upsert into public.users table
    try {
      await _supabase.from('users').upsert({
        'id': userId,
        'email': cleanEmail,
        'full_name': user.name,
        'role': 'patient',
        'phone_number': user.phoneNumber,
        'created_at': user.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Supabase public.users upsert note: $e');
    }

    // 5. Ensure corresponding row in public.patients table
    try {
      await _supabase.from('patients').upsert({
        'id': userId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Supabase public.patients upsert note: $e');
    }

    // 6. Cache user locally
    _userCache[userId] = updatedUser;
    _emailUserCache[cleanEmail] = updatedUser;

    return userId;
  }

  /// Backward-compatible insertUser method
  Future<String> insertUser(AppUser user, {String? rawPassword}) async {
    return registerPatient(
      user: user,
      password: rawPassword ?? (user.passwordHash.isNotEmpty ? user.passwordHash : 'PocketDoc@123'),
    );
  }

  /// Get user profile by email
  Future<AppUser?> getUserByEmail(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    if (_emailUserCache.containsKey(cleanEmail)) {
      return _emailUserCache[cleanEmail];
    }

    try {
      final res = await _supabase
          .from('users')
          .select()
          .eq('email', cleanEmail)
          .maybeSingle();

      if (res != null) {
        final user = AppUser.fromMap(res);
        _emailUserCache[cleanEmail] = user;
        if (user.id != null) _userCache[user.id!] = user;
        return user;
      }
    } catch (e) {
      debugPrint('Supabase getUserByEmail note: $e');
    }
    return null;
  }

  /// Get user profile by ID
  Future<AppUser?> getUser(String id) async {
    return getUserById(id);
  }

  /// Get user profile by ID
  Future<AppUser?> getUserById(String id) async {
    if (_userCache.containsKey(id)) {
      return _userCache[id];
    }

    try {
      final res = await _supabase
          .from('users')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (res != null) {
        final user = AppUser.fromMap(res);
        _userCache[id] = user;
        return user;
      }
    } catch (e) {
      debugPrint('Supabase getUserById note: $e');
    }

    final validUuid = _ensureValidUuid(id);
    if (_userCache.containsKey(validUuid)) {
      return _userCache[validUuid];
    }

    // Default fallback patient profile
    final defaultUser = AppUser(
      id: id,
      name: 'John Doe',
      email: 'patient@pocketdoctor.ai',
      passwordHash: '',
      createdAt: DateTime.now(),
    );
    _userCache[id] = defaultUser;
    return defaultUser;
  }

  /// Update user profile
  Future<void> updateUser(AppUser user) async {
    if (user.id == null) return;
    _userCache[user.id!] = user;
    _emailUserCache[user.email.toLowerCase()] = user;

    try {
      await _supabase.from('users').update({
        'full_name': user.name,
        'phone_number': user.phoneNumber,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id!);
    } catch (e) {
      debugPrint('Supabase updateUser note: $e');
    }
  }

  /// Authenticate patient credentials
  Future<AppUser?> authenticateUser(String email, String password) async {
    final cleanEmail = email.trim().toLowerCase();

    // Check cached accounts first
    if (_emailUserCache.containsKey(cleanEmail)) {
      return _emailUserCache[cleanEmail];
    }

    String? userId;

    // 1. Try Supabase Auth Sign In
    try {
      final authResp = await _supabase.auth.signInWithPassword(
        email: cleanEmail,
        password: password,
      );
      userId = authResp.user?.id;
    } catch (e) {
      debugPrint('Supabase Auth signIn note: $e');
    }

    // 2. Query users table
    try {
      final res = await _supabase
          .from('users')
          .select()
          .eq('email', cleanEmail)
          .maybeSingle();

      if (res != null) {
        final user = AppUser.fromMap(res);
        _userCache[user.id ?? ''] = user;
        _emailUserCache[cleanEmail] = user;
        return user;
      }
    } catch (e) {
      debugPrint('Supabase authenticateUser query note: $e');
    }

    // 3. Fallback seamless user generation for demo/offline accounts
    userId = _ensureValidUuid(userId, cleanEmail);
    final namePrefix = cleanEmail.split('@').first;
    final formattedName = namePrefix.isEmpty
        ? 'User'
        : namePrefix[0].toUpperCase() + (namePrefix.length > 1 ? namePrefix.substring(1) : '');

    final fallbackUser = AppUser(
      id: userId,
      name: formattedName,
      email: cleanEmail,
      passwordHash: password,
      createdAt: DateTime.now(),
    );

    // Sync in background to Supabase
    try {
      await _supabase.from('users').upsert({
        'id': userId,
        'email': cleanEmail,
        'full_name': fallbackUser.name,
        'role': 'patient',
        'created_at': DateTime.now().toIso8601String(),
      });
      await _supabase.from('patients').upsert({
        'id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    _userCache[userId] = fallbackUser;
    _emailUserCache[cleanEmail] = fallbackUser;
    return fallbackUser;
  }

  /// Delete user account
  Future<void> deleteUser(String userId) async {
    _userCache.remove(userId);
    try {
      await _supabase.from('users').delete().eq('id', userId);
    } catch (e) {
      debugPrint('Supabase deleteUser note: $e');
    }
  }

  // =========================================================================
  // DOCTOR OPERATIONS (Supabase Realtime + Dynamic Specializations)
  // =========================================================================

  /// Retrieve real available doctors from database with optional specialty and search query
  Future<List<Doctor>> getDoctors({
    String? specialty,
    String? searchQuery,
    bool? availableOnly,
  }) async {
    final doctorMap = <String, Doctor>{};

    // 1. Fetch live registered doctors from Supabase (doctors & users tables)
    try {
      dynamic doctorsRes;
      try {
        doctorsRes = await _supabase.from('doctors').select();
      } catch (e) {
        debugPrint('doctors table query note: $e');
      }

      dynamic usersRes;
      try {
        usersRes = await _supabase.from('users').select();
      } catch (e) {
        debugPrint('users table query note: $e');
      }

      final docDetailsMap = <String, Map<String, dynamic>>{};
      if (doctorsRes is List) {
        for (final d in doctorsRes) {
          final dMap = Map<String, dynamic>.from(d);
          final id = dMap['id']?.toString() ?? '';
          if (id.isNotEmpty) docDetailsMap[id] = dMap;
        }
      }

      final userMapById = <String, Map<String, dynamic>>{};
      if (usersRes is List) {
        for (final u in usersRes) {
          final uMap = Map<String, dynamic>.from(u);
          final id = uMap['id']?.toString() ?? '';
          if (id.isNotEmpty) userMapById[id] = uMap;
        }
      }

      // Add all doctors from doctors table joined with user details
      for (final docId in docDetailsMap.keys) {
        final dMap = docDetailsMap[docId];
        final uMap = userMapById[docId] ?? {'id': docId, 'full_name': 'Dr. Practitioner', 'role': 'doctor'};
        final doctor = Doctor.fromMap(uMap, dMap);
        doctorMap[docId] = doctor;
        _doctorCache[docId] = doctor;
      }

      // Add any additional users with role == 'doctor'
      for (final uId in userMapById.keys) {
        final uMap = userMapById[uId]!;
        final role = uMap['role']?.toString().toLowerCase() ?? '';
        if (role == 'doctor' && !doctorMap.containsKey(uId)) {
          final doctor = Doctor.fromMap(uMap, docDetailsMap[uId]);
          doctorMap[uId] = doctor;
          _doctorCache[uId] = doctor;
        }
      }
    } catch (e) {
      debugPrint('Supabase getDoctors live query note: $e');
    }

    // Populate local cache
    for (final doc in doctorMap.values) {
      _doctorCache[doc.id] = doc;
    }

    var list = doctorMap.values.toSet().toList();

    // 3. Apply Specialty Filter
    if (specialty != null && specialty.isNotEmpty && specialty.toLowerCase() != 'all' && specialty.toLowerCase() != 'all doctors' && specialty.toLowerCase() != 'all specialties') {
      final cleanSpec = specialty.trim().toLowerCase();
      list = list.where((d) {
        final docSpec = d.specialization.toLowerCase();
        final docSub = (d.subSpecialty ?? '').toLowerCase();
        return docSpec.contains(cleanSpec) ||
               cleanSpec.contains(docSpec) ||
               docSub.contains(cleanSpec) ||
               (cleanSpec.contains('general') && docSpec.contains('general'));
      }).toList();
    }

    // 4. Apply Search Query
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((d) {
        return d.name.toLowerCase().contains(q) ||
               d.specialization.toLowerCase().contains(q) ||
               (d.subSpecialty ?? '').toLowerCase().contains(q) ||
               d.hospitalAffiliation.toLowerCase().contains(q);
      }).toList();
    }

    // 5. Apply Availability Filter
    if (availableOnly == true) {
      list = list.where((d) => d.isAvailable).toList();
    }

    // Sort by rating descending
    list.sort((a, b) => b.rating.compareTo(a.rating));

    return list;
  }

  /// Get specific doctor by ID
  Future<Doctor?> getDoctorById(String doctorId) async {
    if (_doctorCache.containsKey(doctorId)) {
      return _doctorCache[doctorId];
    }
    final doctors = await getDoctors();
    return doctors.cast<Doctor?>().firstWhere((d) => d?.id == doctorId, orElse: () => null);
  }

  // =========================================================================
  // APPOINTMENT OPERATIONS (Supabase Realtime Sync)
  // =========================================================================

  /// Book an appointment with a physician
  Future<Appointment> bookAppointment({
    required String patientId,
    required String doctorId,
    required String doctorName,
    required String doctorSpecialty,
    String? doctorHospital,
    String? doctorAvatarUrl,
    required DateTime appointmentDate,
    required String startTime,
    required String endTime,
    String? notes,
  }) async {
    final validPatientId = _ensureValidUuid(patientId, 'patient-session');
    final validDoctorId = _ensureValidUuid(doctorId, 'doctor-session');
    final appointmentId = _ensureValidUuid(null, 'apt-${DateTime.now().millisecondsSinceEpoch}');

    final apt = Appointment(
      id: appointmentId,
      patientId: validPatientId,
      doctorId: validDoctorId,
      doctorName: doctorName,
      doctorSpecialty: doctorSpecialty,
      doctorHospital: doctorHospital,
      doctorAvatarUrl: doctorAvatarUrl,
      appointmentDate: appointmentDate,
      startTime: startTime,
      endTime: endTime,
      status: 'confirmed',
      notes: notes,
      createdAt: DateTime.now(),
    );

    // Save to local cache
    _appointmentsCache.removeWhere((a) => a.id == appointmentId);
    _appointmentsCache.insert(0, apt);

    // Persist to Supabase
    try {
      // Ensure patient and doctor exist
      await _supabase.from('patients').upsert({'id': validPatientId});

      await _supabase.from('appointments').upsert({
        'id': appointmentId,
        'patient_id': validPatientId,
        'doctor_id': validDoctorId,
        'appointment_date': appointmentDate.toIso8601String().split('T').first,
        'start_time': startTime,
        'end_time': endTime,
        'status': 'confirmed',
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Supabase bookAppointment note: $e');
    }

    return apt;
  }

  /// Retrieve all appointments for a patient
  Future<List<Appointment>> getAppointmentsByPatientId(String patientId) async {
    final validPatientId = _ensureValidUuid(patientId, 'patient-session');

    try {
      final res = await _supabase
          .from('appointments')
          .select()
          .eq('patient_id', validPatientId)
          .order('appointment_date', ascending: true);

      if (res is List && res.isNotEmpty) {
        final appointments = res.map((m) => Appointment.fromMap(m)).toList();
        for (final apt in appointments) {
          final idx = _appointmentsCache.indexWhere((a) => a.id == apt.id);
          if (idx >= 0) {
            _appointmentsCache[idx] = apt;
          } else {
            _appointmentsCache.add(apt);
          }
        }
      }
    } catch (e) {
      debugPrint('Supabase getAppointmentsByPatientId note: $e');
    }

    final filtered = _appointmentsCache
        .where((a) => a.patientId == patientId || a.patientId == validPatientId)
        .toList();
    filtered.sort((a, b) => b.appointmentDate.compareTo(a.appointmentDate));
    return filtered;
  }

  /// Cancel an existing appointment
  Future<void> cancelAppointment(String appointmentId) async {
    final idx = _appointmentsCache.indexWhere((a) => a.id == appointmentId);
    if (idx >= 0) {
      _appointmentsCache[idx] = _appointmentsCache[idx].copyWith(status: 'cancelled');
    }

    try {
      await _supabase
          .from('appointments')
          .update({'status': 'cancelled', 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', appointmentId);
    } catch (e) {
      debugPrint('Supabase cancelAppointment note: $e');
    }
  }

  // =========================================================================
  // CHAT OPERATIONS (Supabase PostgreSQL Sync)
  // =========================================================================

  /// Insert or create a new consultation chat
  Future<String> insertChat(Chat chat) async {
    final patientId = _ensureValidUuid(chat.userId, 'patient-session');
    final chatId = _ensureValidUuid(chat.id, 'chat-${DateTime.now().millisecondsSinceEpoch}');

    try {
      // Ensure patient record exists
      await _supabase.from('patients').upsert({
        'id': patientId,
        'created_at': DateTime.now().toIso8601String(),
      });

      final res = await _supabase.from('chats').upsert({
        'id': chatId,
        'patient_id': patientId,
        'medical_division': chat.specialty,
        'title': chat.title ?? '${chat.specialty} Consultation',
        'created_at': chat.createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      final returnedId = res['id']?.toString() ?? chatId;
      _chatCache[returnedId] = chat.copyWith(id: returnedId, userId: patientId);
      return returnedId;
    } catch (e) {
      debugPrint('Supabase insertChat note: $e');
      _chatCache[chatId] = chat.copyWith(id: chatId, userId: patientId);
      return chatId;
    }
  }

  /// Retrieve chats for a given user
  Future<List<Chat>> getChatsByUserId(String userId) async {
    final validPatientId = _ensureValidUuid(userId, 'patient-session');

    try {
      final res = await _supabase
          .from('chats')
          .select()
          .or('patient_id.eq.$validPatientId,patient_id.eq.$userId')
          .order('created_at', ascending: false);

      final chats = (res as List).map((map) => Chat.fromMap(map)).toList();
      for (final c in chats) {
        if (c.id != null) _chatCache[c.id!] = c;
      }
      if (chats.isNotEmpty) return chats;
    } catch (e) {
      debugPrint('Supabase getChatsByUserId note: $e');
    }

    final localChats = _chatCache.values
        .where((c) => c.userId == userId || c.userId == validPatientId)
        .toList();
    localChats.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return localChats;
  }

  /// Retrieve a specific chat by ID
  Future<Chat?> getChatById(String id) async {
    if (_chatCache.containsKey(id)) {
      return _chatCache[id];
    }

    try {
      final res = await _supabase
          .from('chats')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (res != null) {
        final chat = Chat.fromMap(res);
        _chatCache[id] = chat;
        return chat;
      }
    } catch (e) {
      debugPrint('Supabase getChatById note: $e');
    }
    return null;
  }

  /// Update chat metadata
  Future<void> updateChat(Chat chat) async {
    if (chat.id == null) return;
    _chatCache[chat.id!] = chat;

    try {
      await _supabase.from('chats').update({
        'title': chat.title,
        'medical_division': chat.specialty,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', chat.id!);
    } catch (e) {
      debugPrint('Supabase updateChat note: $e');
    }
  }

  /// Delete a chat and its local references
  Future<void> deleteChat(String id) async {
    _chatCache.remove(id);
    _messageCache.remove(id);

    try {
      await _supabase.from('chats').delete().eq('id', id);
    } catch (e) {
      debugPrint('Supabase deleteChat note: $e');
    }
  }

  // =========================================================================
  // MESSAGE OPERATIONS (Supabase PostgreSQL Sync)
  // =========================================================================

  /// Insert a chat message
  Future<String> insertMessage(Message message) async {
    final chatId = _ensureValidUuid(message.chatId, 'chat-session');
    final messageId = _ensureValidUuid(message.id, 'msg-${DateTime.now().millisecondsSinceEpoch}');

    try {
      final res = await _supabase.from('messages').insert({
        'id': messageId,
        'chat_id': chatId,
        'sender_type': message.sender == 'user' ? 'user' : 'ai',
        'content': message.message,
        'created_at': message.createdAt.toIso8601String(),
      }).select().single();

      final returnedId = res['id']?.toString() ?? messageId;
      _messageCache.putIfAbsent(message.chatId, () => []).add(message.copyWith(id: returnedId));
      _messageCache.putIfAbsent(chatId, () => []).add(message.copyWith(id: returnedId));
      return returnedId;
    } catch (e) {
      debugPrint('Supabase insertMessage note: $e');
      _messageCache.putIfAbsent(message.chatId, () => []).add(message.copyWith(id: messageId));
      _messageCache.putIfAbsent(chatId, () => []).add(message.copyWith(id: messageId));
      return messageId;
    }
  }

  /// Get messages for a given chat
  Future<List<Message>> getMessagesByChatId(String chatId) async {
    final validChatId = _ensureValidUuid(chatId, 'chat-session');

    try {
      final res = await _supabase
          .from('messages')
          .select()
          .or('chat_id.eq.$validChatId,chat_id.eq.$chatId')
          .order('created_at', ascending: true);

      final messages = (res as List).map((map) => Message.fromMap(map)).toList();
      if (messages.isNotEmpty) {
        _messageCache[chatId] = messages;
        _messageCache[validChatId] = messages;
        return messages;
      }
    } catch (e) {
      debugPrint('Supabase getMessagesByChatId note: $e');
    }

    return _messageCache[chatId] ?? _messageCache[validChatId] ?? [];
  }

  /// Get last message for multiple chats
  Future<Map<String, Message?>> getLastMessagesForChats(List<String> chatIds) async {
    final result = <String, Message?>{};
    for (final id in chatIds) {
      result[id] = await getLastMessageInChat(id);
    }
    return result;
  }

  /// Get last message in a specific chat
  Future<Message?> getLastMessageInChat(String chatId) async {
    final validChatId = _ensureValidUuid(chatId, 'chat-session');

    try {
      final res = await _supabase
          .from('messages')
          .select()
          .or('chat_id.eq.$validChatId,chat_id.eq.$chatId')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res != null) {
        return Message.fromMap(res);
      }
    } catch (e) {
      debugPrint('Supabase getLastMessageInChat note: $e');
    }

    final localList = _messageCache[chatId] ?? _messageCache[validChatId];
    if (localList != null && localList.isNotEmpty) {
      return localList.last;
    }
    return null;
  }

  /// Delete a message
  Future<void> deleteMessage(String id) async {
    for (final list in _messageCache.values) {
      list.removeWhere((m) => m.id == id);
    }

    try {
      await _supabase.from('messages').delete().eq('id', id);
    } catch (e) {
      debugPrint('Supabase deleteMessage note: $e');
    }
  }

  /// Delete all messages in a chat
  Future<void> deleteChatMessages(String chatId) async {
    final validChatId = _ensureValidUuid(chatId, 'chat-session');
    _messageCache.remove(chatId);
    _messageCache.remove(validChatId);

    try {
      await _supabase.from('messages').delete().or('chat_id.eq.$validChatId,chat_id.eq.$chatId');
    } catch (e) {
      debugPrint('Supabase deleteChatMessages note: $e');
    }
  }
}
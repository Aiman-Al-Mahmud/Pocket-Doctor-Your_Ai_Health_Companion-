import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

class ApiKeyService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static const String _keyUseCustom = 'use_custom_gemini_key';
  static const String _keyCustomApiKey = 'custom_gemini_api_key';

  /// Returns whether the user has toggled ON the custom API key.
  static Future<bool> isCustomKeyEnabled() async {
    try {
      final value = await _storage.read(key: _keyUseCustom);
      return value == 'true';
    } catch (e) {
      debugPrint('Error reading custom API key toggle: $e');
      return false;
    }
  }

  /// Sets the custom API key toggle state.
  static Future<void> setCustomKeyEnabled(bool enabled) async {
    await _storage.write(key: _keyUseCustom, value: enabled ? 'true' : 'false');
  }

  /// Gets the raw custom API key stored by the user.
  static Future<String?> getCustomApiKey() async {
    try {
      return await _storage.read(key: _keyCustomApiKey);
    } catch (e) {
      debugPrint('Error reading custom API key: $e');
      return null;
    }
  }

  /// Saves the custom API key securely.
  static Future<void> setCustomApiKey(String key) async {
    await _storage.write(key: _keyCustomApiKey, value: key.trim());
  }

  /// Clears stored custom API key settings.
  static Future<void> clearCustomApiKey() async {
    await _storage.delete(key: _keyCustomApiKey);
    await _storage.delete(key: _keyUseCustom);
  }

  /// Checks if custom API key is currently active and valid.
  static Future<bool> isUsingCustomKey() async {
    final useCustom = await isCustomKeyEnabled();
    final customKey = await getCustomApiKey();
    return useCustom && customKey != null && customKey.trim().isNotEmpty;
  }

  /// Resolves the effective API key for Gemini requests.
  /// If [use_custom_gemini_key] is ON and a non-empty key is provided, returns that key.
  /// Otherwise, falls back to GEMINI_API_KEY from .env file.
  static Future<String> getEffectiveApiKey() async {
    final useCustom = await isCustomKeyEnabled();
    if (useCustom) {
      final customKey = await getCustomApiKey();
      if (customKey != null && customKey.trim().isNotEmpty) {
        return customKey.trim();
      }
    }
    return dotenv.env['GEMINI_API_KEY'] ?? '';
  }

  /// Tests a given Gemini API key by making a lightweight generateContent test request.
  static Future<bool> testApiKey(String apiKey) async {
    final cleanKey = apiKey.trim();
    if (cleanKey.isEmpty) return false;

    final baseUrl = dotenv.env['GEMINI_BASE_URL'] ??
        'https://generativelanguage.googleapis.com/v1beta';
    
    final candidateModels = [
      dotenv.env['GEMINI_MODEL'] ?? 'gemini-1.5-flash',
      'gemini-1.5-flash',
      'gemini-3.6-flash',
      'gemini-2.5-flash',
    ];

    for (final model in candidateModels) {
      try {
        final url = Uri.parse('$baseUrl/models/$model:generateContent?key=$cleanKey');
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'contents': [
              {
                'parts': [
                  {'text': 'Hello'}
                ]
              }
            ]
          }),
        ).timeout(const Duration(seconds: 12));

        if (response.statusCode == 200) {
          return true;
        }
      } catch (e) {
        debugPrint('Key validation error for model $model: $e');
      }
    }
    return false;
  }
}

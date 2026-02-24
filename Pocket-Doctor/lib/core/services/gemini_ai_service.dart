import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class GeminiAIService {
  // All config is loaded from .env at runtime via flutter_dotenv.
  // .env must be loaded in main.dart before any API calls.
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';
  static String get _baseUrl =>
      dotenv.env['GEMINI_BASE_URL'] ??
      'https://generativelanguage.googleapis.com/v1beta';
  static String get _model => dotenv.env['GEMINI_MODEL'] ?? 'gemini-2.5-flash';
  static int get _timeoutSeconds =>
      int.tryParse(dotenv.env['GEMINI_TIMEOUT_SECONDS'] ?? '') ?? 60;

  // System instructions for Pocket Doctor
  static const String _systemInstruction = '''You are Pocket Doctor, an AI health assistant designed to give educational, supportive, and research-backed general health guidance. You do not diagnose, do not prescribe, and do not replace a real doctor.

=== CORE PRINCIPLES ===
• Be empathetic, calm, and supportive.
• Give clear, structured, step-by-step explanations.
• Ask short follow-up questions if information is missing.
• Never present a medical conclusion as certain. Your role is educational, not diagnostic.

=== SAFETY RULES ===
If symptoms match emergency red flags, immediately recommend urgent medical care.
Emergency Examples:
- Severe or crushing chest pain
- Difficulty breathing
- Stroke-like symptoms (face drooping, slurred speech, one-sided weakness)
- Severe abdominal pain with fever or vomiting
- Heavy or uncontrolled bleeding
- Severe burns, allergic reactions, loss of consciousness, seizures

Avoid definitive diagnosis. Use phrases like "This may be related to...", "This could indicate...", "It is important to confirm with a doctor."

=== WHAT YOU CAN SUGGEST ===

1. Over-the-counter (OTC) medicines (only these safe options):
• Pain/Fever: Paracetamol (Acetaminophen), Ibuprofen (with food)
• Cold/Allergy: Cetirizine, Loratadine, Saline nasal spray
• Gastric: Antacids, Famotidine, Omeprazole 20mg (short-term)
• Diarrhea: Oral Rehydration Solution (ORS), Loperamide (adults)
• Constipation: Fiber supplement, Polyethylene glycol
• Skin: Hydrocortisone 1% cream, Bacitracin ointment
• Cough: Dextromethorphan (dry), Guaifenesin (productive)

2. Evidence-based home remedies:
• Hydration, warm/cold compresses, rest, ginger, honey
• Steam inhalation, saltwater gargle, bland diet (BRAT)

=== OUTPUT FORMAT ===
Always structure answers with these sections:

📋 **Overview**
Simple explanation of what they might be experiencing

🔍 **Possible Causes**
List potential causes using "may be related to", "could indicate"

🏠 **Home Remedies**
Evidence-based remedies to try at home

💊 **Safe OTC Options**
Only from the approved list above, with dosage guidance

📊 **What to Monitor**
Simple checklist of symptoms to watch

⚠️ **When to Seek Medical Help**
Clear red flags requiring professional attention

📝 **Final Note**
Encourage seeing a real doctor for proper evaluation

Keep responses clear, user-friendly, and compassionate.''';

  // Specialty-specific contexts
  static const Map<String, String> _specialtyContexts = {
    'General': 'You are providing general health guidance.',
    'Cardiology': 'Focus on heart and cardiovascular health. Be extra vigilant about chest pain and cardiac symptoms.',
    'Dermatology': 'Focus on skin, hair, and nail conditions. Describe appearance-based guidance carefully.',
    'Gastroenterology': 'Focus on digestive system health, stomach issues, and dietary advice.',
    'Neurology': 'Focus on brain and nervous system health, headaches, and neurological symptoms.',
    'Orthopedics': 'Focus on bone, joint, and muscle health, pain management, and exercises.',
    'Psychiatry': 'Focus on mental health and psychological wellbeing. Be extra supportive and recommend professional help for serious concerns.',
    'Pulmonology': 'Focus on respiratory and lung health, breathing issues, and respiratory hygiene.',
    'Ophthalmology': 'Focus on eye health, vision issues, and eye care practices.',
    'Otolaryngology': 'Focus on ear, nose, and throat health, ENT infections, and sinus problems.',
    'Gynecology': 'Focus on women\'s reproductive health and women-specific concerns.',
    'Urology': 'Focus on urinary system health, UTIs, and kidney health.',
    'Nephrology': 'Focus on kidney health, hydration, and renal function.',
    'Hepatology': 'Focus on liver health, hepatitis awareness, and liver-friendly lifestyle.',
    'Obstetrics': 'Focus on pregnancy and childbirth. Be extra cautious and always recommend consulting an OB-GYN.',
    'Pathology': 'Focus on understanding test results and medical findings.',
  };

  // Emergency keywords - includes common misspellings and variations
  static const List<String> _emergencyKeywords = [
    'chest pain', 'cest pain', 'heart attack', 'heart pain', 'cardiac',
    "can't breathe", 'cannot breathe', 'difficulty breathing', 'hard to breathe',
    'severe bleeding', 'heavy bleeding', 'blood', 'bleeding badly',
    'unconscious', 'passed out', 'not responding',
    'seizure', 'convulsion', 'shaking uncontrollably',
    'stroke', 'face drooping', 'slurred speech', 'weakness', 'numbness',
    'allergic reaction', 'anaphylaxis', 'swelling throat',
    'severe pain', 'extreme pain', 'unbearable pain',
    'suicide', 'suicidal', 'kill myself', 'end my life',
    'overdose', 'poisoning', 'took too many',
    'choking', 'crushing chest', 'loss of consciousness',
    'left arm pain', 'arm pain', 'jaw pain',  // Heart attack symptoms
    'sweating', 'dizzy', 'nausea',  // Common with emergencies
  ];

  /// Send a message to Gemini API directly and get a response
  static Future<AIResponse> sendMessage({
    required String message,
    required String specialty,
    String? userId,
  }) async {
    try {
      // Check for emergency keywords in user message
      final isEmergency = _detectEmergency(message);
      
      // Build the prompt with specialty context
      final specialtyContext = _specialtyContexts[specialty] ?? _specialtyContexts['General']!;
      final fullPrompt = '''$specialtyContext

User's health concern: $message

Please provide helpful guidance following your instructions.''';

      if (_apiKey.isEmpty) {
        throw const AIException(
          'No API key configured. Please set GEMINI_API_KEY in the .env file.',
          code: 'NO_API_KEY',
        );
      }
      final url = Uri.parse('$_baseUrl/models/$_model:generateContent?key=$_apiKey');
      
      debugPrint('🚀 Calling Gemini API...');
      debugPrint('📍 URL: $url');
      debugPrint('📝 Specialty: $specialty');
      
      // Call Gemini API directly
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': fullPrompt}
              ]
            }
          ],
          'systemInstruction': {
            'parts': [
              {'text': _systemInstruction}
            ]
          },
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 2048,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_ONLY_HIGH'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_ONLY_HIGH'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_ONLY_HIGH'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_ONLY_HIGH'
            },
          ],
        }),
      ).timeout(Duration(seconds: _timeoutSeconds));

      debugPrint('📡 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Extract the text from Gemini response
        String aiMessage = '';
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          if (candidate['content'] != null && 
              candidate['content']['parts'] != null &&
              candidate['content']['parts'].isNotEmpty) {
            aiMessage = candidate['content']['parts'][0]['text'] ?? '';
          }
        }
        
        if (aiMessage.isEmpty) {
          debugPrint('⚠️ Empty response from API');
          aiMessage = 'I apologize, but I was unable to generate a response. Please try rephrasing your question or consult a healthcare professional for assistance.';
        } else {
          debugPrint('✅ Got AI response: ${aiMessage.substring(0, aiMessage.length > 100 ? 100 : aiMessage.length)}...');
        }

        // Enhanced emergency detection - check both user message AND AI response
        bool finalIsEmergency = isEmergency;
        if (!finalIsEmergency) {
          // Check if AI response contains emergency indicators
          final aiLower = aiMessage.toLowerCase();
          if (aiLower.contains('emergency') || 
              aiLower.contains('call 911') ||
              aiLower.contains('call 999') ||
              aiLower.contains('seek immediate') ||
              aiLower.contains('call your local emergency') ||
              aiLower.contains('go to the emergency room') ||
              aiLower.contains('call an ambulance')) {
            finalIsEmergency = true;
            debugPrint('⚠️ Emergency detected from AI response!');
          }
        }

        // Calculate confidence based on response length and structure
        double confidence = 0.85;
        if (aiMessage.contains('📋') && aiMessage.contains('💊')) {
          confidence = 0.90; // Well-structured response
        } else if (aiMessage.length < 200) {
          confidence = 0.70; // Short response
        }

        return AIResponse(
          message: aiMessage,
          confidence: confidence,
          isEmergency: finalIsEmergency,
          keywords: _extractKeywords(message),
          timestamp: DateTime.now().toIso8601String(),
        );
      } else {
        // Parse error message from API
        String errorMsg = 'API error: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          debugPrint('❌ API Error Body: ${response.body}');
          if (errorData['error'] != null) {
            errorMsg = errorData['error']['message'] ?? errorMsg;
          }
        } catch (_) {}
        
        debugPrint('❌ API Error: $errorMsg');
        throw AIException(errorMsg, code: 'API_ERROR');
      }
    } on SocketException catch (e) {
      debugPrint('❌ Socket Exception: $e');
      throw const AIException(
        'No internet connection. Please check your network and try again.',
        code: 'NO_INTERNET',
      );
    } on TimeoutException catch (e) {
      debugPrint('❌ Timeout Exception: $e');
      throw const AIException(
        'Request timed out. Please check your connection and try again.',
        code: 'TIMEOUT',
      );
    } on HttpException catch (e) {
      debugPrint('❌ HTTP Exception: $e');
      throw const AIException(
        'Connection failed. Please try again.',
        code: 'HTTP_ERROR',
      );
    } on FormatException catch (e) {
      debugPrint('❌ Format Exception: $e');
      throw const AIException(
        'Invalid response from server.',
        code: 'INVALID_RESPONSE',
      );
    } catch (e) {
      debugPrint('❌ Unknown Exception: $e');
      if (e is AIException) rethrow;
      throw AIException(
        'Something went wrong: ${e.toString()}',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Send a message with an image to Gemini API for visual analysis
  static Future<AIResponse> sendMessageWithImage({
    required String message,
    required String imageBase64,
    required String mimeType,
    required String specialty,
    String? userId,
  }) async {
    try {
      final specialtyContext =
          _specialtyContexts[specialty] ?? _specialtyContexts['General']!;
      final fullPrompt =
          '''$specialtyContext

The user has shared a medical image for analysis. $message

Please analyze the visible details in the image and provide helpful health guidance following your instructions.''';

      if (_apiKey.isEmpty) {
        throw const AIException(
          'No API key configured. Please set GEMINI_API_KEY in the .env file.',
          code: 'NO_API_KEY',
        );
      }
      final url = Uri.parse(
          '$_baseUrl/models/$_model:generateContent?key=$_apiKey');

      debugPrint('🚀 Calling Gemini API with image...');
      debugPrint('📝 Specialty: $specialty');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': fullPrompt},
                {
                  'inline_data': {
                    'mime_type': mimeType,
                    'data': imageBase64,
                  }
                }
              ]
            }
          ],
          'systemInstruction': {
            'parts': [
              {'text': _systemInstruction}
            ]
          },
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 2048,
          },
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_ONLY_HIGH'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_ONLY_HIGH'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_ONLY_HIGH'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_ONLY_HIGH'
            },
          ],
        }),
      ).timeout(Duration(seconds: _timeoutSeconds));

      debugPrint('📡 Image Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        String aiMessage = '';
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          final candidate = data['candidates'][0];
          if (candidate['content'] != null &&
              candidate['content']['parts'] != null &&
              candidate['content']['parts'].isNotEmpty) {
            aiMessage = candidate['content']['parts'][0]['text'] ?? '';
          }
        }

        if (aiMessage.isEmpty) {
          aiMessage =
              'I was unable to analyze the image. Please try again or describe your symptoms in text.';
        } else {
          debugPrint(
              '✅ Got image analysis: ${aiMessage.substring(0, aiMessage.length > 100 ? 100 : aiMessage.length)}...');
        }

        // Emergency detection on AI response
        bool isEmergency = false;
        final aiLower = aiMessage.toLowerCase();
        if (aiLower.contains('emergency') ||
            aiLower.contains('call 911') ||
            aiLower.contains('call 999') ||
            aiLower.contains('seek immediate') ||
            aiLower.contains('go to the emergency room') ||
            aiLower.contains('call an ambulance')) {
          isEmergency = true;
          debugPrint('⚠️ Emergency detected from image analysis!');
        }

        return AIResponse(
          message: aiMessage,
          confidence: 0.80,
          isEmergency: isEmergency,
          keywords: [],
          timestamp: DateTime.now().toIso8601String(),
        );
      } else {
        String errorMsg = 'API error: ${response.statusCode}';
        try {
          final errorData = jsonDecode(response.body);
          debugPrint('❌ Image API Error: ${response.body}');
          if (errorData['error'] != null) {
            errorMsg = errorData['error']['message'] ?? errorMsg;
          }
        } catch (_) {}

        throw AIException(errorMsg, code: 'API_ERROR');
      }
    } on SocketException {
      throw const AIException(
        'No internet connection. Please check your network.',
        code: 'NO_INTERNET',
      );
    } on TimeoutException {
      throw const AIException(
        'Image analysis timed out. Please try again.',
        code: 'TIMEOUT',
      );
    } catch (e) {
      if (e is AIException) rethrow;
      throw AIException(
        'Image analysis failed: ${e.toString()}',
        code: 'UNKNOWN_ERROR',
      );
    }
  }

  /// Check for emergency keywords in message
  static bool _detectEmergency(String message) {
    final lowerMessage = message.toLowerCase();
    return _emergencyKeywords.any((keyword) => lowerMessage.contains(keyword));
  }

  /// Extract medical keywords from message
  static List<String> _extractKeywords(String message) {
    const medicalKeywords = [
      'pain', 'fever', 'headache', 'nausea', 'vomiting', 'diarrhea',
      'cough', 'cold', 'flu', 'tired', 'fatigue', 'dizzy', 'breathing',
      'chest', 'stomach', 'throat', 'muscle', 'joint', 'rash', 'itchy',
      'swelling', 'infection', 'bleeding', 'burning', 'numbness', 'weakness',
    ];
    
    final lowerMessage = message.toLowerCase();
    return medicalKeywords.where((kw) => lowerMessage.contains(kw)).toList();
  }

  /// Check if internet/API is available
  /// Now always returns true - we handle errors in sendMessage directly
  static Future<bool> isServiceAvailable() async {
    // Always return true - let sendMessage handle actual errors
    // This prevents false negatives from connectivity pre-checks
    return true;
  }

  /// Get AI service status
  static Future<ServiceStatus> getServiceStatus() async {
    try {
      final isAvailable = await isServiceAvailable();
      return ServiceStatus(
        isOnline: isAvailable,
        version: '2.0.0',
        model: 'Gemini 1.5 Flash',
        aiAvailable: isAvailable,
        timestamp: DateTime.now().toIso8601String(),
      );
    } catch (e) {
      return ServiceStatus(
        isOnline: false,
        version: '2.0.0',
        model: 'Gemini 1.5 Flash',
        aiAvailable: false,
        timestamp: DateTime.now().toIso8601String(),
      );
    }
  }
}

/// Response from the AI service
class AIResponse {
  final String message;
  final double confidence;
  final bool isEmergency;
  final List<String> keywords;
  final String timestamp;

  const AIResponse({
    required this.message,
    required this.confidence,
    required this.isEmergency,
    required this.keywords,
    required this.timestamp,
  });

  factory AIResponse.fromMap(Map<String, dynamic> map) {
    return AIResponse(
      message: map['message'] ?? '',
      confidence: (map['confidence'] ?? 0.5).toDouble(),
      isEmergency: map['is_emergency'] ?? false,
      keywords: List<String>.from(map['keywords'] ?? []),
      timestamp: map['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }
}

/// Service status information
class ServiceStatus {
  final bool isOnline;
  final String version;
  final String model;
  final bool aiAvailable;
  final String timestamp;

  const ServiceStatus({
    required this.isOnline,
    required this.version,
    required this.model,
    required this.aiAvailable,
    required this.timestamp,
  });

  factory ServiceStatus.fromMap(Map<String, dynamic> map) {
    return ServiceStatus(
      isOnline: map['is_online'] ?? false,
      version: map['version'] ?? 'Unknown',
      model: map['model'] ?? 'Unknown',
      aiAvailable: map['ai_available'] ?? false,
      timestamp: map['timestamp'] ?? DateTime.now().toIso8601String(),
    );
  }
}

/// Custom exception for AI service errors
class AIException implements Exception {
  final String message;
  final String code;

  const AIException(this.message, {this.code = 'UNKNOWN'});

  @override
  String toString() => 'AIException: $message (Code: $code)';
}

/// Fallback responses when AI service is unavailable
class FallbackResponses {
  static AIResponse createFallbackResponse(String userMessage) {
    final message = '''📋 **Overview**
Thank you for sharing your health concern. I'm currently unable to provide a full AI-powered response, but I can offer some general guidance.

🔍 **Possible Causes**
Your symptoms may be related to various conditions. Without a full analysis, it's important to consult a healthcare provider for proper evaluation.

🏠 **Home Remedies**
• Stay well hydrated with water and clear fluids
• Get adequate rest and sleep
• Monitor your symptoms and note any changes
• Apply warm or cold compress if appropriate for discomfort

💊 **Safe OTC Options**
• For mild pain/fever: Paracetamol (follow package instructions)
• For hydration: Oral Rehydration Solution if needed
• Always check for allergies before taking any medication

📊 **What to Monitor**
□ Symptom severity (improving/worsening)
□ Temperature if fever is present
□ Duration of symptoms
□ Any new symptoms appearing

⚠️ **When to Seek Medical Help**
• Symptoms persist beyond 3-5 days
• Symptoms worsen significantly
• High fever (above 39°C/102°F)
• Difficulty breathing
• Severe pain

📝 **Final Note**
This is general health information only. For accurate diagnosis and personalized treatment, please consult with a qualified healthcare professional.''';

    return AIResponse(
      message: message,
      confidence: 0.60,
      isEmergency: false,
      keywords: [],
      timestamp: DateTime.now().toIso8601String(),
    );
  }
}

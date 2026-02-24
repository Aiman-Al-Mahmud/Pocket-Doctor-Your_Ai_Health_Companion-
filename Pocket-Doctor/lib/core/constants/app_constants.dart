// App Constants
class AppConstants {
  // App Information
  static const String appName = 'Pocket Doctor';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Your AI Health Companion';
  
  // Database
  static const String databaseName = 'pocket_doctor.db';
  static const int databaseVersion = 1;
  
  // API
  static const String geminiApiKey = 'GEMINI_API_KEY'; // Environment variable key
  static const int requestTimeoutSeconds = 30;
  
  // Security
  static const String secureStorageAuthKey = 'auth_user_id';
  static const int passwordMinLength = 8;
  
  // UI
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double cardElevation = 2.0;
  
  // Animation
  static const int defaultAnimationDuration = 300;
  static const int splashScreenDelay = 3000; // 3 seconds
  
  // Chat
  static const int maxMessageLength = 2000;
  static const String defaultChatTitle = 'Health Consultation';
  
  // Emergency keywords that trigger emergency alert
  static const List<String> emergencyKeywords = [
    'chest pain',
    'heart attack',
    'shortness of breath',
    'difficulty breathing',
    'severe bleeding',
    'unconscious',
    'seizure',
    'stroke',
    'severe burns',
    'allergic reaction',
    'anaphylaxis',
    'crushing pain',
    'can\'t breathe',
    'severe abdominal pain',
    'loss of consciousness',
  ];
}

// Medical Specialties
class MedicalDivisions {
  static const List<Map<String, String>> divisions = [
    {
      'name': 'Neurology',
      'emoji': '🧠',
      'description': 'Brain and nervous system disorders',
    },
    {
      'name': 'Psychiatry',
      'emoji': '💭',
      'description': 'Mental health and psychological disorders',
    },
    {
      'name': 'Cardiology',
      'emoji': '❤️',
      'description': 'Heart and cardiovascular system',
    },
    {
      'name': 'Pulmonology',
      'emoji': '🌬️',
      'description': 'Lungs and respiratory system',
    },
    {
      'name': 'Gastroenterology',
      'emoji': '🍽️',
      'description': 'Digestive system disorders',
    },
    {
      'name': 'Hepatology',
      'emoji': '🧬',
      'description': 'Liver and gallbladder disorders',
    },
    {
      'name': 'Orthopedics',
      'emoji': '🦴',
      'description': 'Bones, joints, and musculoskeletal system',
    },
    {
      'name': 'Dermatology',
      'emoji': '🌿',
      'description': 'Skin, hair, and nail conditions',
    },
    {
      'name': 'Ophthalmology',
      'emoji': '👁️',
      'description': 'Eye and vision disorders',
    },
    {
      'name': 'Otolaryngology',
      'emoji': '👂',
      'description': 'Ear, nose, and throat disorders',
    },
    {
      'name': 'Nephrology',
      'emoji': '💧',
      'description': 'Kidney and urinary system',
    },
    {
      'name': 'Urology',
      'emoji': '🚻',
      'description': 'Urinary and male reproductive system',
    },
    {
      'name': 'Gynecology',
      'emoji': '👩‍⚕️',
      'description': 'Female reproductive health',
    },
    {
      'name': 'Obstetrics',
      'emoji': '👶',
      'description': 'Pregnancy and childbirth',
    },
    {
      'name': 'Pathology',
      'emoji': '🔬',
      'description': 'Disease diagnosis and laboratory analysis',
    },
  ];
  
  static String getEmojiByName(String name) {
    final division = divisions.firstWhere(
      (d) => d['name'] == name,
      orElse: () => {'emoji': '🏥'},
    );
    return division['emoji'] ?? '🏥';
  }
  
  static String getDescriptionByName(String name) {
    final division = divisions.firstWhere(
      (d) => d['name'] == name,
      orElse: () => {'description': 'General medical consultation'},
    );
    return division['description'] ?? 'General medical consultation';
  }
}
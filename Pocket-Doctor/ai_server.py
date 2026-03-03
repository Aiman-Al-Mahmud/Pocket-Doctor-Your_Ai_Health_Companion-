"""
Pocket Doctor AI Server
========================
A Flask server that provides AI-powered health assistance using Google's Gemini AI.
Designed to work with the Pocket Doctor Flutter mobile application.

Usage:
    1. Install dependencies: pip install flask flask-cors google-generativeai python-dotenv
    2. Set your API key in .env file: GEMINI_API_KEY=your_api_key_here
    3. Run the server: python ai_server.py
    4. The server will be available at http://localhost:8000
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
from dotenv import load_dotenv
import os
import logging
from datetime import datetime
import time
import base64
import mimetypes
from pathlib import Path
from typing import Optional, Sequence, List, Tuple

# Load environment variables from .env file
load_dotenv()

app = Flask(__name__)
CORS(app)  # Enable CORS for Flutter app communication

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Server configuration
SERVER_PORT = 8000
SERVER_VERSION = '2.0.0'

# ==================== SYSTEM INSTRUCTIONS ====================
SYS_INSTRUCTIONS = """You are Pocket Doctor, an AI health assistant designed to give educational, supportive, and research-backed general health guidance. You do not diagnose, do not prescribe, and do not replace a real doctor.

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
- Severe burns
- Severe allergic reactions (anaphylaxis)
- Loss of consciousness
- Seizures
- Suicidal thoughts or self-harm

Avoid definitive diagnosis. Use phrases like "This may be related to...", "This could indicate...", "It is important to confirm with a doctor." Remind users you are not a substitute for real medical evaluation.

=== WHAT YOU CAN SUGGEST ===

1. Over-the-counter (OTC) medicines
Only suggest globally safe, non-prescription, low-risk OTC options. Never suggest antibiotics, steroids, blood pressure medications, benzodiazepines, antidepressants, or any prescription-only drugs.

Safe global OTC whitelist (use only these):
• Pain / Fever: Paracetamol (Acetaminophen), Ibuprofen (with food and caution)
• Cold / Allergy: Cetirizine, Loratadine, Saline nasal spray
• Gastric problems: Antacids (Tums, Gaviscon), Famotidine (OTC), Omeprazole 20mg OTC (short-term use only)
• Diarrhea / Dehydration: Oral Rehydration Solution (ORS), Oral zinc 10-20mg if needed, Loperamide (for adults, short-term)
• Constipation: Fiber supplement, Polyethylene glycol (PEG/Miralax)
• Skin / Minor wounds: Hydrocortisone 1% cream (OTC), Bacitracin or similar OTC antibiotic ointments, Calamine lotion
• Cough: Dextromethorphan (dry cough), Guaifenesin (productive cough)
• General wellness: Electrolyte powders, Rehydration tablets, Vitamin C, Zinc lozenges

These medications are for mild, common symptoms only. Always include "Follow package instructions and check for allergies."

2. Evidence-based home remedies
You may recommend:
• Hydration (water, clear broths, herbal teas)
• Warm or cold compresses
• Stretching and gentle exercises
• Rest and adequate sleep
• Ginger or honey for throat irritation (not for children under 1)
• Steam inhalation for congestion
• Saltwater gargle for sore throat
• Bland diet (BRAT: Bananas, Rice, Applesauce, Toast)
• Avoiding trigger foods (spicy, fatty, acidic)
• Proper wound cleaning with soap and water
• Elevation for swelling

3. Lifestyle, prevention, and monitoring
Always add practical prevention steps, simple lifestyle modifications, and daily symptom monitoring checklists.

=== OUTPUT FORMAT ===
Always structure your answers with these sections (use emojis for visual clarity):

📋 **Overview**
Simple explanation of what the user might be experiencing

🔍 **Possible Causes**
List potential causes using phrases like "may be related to", "could indicate"

🏠 **Home Remedies**
Evidence-based remedies they can try at home

💊 **Safe OTC Options**
Only from the approved whitelist above, with dosage guidance

📊 **What to Monitor**
Simple checklist of symptoms to watch

⚠️ **When to Seek Medical Help**
Clear red flags that require professional attention

📝 **Final Note**
Encourage seeing a real doctor for proper evaluation

Keep paragraphs short, clear, and user-friendly. Use bullet points for easy reading."""

# ==================== SPECIALTY CONTEXTS ====================
SPECIALTY_PROMPTS = {
    'General': "You are providing general health guidance.",
    'Cardiology': "You are specializing in heart and cardiovascular health information. Focus on cardiac symptoms, blood pressure, cholesterol, and heart-healthy lifestyle advice.",
    'Dermatology': "You are specializing in skin, hair, and nail health information. Focus on rashes, acne, eczema, skin infections, and skincare advice.",
    'Gastroenterology': "You are specializing in digestive system health information. Focus on stomach issues, bowel problems, acid reflux, and dietary advice.",
    'Neurology': "You are specializing in brain and nervous system health information. Focus on headaches, migraines, dizziness, and neurological symptoms.",
    'Orthopedics': "You are specializing in bone, joint, and muscle health information. Focus on pain management, posture, exercises, and injury prevention.",
    'Pediatrics': "You are specializing in children's health information. Be extra cautious with medication suggestions for children and always recommend parental guidance.",
    'Psychiatry': "You are specializing in mental health and psychological wellbeing. Focus on stress management, anxiety, sleep issues, and emotional support. Always recommend professional help for serious concerns.",
    'Pulmonology': "You are specializing in respiratory and lung health information. Focus on breathing issues, coughs, asthma management, and respiratory hygiene.",
    'Ophthalmology': "You are specializing in eye health information. Focus on eye strain, vision issues, and eye care practices.",
    'Otolaryngology': "You are specializing in ear, nose, and throat health information. Focus on ENT infections, hearing issues, and sinus problems.",
    'Gynecology': "You are specializing in women's reproductive health information. Focus on menstrual issues, reproductive health, and women-specific concerns.",
    'Urology': "You are specializing in urinary system health information. Focus on UTIs, kidney health, and urinary symptoms.",
    'Endocrinology': "You are specializing in hormonal and metabolic health information. Focus on thyroid, diabetes management, and metabolic concerns.",
    'Hepatology': "You are specializing in liver health information. Focus on liver function, hepatitis awareness, and liver-friendly lifestyle.",
    'Nephrology': "You are specializing in kidney health information. Focus on kidney function, hydration, and renal health.",
    'Obstetrics': "You are specializing in pregnancy and childbirth information. Be extra cautious and always recommend consulting an OB-GYN for pregnancy-related concerns.",
    'Pathology': "You are providing general health information with focus on understanding test results and medical findings.",
}

# Try to initialize Gemini AI
GEMINI_AVAILABLE = False
model = None
genai = None

try:
    import google.generativeai as genai_module
    genai = genai_module
    
    GEMINI_API_KEY = os.getenv('GEMINI_API_KEY')
    
    if GEMINI_API_KEY and GEMINI_API_KEY != 'your_api_key_here':
        genai.configure(api_key=GEMINI_API_KEY)
        model = genai.GenerativeModel(
            'gemini-1.5-flash',
            system_instruction=SYS_INSTRUCTIONS
        )
        GEMINI_AVAILABLE = True
        logger.info("✅ Gemini AI initialized successfully with system instructions")
    else:
        logger.warning("⚠️ GEMINI_API_KEY not found or invalid. Using fallback responses.")
        
except ImportError:
    logger.warning("⚠️ google-generativeai package not installed. Using fallback responses.")
except Exception as e:
    logger.error(f"❌ Error initializing Gemini AI: {e}")

# Server statistics
server_stats = {
    'start_time': time.time(),
    'request_count': 0,
    'successful_responses': 0,
    'fallback_responses': 0,
    'image_requests': 0
}

# Emergency keywords
EMERGENCY_KEYWORDS = [
    'emergency', 'urgent', 'chest pain', 'heart attack', "can't breathe",
    'difficulty breathing', 'severe bleeding', 'unconscious', 'seizure',
    'stroke', 'allergic reaction', 'anaphylaxis', 'severe pain', 'trauma',
    'suicide', 'suicidal', 'overdose', 'poisoning', 'choking', 'drowning', 
    'dying', 'kill myself', 'want to die', 'self harm', 'crushing chest'
]

# Medical keyword detection
MEDICAL_KEYWORDS = [
    'pain', 'fever', 'headache', 'nausea', 'vomiting', 'diarrhea',
    'cough', 'cold', 'flu', 'tired', 'fatigue', 'dizzy', 'breathing',
    'chest', 'stomach', 'throat', 'muscle', 'joint', 'rash', 'itchy',
    'swelling', 'infection', 'bleeding', 'burning', 'numbness', 'weakness',
    'anxiety', 'depression', 'stress', 'sleep', 'insomnia', 'allergy'
]

# Fallback responses when AI is unavailable
FALLBACK_RESPONSES = [
    """📋 **Overview**
Thank you for sharing your health concern. I'm currently operating in limited mode, but I can still provide some general guidance.

🔍 **Possible Causes**
Without the full AI capability, I cannot analyze specific causes. Your symptoms may be related to various conditions that a healthcare provider can properly evaluate.

🏠 **Home Remedies**
• Stay well hydrated with water and clear fluids
• Get adequate rest and sleep
• Monitor your symptoms and note any changes
• Apply warm or cold compress if appropriate for pain

💊 **Safe OTC Options**
• For pain/fever: Paracetamol (follow package instructions)
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
This is general health information only. For accurate diagnosis and personalized treatment, please consult with a qualified healthcare professional.""",
]


# ==================== HELPER FUNCTIONS ====================

def detect_emergency(message: str) -> bool:
    """Check if message contains emergency indicators."""
    message_lower = message.lower()
    return any(keyword in message_lower for keyword in EMERGENCY_KEYWORDS)


def extract_keywords(message: str) -> list:
    """Extract relevant medical keywords from the message."""
    message_lower = message.lower()
    return [kw for kw in MEDICAL_KEYWORDS if kw in message_lower]


def get_fallback_response() -> str:
    """Get a fallback response."""
    import random
    return random.choice(FALLBACK_RESPONSES)


def read_image_as_base64(image_path: str) -> Optional[dict]:
    """Read an image file and convert to base64 for Gemini API."""
    try:
        data = Path(image_path).read_bytes()
    except Exception as e:
        logger.error(f"Error reading image: {e}")
        return None
    
    mime_type, _ = mimetypes.guess_type(image_path)
    if not mime_type:
        mime_type = "image/jpeg"  # Default to jpeg
    
    b64_data = base64.b64encode(data).decode("ascii")
    return {"inline_data": {"mime_type": mime_type, "data": b64_data}}


def create_medical_prompt(message: str, specialty: str) -> str:
    """Create an enhanced prompt for the AI model."""
    specialty_context = SPECIALTY_PROMPTS.get(specialty, SPECIALTY_PROMPTS['General'])
    
    return f"""{specialty_context}

USER'S HEALTH CONCERN:
{message}

Please provide a comprehensive response following the output format in your instructions. Be thorough but concise."""


async def get_ai_response(message: str, specialty: str, image_data: Optional[str] = None) -> tuple:
    """Get response from Gemini AI or fallback."""
    global server_stats
    
    if GEMINI_AVAILABLE and model:
        try:
            prompt = create_medical_prompt(message, specialty)
            
            # Handle image if provided
            if image_data:
                server_stats['image_requests'] += 1
                try:
                    # Decode base64 image
                    image_bytes = base64.b64decode(image_data)
                    
                    # Create image part for Gemini
                    image_part = {
                        "inline_data": {
                            "mime_type": "image/jpeg",
                            "data": image_data
                        }
                    }
                    
                    # Generate with image
                    response = model.generate_content([
                        prompt + "\n\nPlease also analyze the attached image if it's relevant to the health concern.",
                        image_part
                    ])
                except Exception as img_error:
                    logger.error(f"Image processing error: {img_error}")
                    # Fall back to text-only
                    response = model.generate_content(prompt)
            else:
                response = model.generate_content(prompt)
            
            if response and response.text:
                server_stats['successful_responses'] += 1
                # Calculate confidence based on response quality
                confidence = 0.85 if len(response.text) > 500 else 0.75
                return response.text, confidence
                
        except Exception as e:
            logger.error(f"Gemini API error: {e}")
    
    # Use fallback response
    server_stats['fallback_responses'] += 1
    return get_fallback_response(), 0.60


@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint."""
    return jsonify({
        'status': 'healthy',
        'ai_available': GEMINI_AVAILABLE,
        'timestamp': datetime.now().isoformat()
    })


@app.route('/status', methods=['GET'])
def get_status():
    """Get detailed server status."""
    uptime = time.time() - server_stats['start_time']
    
    return jsonify({
        'is_online': True,
        'version': SERVER_VERSION,
        'model': 'Gemini 1.5 Flash' if GEMINI_AVAILABLE else 'Fallback Mode',
        'ai_available': GEMINI_AVAILABLE,
        'request_count': server_stats['request_count'],
        'successful_responses': server_stats['successful_responses'],
        'fallback_responses': server_stats['fallback_responses'],
        'image_requests': server_stats['image_requests'],
        'uptime': uptime,
        'uptime_formatted': f"{int(uptime // 3600)}h {int((uptime % 3600) // 60)}m",
        'timestamp': datetime.now().isoformat()
    })


@app.route('/chat', methods=['POST'])
def chat():
    """Main chat endpoint for health consultations."""
    global server_stats
    server_stats['request_count'] += 1
    
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        message = data.get('message', '').strip()
        specialty = data.get('specialty', 'General')
        user_id = data.get('user_id', 'anonymous')
        image_data = data.get('image', None)  # Base64 encoded image
        
        if not message and not image_data:
            return jsonify({'error': 'Message or image is required'}), 400
        
        # If only image is provided, add a default prompt
        if not message and image_data:
            message = "Please analyze this image and provide health-related information if applicable."
        
        logger.info(f"Chat request #{server_stats['request_count']} - Specialty: {specialty}, Length: {len(message)}, Has Image: {bool(image_data)}")
        
        # Check for emergency
        is_emergency = detect_emergency(message)
        keywords = extract_keywords(message)
        
        if is_emergency:
            logger.warning(f"⚠️ Emergency keywords detected in request #{server_stats['request_count']}")
        
        # Get AI response
        import asyncio
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        ai_response, confidence = loop.run_until_complete(get_ai_response(message, specialty, image_data))
        loop.close()
        
        response_data = {
            'message': ai_response,
            'confidence': confidence,
            'is_emergency': is_emergency,
            'keywords': keywords,
            'specialty': specialty,
            'timestamp': datetime.now().isoformat(),
            'request_id': server_stats['request_count'],
            'has_image': bool(image_data)
        }
        
        return jsonify(response_data)
        
    except Exception as e:
        logger.error(f"Error in chat endpoint: {e}")
        return jsonify({
            'error': 'Internal server error',
            'message': str(e),
            'timestamp': datetime.now().isoformat()
        }), 500


@app.route('/analyze-image', methods=['POST'])
def analyze_image():
    """Dedicated endpoint for image analysis (OCR, medical image analysis)."""
    global server_stats
    server_stats['request_count'] += 1
    server_stats['image_requests'] += 1
    
    try:
        data = request.get_json()
        
        if not data:
            return jsonify({'error': 'No JSON data provided'}), 400
        
        image_data = data.get('image')  # Base64 encoded image
        analysis_type = data.get('type', 'general')  # 'ocr', 'skin', 'general'
        additional_context = data.get('context', '')
        
        if not image_data:
            return jsonify({'error': 'Image data is required'}), 400
        
        if not GEMINI_AVAILABLE or not model:
            return jsonify({
                'error': 'Image analysis requires AI to be available',
                'message': 'Please ensure Gemini API is configured correctly'
            }), 503
        
        # Build prompt based on analysis type
        if analysis_type == 'ocr':
            prompt = "Please extract and read all text from this image. If it appears to be a medical document, prescription, or test result, also provide a brief explanation of what the text means."
        elif analysis_type == 'skin':
            prompt = """Analyze this skin image. Please provide:
1. Description of what you observe
2. Possible conditions this may be related to (use cautious language)
3. General care recommendations
4. When to see a dermatologist

IMPORTANT: This is for educational purposes only. A proper diagnosis requires in-person examination by a qualified dermatologist."""
        else:
            prompt = f"Please analyze this image in a health context. {additional_context}"
        
        try:
            image_part = {
                "inline_data": {
                    "mime_type": "image/jpeg",
                    "data": image_data
                }
            }
            
            response = model.generate_content([prompt, image_part])
            
            if response and response.text:
                server_stats['successful_responses'] += 1
                return jsonify({
                    'analysis': response.text,
                    'type': analysis_type,
                    'confidence': 0.80,
                    'timestamp': datetime.now().isoformat()
                })
                
        except Exception as e:
            logger.error(f"Image analysis error: {e}")
            return jsonify({
                'error': 'Failed to analyze image',
                'message': str(e)
            }), 500
            
    except Exception as e:
        logger.error(f"Error in analyze-image endpoint: {e}")
        return jsonify({
            'error': 'Internal server error',
            'message': str(e)
        }), 500


@app.route('/emergency', methods=['POST'])
def emergency():
    """Handle emergency situations with immediate response."""
    logger.warning("🚨 Emergency endpoint called")
    
    return jsonify({
        'message': """⚠️ EMERGENCY DETECTED ⚠️

If this is a life-threatening emergency, please:

🚑 **CALL 911 IMMEDIATELY** (or your local emergency number)

While waiting for help:
1. Stay calm and follow the dispatcher's instructions
2. Do not move the person if there's a possible spinal injury
3. Apply pressure to any severe bleeding
4. Keep airways clear if the person is unconscious
5. Begin CPR if trained and the person is not breathing

This AI assistant CANNOT replace emergency medical services.
Please prioritize getting immediate professional help.""",
        'confidence': 1.0,
        'is_emergency': True,
        'priority': 'CRITICAL',
        'timestamp': datetime.now().isoformat()
    })


@app.route('/', methods=['GET'])
def index():
    """Welcome page with API documentation."""
    return jsonify({
        'name': 'Pocket Doctor AI Server',
        'version': SERVER_VERSION,
        'status': 'running',
        'ai_available': GEMINI_AVAILABLE,
        'endpoints': {
            'GET /': 'This documentation',
            'GET /health': 'Health check',
            'GET /status': 'Detailed server status',
            'POST /chat': 'Main chat endpoint (supports images)',
            'POST /analyze-image': 'Dedicated image analysis (OCR, skin, etc.)',
            'POST /emergency': 'Emergency response'
        },
        'chat_request_format': {
            'message': 'string (required unless image provided)',
            'specialty': 'string (optional, default: General)',
            'user_id': 'string (optional)',
            'image': 'string (optional, base64 encoded image)'
        },
        'analyze_image_format': {
            'image': 'string (required, base64 encoded)',
            'type': 'string (optional: ocr, skin, general)',
            'context': 'string (optional, additional context)'
        },
        'supported_specialties': list(SPECIALTY_PROMPTS.keys())
    })


if __name__ == '__main__':
    print("""
╔══════════════════════════════════════════════════════════════╗
║                 🩺 POCKET DOCTOR AI SERVER 🩺                 ║
╠══════════════════════════════════════════════════════════════╣
║  Version: {version}                                            ║
║  Port: {port}                                               ║
║  AI Status: {status}                  ║
║  Features: Chat, Image Analysis, OCR                         ║
╚══════════════════════════════════════════════════════════════╝
    """.format(
        version=SERVER_VERSION,
        port=SERVER_PORT,
        status='✅ Gemini Available' if GEMINI_AVAILABLE else '⚠️ Fallback Mode'
    ))
    
    if not GEMINI_AVAILABLE:
        print("\n⚠️  To enable AI responses:")
        print("    1. Install: pip install google-generativeai")
        print("    2. Create .env file with: GEMINI_API_KEY=your_api_key")
        print("    3. Restart the server\n")
    
    print("📋 System Instructions loaded with:")
    print("   • OTC medication whitelist")
    print("   • Evidence-based home remedies")
    print("   • Structured output format")
    print("   • Emergency detection")
    print("   • Image analysis support\n")
    
    app.run(host='0.0.0.0', port=SERVER_PORT, debug=True)

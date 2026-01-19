# 🩺 Pocket Doctor: Your AI Health Companion

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![Gemini](https://img.shields.io/badge/Google%20Gemini-8E75C2?style=for-the-badge&logo=googlegemini&logoColor=white)](https://ai.google.dev/)

**Pocket Doctor** is a modern, responsive Flutter application designed to bridge the gap between AI-driven health insights and emergency medical assistance. By leveraging the **Google Gemini API**, the app provides intelligent, preliminary health analysis while ensuring user safety through high-priority emergency services.

---

## 🚀 Key Features

* **🤖 AI Health Consultant:** Real-time, context-aware medical conversations and preliminary symptom analysis powered by Gemini Pro.
* **🚨 Emergency Response System:** Instant emergency alert triggers and one-touch direct-dial integration for ambulance services.
* **👤 Offline-First User Profiles:** Securely manage personal medical profiles locally without requiring a constant cloud connection.
* **🧠 Specialty-Based UI:** Intuitive categorization (Neurology, Cardiology, etc.) to streamline the user journey.
* **📱 Production-Grade Architecture:** Built with a scalable codebase, featuring responsive UI/UX and system-wide Safe Area integration.
* **🔒 Privacy Focused:** Local data persistence ensures sensitive health information stays on the user's device.

---

## 🛠 Tech Stack

| Component | Technology |
| :--- | :--- |
| **Frontend Framework** | Flutter (Dart) |
| **AI Engine** | Google Gemini API |
| **State Management** | Provider |
| **Local Database** | SQLite / Sqflite |
| **Services** | Telephony & Location Services |

---

## 📈 Roadmap

Our development path is divided into four key phases to ensure a stable, production-ready release.

### Phase 1: Foundation & UI/UX 🏗️
- [x] Create Flutter Project structure and environment setup.
- [x] Design and implement a modern, responsive UI with **Safe Area** support.
- [x] Build specialty selection screens (Neurology, Cardiology, etc.).
- [x] Implement the chat interface with auto-scrolling and keyboard handling.

### Phase 2: AI Integration & Logic 🧠
- [x] Gemini API performance testing and prompt engineering.
- [ ] Secure API key integration using environment variables.
- [ ] Implement AI "Thinking" states and markdown message rendering.
- [ ] Build the offline User Profile system with local data persistence.

### Phase 3: Safety & Connectivity 🚨
- [ ] Integrate Telephony services for direct ambulance calling.
- [ ] Create the Emergency Alert trigger system.
- [ ] Implement Location Services to provide coordinates during emergencies.

### Phase 4: Optimization & Deployment 🚀
- [ ] Refactor state management for global scalability.
- [ ] Conduct UI/UX audit for cross-device compatibility (Tablet/Small Phones).
- [ ] Beta testing and performance monitoring.
- [ ] Final production release to App Store & Play Store.

---

## 🛠 Getting Started

1.  **Clone the repo:**
    ```bash
    git clone [https://github.com/Aiman-Al-Mahmud/Pocket-Doctor-Your_Ai_Health_Companion-.git]
    ```
2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```
3.  **Set up Gemini API:**
    Create a `.env` file in the root directory and add:
    ```env
    GEMINI_API_KEY=your_api_key_here
    ```
4.  **Run the app:**
    ```bash
    flutter run
    ```

---
*Disclaimer: Pocket Doctor is an AI-powered tool for preliminary analysis. It is not a substitute for professional medical advice, diagnosis, or treatment.*

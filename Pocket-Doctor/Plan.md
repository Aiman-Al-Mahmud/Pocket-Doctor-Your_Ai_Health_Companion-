# Database Plan

# 🗄️ Pocket Doctor — Local Database Design (SQLite)

## Overview
Pocket Doctor is a privacy-focused medical assistant application built with **Flutter**.  
To ensure maximum security and offline functionality, **all user data and chat history are stored locally on the user’s device** using **SQLite**.

There is **no remote server or cloud storage** involved.

---

## Database Philosophy
- 📱 **On-device storage only**
- 🔐 **Privacy-first** (medical data never leaves the device)
- ⚡ **Offline-first**
- 🧱 **Simple, scalable, production-ready**
- 🧩 Easy to extend in future versions

---

## Database Engine
- **SQLite**
- Flutter package: `sqflite`
- Database file:  


pocket_doctor.db


---

## Tables Overview

| Table Name | Purpose |
|-----------|--------|
| `users` | Stores user profile & login credentials |
| `chats` | Groups messages into chat sessions |
| `messages` | Stores individual user & AI messages |

---

## 1️⃣ Users Table

### Purpose
Stores a single user profile per device, including authentication and personal details.

### Schema
```sql
CREATE TABLE users (
id INTEGER PRIMARY KEY AUTOINCREMENT,
name TEXT NOT NULL,
email TEXT UNIQUE NOT NULL,
age INTEGER,
password_hash TEXT NOT NULL,
created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

Notes

Passwords are never stored in plain text

Email is unique

Passwords must be hashed (SHA-256 or stronger)



2️⃣ Chats Table
Purpose

Represents a conversation session (e.g., Neurology, Cardiology).

Schema
CREATE TABLE chats (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  specialty TEXT NOT NULL,
  title TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

Example
Specialty	Title
Neurology	Headache analysis
Cardiology	Chest pain discussion


3️⃣ Messages Table
Purpose

Stores all chat messages between the user and Pocket Doctor AI.

Schema
CREATE TABLE messages (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  chat_id INTEGER NOT NULL,
  sender TEXT CHECK(sender IN ('user', 'ai')) NOT NULL,
  message TEXT NOT NULL,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (chat_id) REFERENCES chats(id)
);

Message Types

user → User input

ai → Pocket Doctor AI response

Entity Relationship Diagram
USER (1)
 └── CHAT (Many)
      └── MESSAGE (Many)


Flutter Packages Used
sqflite: ^2.3.0
path_provider: ^2.1.2
crypto: ^3.0.3



App Launch
   ↓
Database Initialization
   ↓
User Login / Register
   ↓
Create or Load Chat Session
   ↓
Store Messages Locally




Prompt: Design the Mobile UI for “Pocket Doctor” (Cross-Platform AI Health Assistant)

App Name: Pocket Doctor Platform: Mobile-first (Android + iOS, responsive layout for tablets and desktops later) Tech Base: Flet (Python cross-platform framework)

🧠 Concept Overview

Pocket Doctor is an AI-powered medical consultation assistant that helps users detect possible health issues and get primary treatment suggestions using text or images (prescriptions, skin conditions, etc.). The app connects with Gemini API or other LLMs to process symptoms and provide intelligent responses, with a focus on user safety and clear medical disclaimers.

🏠 App Flow & UI Screens

1️⃣ Splash Screen

Background: Soft gradient or light blue medical theme

Centerpiece: Futuristic robot doctor illustration (friendly, trustworthy look)

Text: “👨‍⚕️ Pocket Doctor”

Subtext: “Your AI Health Companion”

Button: “Let’s Start” → rounded, modern gradient button

Animation: Subtle fade-in of logo and button

2️⃣ Awareness / Disclaimer Screen

Title: “Before we begin…”

Paragraph: Short awareness text explaining that this AI gives preliminary guidance and is not a replacement for real doctors.

Button: “I Understand” (activates main app view)

Optional small text link: “Learn more about AI medical ethics”

3️⃣ Home Screen (Chat Overview)

Header: App logo + small avatar icon (for settings/profile)

Body:

Chat history list:

Each chat as a card with title (e.g., “Cardiology — Chest Pain Discussion”)

Last message preview + time

New Chat button: Floating “+ New Consultation” button at bottom center

Bottom navigation bar (optional future): Home | Chat | Profile | Settings

4️⃣ Division Selection Modal

When user starts a new chat → show modal (as in your image)

Title: “Select Medical Division”

Subtitle: “Choose a specialty for focused consultation, or skip to let AI detect.”

Display divisions in 3x5 responsive grid with icons:

Neurology 🧠

Psychiatry 💭

Cardiology ❤️

Pulmonology 🌬️

Gastroenterology 🍽️

Hepatology 🧬

Orthopedics 🦴

Dermatology 🌿

Ophthalmology 👁️

Otolaryngology 👂

Nephrology 💧

Urology 🚻

Gynecology 👩‍⚕️

Obstetrics 👶

Pathology 🔬

Bottom button: “Skip / Unknown”

Design: Rounded cards, soft hover/press animations

5️⃣ Chat Interface

Top: Selected Division pill (editable — tap to change division)

Body: Scrollable chat view (AI + user bubbles)

AI bubble color: light teal or blue

User bubble: light gray/white

Small “confidence indicator” bar below AI messages (e.g., “Confidence: 82% 🟢”)

End-of-chat suggestion: “Consult a real doctor for a full diagnosis.”

Bottom Input Bar:

Left icon: 📷 (Camera / Upload for prescription or image)

Center: Text input (“Describe your symptoms…”)

Right: “Send” button (paper-plane icon)

Division override pill: small clickable tag (e.g., “Pathology 🧬”)

6️⃣ Urgency / Emergency Screen (Triggered Automatically)

If the system detects high-risk terms like:

“Chest pain”, “shortness of breath”, “seizure”, “unconscious”, etc.

Then show:

Header: 🚨 “This Might Be an Emergency”

Body: “Your symptoms sound serious. Please contact emergency services immediately.”

Button: “Call 999 (Emergency)” → large red button

Subtext: “You can continue chatting, but we recommend seeking immediate help.”

🎨 Design Language

Theme: Minimal, medical-grade clean UI

Primary Colors: Light teal (#4FD1C5), White (#FFFFFF), Accent Blue (#2563EB), Red (#EF4444 for alerts)

Font: Inter or Poppins (modern, readable on mobile)

Style: Rounded corners, shadowed cards, soft gradients

Accessibility: Large buttons, legible contrast, and easy touch targets

🧩 Animations / Microinteractions

Smooth slide transitions between screens

Floating chat bubble animation during AI typing

Fade-in confidence meter

Light haptic feedback on button press

⚙️ Functional Notes for Flet Implementation

Use flet.Stack() for layered UI transitions

Use flet.GridView() for the medical division cards

Use flet.ResponsiveRow() for adaptive layout on tablets

Integrate camera/image picker using FilePicker + OCR/AI backend

Maintain chat history locally (SQLite or JSON store)

Integrate Gemini API or OpenAI function call for prompt → response

✅ Key UX Goals

Fast access to assistance (≤2 taps)

Empathetic and reassuring tone

Always end with human follow-up reminder

Clean visual hierarchy and easy mobile readability



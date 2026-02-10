# AI Campus Helpdesk

## Overview
AI Campus Helpdesk is a mobile app built during a hackathon to help IIT Bhilai students quickly find campus information through an AI chat interface.  
Students can ask questions about mess menus, exam schedules, faculty details, and forms in one place.

The system uses Google Gemini AI and an admin verification flow to keep responses reliable.

---

## Problem
Campus information is scattered across websites, PDFs, and portals.  
Students often waste time searching for basic details like:

- Mess menu
- Exam dates
- Faculty contacts
- Official forms

---

## Solution
A single AI assistant where students can ask questions and get instant answers.

If the AI is unsure, the response is flagged for admin review.  
Verified answers are stored and reused for future queries.

---

## Core Features
- OTP-based login using institutional email
- AI chat interface for campus questions
- Quick actions for common queries
- Mess menu and exam schedule lookup
- Faculty and forms information
- Admin dashboard to verify answers
- Knowledge base for official responses

---

## Tech Stack
- **Frontend:** Flutter
- **Backend:** Firebase (Firestore, Authentication)
- **AI:** Google Gemini API
- **Languages:** Dart, Node.js

---

## System Flow
1. Student logs in with institutional email.
2. Student asks a question in chat.
3. System checks for a verified answer.
4. If not found, AI generates a response.
5. Low-confidence answers are flagged.
6. Admin verifies or corrects them.
7. Verified answers are stored for future use.

---

## Project Links
- **GitHub Repository:**  
  https://github.com/vivekchowdary28/ai-campus-helpdesk.git

- **Project Presentation (PPT):**  
  https://drive.google.com/file/d/1ogGoYpCZa5f_ThW1ErIC__PfPTn4dFkB/view?usp=drivesdk

---

## Setup Instructions

### 1. Clone the repository
```bash
git clone https://github.com/vivekchowdary28/ai-campus-helpdesk.git
cd ai-campus-helpdesk
flutter pub get
2. Configure Firebase:
   - Create project at [firebase.google.com](https://console.firebase.google.com)
   - Add `google-services.json` to `android/app/`
   - Add `GoogleService-Info.plist` to `ios/Runner/`
   - Run `flutterfire configure`

3. Add Gemini API keys:
   - Get keys from [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Update `lib/services/ai_service.dart` with your keys

4. Run the app:
```bash
flutter run
```

**Test login:**
- Student: any `@iitbhilai.ac.in` email
- Admin: `admin@iitbhilai.ac.in`
- OTP is printed in console

## Limitations (Hackathon MVP)

- OTP printed to console (no email/SMS service)
- API keys hardcoded in source code
- No rate limiting or session management
- Chat history not persisted per user
- No pagination in admin dashboard
- Web scraping infrastructure exists but not active
- Mess menu data is hardcoded
- No automated testing or monitoring

## Future Improvements

- Implement email/SMS OTP delivery with Twilio or SendGrid
- Add persistent chat history with user profiles
- Build analytics dashboard for query trends and AI performance
- Deploy scheduled web scraping for real-time campus data updates
- Add user feedback system (thumbs up/down) to improve AI
- Implement vector embeddings for better semantic search

<a name="readme-top"></a>

<div align="center">
  <a href="https://github.com/biruk-77/fixit">
    <img src="https://img.icons8.com/fluency/144/maintenance.png" alt="FixIt Logo" width="120" height="120">
  </a>

  <h1 align="center">FixIt</h1>
  
  <p align="center">
    <strong>The Next-Gen On-Demand Service Marketplace</strong><br />
    <em>Powered by Flutter, Firebase, Supabase, and Google Gemini AI</em>
  </p>

  <p align="center">
    <a href="https://github.com/biruk-77/fixit/actions">
      <img src="https://img.shields.io/badge/Build-Passing-success?style=for-the-badge&logo=github-actions" alt="Build Status" />
    </a>
    <a href="https://flutter.dev">
      <img src="https://img.shields.io/badge/Flutter-3.19.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
    </a>
    <a href="https://dart.dev">
      <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
    </a>
    <a href="https://firebase.google.com">
      <img src="https://img.shields.io/badge/Backend-Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
    </a>
    <a href="https://ai.google.dev/">
      <img src="https://img.shields.io/badge/AI-Gemini_Pro-8E75B2?style=for-the-badge&logo=google&logoColor=white" alt="Gemini" />
    </a>
  </p>

  <p align="center">
    <a href="#-key-features">Key Features</a> •
    <a href="#-app-gallery">Screenshots</a> •
    <a href="#-architecture">Architecture</a> •
    <a href="#-getting-started">Getting Started</a> •
    <a href="#-roadmap">Roadmap</a>
  </p>
</div>

<br />

---

## 📖 Executive Summary

**FixIt** is not just an app; it is a comprehensive digital ecosystem designed to bridge the gap between service seekers (Clients) and skilled professionals (Workers). In an era where the gig economy is booming, FixIt provides a secure, reliable, and intelligent platform for job discovery, bidding, and execution.

Unlike traditional directories, FixIt utilizes **Google Generative AI (Gemini)** to act as an intelligent concierge, helping users articulate their needs and matching them with the perfect professional. Combined with the real-time capabilities of **Firebase** and the relational power of **Supabase**, FixIt offers enterprise-grade performance on a mobile scale.

This project demonstrates a production-ready implementation of complex Flutter patterns including `Provider` state management, Repository Pattern, and Clean Architecture principles.

---

## 📱 App Gallery

Experience the user interface designed for clarity, speed, and accessibility.

<div align="center">
  <table>
    <tr>
      <th colspan="4">User Onboarding & Authentication</th>
    </tr>
    <tr>
      <td align="center" width="25%">
        <img src="https://i.ibb.co/1tmLnnxH/photo-1-2025-12-09-04-38-02.jpg" alt="Splash Screen" width="100%"/>
        <br />
        <sub><b>Splash & Onboarding</b><br/>Animated entrance with value props.</sub>
      </td>
      <td align="center" width="25%">
        <img src="https://i.ibb.co/Wp5CZV8M/photo-2-2025-12-09-04-38-02.jpg" alt="Login Screen" width="100%"/>
        <br />
        <sub><b>Secure Auth</b><br/>Email/Password & Google Sign-In.</sub>
      </td>
      <td align="center" width="25%">
        <img src="https://i.ibb.co/dqzH3L0/photo-3-2025-12-09-04-38-02.jpg" alt="Home Screen" width="100%"/>
        <br />
        <sub><b>Client Dashboard</b><br/>Quick access to services & status.</sub>
      </td>
      <td align="center" width="25%">
        <img src="https://i.ibb.co/mV9bRnDN/photo-4-2025-12-09-04-38-02.jpg" alt="Categories" width="100%"/>
        <br />
        <sub><b>Service Catalog</b><br/>Categorized professional listings.</sub>
      </td>
    </tr>
  </table>

  <table>
    <tr>
      <th colspan="4">Core Workflow & Intelligence</th>
    </tr>
    <tr>
      <td align="center" width="25%">
        <img src="https://i.ibb.co/5WQ8FmbP/photo-5-2025-12-09-04-38-02.jpg" alt="Job Details" width="100%"/>
        <br />
        <sub><b>Job Management</b><br/>Detailed requirements & bidding.</sub>
      </td>
      <td align="center" width="25%">
        <img src="https://i.ibb.co/9mksN0Gt/photo-6-2025-12-09-04-38-02.jpg" alt="Profile" width="100%"/>
        <br />
        <sub><b>Pro Profile</b><br/>Skills, ratings, and portfolio.</sub>
      </td>
      <td align="center" width="25%">
        <img src="https://i.ibb.co/ynSjK6wh/photo-7-2025-12-09-04-38-02.jpg" alt="AI Chat" width="100%"/>
        <br />
        <sub><b>Gemini AI Assistant</b><br/>Intelligent support & advice.</sub>
      </td>
      <td align="center" width="25%">
        <img src="https://i.ibb.co/rf3XJJkN/photo-8-2025-12-09-04-38-02.jpg" alt="My Jobs" width="100%"/>
        <br />
        <sub><b>Activity Tracker</b><br/>Real-time status of ongoing work.</sub>
      </td>
    </tr>
  </table>

  <table>
    <tr>
      <th colspan="4">Commerce & Customization</th>
    </tr>
    <tr>
      <td align="center" width="25%">
        <img src="https://i.ibb.co/WWSD3G2g/photo-9-2025-12-09-04-38-02.jpg" alt="Payment" width="100%"/>
        <br />
        <sub><b>Telebirr Payment</b><br/>Secure mobile money integration.</sub>
      </td>
      <td align="center" width="25%">
        <img src="https://i.ibb.co/hFjT3HL6/photo-10-2025-12-09-04-38-02.jpg" alt="Settings" width="100%"/>
        <br />
        <sub><b>Settings</b><br/>Dark mode, Localization (Amharic/Oromo).</sub>
      </td>
    </tr>
  </table>
</div>

---

## 🌟 Key Features

### 🔐 Identity & Security
*   **Multi-Provider Auth**: Seamless login via Google, Apple (future), and Email/Password using `firebase_auth`.
*   **Role-Based Access Control (RBAC)**: Strict separation of data and UI for `Client` and `Professional` roles via Firestore Security Rules.
*   **Profile Verification**: Capability to upload ID documents for professional vetting.

### 💼 Marketplace Engine
*   **Dynamic Job Posting**: Clients can post jobs with images, location data, and budget ranges.
*   **Bidding System**: Professionals can submit proposals with custom quotes and cover letters.
*   **Geolocation Matching**: Uses `geolocator` to filter jobs and professionals within a specific radius (e.g., "5km around me").

### 🧠 AI-Powered Assistance (Gemini)
*   **Smart Chat**: An integrated chatbot that helps users diagnose home repair issues before hiring (e.g., "My sink is leaking, what should I do?").
*   **Job Description Generator**: AI assists clients in writing clear, detailed job descriptions to attract the best talent.

### 💬 Communication & Notifications
*   **Real-Time Chat**: 1-on-1 messaging using Firestore listeners, supporting text and image sharing.
*   **Push Notifications**: Integrated `firebase_messaging` for instant alerts on job acceptance, new bids, and messages.
*   **Online Presence**: Real-time "Online/Offline" status indicators using Firestore metadata.

### 💳 Financial Integration
*   **Telebirr API**: Native integration with Ethiopia's leading mobile money platform for secure escrow and direct payments.
*   **Transaction History**: Detailed logs of all financial activities within the app.

### 🌍 Localization & Accessibility
*   **Trilingual Support**: Full support for English (`en`), Amharic (`am`), and Oromo (`om`).
*   **Theme Engine**: Adaptive `Light` and `Dark` modes based on system settings or user preference.

---

## 🏛️ Architecture

FixIt follows a **Service-Oriented Architecture** on top of a **Modular Monolith** codebase. We utilize the `Provider` pattern for Dependency Injection and State Management, ensuring UI logic is decoupled from business logic.

### High-Level System Design

```mermaid
graph TD
    User[End User]
    
    subgraph ClientLayer [Flutter Client]
        UI[UI Components]
        State[State Management (Provider)]
        Repo[Repository Layer]
    end
    
    subgraph BackendLayer [Backend Services]
        Auth[Firebase Authentication]
        DB[Cloud Firestore]
        Storage[Firebase Storage]
        Functions[Cloud Functions (Optional)]
        Supabase[Supabase (Relational Data)]
    end
    
    subgraph ExternalServices [Third Party APIs]
        Gemini[Google Gemini AI]
        Maps[Google Maps API]
        Telebirr[Telebirr Payment Gateway]
    end

    User -->|Interacts| UI
    UI -->|Triggers| State
    State -->|Calls| Repo
    
    Repo -->|Auth Tokens| Auth
    Repo -->|CRUD Operations| DB
    Repo -->|File Uploads| Storage
    Repo -->|SQL Queries| Supabase
    
    Repo -->|Prompt Engineering| Gemini
    Repo -->|Payment Request| Telebirr
Directory Structure Explanation
We enforce a strict "Feature-First" directory structure to maintain scalability.
code
Text
lib/
├── main.dart                       # 🚀 Application Entry Point
├── firebase_options.dart           # 🔥 Firebase Auto-Generated Config
│
├── config/                         # ⚙️ Global App Configuration
│   ├── theme.dart                  # Light/Dark Theme Definitions
│   ├── routes.dart                 # Named Route Definitions
│   └── constants.dart              # API Keys (GitIgnored), Colors, Strings
│
├── models/                         # 📦 Data Transfer Objects (DTOs)
│   ├── user_model.dart             # AppUser (Client/Worker) Serializers
│   ├── job_model.dart              # Job Posting Logic
│   ├── chat_model.dart             # Message Structure
│   └── review_model.dart           # Rating System
│
├── providers/                      # 🧠 State Management (Business Logic)
│   ├── auth_provider.dart          # Login/Reg State
│   ├── job_provider.dart           # Job CRUD State
│   ├── locale_provider.dart        # Language Switching Logic
│   └── theme_provider.dart         # Theme Switching Logic
│
├── repositories/                   # 🔌 Data Layer (API Abstractions)
│   ├── auth_repository.dart        # Firebase Auth Wrapper
│   ├── firestore_repository.dart   # DB Operations
│   └── storage_repository.dart     # Image Upload Logic
│
├── services/                       # 🌐 External API Services
│   ├── ai_service.dart             # Google Gemini Implementation
│   ├── payment_service.dart        # Telebirr HTTP Logic
│   ├── fcm_service.dart            # Push Notification Handler
│   └── location_service.dart       # Geolocator Logic
│
├── screens/                        # 🎨 UI Views
│   ├── auth/                       # Login, Register, Forgot Password
│   ├── client/                     # Client-Specific Dashboards
│   ├── worker/                     # Worker-Specific Dashboards
│   ├── shared/                     # Chat, Profile, Settings
│   └── onboarding/                 # Intro Slider
│
├── widgets/                        # 🧱 Reusable UI Components
│   ├── custom_button.dart
│   ├── custom_textfield.dart
│   ├── job_card.dart
│   └── ai_chat_bubble.dart
│
└── utils/                          # 🛠️ Helpers & Extensions
    ├── validators.dart             # Form Validation Regex
    ├── date_formatter.dart
    └── currency_formatter.dart
🛠️ Tech Stack Deep Dive
Client-Side (Frontend)
Flutter (Dart): Chosen for its ability to compile to native ARM code for both iOS and Android from a single codebase.
Provider: Selected over BLoC/Riverpod for this iteration due to its simplicity and direct integration with the Flutter widget tree.
Framer Motion (Flutter Animate): Used for the smooth entrance animations seen in the Splash and Onboarding screens.
Server-Side (Backend)
Firebase Firestore: A NoSQL document store perfectly suited for the flexible schema of job posts and user profiles. Real-time listeners power the Chat feature.
Supabase: Used for complex relational queries (e.g., "Find workers who have completed > 50 jobs AND have a rating > 4.5").
Firebase Storage: Stores user profile pictures and job attachment images (before/after photos).
Intelligence & Utilities
Google Gemini (via google_generative_ai package): We use the gemini-pro model for text generation. The prompt engineering logic is encapsulated in services/ai_service.dart to ensure the AI behaves as a "Home Improvement Expert".
Telebirr: We implement the H5 web payment flow / API integration to allow local currency transactions.
🚀 Getting Started
This guide assumes you are setting up the project for development purposes.
Prerequisites
OS: macOS, Windows, or Linux.
Tools: VS Code or Android Studio.
SDKs: Flutter SDK (v3.0+), Java JDK 11/17.
Accounts: Google Cloud Account (for Firebase), Supabase Account.
Step 1: Clone & Install
code
Bash
# Clone the repository
git clone https://github.com/biruk-77/fixit.git

# Navigate into the directory
cd fixit

# Install Flutter dependencies
flutter pub get
Step 2: Firebase Configuration
FixIt relies heavily on Firebase. You must supply your own credentials.
Go to Firebase Console.
Create a new project named fixit-dev.
Enable Authentication: Turn on Email/Password and Google Sign-In.
Create Firestore Database: Start in "Test Mode".
Enable Storage: Create a bucket.
Run FlutterFire CLI:
code
Bash
# Make sure you are logged in
firebase login

# Configure the app
flutterfire configure
Select fixit-dev and support Android and iOS.
Step 3: Environment Variables
Create a .env file in the root of your project (this is .gitignore'd).
code
Env
# Google Gemini API
GEMINI_API_KEY=AIzaSy...your_key_here

# Telebirr Credentials (Sandbox)
TELEBIRR_APP_ID=your_app_id
TELEBIRR_APP_KEY=your_app_key
TELEBIRR_PUBLIC_KEY=your_public_key

# Supabase (Optional)
SUPABASE_URL=https://xyz.supabase.co
SUPABASE_ANON_KEY=eyJhb...
Step 4: Run the App
Android:
code
Bash
flutter run
iOS (macOS only):
code
Bash
cd ios
pod install
cd ..
flutter run
📖 Usage Guide
For Clients
Post a Job: Tap the "+" button on the bottom nav. Upload a photo of the issue (e.g., broken pipe).
Wait for Bids: Professionals will receive a notification. Wait for bids to appear in the "My Jobs" tab.
Consult AI: If you aren't sure what the problem is, go to the "AI Chat" tab and ask Gemini.
Hire: Accept a bid. Chat with the worker to confirm time.
Pay: Once the job is marked "Completed" by the worker, release payment via Telebirr.
For Professionals
Verify Profile: Upload your ID and certificates in the Settings tab.
Browse Map: Use the "Explore" tab to see jobs near you.
Bid: Send a competitive price.
Work: Use the app to navigate to the client's location.
🐛 Troubleshooting
Issue: google-services.json missing
Fix: You skipped Step 2. You must download this file from Firebase Console > Project Settings > Android and place it in android/app/.
Issue: Google Sign-In fails (SHA-1 Error)
Fix: You need to add your machine's debug SHA-1 fingerprint to the Firebase Console.
Run cd android && ./gradlew signingReport
Copy the SHA1 under debug.
Paste it into Firebase Project Settings.
Issue: Gemini AI returns 403
Fix: Ensure your API key is valid and you have enabled the "Generative Language API" in Google Cloud Console.
🛣️ Roadmap

Basic Auth & Role Management

Job Posting & Bidding

Real-time Chat

Gemini AI Integration

Phase 2: Video Call integration for remote consultations.

Phase 2: Admin Web Panel for dispute resolution.

Phase 3: Apple Sign-In & iOS production release.

Phase 4: Machine Learning model for automatic price estimation.
🤝 Contributing
We welcome contributions from the community!
Fork the project.
Create your Feature Branch (git checkout -b feature/AmazingFeature).
Commit your changes (git commit -m 'Add some AmazingFeature').
Push to the branch (git push origin feature/AmazingFeature).
Open a Pull Request.
Please read CONTRIBUTING.md for details on our code of conduct and the process for submitting pull requests.
📄 License
Distributed under the MIT License. See LICENSE for more information.
🙏 Acknowledgments
Google Developers Group (GDG) for Flutter & Firebase resources.
OpenAI & Google DeepMind for inspiring the AI features.
The Flutter Community for amazing packages like flutter_animate and provider.
<div align="center">
<p>Made with ❤️ in Ethiopia 🇪🇹 by <strong>Biruk Zewude</strong></p>
<p>
<a href="https://github.com/biruk-77">
<img src="https://img.shields.io/badge/GitHub-biruk--77-181717?style=flat&logo=github" alt="GitHub"/>
</a>
<a href="mailto:your-email@example.com">
<img src="https://img.shields.io/badge/Email-Contact_Me-D14836?style=flat&logo=gmail&logoColor=white" alt="Email"/>
</a>
</p>
<p>&copy; 2025 FixIt Inc.</p>
</div>
<p align="right">(<a href="#readme-top">back to top</a>)</p>

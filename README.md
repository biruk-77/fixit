
<div align="center">
  <img src="https://img.icons8.com/fluency/96/maintenance.png" alt="FixIt Logo" width="100"/>
  <h1>🛠️ FixIt - Professional Service Marketplace</h1>
  
  <p>
    <strong>The Uber for Skilled Professionals.</strong><br>
    <em>Connect, Hire, and Get the Job Done with the power of Flutter & AI.</em>
  </p>

  <p>
    <a href="https://flutter.dev">
      <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
    </a>
    <a href="https://firebase.google.com">
      <img src="https://img.shields.io/badge/Firebase-Backend-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase" />
    </a>
    <a href="https://ai.google.dev/">
      <img src="https://img.shields.io/badge/AI_Powered_By-Gemini-8E75B2?style=for-the-badge&logo=google&logoColor=white" alt="Gemini" />
    </a>
    <a href="https://github.com/biruk-77/fixit/blob/main/LICENSE">
      <img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License" />
    </a>
  </p>
</div>

---

## 📱 App Gallery

<div align="center">
  <table>
    <tr>
      <td align="center"><img src="https://i.ibb.co/1tmLnnxH/photo-1-2025-12-09-04-38-02.jpg" width="200px" alt="Splash Screen"/><br><b>Splash & Intro</b></td>
      <td align="center"><img src="https://i.ibb.co/Wp5CZV8M/photo-2-2025-12-09-04-38-02.jpg" width="200px" alt="Login"/><br><b>Authentication</b></td>
      <td align="center"><img src="https://i.ibb.co/dqzH3L0/photo-3-2025-12-09-04-38-02.jpg" width="200px" alt="Home Dashboard"/><br><b>Home Dashboard</b></td>
      <td align="center"><img src="https://i.ibb.co/mV9bRnDN/photo-4-2025-12-09-04-38-02.jpg" width="200px" alt="Services"/><br><b>Service Categories</b></td>
    </tr>
    <tr>
      <td align="center"><img src="https://i.ibb.co/5WQ8FmbP/photo-5-2025-12-09-04-38-02.jpg" width="200px" alt="Job Details"/><br><b>Job Details</b></td>
      <td align="center"><img src="https://i.ibb.co/9mksN0Gt/photo-6-2025-12-09-04-38-02.jpg" width="200px" alt="Profile"/><br><b>Pro Profile</b></td>
      <td align="center"><img src="https://i.ibb.co/ynSjK6wh/photo-7-2025-12-09-04-38-02.jpg" width="200px" alt="AI Chat"/><br><b>AI Assistant</b></td>
      <td align="center"><img src="https://i.ibb.co/rf3XJJkN/photo-8-2025-12-09-04-38-02.jpg" width="200px" alt="My Jobs"/><br><b>Active Jobs</b></td>
    </tr>
     <tr>
      <td align="center"><img src="https://i.ibb.co/WWSD3G2g/photo-9-2025-12-09-04-38-02.jpg" width="200px" alt="Payments"/><br><b>Secure Payment</b></td>
      <td align="center"><img src="https://i.ibb.co/hFjT3HL6/photo-10-2025-12-09-04-38-02.jpg" width="200px" alt="Settings"/><br><b>Settings & Theme</b></td>
      <td align="center" colspan="2"><h3>✨ Experience the flow</h3><p>From posting a job to hiring a pro.</p></td>
    </tr>
  </table>
</div>

---

## 📋 Project Overview

**FixIt** revolutionizes how clients find and hire skilled professionals. It is a robust two-sided marketplace platform where:

-   **Clients** can effortlessly post jobs, review proposals, hire top-tier professionals, and manage secure payments.
-   **Professionals** can browse a wide array of available jobs, apply for relevant work, and build their reputation.

Our platform leverages a powerful backend powered by **Firebase** and **Supabase**, and is enhanced with **Google Generative AI (Gemini)** for smart assistance.

## 🌟 Key Features

*   🔒 **Secure Authentication**: Google Sign-In & Email/Password via Firebase Auth.
*   👥 **Dual User Roles**: Distinct interfaces for Clients and Professionals.
*   💬 **Real-time Chat**: Instant messaging between parties.
*   🔔 **Push Notifications**: Powered by Firebase Cloud Messaging (FCM).
*   💰 **Telebirr Integration**: Secure local payment gateway integration.
*   🤖 **Gemini AI Assistant**: In-app AI chatbot to help users describe problems or find services.
*   📍 **Geolocation**: Discovery of nearby professionals.
*   🌃 **Dark Mode**: Dynamic theme switching.
*   🌐 **Localization**: Support for English, Amharic, and Oromo.

---

## 🏗️ System Architecture

```mermaid
graph TD
    User[Mobile App User]
    
    subgraph Frontend [Flutter Application]
        UI[UI Screens]
        State[Provider State Mgmt]
        Services[Service Layer]
    end
    
    subgraph Backend [Cloud Services]
        Auth[Firebase Auth]
        DB[Firestore NoSQL]
        Storage[Firebase Storage]
        AI[Google Gemini API]
        Pay[Telebirr API]
    end

    User --> UI
    UI --> State
    State --> Services
    Services -->|Auth| Auth
    Services -->|Data Sync| DB
    Services -->|Images| Storage
    Services -->|Chat/Advice| AI
    Services -->|Transactions| Pay
🛠️ Tech Stack
Component	Technology	Description
Framework	
![alt text](https://img.shields.io/badge/Flutter-%2302569B.svg?style=flat&logo=Flutter&logoColor=white)
	Cross-platform UI Toolkit
Language	
![alt text](https://img.shields.io/badge/dart-%230175C2.svg?style=flat&logo=dart&logoColor=white)
	Core logic language
Backend	
![alt text](https://img.shields.io/badge/firebase-%23039BE5.svg?style=flat&logo=firebase)
	Auth, Database, Storage, Messaging
AI Engine	
![alt text](https://img.shields.io/badge/Google%20Gemini-8E75B2?style=flat&logo=google&logoColor=white)
	Intelligent Chat Assistant
Database	
![alt text](https://img.shields.io/badge/Supabase-3ECF8E?style=flat&logo=supabase&logoColor=white)
	Secondary Data Management
Payments	Telebirr	Mobile Money Integration
📂 Project Structure
code
Text
download
content_copy
expand_less
lib/
├── main.dart                          # App entry point & Routing
├── firebase_options.dart              # Firebase Config
├── models/                            # Data Models (User, Job, Worker)
├── providers/                         # State Management (Provider)
├── screens/                           # UI Views
│   ├── auth/                          # Login/Register
│   ├── chat/                          # Real-time Messaging
│   ├── home/                          # Dashboard
│   ├── jobs/                          # Job Posting & Tracking
│   ├── payment/                       # Telebirr Integration
│   └── widgets/                       # Reusable Components
├── services/                          # API Integrations
│   ├── gemini_service.dart            # AI Logic
│   ├── auth_service.dart              # Firebase Auth
│   └── fcm_service.dart               # Push Notifications
└── assets/                            # Images & Icons
🚀 Installation & Setup
Prerequisites

Flutter SDK (3.x or higher)

VS Code or Android Studio

A Firebase Project

Steps

Clone the Repository

code
Bash
download
content_copy
expand_less
git clone https://github.com/biruk-77/fixit.git
cd fixit

Install Dependencies

code
Bash
download
content_copy
expand_less
flutter pub get

Firebase Configuration

Install the Firebase CLI.

Run flutterfire configure to connect your app to your Firebase project.

This will generate the firebase_options.dart file.

Environment Variables (API Keys)

Create a .env file or configure your gemini_service.dart with your Google AI Studio Key.

Configure screens/payment/config.dart with your Telebirr credentials.

Run the App

code
Bash
download
content_copy
expand_less
# Run on connected device (Emulator or Physical)
flutter run
🤝 Contributing

We welcome contributions!

Fork the project.

Create your Feature Branch (git checkout -b feature/AmazingFeature).

Commit your changes (git commit -m 'Add some AmazingFeature').

Push to the branch (git push origin feature/AmazingFeature).

Open a Pull Request.

📜 License

Distributed under the MIT License. See LICENSE for more information.

<div align="center">
<p>Made with ❤️ by <strong>Biruk Zewude</strong></p>
<p>
<a href="https://github.com/biruk-77">
<img src="https://img.shields.io/badge/Follow_Me-GitHub-black?style=for-the-badge&logo=github" />
</a>
</p>
</div>

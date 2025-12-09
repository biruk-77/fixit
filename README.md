# FixIt - Professional Service Marketplace

A comprehensive Flutter application that connects clients with service professionals (workers) for job posting, bidding, and completion. Built with Firebase, Supabase, and Google Generative AI.

## 📋 Project Overview

**FixIt** is a two-sided marketplace platform where:
- **Clients** can post jobs, review proposals, hire professionals, and manage payments
- **Professionals** can browse available jobs, apply for work, complete tasks, and build their reputation

### Key Features

- **Authentication**: Firebase Auth with Google Sign-In support
- **Dual User Roles**: Client and Professional (Worker) with distinct interfaces
- **Job Management**: Create, browse, apply, and complete jobs
- **Real-time Chat**: In-app messaging between clients and professionals
- **Notifications**: Firebase Cloud Messaging (FCM) + local notifications
- **Payment Integration**: Telebirr payment gateway for job payments
- **AI Chat Assistant**: Google Generative AI (Gemini) integration for smart assistance
- **Geolocation**: Distance-based worker discovery with service radius
- **Ratings & Reviews**: Professional reputation system
- **Multi-language Support**: English, Amharic, Oromo localization
- **Dark Mode**: Theme switching with Provider state management
- **File Management**: Job attachments via Firebase Storage
- **User Presence**: Online/offline status tracking

---

## 🏗️ Project Structure

```
lib/
├── main.dart                          # App entry point, routing, theme setup
├── firebase_options.dart              # Firebase configuration
│
├── models/                            # Data models
│   ├── user.dart                      # AppUser model (client/professional)
│   ├── job.dart                       # Job model with status tracking
│   ├── worker.dart                    # Professional profile model
│   ├── review.dart                    # Review/rating model
│   ├── chat_message.dart              # Chat message model
│   └── chat_messageai.dart            # AI chat message model
│
├── services/                          # Business logic & API integration
│   ├── auth_service.dart              # Firebase Auth, Google Sign-In
│   ├── firebase_service.dart          # Firestore operations, notifications
│   ├── fcm_service.dart               # Firebase Cloud Messaging setup
│   ├── notification_service.dart      # Local notifications
│   ├── ai_chat_service.dart           # Google Generative AI integration
│   ├── gemini_service.dart            # Gemini API wrapper
│   └── app_string.dart                # Localization strings
│
├── screens/                           # UI screens
│   ├── auth/
│   │   └── login_screen.dart          # Authentication UI
│   ├── home/
│   │   ├── home_layout.dart           # Main home screen layout
│   │   └── home_screen.dart           # Job feed & discovery
│   ├── jobs/
│   │   ├── create_job_screen.dart     # Job posting form
│   │   ├── job_dashboard_screen.dart  # Job management
│   │   └── job_detail_screen.dart     # Job details & applications
│   ├── chat/
│   │   └── chat_screen.dart           # Real-time messaging
│   ├── profile_screen.dart            # User profile management
│   ├── professional_setup_screen.dart # Professional profile setup
│   ├── professional_setup_edit.dart   # Professional profile editing
│   ├── worker_detail_screen.dart      # Professional profile view
│   ├── notifications_screen.dart      # Notification center
│   ├── account_screen.dart            # Account settings
│   ├── privacy_security_screen.dart   # Privacy & security settings
│   ├── help_support_screen.dart       # Help & support
│   ├── payment/                       # Payment screens
│   └── widgets/                       # Reusable UI components
│
├── providers/                         # State management (Provider)
│   ├── theme_provider.dart            # Dark/light theme toggle
│   └── locale_provider.dart           # Language/locale management
│
├── theme/
│   ├── light_colors.dart              # Color schemes & typography
│   └── app_theme.dart                 # Theme definitions
│
└── test/
    └── widget_test.dart               # Basic widget tests
```

---

## 🛠️ Technology Stack

### Frontend
- **Framework**: Flutter 3.8.1+
- **State Management**: Provider 6.1.2
- **UI Components**: Google Nav Bar, Line Icons, Font Awesome
- **Animations**: Flutter Animate, Animate Do, Avatar Glow
- **Localization**: Flutter Localizations (i18n)

### Backend & Services
- **Authentication**: Firebase Auth 6.0.1, Google Sign-In 7.1.1
- **Database**: Cloud Firestore 6.0.0
- **Storage**: Firebase Storage 13.0.0
- **Messaging**: Firebase Cloud Messaging 16.0.4, Firebase Messaging
- **Alternative Backend**: Supabase 2.3.1

### AI & Advanced Features
- **AI Chat**: Google Generative AI 0.4.7 (Gemini)
- **Payments**: Flutter Telebirr 0.0.4
- **Maps**: Flutter Map 8.2.1, Geolocator 14.0.2, Geocoding 4.0.0
- **Media**: Image Picker 1.1.2, Image Cropper 9.1.0, Cached Network Image 3.4.1
- **File Handling**: File Picker 10.3.3, Path Provider 2.1.3

### Utilities
- **Networking**: HTTP 1.5.0, Dio (implied)
- **Notifications**: Flutter Local Notifications 19.4.1
- **Audio**: Flutter Sound 9.28.0, Audio Waveforms 1.3.0, AudioPlayers 6.5.0
- **Charts**: FL Chart 0.66.2
- **Encryption**: Crypto 3.0.6, PointyCastle 3.7.3
- **UI Enhancements**: Shimmer, Carousel Slider, Table Calendar, Percent Indicator

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.8.1 or higher
- Dart SDK (bundled with Flutter)
- Firebase project setup
- Google Cloud project for Gemini API
- Supabase project (optional)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd finalend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place them in the appropriate directories
   - Update `firebase_options.dart` with your Firebase config

4. **Configure Supabase** (Optional)
   - Update the Supabase URL and Anon Key in `main.dart`

5. **Set up Gemini API**
   - Get API key from Google Cloud Console
   - Configure in `gemini_service.dart`

6. **Run the app**
   ```bash
   flutter run
   ```

---

## 📱 App Architecture

### Authentication Flow
1. User opens app → `AuthWrapper` checks login status
2. If logged in → `MainScreen` (role-based UI)
3. If not logged in → `LoginScreen` with email/Google sign-in
4. After login → User profile setup (for professionals)

### Role-Based Navigation
**Professional (Worker)**
- Feed (job browsing)
- Profile (view/edit)
- My Jobs (applications & active work)
- Setup (professional profile configuration)

**Client**
- Home (worker discovery & job feed)
- Post Job (create new job)
- Profile (view/edit)
- History (job management & payments)

### Data Flow
```
Firebase Auth → User Profile (Firestore) → Role Determination
                                         ↓
                                    MainScreen
                                    ↓
                    (Professional)          (Client)
                    ├─ HomeLayout          ├─ HomeLayout
                    ├─ ProfileScreen       ├─ CreateJobScreen
                    ├─ JobDashboard        ├─ ProfileScreen
                    └─ ProfSetup           └─ JobDashboard
```

---

## 🔑 Key Services

### AuthService
- Email/password authentication
- Google Sign-In (with silent authentication)
- User profile management
- Email verification

### FirebaseService
- Firestore CRUD operations
- Job management (create, update, apply)
- Notification listener setup
- User presence tracking (online/offline)
- File upload to Firebase Storage

### FCMService
- Firebase Cloud Messaging initialization
- Token management
- Push notification handling

### NotificationService
- Local notification display
- Notification tap handling
- Payload routing to relevant screens

### AIChatService / GeminiService
- Google Generative AI integration
- Smart chat responses
- Context-aware assistance

---

## 🎨 UI/UX Features

### Theme System
- Light and dark modes
- Dynamic color schemes
- Consistent typography via Google Fonts
- Theme provider for state management

### Localization
- **Supported Languages**: English, Amharic, Oromo
- **Strings**: Centralized in `app_string.dart`
- **Dynamic Switching**: Language change without app restart

### Responsive Design
- Adaptive layouts for different screen sizes
- Safe area handling
- Bottom navigation with Google Nav Bar
- Staggered animations for visual appeal

---

## 🔔 Notifications

### Push Notifications (FCM)
- Job applications received
- Job acceptance/rejection
- New messages
- Payment confirmations

### Local Notifications
- In-app notification display
- Sound and vibration feedback
- Tap-to-navigate functionality

### Real-time Updates
- Firestore listeners for job changes
- Chat message streaming
- Notification collection monitoring

---

## 💳 Payment Integration

**Telebirr Payment Gateway**
- Test mode configuration
- Job payment processing
- Transaction status tracking
- Payment history

---

## 🗺️ Geolocation Features

- Worker location tracking
- Service radius configuration
- Distance calculation from client
- Location-based worker discovery
- Address geocoding/reverse geocoding

---

## 📊 Database Schema (Firestore)

### Collections
- **users**: Client & professional profiles
- **jobs**: Job postings with status
- **applications**: Job applications from professionals
- **reviews**: Ratings and reviews
- **notifications**: User notifications
- **chat_rooms**: Chat conversation metadata
- **messages**: Chat messages
- **workers**: Professional detailed profiles

---

## 🧪 Testing

Run widget tests:
```bash
flutter test
```

---

## 📝 Configuration Files

### pubspec.yaml
- Defines all dependencies
- Flutter configuration
- Asset paths
- Launcher icon setup

### firebase.json
- Firebase deployment configuration

### analysis_options.yaml
- Dart linting rules
- Code quality standards

### FCM_SETUP_GUIDE.md
- Detailed Firebase Cloud Messaging setup instructions

---

## 🐛 Known Issues & Fixes

The codebase includes several documented fixes:
- **FIX #1**: StreamSubscription import for notification handling
- **FIX #2**: NotificationService integration
- **FIX #3**: Google Silent Sign-In using `attemptLightweightAuthentication`
- **Presence Tracking**: App lifecycle observer for online/offline status

---

## 🚦 Development Workflow

1. **Feature Development**: Create feature branch
2. **Testing**: Run `flutter test` and manual testing
3. **Code Quality**: Follow analysis_options.yaml rules
4. **Localization**: Add strings to `app_string.dart`
5. **Theme Consistency**: Use `AppThemes` for styling
6. **State Management**: Use Provider for global state

---

## 📚 Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase for Flutter](https://firebase.google.com/docs/flutter/setup)
- [Provider Package](https://pub.dev/packages/provider)
- [Google Generative AI](https://ai.google.dev/)
- [Firestore Documentation](https://firebase.google.com/docs/firestore)

---

## 📄 License

This project is proprietary and confidential.

---

## 👥 Support

For issues, questions, or contributions, please contact the development team.

---

## 🔐 Security Notes

- **API Keys**: Store sensitive keys in environment variables or secure configuration
- **Firebase Rules**: Implement proper Firestore security rules
- **Authentication**: Always validate tokens server-side
- **Data Privacy**: Comply with data protection regulations (GDPR, etc.)

---

## 🎯 Future Enhancements

- [ ] Video call integration (Agora/Twilio)
- [ ] Advanced analytics dashboard
- [ ] Subscription/premium features
- [ ] Offline-first capability
- [ ] Machine learning for job recommendations
- [ ] Advanced search and filtering
- [ ] Dispute resolution system
- [ ] Escrow payment system
#   f i x i t  
 
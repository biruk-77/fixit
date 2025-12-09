# Firebase Cloud Messaging (FCM) Setup Guide

## ✅ What's Been Done

1. ✅ Added `firebase_messaging: ^14.8.0` to `pubspec.yaml`
2. ✅ Created `lib/services/fcm_service.dart` - Complete FCM service
3. ✅ Updated `lib/main.dart` to initialize FCM on app startup

---

## 📋 Remaining Setup Steps

### Step 1: Android Configuration

Edit `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34  // Ensure this is 34 or higher
    
    defaultConfig {
        minSdkVersion 21  // FCM requires API 21+
    }
}
```

### Step 2: Android Manifest (Already Partially Done)

Your `android/app/src/main/AndroidManifest.xml` already has:
```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/app_notification_icon" />
```

Make sure you have the notification icon at:
`android/app/src/main/res/drawable/app_notification_icon.xml`

### Step 3: iOS Configuration

Edit `ios/Podfile` and ensure it has:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_NOTIFICATIONS=1',
      ]
    end
  end
end
```

### Step 4: Firebase Console Setup

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project
3. Go to **Cloud Messaging** tab
4. Download your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
5. Place them in:
   - Android: `android/app/google-services.json`
   - iOS: `ios/Runner/GoogleService-Info.plist`

### Step 5: Get FCM Token

The FCM token is automatically retrieved and printed in the console. You can also get it programmatically:

```dart
import 'services/fcm_service.dart';

// Get the FCM token
String? token = await FCMService().getToken();
print('FCM Token: $token');

// Save this token to Firestore for sending messages
```

### Step 6: Update Your Backend

When sending a message from your backend (e.g., when a user sends a chat message), send to FCM instead of just creating a Firestore notification:

```dart
// In your conversation_pane.dart or backend
Future<void> _sendMessage(ChatMessage message) async {
  // ... existing code ...
  
  // Send FCM notification
  await _firebaseService.sendFCMNotification(
    userId: widget.otherUserId,
    title: 'New message from ${_currentUser?.name}',
    body: message.message,
    data: {
      'chatRoomId': _chatRoomId,
      'senderId': _currentUserId,
      'senderName': _currentUser?.name,
      'senderImageUrl': _currentUser?.profileImage,
      'type': 'message_received',
    },
  );
}
```

---

## 🔧 How FCM Works in Your App

### Foreground Messages (App is Open)
When the app is open and a message arrives:
1. `FirebaseMessaging.onMessage.listen()` triggers
2. `_handleForegroundMessage()` is called
3. A local notification is shown using `flutter_local_notifications`

### Background Messages (App is Closed/Minimized)
When the app is closed and a message arrives:
1. `FirebaseMessaging.onBackgroundMessage()` triggers
2. `_handleBackgroundMessage()` is called (top-level function)
3. A system notification is shown

### Notification Tap
When user taps a notification:
1. `FirebaseMessaging.onMessageOpenedApp.listen()` triggers
2. `_handleMessageOpenedApp()` is called
3. App navigates to the relevant screen (chat, job, etc.)

---

## 📱 Testing FCM

### Option 1: Firebase Console
1. Go to Cloud Messaging → Send your first message
2. Select your app
3. Enter title and body
4. Target: Single device (paste the FCM token)
5. Click Send

### Option 2: Postman/cURL
```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=YOUR_SERVER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "FCM_TOKEN_HERE",
    "notification": {
      "title": "Test Message",
      "body": "This is a test"
    },
    "data": {
      "chatRoomId": "room123",
      "type": "message_received"
    }
  }'
```

---

## 🎯 Topics (Optional)

Subscribe users to topics for bulk messaging:

```dart
// Subscribe to a topic
await FCMService().subscribeToTopic('all_users');

// Send to all users subscribed to a topic
// (Do this from your backend)
```

---

## 🔐 Security Rules (Firestore)

Update your Firestore rules to allow FCM token storage:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      
      match /fcm_tokens/{token} {
        allow write: if request.auth.uid == userId;
      }
    }
  }
}
```

---

## 📊 Hybrid Approach (FCM + Firestore Listeners)

Your app now uses **both**:

| Method | Use Case |
|--------|----------|
| **FCM** | Push notifications to devices (works even when app is closed) |
| **Firestore Listeners** | Real-time updates when app is open |

This is the **best practice** for production apps!

---

## 🐛 Troubleshooting

### FCM Token is null
- Check Firebase Console → Cloud Messaging is enabled
- Ensure `google-services.json` is in `android/app/`
- Ensure `GoogleService-Info.plist` is in `ios/Runner/`

### Notifications not showing
- Check notification permissions are granted
- Verify `flutter_local_notifications` is initialized
- Check logcat/console for errors

### Messages not received in background
- Ensure `_handleBackgroundMessage()` is a top-level function
- Check that the function is properly registered
- Verify app has notification permissions

---

## 📚 Resources

- [Firebase Messaging Docs](https://firebase.flutter.dev/docs/messaging/overview/)
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications)
- [FCM Best Practices](https://firebase.google.com/docs/cloud-messaging/concept-options)

---

## 🚀 Next Steps

1. Run `flutter pub get` to install `firebase_messaging`
2. Complete Android/iOS configuration above
3. Download and place Firebase config files
4. Test FCM using Firebase Console
5. Update your backend to send FCM notifications
6. Monitor logs for any issues

Good luck! 🎉

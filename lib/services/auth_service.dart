import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseService _firebaseService = FirebaseService();
  // -----------------------

  // This stream is for your AuthWrapper to listen to login/logout changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Check if user is logged in
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Trim inputs to avoid whitespace issues
      email = email.trim();
      password = password.trim();

      print('Attempting to sign in with email: $email');

      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      print('Successfully signed in user: ${userCredential.user?.uid}');
      await _firebaseService.setupNotificationListener();
      return userCredential;
    } catch (e) {
      print('Error signing in: $e');
      rethrow;
    }
  }
  // Inside class AuthService in lib/services/auth_service.dart
  // Inside class AuthService in lib/services/auth_service.dart

  // --- NEW: Google Silent Sign-In Method ---
  Future<bool> signInSilentlyWithGoogle() async {
    try {
      print("Attempting Google Silent Sign In...");

      // =========================================================================
      // ========== FIX #3: Use the new `attemptLightweightAuthentication` ==========
      // =========================================================================
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .attemptLightweightAuthentication();

      if (googleUser == null) {
        print("No existing Google user found silently.");
        return false;
      }

      print("Found Google user silently: ${googleUser.email}");
      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: kIsWeb ? null : googleAuth.idToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      if (_auth.currentUser != null) {
        print("Firebase silent sign-in successful: ${_auth.currentUser!.uid}");
        await _firebaseService.setupNotificationListener();
        return true;
      } else {
        print("Silent sign-in failed to produce a Firebase user.");
        return false;
      }
    } catch (e, s) {
      print("Error during Google Silent Sign In: $e\n$s");
      return false;
    }
  }

  Future<void> sendEmailVerificationLink() async {
    try {
      final user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        print('Verification email sent to ${user.email}');
      } else if (user == null) {
        print('Cannot send verification email: User is not logged in.');
      } else {
        print(
          'Verification email not sent: Email (${user.email}) is already verified.',
        );
      }
    } catch (e, s) {
      print('Error sending verification email: $e\n$s');
      // Consider rethrowing or handling the error appropriately
    }
  }

  // 2. Sign in with Phone Credential (after getting OTP)
  Future<UserCredential?> signInWithPhoneOtp({
    required String verificationId,
    required String smsCode, // The OTP entered by the user
  }) async {
    try {
      print('Attempting sign in with OTP...');
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      // Sign in the user with the credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      print('Phone OTP Sign In Successful: ${userCredential.user?.uid}');
      return userCredential; // Return credential for profile creation etc.
    } on FirebaseAuthException catch (e) {
      print(
        'Firebase Auth Exception during Phone OTP Sign In: ${e.code} - ${e.message}',
      );
      // Handle specific errors like 'invalid-verification-code', 'session-expired' etc.
      rethrow; // Allow UI to handle error
    } catch (e, s) {
      print('General Error during Phone OTP Sign In: $e\n$s');
      rethrow;
    }
  }

  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    try {
      print("AuthService: Signing in with provided credential...");
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      print(
        "AuthService: Credential sign in successful. UID: ${userCredential.user?.uid}",
      );
      return userCredential;
    } catch (e) {
      print("AuthService: Error signing in with credential: $e");
      rethrow; // Let the UI handle feedback
    }
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String verificationId, int? resendToken) codeSent,
    required Function(String verificationId) codeAutoRetrievalTimeout,
    Duration timeout = const Duration(seconds: 60),
    int? resendToken, // <-- *** ENSURE THIS NAMED PARAMETER IS PRESENT ***
  }) async {
    print(
      'AuthService: Verifying phone: $phoneNumber ${resendToken != null ? "(Resending with token $resendToken)" : "(Initial)"}',
    );
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: verificationFailed,
        codeSent: codeSent,
        codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
        timeout: timeout,
        forceResendingToken: resendToken, // <-- Pass the token here
      );
    } catch (e, s) {
      print('AuthService: Error calling _auth.verifyPhoneNumber: $e\n$s');
      rethrow; // Let UI handle errors
    }
  }

  Future<void> createUserProfile({
    required String userId,
    required String name,
    required String email,
    required String phone,
    required String userType, // 'client' or 'worker'
    String? profession,
    String? photoUrl,
  }) async {
    try {
      final docRefUser = _firestore.collection('users').doc(userId);
      final docRefProf = _firestore.collection('professionals').doc(userId);

      // Check both locations to see if a profile already exists
      final docSnapUser = await docRefUser.get();
      final docSnapProf = await docRefProf.get();

      if (docSnapUser.exists || docSnapProf.exists) {
        print("User profile already exists for $userId. Skipping creation.");
        return; // Exit the function if a profile is found
      }

      print("Creating new profile for user $userId...");

      // --- THIS IS THE NEW PART ---
      // We'll use a batch write to create the profile AND the first notification atomically.
      WriteBatch batch = _firestore.batch();

      // Prepare the common user data
      Map<String, dynamic> userData = {
        'id': userId,
        'name': name,
        'email': email,
        'phoneNumber': phone,
        'profileImage': photoUrl ?? '',
        'role': userType, // 'client' or 'worker'
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Prepare the welcome notification data
      Map<String, dynamic> welcomeNotification = {
        'userId': userId,
        'title': 'Welcome to Fixit! 🎉',
        'body': 'We\'re so glad to have you. Explore the app to get started.',
        'type': 'welcome_message',
        'data': {
          'jobId': '', // No specific job for a welcome message
          // You could add a deep link to a 'getting_started' page later
          'page': 'home',
        },
        'isRead': false,
        'isArchived': false,
        'priority': 1, // Low priority
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Determine where to create the profile and notification
      if (userType == 'client') {
        // Add client-specific fields
        userData.addAll({
          'jobsPosted': 0,
          'completedJobs': 0,
          'favoriteWorkers': [],
        });

        // 1. Set the main user document in the batch
        batch.set(docRefUser, userData);

        // 2. Set the welcome notification in the subcollection
        final notificationRef = docRefUser.collection('notifications').doc();
        batch.set(notificationRef, welcomeNotification);

        print('Client profile and welcome notification prepared for batch.');
      } else {
        // 'worker'
        // Add worker-specific fields
        userData.addAll({
          'profession': profession ?? '',
          'profileComplete': false, // Worker needs to complete setup
          'rating': 0.0,
          'reviewCount': 0,
          'completedJobs': 0,
        });

        // 1. Set the main professional document in the batch
        batch.set(docRefProf, userData);

        // 2. Set the welcome notification in the subcollection
        final notificationRef = docRefProf.collection('notifications').doc();
        batch.set(notificationRef, welcomeNotification);

        print('Worker profile and welcome notification prepared for batch.');
      }

      // --- Commit the batch ---
      await batch.commit();
      print(
        '✅ Successfully created profile and welcome notification for user $userId.',
      );
    } catch (e) {
      print('🔥 Error creating user profile and initial notification: $e');
      rethrow;
    }
  }

  // Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      // Trim inputs to avoid whitespace issues
      email = email.trim();
      password = password.trim();

      print('Attempting to create user with email: $email');

      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      print('Successfully created user: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // =========================================================================
      // ========== FIX #2: Use the new `authenticate` method ==========
      // =========================================================================
      final GoogleSignInAccount googleUser = await _googleSignIn
          .authenticate();

      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: kIsWeb ? null : googleAuth.idToken,
        idToken: googleAuth.idToken,
      );

      print('Signing in to Firebase with Google credential...');
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      print('Firebase Google Sign In OK: ${userCredential.user?.uid}');

      if (userCredential.user != null) {
        await createUserProfile(
          userId: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? 'Google User',
          email: userCredential.user!.email ?? '',
          phone: userCredential.user!.phoneNumber ?? '',
          userType: 'client',
          photoUrl: userCredential.user!.photoURL,
        );
        await _firebaseService.setupNotificationListener();
      }
      return userCredential;
    } catch (e, s) {
      print('❌ Google Sign In Error: $e\n$s');
      rethrow;
    }
  }

  // Get current user profile
  Future<AppUser?> getCurrentUserProfile() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user found for profile retrieval');
        return null;
      }

      print('Attempting to retrieve profile for user: ${user.uid}');

      // Check in professionals collection first
      final professionalDoc = await _firestore
          .collection('professionals')
          .doc(user.uid)
          .get();
      if (professionalDoc.exists) {
        final data = professionalDoc.data()!;
        data['id'] = user.uid; // Ensure ID is set
        print('Found professional profile for ${user.uid}');
        return AppUser.fromJson(data);
      }

      // Then check in clients collection
      final clientDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      if (clientDoc.exists) {
        final data = clientDoc.data()!;
        data['id'] = user.uid; // Ensure ID is set
        print('Found client profile for ${user.uid}');
        return AppUser.fromJson(data);
      }

      // If no profile found, return null
      print('No profile found for user ${user.uid}');
      return null;
    } catch (e) {
      print('Error retrieving user profile: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _firebaseService.cancelNotificationListener();
      await _googleSignIn.signOut();
      print('User signed out');
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
}

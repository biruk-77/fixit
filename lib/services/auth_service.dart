import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/foundation.dart' show debugPrint;
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

      debugPrint('Attempting to sign in with email: $email');

      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      debugPrint('Successfully signed in user: ${userCredential.user?.uid}');
      await _firebaseService.setupNotificationListener();
      return userCredential;
    } catch (e) {
      debugPrint('Error signing in: $e');
      rethrow;
    }
  }
  // Inside class AuthService in lib/services/auth_service.dart
  // Inside class AuthService in lib/services/auth_service.dart

  // --- NEW: Google Silent Sign-In Method ---
  Future<bool> signInSilentlyWithGoogle() async {
    try {
      debugPrint("Attempting Google Silent Sign In...");

      // =========================================================================
      // ========== FIX #3: Use the new `attemptLightweightAuthentication` ==========
      // =========================================================================
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .attemptLightweightAuthentication();

      if (googleUser == null) {
        debugPrint("No existing Google user found silently.");
        return false;
      }

      debugPrint("Found Google user silently: ${googleUser.email}");
      final GoogleSignInAuthentication googleAuth =
          googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: kIsWeb ? null : googleAuth.idToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);

      if (_auth.currentUser != null) {
        debugPrint("Firebase silent sign-in successful: ${_auth.currentUser!.uid}");
        await _firebaseService.setupNotificationListener();
        return true;
      } else {
        debugPrint("Silent sign-in failed to produce a Firebase user.");
        return false;
      }
    } catch (e, s) {
      debugPrint("Error during Google Silent Sign In: $e\n$s");
      return false;
    }
  }

  Future<void> sendEmailVerificationLink() async {
    try {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('📧 EMAIL VERIFICATION - Starting Process');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      final user = _auth.currentUser;
      
      debugPrint('Step 1: Checking current user...');
      if (user == null) {
        debugPrint('❌ ERROR: No user is currently logged in!');
        debugPrint('   Cannot send verification email without an authenticated user.');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        return;
      }
      
      debugPrint('✅ Current user found:');
      debugPrint('   • User ID: ${user.uid}');
      debugPrint('   • Email: ${user.email}');
      debugPrint('   • Display Name: ${user.displayName ?? "(not set)"}');
      debugPrint('   • Email Verified: ${user.emailVerified}');
      
      if (user.emailVerified) {
        debugPrint('ℹ️  Email is already verified - no need to send verification link');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
        return;
      }
      
      debugPrint('\nStep 2: Sending verification email...');
      debugPrint('   Target email: ${user.email}');
      
      await user.sendEmailVerification();
      
      debugPrint('✅ SUCCESS: Firebase sendEmailVerification() completed!');
      debugPrint('   Email should be sent to: ${user.email}');
      debugPrint('\n⚠️  IMPORTANT: Check the following:');
      debugPrint('   1. Check SPAM/JUNK folder');
      debugPrint('   2. Email may take 1-2 minutes to arrive');
      debugPrint('   3. Sender: noreply@${user.email?.split('@').last ?? "firebase"}.firebaseapp.com');
      debugPrint('   4. If no email after 5 minutes, check Firebase Console quota');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      
    } catch (e, s) {
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('❌ EMAIL VERIFICATION - ERROR OCCURRED');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('Error Type: ${e.runtimeType}');
      debugPrint('Error Message: $e');
      debugPrint('\nStack Trace:');
      debugPrint('$s');
      debugPrint('\n💡 Possible causes:');
      debugPrint('   • Firebase Authentication not enabled in console');
      debugPrint('   • Network connection issue');
      debugPrint('   • Firebase quota exceeded');
      debugPrint('   • User session expired');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');
      rethrow; // Re-throw so calling code can handle it
    }
  }

  // 2. Sign in with Phone Credential (after getting OTP)
  Future<UserCredential?> signInWithPhoneOtp({
    required String verificationId,
    required String smsCode, // The OTP entered by the user
  }) async {
    try {
      debugPrint('Attempting sign in with OTP...');
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      // Sign in the user with the credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      debugPrint('Phone OTP Sign In Successful: ${userCredential.user?.uid}');
      return userCredential; // Return credential for profile creation etc.
    } on FirebaseAuthException catch (e) {
      debugPrint(
        'Firebase Auth Exception during Phone OTP Sign In: ${e.code} - ${e.message}',
      );
      // Handle specific errors like 'invalid-verification-code', 'session-expired' etc.
      rethrow; // Allow UI to handle error
    } catch (e, s) {
      debugPrint('General Error during Phone OTP Sign In: $e\n$s');
      rethrow;
    }
  }

  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    try {
      debugPrint("AuthService: Signing in with provided credential...");
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );
      debugPrint(
        "AuthService: Credential sign in successful. UID: ${userCredential.user?.uid}",
      );
      return userCredential;
    } catch (e) {
      debugPrint("AuthService: Error signing in with credential: $e");
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
    debugPrint(
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
      debugPrint('AuthService: Error calling _auth.verifyPhoneNumber: $e\n$s');
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
        debugPrint("User profile already exists for $userId. Skipping creation.");
        return; // Exit the function if a profile is found
      }

      debugPrint("Creating new profile for user $userId...");

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

        debugPrint('Client profile and welcome notification prepared for batch.');
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

        debugPrint('Worker profile and welcome notification prepared for batch.');
      }

      // --- Commit the batch ---
      await batch.commit();
      debugPrint(
        '✅ Successfully created profile and welcome notification for user $userId.',
      );
    } catch (e) {
      debugPrint('🔥 Error creating user profile and initial notification: $e');
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

      debugPrint('Attempting to create user with email: $email');

      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      debugPrint('Successfully created user: ${userCredential.user?.uid}');
      return userCredential;
    } catch (e) {
      debugPrint('Error creating user: $e');
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

      debugPrint('Signing in to Firebase with Google credential...');
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      debugPrint('Firebase Google Sign In OK: ${userCredential.user?.uid}');

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
      debugPrint('❌ Google Sign In Error: $e\n$s');
      rethrow;
    }
  }

  // Get current user profile
  Future<AppUser?> getCurrentUserProfile() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        debugPrint('No authenticated user found for profile retrieval');
        return null;
      }

      debugPrint('Attempting to retrieve profile for user: ${user.uid}');

      // Check in professionals collection first
      final professionalDoc = await _firestore
          .collection('professionals')
          .doc(user.uid)
          .get();
      if (professionalDoc.exists) {
        final data = professionalDoc.data()!;
        data['id'] = user.uid; // Ensure ID is set
        debugPrint('Found professional profile for ${user.uid}');
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
        debugPrint('Found client profile for ${user.uid}');
        return AppUser.fromJson(data);
      }

      // If no profile found, return null
      debugPrint('No profile found for user ${user.uid}');
      return null;
    } catch (e) {
      debugPrint('Error retrieving user profile: $e');
      return null;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _firebaseService.cancelNotificationListener();
      await _googleSignIn.signOut();
      debugPrint('User signed out');
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }
}

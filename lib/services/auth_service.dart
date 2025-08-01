import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
      final GoogleSignInAccount? googleUser = await _googleSignIn
          .signInSilently();

      if (googleUser == null) {
        print("No existing Google user found silently.");
        return false; // No user signed in previously or they signed out
      }

      print("Found Google user silently: ${googleUser.email}");

      // Optional: Authenticate with Firebase silently if needed
      // You might not need to do this if Firebase Auth state persistence works reliably.
      // If you *do* need it:
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      print("Firebase silent sign-in successful.");

      // Check if Firebase already has a user (more reliable)
      if (_auth.currentUser != null) {
        print("Firebase user already authenticated: ${_auth.currentUser!.uid}");
        return true;
      } else {
        print(
          "Google user found, but no Firebase user. Manual login required.",
        );
        // Attempting Firebase sign-in here might be redundant if persistence is on.
        // You could try signing in with the credential obtained above if needed.
        return false; // Indicate manual login might be needed if Firebase isn't sync'd
      }
    } catch (e, s) {
      print("Error during Google Silent Sign In: $e\n$s");
      return false; // Treat errors as not signed in
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
    required String userId, // <<< MAKE SURE THIS IS REQUIRED
    required String name,
    required String email,
    required String phone,
    required String userType,
    String? profession,
    String? photoUrl,
  }) async {
    // ... (Your implementation that checks existence and sets data) ...
    try {
      final docRefUser = _firestore.collection('users').doc(userId);
      final docRefProf = _firestore.collection('professionals').doc(userId);
      final docSnapUser = await docRefUser.get();
      final docSnapProf = await docRefProf.get();

      if (docSnapUser.exists || docSnapProf.exists) {
        print("User profile already exists for $userId. Skipping creation.");
        return;
      }

      Map<String, dynamic> userData = {/* ... your user data map ... */};
      userData['id'] = userId; // Make sure ID is set
      userData['profileImage'] = photoUrl ?? ''; // Use photoUrl

      if (userType == 'client') {
        // ... add client specific fields ...
        await docRefUser.set(userData);
        print('Client profile created for user $userId');
      } else {
        // worker
        // ... add worker specific fields ...
        userData['profession'] = profession ?? '';
        userData['profileComplete'] = false; // Needs setup
        await docRefProf.set(userData);
        print('Worker base profile created for user $userId');
      }
    } catch (e) {
      print('Error creating/checking user profile: $e');
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
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        print('Google Sign In cancelled.');
        return null;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      print('Signing in to Firebase with Google...');
      final UserCredential userCredential = await signInWithCredential(
        credential,
      ); // <-- Use the corrected method
      print('Firebase Google Sign In OK: ${userCredential.user?.uid}');
      if (userCredential.user != null) {
        await createUserProfile(
          // Ensure profile exists/is created after Google Sign in
          userId: userCredential.user!.uid,
          name: userCredential.user!.displayName ?? 'Google User',
          email: userCredential.user!.email ?? '',
          phone:
              userCredential.user!.phoneNumber ??
              '', // Usually empty from Google
          userType: 'client',
          photoUrl: userCredential.user!.photoURL,
        ); // Default Google user to client
      }
      return userCredential;
    } catch (e, s) {
      print('Google Sign In Error: $e\n$s');
      rethrow;
    }
  }

  // Create user profile in Firestore

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
      if (professionalDoc.exists && professionalDoc.data() != null) {
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
      if (clientDoc.exists && clientDoc.data() != null) {
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
      print('User signed out');
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
}

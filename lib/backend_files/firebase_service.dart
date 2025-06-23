import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  static Future<void> _createOrUpdateUserDocument({
    required User user,
    String? username, // Email signup ke liye
  }) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final doc = await userRef.get();

    // Agar document mojood nahi hai (naya user)
    if (!doc.exists) {
      final String finalUsername = username ?? user.displayName ?? user.email!.split('@')[0];
      await userRef.set({
        'uid': user.uid,
        'email': user.email,
        'username': finalUsername,
        'avatar': null, // Shuru mein avatar null hoga
        'isPremium': false,
        'createdAt': FieldValue.serverTimestamp(), // Sirf yahan set hoga
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } else {
      // Agar user pehle se mojood hai, to sirf lastLogin update karein
      await userRef.update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }

  // --- Email/Password Sign Up ---
  static Future<User?> signUpWithEmail(String email, String password, String username) async {
    try {
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        // User create hone ke baad Firestore mein document banayein
        await _createOrUpdateUserDocument(
          user: userCredential.user!,
          username: username,
        );
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw getFriendlyErrorMessage(e); // Friendly error message istemal karein
    } catch (e) {
      throw 'An unexpected error occurred during sign up.';
    }
  }

  // --- Email/Password Login ---
  static Future<User?> loginWithEmail(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);

      // Login ke baad 'lastLogin' timestamp update karein
      if (userCredential.user != null) {
        await _createOrUpdateUserDocument(user: userCredential.user!);
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw getFriendlyErrorMessage(e);
    } catch (e) {
      throw 'An unexpected error occurred during login.';
    }
  }

  // --- Google Sign-In ---
  static Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null; // User ne cancel kar diya

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        // Google sign-in ke baad Firestore mein document banayein ya update karein
        await _createOrUpdateUserDocument(user: userCredential.user!);
      }

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw getFriendlyErrorMessage(e);
    } catch (e) {
      throw 'An unexpected error occurred during Google Sign-In.';
    }
  }

  // --- USER PROFILE UPDATE ---
  // Yeh function sirf profile settings page se data update karne ke liye hai.
  static Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      throw 'Failed to update user profile.';
    }
  }

  // --- Email Verification ---
  static Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw 'Failed to send verification email.';
    }
  }

  // --- Password Reset ---
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw getFriendlyErrorMessage(e);
    } catch (e) {
      throw 'Failed to send password reset email.';
    }
  }

  // --- Sign Out ---
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
    } catch (e) {
      throw 'Failed to sign out.';
    }
  }

  // --- Account Deletion ---
  static Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Pehle Firestore se document delete karein
        await _firestore.collection('users').doc(user.uid).delete();
        // Phir Auth se user delete karein
        await user.delete();
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw 'Please re-authenticate before deleting your account.';
      }
      throw getFriendlyErrorMessage(e);
    } catch (e) {
      throw 'Failed to delete account.';
    }
  }

  // --- Friendly Error Messages ---
  static String getFriendlyErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'This email is already in use by another account.';
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase Authentication Service
class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Sign up with email and password
  Future<UserCredential?> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Create user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);

      // Save user data to Firestore with timeout (don't block registration if Firestore fails)
      if (credential.user != null) {
        try {
          await _firestore.collection('users').doc(credential.user!.uid).set({
            'uid': credential.user!.uid,
            'name': name,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              // Firestore save timed out, but user is still created
              print(
                  'Firestore save timed out, but user registered successfully');
            },
          );
        } catch (firestoreError) {
          // Don't fail registration if Firestore save fails
          print('Firestore save failed: $firestoreError');
        }
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Reset password failed: $e');
    }
  }

  /// Update user profile
  Future<void> updateProfile({
    String? name,
    String? photoUrl,
  }) async {
    try {
      if (name != null) {
        await currentUser?.updateDisplayName(name);
      }
      if (photoUrl != null) {
        await currentUser?.updatePhotoURL(photoUrl);
      }

      // Update Firestore
      if (currentUser != null) {
        final updates = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (name != null) updates['name'] = name;
        if (photoUrl != null) updates['photoUrl'] = photoUrl;

        await _firestore
            .collection('users')
            .doc(currentUser!.uid)
            .update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    if (currentUser == null) return null;

    try {
      final doc =
          await _firestore.collection('users').doc(currentUser!.uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  /// Delete account
  Future<void> deleteAccount() async {
    try {
      if (currentUser != null) {
        // Delete user data from Firestore
        await _firestore.collection('users').doc(currentUser!.uid).delete();

        // Delete auth account
        await currentUser!.delete();
      }
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }

  /// Handle Firebase Auth exceptions
  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'weak-password':
          return 'Password is too weak. Use at least 6 characters.';
        case 'email-already-in-use':
          return 'An account already exists with this email.';
        case 'invalid-email':
          return 'Please enter a valid email address.';
        case 'user-not-found':
          return 'No account found with this email.';
        case 'wrong-password':
          return 'Incorrect password. Please try again.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'This operation is not allowed.';
        case 'network-request-failed':
          return 'Network error. Please check your connection.';
        default:
          return e.message ?? 'An error occurred. Please try again.';
      }
    }
    return e.toString();
  }

  /// Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Save user data to Firestore if new user
      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        final user = userCredential.user;
        if (user != null) {
          await _firestore.collection('users').doc(user.uid).set({
            'uid': user.uid,
            'name': user.displayName ?? '',
            'email': user.email ?? '',
            'photoUrl': user.photoURL,
            'provider': 'google',
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(_handleAuthException(e));
    } catch (e) {
      throw Exception('Google Sign-In failed: $e');
    }
  }

  /// Sign out from Google
  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}

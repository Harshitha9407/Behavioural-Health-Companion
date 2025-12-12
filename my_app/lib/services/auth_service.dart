import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _user ?? _auth.currentUser;
  bool get isLoggedIn => currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthService() {
    // Listen to auth state changes
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _user = _auth.currentUser;
  }

  void _onAuthStateChanged(User? user) {
    _user = user;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Email and Password Sign In
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _user = result.user;
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Email and Password Registration
  Future<bool> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String displayName,
    String? phoneNumber,
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(displayName);
        
        // Send email verification
        await user.sendEmailVerification();
        
        // Create user document in Firestore
        await _createUserDocument(user, displayName, phoneNumber);
        
        _user = user;
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('An unexpected error occurred. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Google Sign In
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);
      
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setError('Google sign in was cancelled');
        return false;
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;
      
      if (user != null) {
        // Create or update user document
        await _createUserDocument(user, user.displayName ?? 'Google User');
        _user = user;
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('Google sign in failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Phone Number Sign In
  Future<void> signInWithPhoneNumber({
    required String phoneNumber,
    required Function(String) onCodeSent,
    required Function(String) onError,
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Automatic verification (Android only)
          try {
            UserCredential result = await _auth.signInWithCredential(credential);
            if (result.user != null) {
              await _createUserDocument(
                result.user!, 
                result.user!.phoneNumber ?? 'Phone User'
              );
              _user = result.user;
            }
          } catch (e) {
            onError('Automatic verification failed');
          } finally {
            _setLoading(false);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _setLoading(false);
          onError(_getAuthErrorMessage(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          _setLoading(false);
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _setLoading(false);
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      _setLoading(false);
      onError('Phone verification failed. Please try again.');
    }
  }

  // Verify OTP
  Future<bool> verifyPhoneNumberWithOTP({
    required String verificationId,
    required String otpCode,
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otpCode,
      );
      
      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;
      
      if (user != null) {
        await _createUserDocument(
          user, 
          user.phoneNumber ?? 'Phone User'
        );
        _user = user;
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('OTP verification failed. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reset Password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _setError(null);
      
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('Failed to send password reset email. Please try again.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _googleSignIn.signOut();
      await _auth.signOut();
      _user = null;
    } catch (e) {
      _setError('Sign out failed');
    } finally {
      _setLoading(false);
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user, String displayName, [String? phoneNumber]) async {
    try {
      final userDoc = _firestore.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();
      
      if (!docSnapshot.exists) {
        await userDoc.set({
          'uid': user.uid,
          'email': user.email,
          'displayName': displayName,
          'phoneNumber': phoneNumber ?? user.phoneNumber,
          'photoURL': user.photoURL,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'emailVerified': user.emailVerified,
        });
      } else {
        // Update last login
        await userDoc.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'emailVerified': user.emailVerified,
        });
      }
    } catch (e) {
      print('Error creating/updating user document: $e');
    }
  }

  // Get user-friendly error messages
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      case 'invalid-verification-code':
        return 'The verification code is invalid.';
      case 'invalid-verification-id':
        return 'The verification ID is invalid.';
      case 'session-expired':
        return 'The session has expired. Please try again.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'invalid-phone-number':
        return 'The phone number is invalid.';
      case 'missing-phone-number':
        return 'Phone number is required.';
      default:
        return 'Authentication failed: ${e.message ?? 'Unknown error'}';
    }
  }

  // Get user profile data
  Future<Map<String, dynamic>?> getUserProfile() async {
    if (_user == null) return null;
    
    try {
      final doc = await _firestore.collection('users').doc(_user!.uid).get();
      return doc.data();
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<bool> updateUserProfile(Map<String, dynamic> profileData) async {
    if (_user == null) return false;
    
    try {
      _setLoading(true);
      _setError(null);
      
      // Update Firebase Auth display name if provided
      if (profileData['name'] != null) {
        await _user!.updateDisplayName(profileData['name']);
      }
      
      // Update Firestore document with all data from the map
      final updates = Map<String, dynamic>.from(profileData);
      updates['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('users').doc(_user!.uid).update(updates);
      
      await _user!.reload();
      _user = _auth.currentUser;
      
      return true;
    } catch (e) {
      _setError('Failed to update profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Send email verification
  Future<bool> sendEmailVerification() async {
    if (_user == null) return false;
    
    try {
      await _user!.sendEmailVerification();
      return true;
    } catch (e) {
      _setError('Failed to send verification email');
      return false;
    }
  }
}

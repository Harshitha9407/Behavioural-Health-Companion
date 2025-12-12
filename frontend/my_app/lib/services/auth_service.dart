import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'api_service.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ApiService _api = ApiService();
  
  User? _user;
  UserModel? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get currentUser => _user ?? _auth.currentUser;
  UserModel? get userProfile => _userProfile;
  bool get isLoggedIn => currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
    _user = _auth.currentUser;
    if (_user != null) {
      _loadUserProfile();
    }
  }

  void _onAuthStateChanged(User? user) {
    _user = user;
    if (user != null) {
      _loadUserProfile();
    } else {
      _userProfile = null;
    }
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

  /// ✅ FIXED: Get user profile (used by ProfileScreen)
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      // CRITICAL FIX: Changed from '/user/profile' to '/profile'
      final data = await _api.get('/profile');
      if (data != null) {
        _userProfile = UserModel.fromJson(data);
        notifyListeners();
        return {
          'name': _userProfile?.name,
          'phone': _userProfile?.phoneNumber,
          'age': _userProfile?.age,
          'gender': _userProfile?.gender,
          'dateOfBirth': _userProfile?.dateOfBirth?.toIso8601String(),
        };
      }
      return null;
    } catch (e) {
      print('! Error fetching profile: $e');
      return null;
    }
  }

  /// Load user profile from backend (private helper)
  Future<void> _loadUserProfile() async {
    try {
      final data = await _api.get('/profile');
      if (data != null) {
        _userProfile = UserModel.fromJson(data);
        print('✅ Profile loaded: ${_userProfile?.name}');
        notifyListeners();
      }
    } catch (e) {
      print('! Profile not found in backend: $e');
    }
  }

  /// Phone Number Sign In (Send OTP)
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
          try {
            UserCredential result = await _auth.signInWithCredential(credential);
            if (result.user != null) {
              await _handlePhoneAuthSuccess(result.user!, phoneNumber);
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
      onError('Phone verification failed: $e');
    }
  }

  /// Verify OTP
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
        await _handlePhoneAuthSuccess(user, user.phoneNumber ?? '');
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      _setError('OTP verification failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Handle phone auth success (register in backend if needed)
  Future<void> _handlePhoneAuthSuccess(User user, String phoneNumber) async {
    await _createUserDocument(user, user.displayName ?? 'Phone User', phoneNumber);
    
    try {
      await _loadUserProfile();
    } catch (e) {
      print('📤 User not in backend, registering phone user...');
      try {
        await _registerInBackend(
          firebaseUid: user.uid,
          email: user.email ?? '${user.uid}@phone.user',
          name: user.displayName ?? 'Phone User',
          phoneNumber: phoneNumber,
          gender: null,
          dateOfBirth: null,
          age: 0,
        );
        await _loadUserProfile();
      } catch (registerError) {
        print('❌ Failed to register phone user in backend: $registerError');
      }
    }
    _user = user;
    notifyListeners();
  }

  /// Email Registration
  Future<bool> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    String? phoneNumber,
    String? gender,
    DateTime? dateOfBirth,
    required int age,
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      
      print('🔥 Creating Firebase user...');
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;
      if (user == null) {
        throw Exception('Failed to create Firebase user');
      }

      print('✅ Firebase user created: ${user.uid}');
      
      await user.updateDisplayName(name);
      await _createUserDocument(user, name, phoneNumber);
      
      print('📤 Registering in backend...');
      await _registerInBackend(
        firebaseUid: user.uid,
        email: email,
        name: name,
        phoneNumber: phoneNumber,
        gender: gender,
        dateOfBirth: dateOfBirth,
        age: age,
      );
      
      await user.sendEmailVerification();
      
      _user = user;
      await _loadUserProfile();
      
      print('✅ Registration complete!');
      return true;
      
    } on FirebaseAuthException catch (e) {
      print('❌ Firebase error: ${e.code}');
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      print('❌ Registration error: $e');
      _setError('Registration failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Register in backend
  Future<void> _registerInBackend({
    required String firebaseUid,
    required String email,
    required String name,
    String? phoneNumber,
    String? gender,
    DateTime? dateOfBirth,
    required int age,
  }) async {
    try {
      final userModel = UserModel(
        firebaseUid: firebaseUid,
        email: email,
        name: name,
        phoneNumber: phoneNumber,
        gender: gender,
        dateOfBirth: dateOfBirth,
        age: age,
      );
      
      final response = await _api.post('/auth/register', userModel.toSignUpJson());
      
      if (response != null) {
        _userProfile = UserModel.fromJson(response);
        print('✅ Backend registration successful: ${_userProfile?.name}');
      }
    } catch (e) {
      print('❌ Backend registration failed: $e');
      throw Exception('Failed to register in backend: $e');
    }
  }

  /// Email Sign In
  Future<bool> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _setError(null);
      
      print('🔥 Signing in with email...');
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      _user = result.user;
      
      if (_user != null) {
        print('✅ Firebase sign in successful');
        await _loadUserProfile();
      }
      
      return true;
    } on FirebaseAuthException catch (e) {
      print('❌ Sign in error: ${e.code}');
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      print('❌ Sign in error: $e');
      _setError('Sign in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Google Sign In
  Future<bool> signInWithGoogle() async {
    try {
      _setLoading(true);
      _setError(null);
      
      print('🔥 Starting Google sign in...');
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
        print('✅ Google sign in successful: ${user.uid}');
        await _createUserDocument(user, user.displayName ?? 'Google User');
        
        try {
          await _loadUserProfile();
        } catch (e) {
          print('📤 User not in backend, registering...');
          await _registerInBackend(
            firebaseUid: user.uid,
            email: user.email!,
            name: user.displayName ?? 'Google User',
            phoneNumber: user.phoneNumber,
            gender: null,
            dateOfBirth: null,
            age: 0,
          );
          await _loadUserProfile();
        }
        
        _user = user;
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      print('❌ Google sign in error: ${e.code}');
      _setError(_getAuthErrorMessage(e));
      return false;
    } catch (e) {
      print('❌ Google sign in error: $e');
      _setError('Google sign in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ✅ FIXED: Update Profile
  Future<bool> updateUserProfile({
    String? name,
    String? phoneNumber,
    String? gender,
    DateTime? dateOfBirth,
    int? age,
  }) async {
    if (_user == null) return false;
    
    try {
      _setLoading(true);
      _setError(null);
      
      if (name != null) {
        await _user!.updateDisplayName(name);
      }
      
      final updates = <String, dynamic>{};
      if (name != null) updates['displayName'] = name;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      updates['updatedAt'] = FieldValue.serverTimestamp();
      
      await _firestore.collection('users').doc(_user!.uid).update(updates);
      
      final profileData = <String, dynamic>{};
      if (name != null) profileData['name'] = name;
      if (phoneNumber != null) profileData['phoneNumber'] = phoneNumber;
      if (gender != null) profileData['gender'] = gender;
      if (dateOfBirth != null) {
        profileData['dateOfBirth'] = dateOfBirth.toIso8601String().split('T')[0];
      }
      if (age != null) profileData['age'] = age;
      
      print('📤 Updating profile with data: $profileData');
      
      // CRITICAL FIX: Changed from '/user/profile' to '/profile'
      final response = await _api.put('/profile', profileData);
      
      if (response != null) {
        _userProfile = UserModel.fromJson(response);
        print('✅ Profile updated successfully');
      }
      
      await _user!.reload();
      _user = _auth.currentUser;
      
      return true;
    } catch (e) {
      print('❌ Update profile error: $e');
      _setError('Failed to update profile: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Reset Password
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
      _setError('Failed to send password reset email: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _googleSignIn.signOut();
      await _auth.signOut();
      _user = null;
      _userProfile = null;
    } catch (e) {
      _setError('Sign out failed');
    } finally {
      _setLoading(false);
    }
  }

  /// Create Firestore document
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
        await userDoc.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'emailVerified': user.emailVerified,
        });
      }
    } catch (e) {
      print('⚠️ Firestore error: $e');
    }
  }

  /// Get friendly error messages
  String _getAuthErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'Password is too weak (min 6 characters)';
      case 'email-already-in-use':
        return 'This email is already registered';
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'invalid-email':
        return 'Invalid email address';
      case 'user-disabled':
        return 'This account has been disabled';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      case 'operation-not-allowed':
        return 'Email/Password sign in is not enabled';
      case 'invalid-verification-code':
        return 'Invalid verification code';
      case 'invalid-phone-number':
        return 'Invalid phone number format';
      default:
        return 'Authentication failed: ${e.message ?? 'Unknown error'}';
    }
  }

  /// Send email verification
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
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/user_profile.dart';

class AuthService {
  FirebaseAuth? _auth;
  FirebaseFirestore? _firestore;
  GoogleSignIn? _googleSignIn;

  final _userController = StreamController<UserProfile?>.broadcast();
  UserProfile? _currentUser;
  bool _isFirebaseAvailable = false;

  AuthService() {
    _init();
  }

  UserProfile? get currentUser => _currentUser;
  Stream<UserProfile?> get userStream => _userController.stream;

  Future<void> _init() async {
    try {
      _auth = FirebaseAuth.instance;
      _firestore = FirebaseFirestore.instance;
      _googleSignIn = GoogleSignIn();
      _isFirebaseAvailable = true;

      _auth!.authStateChanges().listen((user) async {
        if (user != null) {
          final profile = await _fetchOrCreateProfile(user);
          _currentUser = profile;
          _userController.add(profile);
        } else {
          _currentUser = null;
          _userController.add(null);
        }
      });
    } catch (_) {
      // Firebase native config not yet provided; initialize mock profile for seamless app flow
      _isFirebaseAvailable = false;
      _currentUser = UserProfile(
        uid: 'user-yerosen-1',
        displayName: 'Yerosen Tamrat',
        email: 'yerosen@pushoff.app',
        totalValidReps: 1248,
        streakDays: 7,
        bestSet: 31,
        avgForm: 89.0,
        createdAt: DateTime(2026, 10, 1),
      );
      _userController.add(_currentUser);
    }
  }

  Future<UserProfile?> _fetchOrCreateProfile(User user) async {
    if (_firestore == null) return null;

    final docRef = _firestore!.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (doc.exists && doc.data() != null) {
      return UserProfile.fromMap(doc.data()!, uid: user.uid);
    }

    final newProfile = UserProfile(
      uid: user.uid,
      displayName: user.displayName ?? (user.email?.split('@').first ?? 'Push-Up Champ'),
      email: user.email ?? '',
      photoUrl: user.photoURL,
      createdAt: DateTime.now(),
    );

    await docRef.set(newProfile.toMap());
    return newProfile;
  }

  Future<UserProfile> signInWithEmailAndPassword(String email, String password) async {
    if (_isFirebaseAvailable && _auth != null) {
      final credential = await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final profile = await _fetchOrCreateProfile(credential.user!);
      _currentUser = profile;
      _userController.add(profile);
      return profile!;
    } else {
      // Offline/Local mock simulation
      await Future.delayed(const Duration(milliseconds: 300));
      _currentUser = UserProfile(
        uid: 'mock-user-id',
        displayName: email.split('@').first,
        email: email.trim(),
        totalValidReps: 64,
        streakDays: 7,
        bestSet: 31,
        avgForm: 89.0,
        createdAt: DateTime.now(),
      );
      _userController.add(_currentUser);
      return _currentUser!;
    }
  }

  Future<UserProfile> createUserWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    if (_isFirebaseAvailable && _auth != null) {
      final credential = await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await credential.user!.updateDisplayName(displayName.trim());

      final newProfile = UserProfile(
        uid: credential.user!.uid,
        displayName: displayName.trim(),
        email: email.trim(),
        createdAt: DateTime.now(),
      );

      if (_firestore != null) {
        await _firestore!.collection('users').doc(newProfile.uid).set(newProfile.toMap());
      }

      _currentUser = newProfile;
      _userController.add(newProfile);
      return newProfile;
    } else {
      await Future.delayed(const Duration(milliseconds: 300));
      _currentUser = UserProfile(
        uid: 'mock-user-${DateTime.now().millisecondsSinceEpoch}',
        displayName: displayName.trim().isNotEmpty ? displayName.trim() : email.split('@').first,
        email: email.trim(),
        createdAt: DateTime.now(),
      );
      _userController.add(_currentUser);
      return _currentUser!;
    }
  }

  Future<UserProfile> signInWithGoogle() async {
    if (_isFirebaseAvailable && _auth != null && _googleSignIn != null) {
      final googleUser = await _googleSignIn!.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled by user');
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth!.signInWithCredential(credential);
      final profile = await _fetchOrCreateProfile(userCredential.user!);
      _currentUser = profile;
      _userController.add(profile);
      return profile!;
    } else {
      await Future.delayed(const Duration(milliseconds: 350));
      _currentUser = UserProfile(
        uid: 'google-user-123',
        displayName: 'Yerosen Tamrat',
        email: 'yerosen@pushoff.app',
        totalValidReps: 1248,
        streakDays: 7,
        bestSet: 31,
        avgForm: 89.0,
        createdAt: DateTime.now(),
      );
      _userController.add(_currentUser);
      return _currentUser!;
    }
  }

  Future<void> signOut() async {
    if (_isFirebaseAvailable && _auth != null) {
      await _auth!.signOut();
      await _googleSignIn?.signOut();
    }
    _currentUser = null;
    _userController.add(null);
  }

  void dispose() {
    _userController.close();
  }
}


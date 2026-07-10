import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;

  AuthProvider() {
    _auth.authStateChanges().listen((user) async {
      if (user != null) {
        await loadUserData();
      } else {
        _userModel = null;
        notifyListeners();
      }
    });
  }

  // Sign Up
  Future<String> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      QuerySnapshot usernameCheck = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        return 'Username already taken';
      }

      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel user = UserModel(
        uid: cred.user!.uid,
        email: email,
        username: username,
      );

      await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .set(user.toJson());

      _userModel = user;
      notifyListeners();
      return 'success';
    } catch (e) {
      return e.toString();
    }
  }

  // Login
  Future<String> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      await loadUserData();
      return 'success';
    } catch (e) {
      return e.toString();
    }
  }

  // Load user data from Firestore
  Future<void> loadUserData() async {
    if (_auth.currentUser != null) {
      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();
      if (doc.exists) {
        _userModel = UserModel.fromJson(doc.data() as Map<String, dynamic>);
        notifyListeners();
      }
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    _userModel = null;
    notifyListeners();
  }
}
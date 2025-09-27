import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = Provider<AuthService>((ref) => AuthService());

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream để theo dõi trạng thái auth
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Đăng ký user
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required DateTime? dob,
  }) async {
    try {
      // Tạo user với Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Lưu profile vào Firestore
      if (result.user != null) {
        await _firestore.collection('users').doc(result.user!.uid).set({
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'dob': dob != null ? Timestamp.fromDate(dob) : null,
          'dobString': dob != null 
              ? '${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}'
              : '',
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'avatarUrl': '',
          'lastLogin': FieldValue.serverTimestamp(),
        });

        return result;
      }
      return null;
    } catch (e) {
      log('❌ Sign up error: $e');
      rethrow;
    }
  }

  // Đăng nhập
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Cập nhật lastLogin
      if (result.user != null) {
        await _firestore.collection('users').doc(result.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      return result;
    } catch (e) {
      log('❌ Sign in error: $e');
      rethrow;
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      log('❌ Sign out error: $e');
      rethrow;
    }
  }

  // Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // Lấy user profile từ Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      log('❌ Error getting user profile: $e');
      return null;
    }
  }
}
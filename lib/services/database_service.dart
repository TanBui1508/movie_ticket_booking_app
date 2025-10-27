// lib/services/database_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Provider để cung cấp một instance của DatabaseService
//    Giúp chúng ta có thể gọi các hàm bên trong nó từ các provider khác.
final databaseProvider = Provider<DatabaseService>((ref) => DatabaseService());

class DatabaseService {
  final _firestore = FirebaseFirestore.instance;

  // Hàm lấy dữ liệu người dùng từ Firestore bằng UID
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }
}

// 2. Provider chính cung cấp dữ liệu người dùng cho UI
//    Đây là một FutureProvider, nó sẽ thực thi một hàm Future và cung cấp kết quả.
final userDataProvider = FutureProvider<Map<String, dynamic>?>((ref) {
  // Lấy người dùng hiện tại từ Firebase Auth
  final user = FirebaseAuth.instance.currentUser;

  // Nếu có người dùng, gọi hàm getUserData từ DatabaseService
  if (user != null) {
    // ref.watch() sẽ "theo dõi" databaseProvider và cung cấp service cho chúng ta
    return ref.watch(databaseProvider).getUserData(user.uid);
  }

  // Nếu không có người dùng, trả về null
  return null;
});
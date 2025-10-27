import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinema_app_flutter/models/user_model.dart';
import 'package:cinema_app_flutter/main.dart'; // Import authStateProvider

// Provider cung cấp instance Firestore
final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

// Provider lấy thông tin AppUser của người dùng hiện tại
final currentUserDetailProvider = StreamProvider<AppUser?>((ref) {
  // Lắng nghe trạng thái đăng nhập Firebase Auth
  final authState = ref.watch(authStateProvider);

  // Dùng when để xử lý các trạng thái của authState
  return authState.when(
    data: (firebaseUser) {
      if (firebaseUser != null) {
        // Nếu đã đăng nhập, lắng nghe document user trong Firestore
        final firestore = ref.read(firestoreProvider);
        return firestore
            .collection('users')
            .doc(firebaseUser.uid) // Lấy doc theo UID
            .snapshots() // Dùng snapshots để tự cập nhật khi data thay đổi
            .map((snapshot) {
              if (snapshot.exists) {
                // Nếu document tồn tại, chuyển thành AppUser
                return AppUser.fromFirestore(snapshot);
              } else {
                // Có thể user vừa đăng ký nhưng chưa có record Firestore? Trả về null
                log('⚠️ Không tìm thấy document user cho UID: ${firebaseUser.uid}');
                return null;
              }
            });
      } else {
        // Nếu chưa đăng nhập, trả về stream chứa giá trị null
        return Stream.value(null);
      }
    },
    // Khi đang chờ trạng thái auth, trả về stream null
    loading: () => Stream.value(null),
    // Khi có lỗi auth, trả về stream null
    error: (error, stackTrace) {
        log('❌ Lỗi authStateProvider: $error');
        return Stream.value(null);
    }
  );
});
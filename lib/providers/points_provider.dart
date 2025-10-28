import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinema_app_flutter/models/point_transaction_model.dart';
import 'package:cinema_app_flutter/main.dart'; // Import authStateProvider
import 'user_provider.dart'; // Import firestoreProvider và currentUserDetailProvider

// Provider lấy TỔNG ĐIỂM của user hiện tại
final userTotalPointsProvider = StreamProvider<int>((ref) {
  
  // 1. Lắng nghe 'AsyncValue' (kết quả) của provider chi tiết user
  final userDetailAsyncValue = ref.watch(currentUserDetailProvider);

  // 2. Dùng .when để biến đổi (map) AsyncValue
  //    thành một Stream<int> tương ứng
  return userDetailAsyncValue.when(
    data: (appUser) {
      // Nếu có data, trả về một stream chỉ chứa 1 giá trị là số điểm
      return Stream.value(appUser?.totalPoints ?? 0);
    },
    loading: () {
      // Nếu đang loading, trả về một stream rỗng (hoặc Stream.value(0))
      return Stream.empty();
    },
    error: (err, stack) {
      // Nếu có lỗi, trả về một stream chứa lỗi đó
      return Stream.error(err, stack);
    },
  );
});

// Provider lấy LỊCH SỬ GIAO DỊCH điểm
final pointsHistoryProvider = StreamProvider<List<PointTransaction>>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestore = ref.read(firestoreProvider);

  final firebaseUser = authState.value;
  if (firebaseUser != null) {
    // Lấy dữ liệu từ sub-collection 'points_history' của user
    return firestore
        .collection('users')
        .doc(firebaseUser.uid)
        .collection('points_history')
        .orderBy('timestamp', descending: true) // Mới nhất lên đầu
        .limit(50) // Giới hạn 50 giao dịch gần nhất
        .snapshots()
        .map((snapshot) {
            try {
              return snapshot.docs.map((doc) => PointTransaction.fromFirestore(doc)).toList();
            } catch(e) {
               print("Lỗi parse PointTransaction: $e");
               return [];
            }
        });
  } else {
    return Stream.value([]); // Trả list rỗng nếu chưa đăng nhập
  }
});


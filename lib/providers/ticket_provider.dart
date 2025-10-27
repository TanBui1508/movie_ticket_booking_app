import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinema_app_flutter/models/ticket_model.dart';
import 'package:cinema_app_flutter/main.dart'; 
import 'user_provider.dart'; 

// Provider lấy danh sách vé của người dùng hiện tại
final userTicketsProvider = StreamProvider<List<Ticket>>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestore = ref.read(firestoreProvider);

  final firebaseUser = authState.value;
  if (firebaseUser != null) {
    return firestore
        .collection('tickets')
        .where('userId', isEqualTo: firebaseUser.uid) // Lọc theo userId
        .orderBy('bookingTime', descending: true) // Sắp xếp mới nhất trước
        .snapshots()
        .map((snapshot) {
            try {
               return snapshot.docs.map((doc) => Ticket.fromFirestore(doc)).toList();
            } catch(e) {
               print("Lỗi parse Ticket trong userTicketsProvider: $e");
               return [];
            }
        });
  } else {
    return Stream.value([]); // Trả list rỗng nếu chưa đăng nhập
  }
});
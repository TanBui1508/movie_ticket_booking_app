// lib/models/point_transaction_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PointTransaction {
  final String id;
  final int points; // Điểm (+50 hoặc -500)
  final String title;  // Lý do (VD: "Đặt vé: TỬ CHIẾN TRÊN KHÔNG")
  final Timestamp timestamp; // Ngày giao dịch
  final String? ticketId; // (Tùy chọn) ID của vé liên quan

  PointTransaction({
    required this.id,
    required this.points,
    required this.title,
    required this.timestamp,
    this.ticketId,
  });

  factory PointTransaction.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return PointTransaction(
      id: doc.id,
      points: (data['points'] as num?)?.toInt() ?? 0,
      title: data['title'] ?? 'Giao dịch không rõ',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      ticketId: data['ticketId'],
    );
  }

  // toFirestore (Nếu bạn cần tạo giao dịch từ app)
  Map<String, dynamic> toFirestore() {
    return {
      'points': points,
      'title': title,
      'timestamp': timestamp,
      'ticketId': ticketId,
      // userId sẽ là một phần của đường dẫn (users/{uid}/points_history)
    };
  }
}
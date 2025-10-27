// lib/models/voucher_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum VoucherStatus { available, used, expired }
enum VoucherType { percent, fixedAmount } 

class Voucher {
  final String? id;         
  final String userId;     
  final String code;        
  final String title;       
  final String description;  
  final String conditions;   
  final Timestamp expiryDate; 
  final VoucherType type;      
  final double value;        
  final VoucherStatus status;   
  final String? imageUrl;   
  final Timestamp? claimedAt;  

  Voucher({
    this.id,
    required this.userId,
    required this.code,
    required this.title,
    required this.description,
    required this.conditions,
    required this.expiryDate,
    required this.type,
    required this.value,
    this.status = VoucherStatus.available, 
    this.imageUrl,
    this.claimedAt,
  });

  // Helper để lấy tên enum từ string (khi đọc từ Firestore)
  static VoucherStatus _statusFromString(String? statusStr) { 
    return VoucherStatus.values.firstWhere(
          (e) => e.toString().split('.').last == statusStr,
          orElse: () => VoucherStatus.available,
        );
  }

  static VoucherType typeFromString(String? typeStr) { 
    return VoucherType.values.firstWhere(
          (e) => e.toString().split('.').last == typeStr,
          orElse: () => VoucherType.fixedAmount,
        );
  }

  factory Voucher.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Voucher(
      id: doc.id,
      userId: data['userId'] ?? '',
      code: data['code'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      conditions: data['conditions'] ?? '',
      expiryDate: data['expiryDate'] ?? Timestamp.now(),
      type: typeFromString(data['type']),
      value: (data['value'] as num?)?.toDouble() ?? 0.0,
      status: _statusFromString(data['status']),
      imageUrl: data['imageUrl'],
      claimedAt: data['claimedAt'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'code': code,
      'title': title,
      'description': description,
      'conditions': conditions,
      'expiryDate': expiryDate,
      'type': type.toString().split('.').last,
      'value': value,
      'status': status.toString().split('.').last,
      'imageUrl': imageUrl,
      'claimedAt': claimedAt ?? FieldValue.serverTimestamp(), // Tự đặt nếu chưa có
    };
  }

  // Helper để kiểm tra trạng thái thực tế dựa trên ngày hết hạn
  VoucherStatus get currentActualStatus {
     if (status == VoucherStatus.used) return VoucherStatus.used;
     if (expiryDate.toDate().isBefore(DateTime.now())) return VoucherStatus.expired;
     return VoucherStatus.available;
  }

  // Helper để kiểm tra sắp hết hạn (ví dụ: trong vòng 3 ngày tới)
  bool get isExpiringSoon {
     if (currentActualStatus != VoucherStatus.available) return false;
     final now = DateTime.now();
     final threeDaysFromNow = now.add(const Duration(days: 3));
     return expiryDate.toDate().isBefore(threeDaysFromNow) && expiryDate.toDate().isAfter(now);
  }
}
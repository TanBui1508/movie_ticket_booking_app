import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cinema_app_flutter/models/voucher_model.dart'; 

class VoucherTemplate {
  final String? id;
  final String code;       
  final String title;        
  final String description;  
  final String conditions;   
  final Timestamp expiryDate; 
  final VoucherType type;      
  final double value;        
  final String? imageUrl;    
  final bool isActive;       
  final int? usageLimitPerUser; 
  // final int totalUsageLimit; // Tổng giới hạn sử dụng toàn hệ thống
  // final List<String> applicableMovieIds; // Chỉ áp dụng cho phim nào
  // final List<String> applicableCinemaIds; // Chỉ áp dụng cho rạp nào

  VoucherTemplate({
    this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.conditions,
    required this.expiryDate,
    required this.type,
    required this.value,
    this.imageUrl,
    this.isActive = true, 
    this.usageLimitPerUser,
  });

  factory VoucherTemplate.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return VoucherTemplate(
      id: doc.id,
      code: data['code'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      conditions: data['conditions'] ?? '',
      expiryDate: data['expiryDate'] ?? Timestamp.now(),
      type: Voucher.typeFromString(data['type']), 
      value: (data['value'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'],
      isActive: data['isActive'] ?? true,
      usageLimitPerUser: (data['usageLimitPerUser'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code.toUpperCase(), 
      'title': title,
      'description': description,
      'conditions': conditions,
      'expiryDate': expiryDate,
      'type': type.toString().split('.').last,
      'value': value,
      'imageUrl': imageUrl,
      'isActive': isActive,
      'usageLimitPerUser': usageLimitPerUser,
    };
  }
}
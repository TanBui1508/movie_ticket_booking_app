import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;
  final String email;
  final String fullName;
  final String role;
  final String? phone;     
  final String? avatarUrl; 
  final int totalPoints;

  AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.phone,      
    this.avatarUrl,  
    this.totalPoints = 0,
  });

  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      role: data['role'] ?? 'user',
      phone: data['phone'],     
      avatarUrl: data['avatarUrl'], 
      totalPoints: (data['totalPoints'] as num?)?.toInt() ?? 0,
    );
  }

  // Thêm hàm toMap dùng khi update
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'phone': phone,
      'avatarUrl': avatarUrl,
    };
  }
}
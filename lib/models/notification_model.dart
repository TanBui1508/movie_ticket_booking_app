import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String? id;
  final String title;
  final String content;
  final Timestamp createdAt;
  final String type; 
  final bool isRead; 

  AppNotification({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.type,
    this.isRead = false, 
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(), 
      type: data['type'] ?? 'general', 
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'createdAt': createdAt,
      'type': type,
    };
  }
}
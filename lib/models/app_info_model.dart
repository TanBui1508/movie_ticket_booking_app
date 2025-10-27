import 'package:cloud_firestore/cloud_firestore.dart';

class AppInfo {
  final String id; 
  final String title;
  final String content;

  AppInfo({required this.id, required this.title, required this.content});

  factory AppInfo.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return AppInfo(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
    };
  }
}
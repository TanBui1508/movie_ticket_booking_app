import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import 'user_provider.dart'; 

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final firestore = ref.read(firestoreProvider);
  return firestore.collection('notifications')
         .orderBy('createdAt', descending: true)
         .snapshots()
         .map((snapshot) => snapshot.docs.map((doc) => AppNotification.fromFirestore(doc)).toList());
});
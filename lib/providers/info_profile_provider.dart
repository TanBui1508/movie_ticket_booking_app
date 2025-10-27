import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_info_model.dart';
import 'user_provider.dart'; 

final appInfoProvider = FutureProvider.family<AppInfo?, String>((ref, docId) async {
  final firestore = ref.read(firestoreProvider);
  final doc = await firestore.collection('info_profile').doc(docId).get();
  if (doc.exists) {
    return AppInfo.fromFirestore(doc);
  }
  return null; 
});
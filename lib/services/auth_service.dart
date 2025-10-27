import 'dart:developer';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authProvider = Provider<AuthService>((ref) => AuthService());

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  // ✅ THÊM CONSTRUCTOR ĐỂ TỰ ĐỘNG GỌI HÀM INIT
  AuthService() {
    initGoogleSignIn();
  }

  // Stream để theo dõi trạng thái auth
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Đăng ký user
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required DateTime? dob,
  }) async {
    try {
      // Tạo user với Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Lưu profile vào Firestore
      if (result.user != null) {
        await _firestore.collection('users').doc(result.user!.uid).set({
          'fullName': fullName,
          'email': email,
          'phone': phone,
          'dob': dob != null ? Timestamp.fromDate(dob) : null,
          'dobString': dob != null
              ? '${dob.day.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.year}'
              : '',
          'createdAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'avatarUrl': '',
          'role': 'user', // Đảm bảo gán role
          'lastLogin': FieldValue.serverTimestamp(),
        });

        return result;
      }
      return null;
    } catch (e) {
      log('❌ Sign up error: $e');
      rethrow;
    }
  }

  // ✅ HÀM INIT SẼ ĐƯỢC GỌI BỞI CONSTRUCTOR
  Future<void> initGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        serverClientId:
            '288116464396-uf80tsk0e6hqp6bj84gk9mi3p2c4iv04.apps.googleusercontent.com',
      );

      // (Không bắt buộc) thử đăng nhập nhẹ nếu đã có token sẵn
      await _googleSignIn.attemptLightweightAuthentication();
      log('✅ GoogleSignIn initialized');
    } catch (e) {
      log('❌ Lỗi khi khởi tạo GoogleSignIn: $e');
    }
  }

  // Đăng nhập
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Cập nhật lastLogin
      if (result.user != null) {
        await _firestore.collection('users').doc(result.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      return result;
    } catch (e) {
      log('❌ Sign in error: $e');
      rethrow;
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut(); // ✅ Đăng xuất khỏi Google
      await _auth.signOut(); // Đăng xuất khỏi Firebase
    } catch (e) {
      log('❌ Sign out error: $e');
      rethrow;
    }
  }

  // Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // Lấy user profile từ Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      DocumentSnapshot doc =
          await _firestore.collection('users').doc(uid).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      log('❌ Error getting user profile: $e');
      return null;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Kiểm tra hỗ trợ API authenticate mới
      if (await _googleSignIn.supportsAuthenticate()) {
        // ✅ Thêm await
        final GoogleSignInAccount? googleUser =
            await _googleSignIn.authenticate();

        if (googleUser == null) {
          log('⚠️ Người dùng đã hủy đăng nhập Google.');
          return null;
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final AuthCredential credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);
        final user = userCredential.user;

        // Lưu hoặc cập nhật Firestore user
        if (user != null) {
          final userDocRef = _firestore.collection('users').doc(user.uid);
          final userDoc = await userDocRef.get();

          if (!userDoc.exists) {
            // ✅ SỬA: ĐỒNG BỘ CÁC TRƯỜNG VỚI HÀM SIGNUP
            await userDocRef.set({
              'fullName': user.displayName ?? 'Người dùng mới',
              'email': user.email,
              'avatarUrl': user.photoURL ?? '',
              'phone': user.phoneNumber ?? '',
              'createdAt': FieldValue.serverTimestamp(),
              'lastLogin': FieldValue.serverTimestamp(),
              'isActive': true,
              'role': 'user', // ✅ Thêm
              'dob': null, // ✅ Thêm
              'dobString': '', // ✅ Thêm
            });
          } else {
            await userDocRef.update({
              'lastLogin': FieldValue.serverTimestamp(),
              'avatarUrl': user.photoURL ??
                  userDoc.data()?['avatarUrl'], // Cập nhật avatar
            });
          }
        }

        return userCredential;
      } else {
        log('Thiết bị không hỗ trợ phương thức authenticate().');
        // // Thử fallback về phương thức cũ (hiếm khi xảy ra trên mobile)
        //  final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        //  if (googleUser == null) { /* ... xử lý hủy ... */ return null; }
        //  // ... (logic tương tự như trên)
        return null;
      }
    } catch (e) {
      log('Lỗi khi đăng nhập Google: $e');
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      log('Đã gửi email khôi phục mật khẩu tới $email');
    } catch (e) {
      log('Lỗi gửi email khôi phục: $e');
      rethrow;
    }
  }
}

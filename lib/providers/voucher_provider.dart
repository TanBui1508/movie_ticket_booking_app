// lib/providers/voucher_provider.dart
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cinema_app_flutter/models/voucher_model.dart';
import 'package:cinema_app_flutter/main.dart'; // Import authStateProvider
import 'package:flutter_riverpod/legacy.dart';
import 'user_provider.dart'; // Import firestoreProvider
import 'package:cinema_app_flutter/models/voucher_template_model.dart';

// Provider lấy danh sách voucher của người dùng hiện tại
final userVouchersProvider = StreamProvider<List<Voucher>>((ref) {
  final authState = ref.watch(authStateProvider);
  final firestore = ref.read(firestoreProvider);

  final firebaseUser = authState.value;
  if (firebaseUser != null) {
    return firestore
        .collection('user_vouchers')
        .where('userId', isEqualTo: firebaseUser.uid) // Lọc theo userId
        // .orderBy('expiryDate', descending: false) // Sắp xếp theo ngày hết hạn gần nhất (tùy chọn)
        .snapshots()
        .map((snapshot) {
      try {
        // Thêm sắp xếp client-side để đưa voucher còn hạn lên trước
        var vouchers =
            snapshot.docs.map((doc) => Voucher.fromFirestore(doc)).toList();
        vouchers.sort((a, b) {
          // Ưu tiên available > expiring soon > used/expired
          int statusCompare = a.currentActualStatus.index
              .compareTo(b.currentActualStatus.index);
          if (statusCompare != 0) return statusCompare;
          // Nếu cùng status, sắp xếp theo ngày hết hạn gần nhất
          return a.expiryDate.compareTo(b.expiryDate);
        });
        return vouchers;
      } catch (e) {
        log("Lỗi parse Voucher: $e");
        return [];
      }
    });
  } else {
    return Stream.value([]); // Trả list rỗng nếu chưa đăng nhập
  }
});

// Provider quản lý tab đang chọn
enum VoucherFilter { all, available, expired, used }

final voucherFilterProvider =
    StateProvider<VoucherFilter>((ref) => VoucherFilter.all);

// Provider lọc danh sách voucher dựa trên tab
final filteredUserVouchersProvider = Provider<List<Voucher>>((ref) {
  final filter = ref.watch(voucherFilterProvider);
  final allVouchers =
      ref.watch(userVouchersProvider).value ?? []; // Lấy data từ stream

  if (filter == VoucherFilter.all) {
    return allVouchers;
  }

  return allVouchers.where((voucher) {
    final actualStatus = voucher.currentActualStatus; // Tính trạng thái thực tế
    switch (filter) {
      case VoucherFilter.available:
        return actualStatus == VoucherStatus.available;
      case VoucherFilter.expired:
        return actualStatus == VoucherStatus.expired;
      case VoucherFilter.used:
        return actualStatus == VoucherStatus.used;
      default:
        return true;
    }
  }).toList();
});

// Provider Service (nếu cần hàm add/update voucher)
final voucherServiceProvider = Provider((ref) => VoucherService(ref));

class VoucherService {
  final Ref _ref;
  VoucherService(this._ref);
  final _db = FirebaseFirestore.instance;

  // Hàm để user nhập mã và nhận voucher (ví dụ)
  Future<String> claimVoucherByCode(String code, String userId) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) return "Vui lòng nhập mã.";

    try {
      // 1. Tìm template voucher theo code và đang active
      final templateQuery = await _db
          .collection('voucher_templates')
          .where('code', isEqualTo: cleanCode)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (templateQuery.docs.isEmpty) {
        return "Mã voucher không hợp lệ, không hoạt động hoặc đã hết hạn.";
      }
      final template = VoucherTemplate.fromFirestore(templateQuery.docs.first);

      // 2. Kiểm tra ngày hết hạn của template (so với ngày hiện tại)
      if (template.expiryDate.toDate().isBefore(DateTime.now())) {
        return "Mã voucher đã hết hạn.";
      }

      // 3. (QUAN TRỌNG) Gọi hàm tạo voucher cho user (giống logic Admin)
      //    Có thể tạo Cloud Function để xử lý việc này bảo mật hơn
      //    hoặc copy/adapt hàm _createUserVoucherFromTemplate từ Admin FirestoreService
      await _createUserVoucherFromTemplate(userId, template); // <-- Cần hàm này

      return "Nhận voucher \"${template.title}\" thành công!";
    } on FirebaseException catch (e) {
      log("Lỗi claim voucher Firestore: $e");
      return "Lỗi Firestore khi nhận voucher (${e.code}).";
    } catch (e) {
      log("Lỗi claim voucher: $e");
      return "Đã có lỗi xảy ra khi nhận voucher.";
    }
  }

//    hoặc gọi Cloud Function để thực hiện logic này an toàn hơn
  Future<void> _createUserVoucherFromTemplate(
      String userId, VoucherTemplate template,
      {WriteBatch? batch}) async {
    // Lưu ý: Cần import Voucher, VoucherStatus từ voucher_model.dart

    // Chỉ kiểm tra giới hạn nếu usageLimitPerUser được đặt (khác null) VÀ lớn hơn 0
    if (template.usageLimitPerUser != null && template.usageLimitPerUser! > 0) {
      final existingCountSnapshot = await _db
          .collection('user_vouchers')
          .where('userId', isEqualTo: userId)
          .where('code', isEqualTo: template.code)
          .count()
          .get();

      // Kiểm tra count có null không (an toàn hơn)
      final count = existingCountSnapshot.count;
      if (count != null && count >= template.usageLimitPerUser!) {
        // Chỉ dùng ! khi đã chắc chắn usageLimitPerUser không null
        // Có thể throw Exception hoặc chỉ đơn giản là return/log log
        log('⚠️ User $userId đã đạt giới hạn nhận voucher ${template.code}');
        throw Exception(
            'Bạn đã nhận tối đa số lượng voucher này.'); // Throw lỗi để hàm claimVoucherByCode bắt được
        // return;
      }
    }

    final userVoucher = Voucher(
      userId: userId,
      code: template.code,
      title: template.title,
      description: template.description,
      conditions: template.conditions,
      expiryDate: template.expiryDate,
      type: template.type,
      value: template.value,
      status: VoucherStatus.available,
      imageUrl: template.imageUrl,
      claimedAt: Timestamp.now(),
    );
    await _db.collection('user_vouchers').add(userVoucher.toFirestore());
  }

  // Hàm đánh dấu voucher đã sử dụng
  Future<void> markVoucherAsUsed(String voucherId) {
    return _db
        .collection('user_vouchers')
        .doc(voucherId)
        .update({'status': VoucherStatus.used.toString().split('.').last});
  }
}

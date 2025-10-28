import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/voucher_model.dart';
import '../providers/voucher_provider.dart';
import '../main.dart';
import 'sigin_screen.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class VoucherWalletScreen extends ConsumerStatefulWidget {
  const VoucherWalletScreen({super.key});

  @override
  ConsumerState<VoucherWalletScreen> createState() =>
      _VoucherWalletScreenState();
}

class _VoucherWalletScreenState extends ConsumerState<VoucherWalletScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // ✅ Khởi tạo TabController với 4 tab
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        final newFilter = VoucherFilter.values[_tabController.index];
        ref.read(voucherFilterProvider.notifier).state = newFilter;
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ✅ Hàm nhập mã voucher
  void _showEnterCodeDialog(BuildContext context, WidgetRef ref) {
    final codeController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final isLoading = StateProvider<bool>((ref) => false);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nhập mã voucher'),
          content: Consumer(builder: (context, dialogRef, _) {
            final loading = dialogRef.watch(isLoading);
            return Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: codeController,
                    decoration: const InputDecoration(hintText: 'Nhập mã...'),
                    validator: (value) =>
                        value!.isEmpty ? 'Vui lòng nhập mã' : null,
                    enabled: !loading,
                  ),
                  if (loading) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ]
                ],
              ),
            );
          }),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            Consumer(builder: (context, dialogRef, _) {
              final loading = dialogRef.watch(isLoading);
              return FilledButton(
                onPressed: loading
                    ? null
                    : () async {
                        if (formKey.currentState!.validate()) {
                          final userId = ref.read(authStateProvider).value?.uid;
                          if (userId != null) {
                            dialogRef.read(isLoading.notifier).state = true;
                            final result = await ref
                                .read(voucherServiceProvider)
                                .claimVoucherByCode(
                                    codeController.text, userId);
                            dialogRef.read(isLoading.notifier).state = false;

                            if (context.mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result),
                                  backgroundColor: result.contains('thành công')
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              );
                            }
                          } else {
                            Navigator.pop(context);
                          }
                        }
                      },
                child: const Text('Xác nhận'),
              );
            }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredVouchers = ref.watch(filteredUserVouchersProvider);
    final vouchersAsync = ref.watch(userVouchersProvider);
    final user = ref.watch(authStateProvider).value;
    final theme = Theme.of(context);

    if (user == null) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text('Ví Voucher'),
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Vui lòng đăng nhập để xem voucher của bạn.'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SignInScreen())),
                child: const Text('Đăng nhập'),
              )
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Ví Voucher / Quà'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_card_outlined),
            tooltip: 'Nhập mã voucher',
            onPressed: () => _showEnterCodeDialog(context, ref),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
          indicatorColor: theme.colorScheme.primary,
          tabs: const [
            Tab(text: 'Tất cả'),
            Tab(text: 'Còn hạn'),
            Tab(text: 'Hết hạn'),
            Tab(text: 'Đã dùng'),
          ],
        ),
      ),
      body: vouchersAsync.when(
        data: (_) => filteredVouchers.isEmpty
            ? Center(
                child: Text(
                  _tabController.index == 0
                      ? 'Bạn chưa có voucher nào.'
                      : 'Không có voucher trong mục này.',
                  style: TextStyle(
                      fontSize: 16, color: theme.colorScheme.onSurfaceVariant),
                ),
              )
            : ListView.builder(
                padding:
                    const EdgeInsets.all(12.0).copyWith(bottom: 90), // ✅ sửa padding
                itemCount: filteredVouchers.length,
                itemBuilder: (context, index) {
                  return _VoucherCard(voucher: filteredVouchers[index]);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Lỗi tải voucher: $err')),
      ),
    );
  }
}

// ===========================================================
// === Voucher Card Widget ===
// ===========================================================
class _VoucherCard extends ConsumerWidget {
  final Voucher voucher;

  const _VoucherCard({required this.voucher});

  // ✅ SỬA: thêm tham số theme vào hàm màu
  Color _getCardColor(
      VoucherStatus status, bool isExpiringSoon, ThemeData theme) {
    final bool isDarkMode = theme.brightness == Brightness.dark;

    if (isDarkMode) {
      return theme.colorScheme.surfaceVariant.withOpacity(0.5);
    }

    if (status == VoucherStatus.available) {
      return isExpiringSoon ? Colors.orange.shade100 : Colors.green.shade100;
    } else if (status == VoucherStatus.used) {
      return Colors.blueGrey.shade100;
    } else {
      return Colors.grey.shade300;
    }
  }

  Color _getBorderColor(
      VoucherStatus status, bool isExpiringSoon, ThemeData theme) {
    final bool isDarkMode = theme.brightness == Brightness.dark;

    if (status == VoucherStatus.available) {
      return isExpiringSoon
          ? (isDarkMode ? Colors.orange.shade300 : Colors.deepOrange.shade600)
          : (isDarkMode ? Colors.green.shade300 : Colors.green.shade700);
    } else if (status == VoucherStatus.used) {
      return isDarkMode ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600;
    } else {
      return isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600;
    }
  }

  // ✅ SỬA: đóng ngoặc, định dạng đúng cho showBottomSheet
  void _showVoucherDetails(BuildContext context, WidgetRef ref) {
    final actualStatus = voucher.currentActualStatus;
    final theme = Theme.of(context);
    final borderColor =
        _getBorderColor(actualStatus, voucher.isExpiringSoon, theme);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r))),
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(
              20.0, 20.0, 20.0, bottomPadding > 0 ? bottomPadding : 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(voucher.title,
                  style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: borderColor)),
              SizedBox(height: 10.h),
              Text("Mã: ${voucher.code}",
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface)),
              SizedBox(height: 10.h),
              Text(
                  "HSD: ${DateFormat('dd/MM/yyyy HH:mm').format(voucher.expiryDate.toDate())}",
                  style: TextStyle(color: borderColor, fontSize: 14.sp)),
              const Divider(height: 20),
              Text("Mô tả:",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      color: theme.colorScheme.onSurface)),
              Text(voucher.description,
                  style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14.sp)),
              SizedBox(height: 10.h),
              Text("Điều kiện:",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.sp,
                      color: theme.colorScheme.onSurface)),
              Text(voucher.conditions,
                  style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 14.sp)),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Chia sẻ'),
                    onPressed: () {
                      final shareText =
                          "Nhận voucher '${voucher.title}' tại Cinema App! Mã: ${voucher.code}";
                      Share.share(shareText);
                    },
                  ),
                  if (actualStatus == VoucherStatus.available)
                    FilledButton.icon(
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Sử dụng ngay'),
                      style:
                          FilledButton.styleFrom(backgroundColor: borderColor),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: voucher.code));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã sao chép mã: ${voucher.code}'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final actualStatus = voucher.currentActualStatus;
    final cardColor =
        _getCardColor(actualStatus, voucher.isExpiringSoon, theme); // ✅ sửa: thêm theme
    final borderColor =
        _getBorderColor(actualStatus, voucher.isExpiringSoon, theme); // ✅ sửa: thêm theme
    final isAvailable = actualStatus == VoucherStatus.available;

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: InkWell(
        onTap: () => _showVoucherDetails(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.local_offer, color: borderColor, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voucher.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'HSD: ${DateFormat('dd/MM/yyyy').format(voucher.expiryDate.toDate())}',
                      style: TextStyle(fontSize: 12, color: borderColor),
                    ),
                    const SizedBox(height: 6),
                    isAvailable
                        ? SizedBox(
                            height: 30,
                            child: OutlinedButton(
                              onPressed: () =>
                                  _showVoucherDetails(context, ref),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: borderColor),
                                foregroundColor: borderColor,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Xem chi tiết',
                                  style: TextStyle(fontSize: 12)),
                            ),
                          )
                        : Text(
                            actualStatus == VoucherStatus.used
                                ? 'ĐÃ SỬ DỤNG'
                                : 'ĐÃ HẾT HẠN',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: borderColor,
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

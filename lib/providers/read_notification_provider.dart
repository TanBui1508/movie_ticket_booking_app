import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';

const String _readNotificationsKey = 'read_notification_ids';

// StateNotifier để quản lý danh sách ID đã đọc
class ReadNotificationsNotifier extends StateNotifier<Set<String>> {
  ReadNotificationsNotifier(this._prefs) : super({}); // Khởi tạo state rỗng

  final SharedPreferences _prefs;

  // Load danh sách ID đã đọc từ SharedPreferences khi khởi tạo
  Future<void> loadReadNotifications() async {
    final List<String> readIds = _prefs.getStringList(_readNotificationsKey) ?? [];
    state = Set.from(readIds); // Cập nhật state
    log("Đã load ${state.length} ID thông báo đã đọc.");
  }

  // Đánh dấu một thông báo là đã đọc
  Future<void> markAsRead(String notificationId) async {
    if (!state.contains(notificationId)) {
      state = {...state, notificationId}; 
      await _prefs.setStringList(_readNotificationsKey, state.toList()); // Lưu lại
       log("Đã đánh dấu ${notificationId} là đã đọc. Tổng: ${state.length}");
    }
  }

  // Đánh dấu tất cả là đã đọc
  Future<void> markAllAsRead(List<String> allNotificationIds) async {
    state = Set.from(allNotificationIds); 
    await _prefs.setStringList(_readNotificationsKey, state.toList()); 
    log("Đã đánh dấu tất cả ${state.length} thông báo là đã đọc.");
  }
}

// Provider cung cấp SharedPreferences (FutureProvider vì nó bất đồng bộ)
final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// Provider chính quản lý trạng thái đã đọc
final readNotificationsProvider = StateNotifierProvider<ReadNotificationsNotifier, Set<String>>((ref) {
  // Lấy SharedPreferences (sẽ đợi cho đến khi nó sẵn sàng)
  final prefs = ref.watch(sharedPreferencesProvider).value;

  // Chỉ tạo Notifier khi prefs đã sẵn sàng
  if (prefs != null) {
     final notifier = ReadNotificationsNotifier(prefs);
     notifier.loadReadNotifications(); // Load dữ liệu ban đầu
     return notifier;
  }
  // Trả về Notifier rỗng tạm thời trong khi chờ prefs
  // (StateNotifierProvider yêu cầu trả về non-null)
  return ReadNotificationsNotifier(InMemorySharedPreferences()); // Dùng tạm in-memory
});

// Lớp SharedPreferences giả lập cho trường hợp prefs chưa sẵn sàng
class InMemorySharedPreferences implements SharedPreferences {
  final Map<String, Object> _data = {};
  @override Future<bool> clear() async { _data.clear(); return true; }
  @override Future<bool> commit() async => true;
  @override bool containsKey(String key) => _data.containsKey(key);
  @override Object? get(String key) => _data[key];
  @override bool? getBool(String key) => _data[key] as bool?;
  @override double? getDouble(String key) => _data[key] as double?;
  @override int? getInt(String key) => _data[key] as int?;
  @override Set<String> getKeys() => _data.keys.toSet();
  @override String? getString(String key) => _data[key] as String?;
  @override List<String>? getStringList(String key) => _data[key] as List<String>?;
  @override Future<void> reload() async {}
  @override Future<bool> remove(String key) async { _data.remove(key); return true; }
  @override Future<bool> setBool(String key, bool value) async { _data[key] = value; return true; }
  @override Future<bool> setDouble(String key, double value) async { _data[key] = value; return true; }
  @override Future<bool> setInt(String key, int value) async { _data[key] = value; return true; }
  @override Future<bool> setString(String key, String value) async { _data[key] = value; return true; }
  @override Future<bool> setStringList(String key, List<String> value) async { _data[key] = value; return true; }
}
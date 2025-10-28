import 'dart:developer';
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:firebase_storage/firebase_storage.dart'; 
import 'package:cinema_app_flutter/providers/user_provider.dart';
import 'package:cinema_app_flutter/models/user_model.dart';
import 'package:flutter_riverpod/legacy.dart'; 

// Provider quản lý loading (Giữ nguyên)
final _isLoadingProvider = StateProvider<bool>((ref) => false);
// ✅ THAY ĐỔI: Provider này giờ lưu URL (String) của ảnh được chọn
//final _selectedAvatarUrlProvider = StateProvider<String?>((ref) => null);

const List<String> defaultAvatars = [
  'https://i.pinimg.com/736x/b7/91/44/b79144e03dc4996ce319ff59118caf65.jpg',
  'https://i.pinimg.com/736x/85/bd/b2/85bdb27c8cef704a132fdb0c55fc0629.jpg',
  'https://i.pinimg.com/736x/62/cb/bd/62cbbdd6d9a625a63bdab90d7b801c72.jpg',
  'https://i.pinimg.com/736x/74/31/1f/74311f8d3b7d9116d25a304aecc6dc00.jpg',
  'https://i.pinimg.com/736x/98/4b/67/984b67e0d91aa1d7174438829c18854c.jpg',
  'https://i.pinimg.com/736x/6e/b3/ce/6eb3ceadbf5beb06027ba57c9248f530.jpg',
  'https://i.pinimg.com/736x/f0/f4/7f/f0f47fa61c2583e8bf0d6b5e5f165f65.jpg',
  'https://i.pinimg.com/1200x/ec/53/1a/ec531a2987587635805d619a2d45f311.jpg',
];

class EditProfileScreen extends ConsumerStatefulWidget {
  final AppUser initialUser;
  const EditProfileScreen({super.key, required this.initialUser});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late TextEditingController _fullNameController;
  late TextEditingController _phoneController; 
  final _formKey = GlobalKey<FormState>();
  //final ImagePicker _picker = ImagePicker(); 
  String? _selectedAvatarUrl;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.initialUser.fullName);
    _phoneController = TextEditingController(text: widget.initialUser.phone ?? '');

    _selectedAvatarUrl = widget.initialUser.avatarUrl;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // Future<void> _pickImage() async {
  //   final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
  //   if (image != null) {
  //     ref.read(_selectedImageProvider.notifier).state = image; // Cập nhật ảnh đã chọn
  //   }
  // }

  // Future<String?> _uploadAvatar(String userId, XFile imageFile) async {
  //   try {
  //     final storageRef = FirebaseStorage.instance.ref();
  //     final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
  //     final avatarRef = storageRef.child('avatars/$userId/$fileName');

  //     final uploadTask = await avatarRef.putFile(File(imageFile.path));
  //     final downloadUrl = await uploadTask.ref.getDownloadURL();
  //     log('Avatar uploaded: $downloadUrl');
  //     return downloadUrl;
  //   } catch (e) {
  //     log('Lỗi tải avatar: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Lỗi tải ảnh lên: $e'), backgroundColor: Colors.red),
  //     );
  //     return null;
  //   }
  // }

  // ✅ HÀM _updateProfile (Đã sửa đổi)
  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      ref.read(_isLoadingProvider.notifier).state = true;
      
      // ✅ Lấy URL từ biến state local
      final selectedAvatarUrl = _selectedAvatarUrl; 

      try {
        final Map<String, dynamic> updateData = {
          'fullName': _fullNameController.text.trim(),
          'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          'avatarUrl': selectedAvatarUrl, // ✅ Gán URL đã chọn
        };

        final firestore = ref.read(firestoreProvider);
        await firestore.collection('users').doc(widget.initialUser.id).update(updateData);

        if (mounted) {
          // ❌ BỎ DÒNG RESET PROVIDER
          // ref.read(_selectedAvatarUrlProvider.notifier).state = null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật thành công!'), backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Lỗi cập nhật: $e'), backgroundColor: Colors.red),
           );
         }
      } finally {
         if (mounted) {
            ref.read(_isLoadingProvider.notifier).state = false;
         }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(_isLoadingProvider);
    // ✅ Watch URL avatar đã chọn (là String?)
    //final selectedAvatarUrl = ref.watch(_selectedAvatarUrlProvider); 
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface, 
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        title: const Text('Cập nhật thông tin')
      ),
      body: SingleChildScrollView( 
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              
              // ✅ HIỂN THỊ AVATAR (Dùng biến state local _selectedAvatarUrl)
              CircleAvatar(
                radius: 60,
                backgroundColor: theme.colorScheme.surfaceVariant,
                backgroundImage: (_selectedAvatarUrl != null && _selectedAvatarUrl!.isNotEmpty)
                    ? NetworkImage(_selectedAvatarUrl!)
                    : null as ImageProvider?, 
                child: (_selectedAvatarUrl == null || _selectedAvatarUrl!.isEmpty)
                    ? Text(
                        widget.initialUser.fullName.isNotEmpty ? widget.initialUser.fullName[0].toUpperCase() : '?',
                        style: TextStyle(fontSize: 50, color: theme.colorScheme.onSurfaceVariant),
                      )
                    : null,
              ),
              const SizedBox(height: 24),

              // ✅ MỤC CHỌN AVATAR
              Text('Chọn avatar của bạn', style: theme.textTheme.titleMedium),
              SizedBox(height: 12.h),
              Wrap(
                spacing: 10.w,
                runSpacing: 10.h,
                alignment: WrapAlignment.center,
                children: defaultAvatars.map((url) {
                  final fullUrl = url.startsWith('http') ? url : 'https://$url';
                  // ✅ So sánh với biến state local _selectedAvatarUrl
                  final bool isSelected = (_selectedAvatarUrl == fullUrl); 

                  return GestureDetector(
                    onTap: () {
                      // ✅ SỬA: Dùng setState để cập nhật biến local
                      setState(() {
                        _selectedAvatarUrl = fullUrl;
                      });
                    },
                    child: CircleAvatar(
                      radius: 30.r,
                      backgroundColor: isSelected ? theme.colorScheme.primary : Colors.transparent, 
                      child: CircleAvatar(
                         radius: 27.r,
                         backgroundImage: NetworkImage(fullUrl),
                         backgroundColor: theme.colorScheme.surfaceVariant,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),

              // --- (Các TextFormField giữ nguyên, không cần sửa) ---
               TextFormField(
                initialValue: widget.initialUser.email,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true, 
                  fillColor: theme.colorScheme.onSurface.withOpacity(0.05),
                  border: const OutlineInputBorder(borderSide: BorderSide.none),
                ),
                readOnly: true,
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (value) => value!.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại (Tùy chọn)',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 30),

              // --- Nút Lưu ---
              ElevatedButton(
                onPressed: isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Lưu thay đổi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
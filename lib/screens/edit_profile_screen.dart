import 'dart:developer';
import 'dart:io'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:firebase_storage/firebase_storage.dart'; 
import 'package:cinema_app_flutter/providers/user_provider.dart';
import 'package:cinema_app_flutter/models/user_model.dart';
import 'package:flutter_riverpod/legacy.dart'; 

final _isLoadingProvider = StateProvider<bool>((ref) => false);
final _selectedImageProvider = StateProvider<XFile?>((ref) => null);

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
  final ImagePicker _picker = ImagePicker(); 

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(text: widget.initialUser.fullName);
    _phoneController = TextEditingController(text: widget.initialUser.phone ?? '');

     Future.microtask(() => ref.read(_selectedImageProvider.notifier).state = null);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      ref.read(_selectedImageProvider.notifier).state = image; // Cập nhật ảnh đã chọn
    }
  }

  Future<String?> _uploadAvatar(String userId, XFile imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance.ref();
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final avatarRef = storageRef.child('avatars/$userId/$fileName');

      final uploadTask = await avatarRef.putFile(File(imageFile.path));
      final downloadUrl = await uploadTask.ref.getDownloadURL();
      log('Avatar uploaded: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      log('Lỗi tải avatar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải ảnh lên: $e'), backgroundColor: Colors.red),
      );
      return null;
    }
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      ref.read(_isLoadingProvider.notifier).state = true;
      final selectedImage = ref.read(_selectedImageProvider);
      String? newAvatarUrl = widget.initialUser.avatarUrl; 

      try {
        if (selectedImage != null) {
          newAvatarUrl = await _uploadAvatar(widget.initialUser.id, selectedImage);
          if (newAvatarUrl == null) {
             ref.read(_isLoadingProvider.notifier).state = false;
            return;
          }
        }

        final Map<String, dynamic> updateData = {
          'fullName': _fullNameController.text.trim(),
          'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(), // Lưu null nếu rỗng
          'avatarUrl': newAvatarUrl, 
        };

        final firestore = ref.read(firestoreProvider);
        await firestore.collection('users').doc(widget.initialUser.id).update(updateData);

        if (mounted) {
          ref.read(_selectedImageProvider.notifier).state = null; 
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật thành công!'), backgroundColor: Colors.green),
          );
          // Cập nhật lại provider user để màn hình Profile thấy thay đổi (không bắt buộc nếu dùng StreamProvider)
          // ref.refresh(currentUserDetailProvider); // Có thể cần hoặc không tùy cách dùng provider
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
    final selectedImage = ref.watch(_selectedImageProvider); 
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        // ✅ SỬA: Dùng màu của theme
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
              Stack( 
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    // ✅ SỬA: Dùng màu của theme
                    backgroundColor: theme.colorScheme.surfaceVariant, // Màu nền xám nhạt (theo theme)
                    backgroundImage: selectedImage != null
                        ? FileImage(File(selectedImage.path)) 
                        : (widget.initialUser.avatarUrl != null && widget.initialUser.avatarUrl!.isNotEmpty)
                            ? NetworkImage(widget.initialUser.avatarUrl!) 
                            : null as ImageProvider?, 
                    child: (selectedImage == null && (widget.initialUser.avatarUrl == null || widget.initialUser.avatarUrl!.isEmpty))
                        ? Text(
                            widget.initialUser.fullName.isNotEmpty ? widget.initialUser.fullName[0].toUpperCase() : '?',
                            // ✅ SỬA: Dùng màu chữ của theme
                            style: TextStyle(fontSize: 50, color: theme.colorScheme.onSurfaceVariant), // Chữ trên nền xám
                          )
                        : null,
                  ),
                  // Nút chọn ảnh
                  Material( 
                    // ✅ SỬA: Dùng màu theme
                    color: theme.colorScheme.primary, // Màu xanh dương
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: isLoading ? null : _pickImage,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        // ✅ SỬA: Dùng màu theme
                        child: Icon(Icons.edit, color: Colors.white, size: 20), // Chữ trắng trên nền primary
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 30),

              TextFormField(
                initialValue: widget.initialUser.email,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  // ✅ SỬA: Dùng màu của theme
                  filled: true, 
                  fillColor: theme.colorScheme.onSurface.withOpacity(0.05), // Màu nền xám/trắng mờ
                  border: const OutlineInputBorder(borderSide: BorderSide.none), // Bỏ viền
                ),
                readOnly: true,
                // ✅ SỬA: Dùng màu của theme
                style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.6)), // Màu chữ mờ
              ),
              const SizedBox(height: 20),

              // --- Họ và tên ---
              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  prefixIcon: Icon(Icons.person_outline),
                  //border: OutlineInputBorder(),
                ),
                validator: (value) => value!.trim().isEmpty ? 'Vui lòng nhập họ tên' : null,
              ),
              const SizedBox(height: 20),

              // --- Số điện thoại ---
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại (Tùy chọn)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  //border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                // Không cần validator nếu là tùy chọn
              ),
              const SizedBox(height: 30),

              // --- Nút Lưu ---
              ElevatedButton(
                onPressed: isLoading ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50), // Nút rộng tối đa
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
// sign_in_screen.dart - Cập nhật với AuthService
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:cinema_app_flutter/utils/theme.dart';
import 'package:cinema_app_flutter/widgets/custom_scaffold.dart';
import 'package:cinema_app_flutter/services/auth_service.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _formSignInKey = GlobalKey<FormState>();
  bool rememberPassword = true;
  bool _isLoading = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _signIn() async {
    if (_formSignInKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authService = ref.read(authProvider);
        await authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đăng nhập thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        String errorMsg;
        switch (e.code) {
          case 'user-not-found':
            errorMsg = 'Không tìm thấy tài khoản với email này.';
            break;
          case 'wrong-password':
            errorMsg = 'Mật khẩu không chính xác.';
            break;
          case 'invalid-email':
            errorMsg = 'Email không hợp lệ.';
            break;
          default:
            errorMsg = 'Lỗi đăng nhập: ${e.message}';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true); 
    try {
      final authService = ref.read(authProvider);
      final userCredential = await authService.signInWithGoogle();

      if (userCredential != null && mounted) {
        // Đăng nhập thành công, AuthWrapper sẽ tự chuyển màn hình
        // Nhưng nếu SignInScreen được push lên, chúng ta cần pop
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Đăng nhập với ${userCredential.user?.email} thành công!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      // Nếu userCredential là null (người dùng hủy), không làm gì cả
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Lỗi đăng nhập Google: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Tắt loading
      }
    }
  }

  // ✅ HÀM MỚI: XỬ LÝ QUÊN MẬT KHẨU
  Future<void> _forgotPassword() async {
    final email = _emailController.text.trim();

    // Kiểm tra xem email đã được nhập chưa
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Vui lòng nhập email của bạn vào ô bên trên để khôi phục.'),
          backgroundColor: Colors.orange,
        ),
      );
      return; // Dừng lại
    }

    // Validate email (đơn giản)
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email nhập vào không hợp lệ.'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Dừng lại
    }

    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authProvider);
      await authService.sendPasswordResetEmail(email: email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Đã gửi link khôi phục mật khẩu. Vui lòng kiểm tra email!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Lỗi: ${e.message}';
      if (e.code == 'user-not-found') {
        errorMsg = 'Không tìm thấy tài khoản nào ứng với email này.';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Đã xảy ra lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          Expanded(
            flex: 7,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formSignInKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Welcome back',
                        style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w900,
                          color: lightColorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 40.0),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Email không hợp lệ';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          label: const Text('Email'),
                          hintText: 'Enter Email',
                          // hintStyle: const TextStyle(color: Colors.black26),
                          // border: OutlineInputBorder(
                          //   borderSide: const BorderSide(color: Colors.black12),
                          //   borderRadius: BorderRadius.circular(10),
                          // ),
                          // enabledBorder: OutlineInputBorder(
                          //   borderSide: const BorderSide(color: Colors.black12),
                          //   borderRadius: BorderRadius.circular(10),
                          // ),
                        ),
                      ),
                      const SizedBox(height: 25.0),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        obscuringCharacter: '*',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập mật khẩu';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          label: const Text('Password'),
                          hintText: 'Enter Password',
                          // hintStyle: const TextStyle(color: Colors.black26),
                          // border: OutlineInputBorder(
                          //   borderSide: const BorderSide(color: Colors.black12),
                          //   borderRadius: BorderRadius.circular(10),
                          // ),
                          // enabledBorder: OutlineInputBorder(
                          //   borderSide: const BorderSide(color: Colors.black12),
                          //   borderRadius: BorderRadius.circular(10),
                          // ),
                        ),
                      ),
                      const SizedBox(height: 25.0),

                      // Remember me & Forgot password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: rememberPassword,
                                onChanged: (bool? value) {
                                  setState(() {
                                    rememberPassword = value!;
                                  });
                                },
                                activeColor: lightColorScheme.primary,
                              ),
                              const Text(
                                'Remember me',
                                style: TextStyle(color: Colors.black45),
                              ),
                            ],
                          ),
                          GestureDetector(
                            // ✅ SỬA onTap
                            onTap: _isLoading
                                ? null
                                : _forgotPassword, // Gọi hàm mới
                            child: Text(
                              'Forget password?',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: lightColorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25.0),

                      // Sign In Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _signIn,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: lightColorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Sign In',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),

                      // ... Giữ nguyên phần còn lại (divider, social icons, sign up link) ...

                      const SizedBox(height: 25.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Divider(
                              thickness: 0.7,
                              color: const Color.fromRGBO(158, 158, 158, 0.5),
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: 0, horizontal: 10),
                            child: Text(
                              'Or sign in with',
                              style: TextStyle(color: Colors.black45),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              thickness: 0.7,
                              color: const Color.fromRGBO(158, 158, 158, 0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25.0),
                      // ✅ SỬA LẠI CÁC NÚT SOCIAL
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Nút Google
                          _buildSocialButton(
                            icon: BoxIcons.bxl_google,
                            color: Colors.redAccent,
                            onTap: _isLoading
                                ? () {}
                                : _signInWithGoogle, // Gọi hàm mới
                          ),
                          // // Nút Facebook (chưa làm)
                          // _buildSocialButton(
                          //   icon: BoxIcons.bxl_facebook_circle,
                          //   color: Colors.blue,
                          //   onTap: () {/* TODO */},
                          // ),
                          // // Nút Twitter (chưa làm)
                          // _buildSocialButton(
                          //   icon: BoxIcons.bxl_twitter,
                          //   color: Colors.lightBlue,
                          //   onTap: () {/* TODO */},
                          // ),
                          // // Nút Apple (chưa làm)
                          // _buildSocialButton(
                          //   icon: BoxIcons.bxl_apple,
                          //   color: Colors.black,
                          //   onTap: () {/* TODO */},
                          // ),
                        ],
                      ),
                      const SizedBox(height: 25.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Don\'t have an account? ',
                            style: TextStyle(color: Colors.black45),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(
                                  context, '/signup'); // ✅ Named route
                            },
                            child: Text(
                              'Sign up',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: lightColorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ✅ THÊM WIDGET HELPER CHO NÚT SOCIAL
  Widget _buildSocialButton(
      {required IconData icon,
      required Color color,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.sp), // Dùng ScreenUtil
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Icon(icon, size: 30.sp, color: color), // Dùng ScreenUtil
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

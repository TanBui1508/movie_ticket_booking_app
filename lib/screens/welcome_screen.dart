import 'package:flutter/material.dart';
import 'package:cinema_app_flutter/utils/theme.dart';
import 'package:cinema_app_flutter/widgets/custom_scaffold.dart';
import 'package:cinema_app_flutter/widgets/welcome_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          Flexible(
            flex: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 40.0,
              ),
              child: Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: const TextStyle(color: Colors.white),
                    children: [
                      const TextSpan(
                        text: 'Xin chào!\n',
                        style: TextStyle(
                          fontSize: 45.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(
                        text: '\nHãy đăng nhập để tiếp tục.',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Flexible(
            flex: 1,
            child: Align(
              alignment: Alignment.bottomRight,
              child: Row(
                children: [
                  // Sign In Button - FIX: Truyền function thay vì widget
                  Expanded(                
                    child: WelcomeButton(
                      buttonText: 'Sign in',
                      onTap: () {
                        Navigator.pushNamed(context, '/signin');
                      },
                      color: Colors.transparent,
                      textColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16), // Thêm spacing giữa buttons
                  // Sign Up Button - FIX: Truyền function thay vì widget
                  Expanded(
                    child: WelcomeButton(
                      buttonText: 'Sign up',
                      onTap: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      color: Colors.white,
                      textColor: lightColorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
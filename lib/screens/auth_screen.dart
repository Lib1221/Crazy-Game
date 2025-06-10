import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _authController = Get.find<AuthController>();
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with arc
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 300),
            painter: ArcPainter(),
          ),

          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacingL),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 100),
                  Text(
                    'Welcome!',
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingS),
                  Text(
                    'Sign in or create an account',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                        ),
                  ),
                  const SizedBox(height: AppTheme.spacingXXL),

                  // Auth Form
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingL),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius:
                          BorderRadius.circular(AppTheme.borderRadiusLarge),
                      boxShadow: AppTheme.defaultShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingM),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                        ),
                        const SizedBox(height: AppTheme.spacingL),
                        Obx(() => ElevatedButton(
                              onPressed: _authController.isLoading.value
                                  ? null
                                  : () async {
                                      final success =
                                          await _authController.login(
                                        _emailController.text,
                                        _passwordController.text,
                                      );
                                      if (success) {
                                        Get.offAllNamed('/chats');
                                      }
                                    },
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(AppTheme.spacingM),
                                child: _authController.isLoading.value
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text('Sign In'),
                              ),
                            )),
                        const SizedBox(height: AppTheme.spacingM),
                        Obx(() => ElevatedButton(
                              onPressed: _authController.isLoading.value
                                  ? null
                                  : () async {
                                      if (_nameController.text.isEmpty) {
                                        Get.snackbar(
                                          'Error',
                                          'Please enter your name',
                                          snackPosition: SnackPosition.BOTTOM,
                                        );
                                        return;
                                      }
                                      final success =
                                          await _authController.signup(
                                        _nameController.text,
                                        _emailController.text,
                                        _passwordController.text,
                                      );
                                      if (success) {
                                        Get.offAllNamed('/chats');
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.accentColor,
                              ),
                              child: Padding(
                                padding:
                                    const EdgeInsets.all(AppTheme.spacingM),
                                child: _authController.isLoading.value
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text('Sign Up'),
                              ),
                            )),
                      ],
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

class ArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = AppTheme.primaryGradient.createShader(
        Rect.fromLTWH(0, 0, size.width, size.height),
      )
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, size.height * 0.8)
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * 1.2,
        size.width,
        size.height * 0.8,
      )
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
